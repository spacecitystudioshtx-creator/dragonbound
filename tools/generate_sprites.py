"""
Drake sprite generator — standalone Python version of sprite_generator.gd.

Uses stabilityai/stable-diffusion-3-medium-diffusers via HuggingFace Inference API
(free serverless tier).  Falls back to FLUX.1-schnell if SD3 fails.

Post-processing pipeline:
  1. Flood-fill from corners → removes black background, sets alpha=0
  2. Resize to 80×80 with Lanczos
  3. Quantize sprite region to 32 colours → enforces flat GBA palette look

Output: art/drakes/<id>_front.png  (80×80, RGBA)
Log:    art/drakes/generation_log.txt

Usage (from project root):
    HF_TOKEN=hf_... python3 tools/generate_sprites.py
"""

import os, sys, time, json, io, logging
from collections import deque

try:
    import requests
    from PIL import Image
except ImportError:
    print("Missing deps. Run: pip3 install requests Pillow")
    sys.exit(1)

# ── config ─────────────────────────────────────────────────────────────────────
SD3_URL   = "https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-3-medium-diffusers"
FLUX_URL  = "https://router.huggingface.co/hf-inference/models/black-forest-labs/FLUX.1-schnell"

OUT_DIR    = os.path.join(os.path.dirname(__file__), "..", "art", "drakes")
TARGET_PX  = 80        # final sprite size (square)
GEN_W      = 512       # generation resolution
GEN_H      = 512
BG_THRESH  = 40        # flood-fill tolerance (lower = stricter bg removal)
MAX_RETRY  = 4         # 503 retries
PALETTE_N  = 32        # max colours in final sprite (GBA limit)

TOKEN = os.environ.get("HF_TOKEN", "")
if not TOKEN:
    print("Set HF_TOKEN environment variable before running.")
    sys.exit(1)

