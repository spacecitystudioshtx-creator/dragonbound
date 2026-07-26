# ComfyUI Setup For Dragonbound

Dragonbound can generate art from `data/art_queue.json` through ComfyUI's local
API, then automatically process the raw image into crisp game art.

## 1. Confirm ComfyUI Address

ComfyUI usually runs at:

```bash
http://127.0.0.1:8000
```

The Dragonbound setup uses `8000` because the installed ComfyUI Desktop logs on
this Mac show that port. If your browser shows a different address, edit:

```bash
config/comfyui.json
```

and change `url`, or run commands with:

```bash
COMFYUI_URL=http://127.0.0.1:8188 tools/comfyui_generate.py --check
```

The ComfyUI server must stay open while Codex generates assets. The desktop app
stops the backend when its window closes.

## 2. Pick A Checkpoint

With ComfyUI running:

```bash
tools/comfyui_generate.py --list-checkpoints
```

Copy one checkpoint name into `config/comfyui.json` as `checkpoint`.

Installed locally now:

- `v1-5-pruned-emaonly-fp16.safetensors`: reliable base model.
- `pixel_f2.safetensors`: SD 1.5 pixel LoRA, useful for rough pixel tests.
- `AziibPixelMix_Full.safetensors`: stronger pixel checkpoint, useful for
  overworld/background mockups; licensing metadata should be reviewed before
  using as the final commercial standard.
- `flux2-klein/FLUX.2-klein-4B.safetensors` plus
  `pixel-art-lora.safetensors`: promising game-sprite stack, but it needs a
  dedicated FLUX workflow with explicit text encoder/VAE nodes before it can be
  used through the queue runner.

Good model direction for this project:

- Use any strong SD 1.5 or SDXL pixel-art-friendly checkpoint you already have.
- If choosing later, prioritize models that produce crisp sprites and clean
  silhouettes over painterly illustration quality.
- A pixel-art LoRA can help, but the required part is still the post-process:
  nearest-neighbor resize, palette reduction, and manual taste checks.

## 3. Generate The Next Queued Asset

```bash
tools/comfyui_generate.py --mark-done
```

That will:

1. Read the next pending item from `data/art_queue.json`.
2. Submit a simple text-to-image workflow to ComfyUI.
3. Save the raw image into `art/generated/raw/`.
4. Process it into the asset's final output path.
5. Mark the queue item done.

To generate a specific item:

```bash
tools/comfyui_generate.py --id ember-front-refresh --mark-done
```

To test the connection:

```bash
tools/comfyui_generate.py --check
```

## 4. Current Workflow Shape

The first bridge uses ComfyUI's stock nodes:

- `CheckpointLoaderSimple`
- `CLIPTextEncode`
- `EmptyLatentImage`
- `KSampler`
- `VAEDecode`
- `SaveImage`

This keeps setup simple and avoids depending on custom nodes. Later, we can add
saved ComfyUI workflows for:

- Drake battle sprites.
- Trainer/warden portraits.
- 16x16 overworld tiles.
- Icons.

## 5. Quality Target

Even if ComfyUI outputs a large smooth image, the Dragonbound processor forces:

- Target size such as 64x64 or 16x16.
- Nearest-neighbor scaling.
- 16-color palette reduction.
- Transparent edge cleanup.

The best raw generations are simple, centered, full-body, and high contrast.

Current benchmark assets:

- `art/generated/candidates/auricinder_benchmark_hand_pixel.png`: target
  original baby-dragon silhouette and readability.
- `art/generated/backgrounds/kindra_route_background_v2.png`: current
  background quality target for bold readable retro scene language.