# ── logging ────────────────────────────────────────────────────────────────────
os.makedirs(OUT_DIR, exist_ok=True)
log_path = os.path.join(OUT_DIR, "generation_log.txt")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(message)s",
    handlers=[
        logging.FileHandler(log_path, mode="w"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger()

# ── style prompts ──────────────────────────────────────────────────────────────
STYLE_PREFIX = (
    "pixel art 16-bit GBA Game Boy Advance Pokemon FireRed official battle sprite, "
    "bold black outline, flat cell shading no gradients, strictly limited GBA color palette, "
    "front 3/4 view facing viewer, single bipedal dragon creature centered, "
    "pure solid black background, chunky readable pixels, gen 3 Pokemon style, "
    "no antialiasing, no smooth shading, hard pixel edges, "
)

NEG_PROMPT = (
    "blurry, realistic, photograph, 3d render, smooth gradients, airbrushed, "
    "anime style, chibi, too cute, multiple creatures, text, watermark, "
    "washed out, pastel, white background, sketch, pencil, painterly, "
    "overdetailed, noisy, jpeg artifacts, low quality, deformed, "
    "anti-aliased edges, smooth shading, photorealistic, high resolution art"
)

# ── sprite list ────────────────────────────────────────────────────────────────
SPRITES = [
    # ── Fire starter line ─────────────────────────────────────────────────
    ("ember",
     "small juvenile fire dragon hatchling, bright orange-red scales, "
     "pale orange segmented underbelly, tiny crimson membranous bat wings, "
     "flame-tipped tail, small ivory fangs and stubby horns, "
     "white eyes with red pupils, stocky compact bipedal body, fierce starter pose"),

    ("scornn",
     "medium fire dragon, deep blood-red and dark charcoal scales, "
     "row of ivory spikes along spine and shoulders, swept-back curved horns, "
     "dark ember-orange segmented underbelly, broad crimson bat wings, "
     "heavy muscular clawed arms, white eyes with red pupils, aggressive stance"),

    ("ashvane",
     "large volcanic fire dragon, dark charcoal slate-gray scales, "
     "ashen cream segmented underbelly plates, massive dark crimson membranous bat wings, "
     "crown of ivory spikes along head and spine, heavy muscular bipedal body, "
     "solid black eyes, apex dragon predator stance"),

    # ── Water starter line ────────────────────────────────────────────────
    ("ripple",
     "small aquatic dragon hatchling, bright sky-blue scales, "
     "pale white segmented underbelly, fin-shaped ear crests, "
     "white eyes with blue pupils, slim serpentine tail, tiny webbed claws, "
     "sleek cute water starter body, gentle alert pose"),

    ("undertow",
     "medium sea dragon, deep ocean blue scales with teal highlights, "
     "silver-white segmented underbelly, tall swept dorsal fin crest on head, "
     "powerful flipper-clawed arms, sinuous muscular body, "
     "white eyes with blue pupils, flowing ribbon tail fins, confident swimmer stance"),

    ("tidewrath",
     "large water leviathan dragon, dark midnight blue and deep teal armored scales, "
     "massive armored lower jaw full of sharp fangs, crimson segmented underbelly, "
     "enormous sweeping ocean fin wings, solid black eyes, "
     "thick serpentine neck, heavy apex sea predator, imposing front stance"),

    # ── Nature starter line ───────────────────────────────────────────────
    ("sprig",
     "small forest spirit dragon hatchling, bright leaf-green scales, "
     "cream woody segmented underbelly, two branching twig antlers, "
     "white eyes with amber pupils, small leaf-frond wings, vine-wrapped tail, "
     "round compact cute plant hatchling body, curious upright pose"),

    ("thicket",
     "medium bark-armored forest dragon, dark mahogany brown bark plating, "
     "forest-green moss patches between armor segments, white eyes with amber pupils, "
     "vine whip forearms with thorn hooks, leaf-edged wings, "
     "sturdy powerful guardian bipedal stance, nature protector"),

    ("ironbark",
     "large ancient tree golem dragon, very dark bark and stone-gray cracked body, "
     "gnarled root-like legs and sweeping root tail, massive trunk torso, "
     "solid black eyes under heavy stone brow ridge, "
     "rough cracked bark scales with ivy and lichen patches, "
     "towering ancient titan bipedal stance, awe-inspiring size"),

    # ── Common wild fodder ────────────────────────────────────────────────
    ("flick",
     "small quick common lizard drake, muddy grey-green scales, "
     "pale beige underbelly, wide alert white eyes with yellow pupils, slender swift body, "
     "long thin whip tail, tiny sharp claws, unassuming wild creature pose"),

    ("tuft",
     "small round fluffy common drake, cream and soft white fur, "
     "round large white eyes with black pupils, stubby tiny limbs barely visible, "
     "plump round balloon-like body, small folded pointed ears, "
     "harmless endearing common critter pose"),

    ("gulp",
     "small squat toad drake, bumpy warty dark olive-green skin, "
     "wide pale cream belly, enormous gaping tooth-lined mouth, "
     "bulging round white eyes with yellow pupils on top of flat head, "
     "short stubby powerful legs, hunched common swamp critter pose"),
]


# ── background removal ─────────────────────────────────────────────────────────

def remove_background(img: Image.Image, threshold: int = BG_THRESH) -> Image.Image:
    """
    Adaptive BFS flood-fill from all four corners.
    Samples actual corner pixel colours to find the real background colour
    (works even when the model generates gray/off-black backgrounds).
    Any connected pixels within `threshold` colour-distance of the corner
    sample are set to alpha=0.
    """
    rgba = img.convert("RGBA")
    w, h = rgba.size
    pixels = rgba.load()

    # Determine actual background colour from corner samples
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    bg_r = sum(pixels[x, y][0] for x, y in corners) // 4
    bg_g = sum(pixels[x, y][1] for x, y in corners) // 4
    bg_b = sum(pixels[x, y][2] for x, y in corners) // 4

    def is_bg(x: int, y: int) -> bool:
        r, g, b, _ = pixels[x, y]
        return (abs(r - bg_r) < threshold and
                abs(g - bg_g) < threshold and
                abs(b - bg_b) < threshold)

    visited = [[False] * h for _ in range(w)]
    queue   = deque()
    for sx, sy in corners:
        if is_bg(sx, sy) and not visited[sx][sy]:
            visited[sx][sy] = True
            queue.append((sx, sy))

    while queue:
        cx, cy = queue.popleft()
        r, g, b, _ = pixels[cx, cy]
        pixels[cx, cy] = (r, g, b, 0)
        for nx, ny in [(cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)]:
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny] and is_bg(nx, ny):
                visited[nx][ny] = True
                queue.append((nx, ny))

    return rgba


def quantize_sprite(img: Image.Image, n_colors: int = PALETTE_N) -> Image.Image:
    """
    Reduce the opaque sprite region to at most n_colors colours.
    Transparent pixels are kept transparent.
    This enforces the flat GBA cell-shading look.
    """
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    # Split alpha so quantisation doesn't smear the transparent edges
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))
    quantized = rgb.quantize(colors=n_colors, method=Image.Quantize.MEDIANCUT, dither=0)
    quantized = quantized.convert("RGB")

    # Reattach original alpha
    result = quantized.convert("RGBA")
    result.putalpha(a)
    return result


# ── API helpers ────────────────────────────────────────────────────────────────

def _post(url: str, prompt: str, steps: int, retry: int = 0) -> bytes:
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type":  "application/json",
    }
    body = json.dumps({
        "inputs": prompt,
        "parameters": {
            "negative_prompt": NEG_PROMPT,
            "width":  GEN_W,
            "height": GEN_H,
            "num_inference_steps": steps,
        },
        "options": {"wait_for_model": True},
    })
    resp = requests.post(url, headers=headers, data=body, timeout=300)

    if resp.status_code == 200:
        return resp.content

    if resp.status_code in (503, 504) and retry < MAX_RETRY:
        wait = 20.0
        try:
            j = resp.json()
            if "estimated_time" in j:
                wait = float(j["estimated_time"]) + 2.0
        except Exception:
            pass
        log.info(f"    HTTP {resp.status_code} — retrying in {int(wait)}s (attempt {retry + 2}/{MAX_RETRY + 1})")
        time.sleep(wait)
        return _post(url, prompt, steps, retry + 1)

    raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:300]}")


def call_api(prompt: str) -> bytes:
    """
    Try FLUX.1-schnell first — it reliably generates pure black backgrounds which
    makes flood-fill background removal accurate.  Fall back to SD3 if FLUX fails.
    """
    try:
        log.info("    Using FLUX.1-schnell …")
        return _post(FLUX_URL, prompt, steps=4)
    except RuntimeError as flux_err:
        log.warning(f"    FLUX failed ({flux_err}), trying SD3 …")
        return _post(SD3_URL, prompt, steps=20)


# ── main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    log.info(f"Drake sprite generation — {len(SPRITES)} sprites")
    log.info(f"Output: {os.path.abspath(OUT_DIR)}")
    log.info(f"Models: SD3 (primary) → FLUX.1-schnell (fallback)")

    # Delete existing stubs so fresh sprites are created
    deleted = 0
    for sid, _ in SPRITES:
        p = os.path.join(OUT_DIR, f"{sid}_front.png")
        if os.path.exists(p):
            os.remove(p)
            deleted += 1
    if deleted:
        log.info(f"Deleted {deleted} existing stub sprite(s).")

    ok, failed = 0, []

    for i, (sid, desc) in enumerate(SPRITES, 1):
        out_path = os.path.join(OUT_DIR, f"{sid}_front.png")
        prompt   = STYLE_PREFIX + desc
        log.info(f"\n[{i}/{len(SPRITES)}] {sid}")

        try:
            raw = call_api(prompt)

            # Decode
            img = Image.open(io.BytesIO(raw))
            log.info(f"    Generated: {img.size} {img.mode}")

            # Remove solid black background
            img = remove_background(img, threshold=BG_THRESH)

            # Resize to target
            img = img.resize((TARGET_PX, TARGET_PX), Image.LANCZOS)

            # Enforce GBA palette (flat cell-shading look)
            img = quantize_sprite(img, n_colors=PALETTE_N)

            img.save(out_path, "PNG")
            sz = os.path.getsize(out_path)
            log.info(f"    ✓ Saved {sid}_front.png ({sz:,} bytes)")
            ok += 1

        except Exception as exc:
            log.error(f"    ✗ {sid} failed: {exc}")
            failed.append(sid)
            time.sleep(2)

    log.info("\n" + "=" * 60)
    log.info(f"Done: {ok}/{len(SPRITES)} generated successfully.")
    if failed:
        log.info(f"Failed: {', '.join(failed)}")
    log.info("Restart Godot to import the new sprites.")


if __name__ == "__main__":
    main()
