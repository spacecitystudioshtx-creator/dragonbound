#!/usr/bin/env python3
"""
Character sprite generator — FireRed-proportioned original pixel people.

Each character sheet: 3 cols x 4 rows of 16x20 frames.
  rows: down, left, right, up   cols: step-A, idle, step-B
Left row is a pixel-mirror of right, so the engine never flips sprites.

Output: public/assets/chars/<name>.png + src/data/characters.gen.json
Run: python3 tools/generate_characters.py
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "assets" / "chars"
MANIFEST = ROOT / "src" / "data" / "characters.gen.json"

W, H = 16, 20
OUTLN = (34, 30, 38, 255)
SKIN = (244, 202, 160, 255)
SKIN_SH = (216, 168, 126, 255)


def px(d, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        d.point((x, y), c)


def rect(d, x0, y0, x1, y1, c):
    d.rectangle([x0, y0, x1, y1], fill=c)


class Look:
    """Palette + shape switches for one character."""

    def __init__(self, hair, shirt, pants, *, hat=None, hood=False, dress=False,
                 apron=False, short=False, gray_side=False, scarf=None):
        self.hair = hair
        self.shirt = shirt
        self.pants = pants
        self.hat = hat          # (color) flat cap
        self.hood = hood        # robe hood instead of hair
        self.dress = dress      # skirt to the ankles
        self.apron = apron      # light front panel
        self.short = short      # kid: everything squished down 2px
        self.gray_side = gray_side
        self.scarf = scarf

    def dk(self, c):
        return tuple(max(0, v - 44) for v in c[:3]) + (255,)

    def lt(self, c):
        return tuple(min(255, v + 36) for v in c[:3]) + (255,)


def draw_frame(look: Look, facing: str, step: int) -> Image.Image:
    """step: 0=A, 1=idle, 2=B."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    o = 2 if look.short else 0          # vertical squash for kids
    hair = look.hair
    bob = 1 if step != 1 else 0         # slight body bob while walking

    # ── legs (rows 15..19) ────────────────────────────────────────────────
    leg_top = 15 + (o // 2)
    boot = look.dk(look.pants)
    if look.dress:
        rect(d, 4, leg_top - 1, 11, 17, look.shirt)          # skirt
        rect(d, 4, 17, 11, 17, look.dk(look.shirt))
        # feet
        fa = 0 if step == 1 else (-1 if step == 0 else 1)
        rect(d, 5 + fa, 18, 6 + fa, 19, boot)
        rect(d, 9 + fa, 18, 10 + fa, 19, boot)
    else:
        if facing in ("down", "up"):
            lift_l = 1 if step == 0 else 0
            lift_r = 1 if step == 2 else 0
            rect(d, 5, leg_top, 7, 19 - lift_l, look.pants)
            rect(d, 8, leg_top, 10, 19 - lift_r, look.pants)
            rect(d, 5, 18 - lift_l, 7, 19 - lift_l, boot)
            rect(d, 8, 18 - lift_r, 10, 19 - lift_r, boot)
        else:  # side: stride
            spread = 0 if step == 1 else 2
            rect(d, 5 - spread // 2, leg_top, 7 - spread // 2, 19, look.pants)
            rect(d, 8 + spread // 2, leg_top, 10 + spread // 2, 19, look.pants)
            rect(d, 5 - spread // 2, 18, 7 - spread // 2, 19, boot)
            rect(d, 8 + spread // 2, 18, 10 + spread // 2, 19, boot)

    # ── body (rows 10..15) ────────────────────────────────────────────────
    body_top = 10 + o - (0 if facing in ("left", "right") else 0) + bob * 0
    rect(d, 4, body_top, 11, leg_top - (0 if look.dress else 0), look.shirt)
    rect(d, 4, leg_top - 1, 11, leg_top - 1, look.dk(look.shirt))
    if look.apron:
        rect(d, 6, body_top + 1, 9, leg_top + 2 if look.dress else leg_top, (240, 236, 224, 255))
    if look.scarf:
        rect(d, 4, body_top, 11, body_top + 1, look.scarf)
    # arms
    arm = look.shirt
    if facing == "down" or facing == "up":
        swing_l = 1 if step == 0 else 0
        swing_r = 1 if step == 2 else 0
        rect(d, 3, body_top + swing_l, 3, leg_top - 2 + swing_l, arm)
        rect(d, 12, body_top + swing_r, 12, leg_top - 2 + swing_r, arm)
        px(d, 3, leg_top - 1 + swing_l, SKIN)
        px(d, 12, leg_top - 1 + swing_r, SKIN)
    else:
        sw = -1 if step == 0 else (1 if step == 2 else 0)
        ax = 7 + sw
        rect(d, ax, body_top + 1, ax + 1, leg_top - 2, look.dk(arm))
        px(d, ax, leg_top - 1, SKIN)

    # ── head (rows 1..10) — drawn last so it overlaps the body ───────────
    ht = 1 + o + bob  # head top; bobs 1px while stepping
    hb = 9 + o + bob  # head bottom row
    if facing == "down":
        rect(d, 4, ht + 1, 11, hb, SKIN)
        rect(d, 3, ht + 2, 3, hb - 1, SKIN_SH)
        rect(d, 12, ht + 2, 12, hb - 1, SKIN_SH)
        # hair: top + sides + bangs (low forehead, GBA-style)
        rect(d, 3, ht, 12, ht + 3, hair)
        rect(d, 3, ht + 1, 4, ht + 5, hair)
        rect(d, 11, ht + 1, 12, ht + 5, hair)
        px(d, 5, ht + 4, hair)
        px(d, 7, ht + 4, hair)
        px(d, 10, ht + 4, hair)
        # eyes
        px(d, 5, ht + 5, OUTLN)
        px(d, 10, ht + 5, OUTLN)
        px(d, 5, ht + 6, OUTLN)
        px(d, 10, ht + 6, OUTLN)
        if look.hood:
            rect(d, 3, ht, 12, ht + 3, look.shirt)
            rect(d, 3, ht + 1, 4, hb - 1, look.shirt)
            rect(d, 11, ht + 1, 12, hb - 1, look.shirt)
    elif facing == "up":
        rect(d, 3, ht, 12, hb, hair if not look.hood else look.shirt)
        rect(d, 4, hb, 11, hb, SKIN_SH)  # neck sliver
        if look.gray_side:
            rect(d, 3, ht + 4, 12, hb - 1, look.lt(hair))
    else:  # right (left is mirrored later)
        rect(d, 4, ht + 1, 11, hb, SKIN)
        rect(d, 4, ht, 11, ht + 3, hair)
        rect(d, 4, ht + 1, 6, hb, hair)              # hair back
        rect(d, 7, ht + 3, 9, ht + 4, hair)           # fringe over brow
        px(d, 10, ht + 5, OUTLN)                      # eye
        px(d, 10, ht + 6, OUTLN)
        if look.hood:
            rect(d, 4, ht, 11, ht + 2, look.shirt)
            rect(d, 4, ht + 1, 6, hb, look.shirt)
    if look.hat:
        hat = look.hat
        rect(d, 3, ht, 12, ht + 2, hat)
        rect(d, 2, ht + 2, 13, ht + 3, hat)           # brim
        rect(d, 2, ht + 3, 13, ht + 3, look.dk(hat))

    # ── outline: 1px silhouette ───────────────────────────────────────────
    src = im.load()
    outline = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(outline)
    for y in range(H):
        for x in range(W):
            if src[x, y][3] == 0:
                for nx, ny in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                    if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] > 0 and src[nx, ny] != OUTLN:
                        od.point((x, y), OUTLN)
                        break
    im.alpha_composite(outline)
    return im


def build_sheet(look: Look) -> Image.Image:
    sheet = Image.new("RGBA", (W * 3, H * 4), (0, 0, 0, 0))
    for r, facing in enumerate(["down", "left", "right", "up"]):
        for c in range(3):
            if facing == "left":
                fr = draw_frame(look, "right", c).transpose(Image.FLIP_LEFT_RIGHT)
            else:
                fr = draw_frame(look, facing, c)
            sheet.paste(fr, (c * W, r * H))
    return sheet


def build_pet() -> Image.Image:
    """Tiny drake critter: same 3x4 layout, simple two-pose idle."""
    sheet = Image.new("RGBA", (W * 3, H * 4), (0, 0, 0, 0))
    for r in range(4):
        for c in range(3):
            im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            hop = 1 if c == 1 else 0
            body = (200, 92, 60, 255)
            belly = (240, 200, 140, 255)
            d.ellipse([3, 9 - hop, 12, 17 - hop], fill=body, outline=OUTLN)
            d.ellipse([5, 12 - hop, 10, 16 - hop], fill=belly)
            d.ellipse([7, 5 - hop, 14, 12 - hop], fill=body, outline=OUTLN)
            px(d, 12, 8 - hop, OUTLN)                       # eye
            d.polygon([(8, 5 - hop), (10, 1 - hop), (11, 5 - hop)], fill=body, outline=OUTLN)
            d.line([(3, 12 - hop), (0, 9 - hop)], fill=body, width=2)  # tail
            rect(d, 4, 17 - hop, 5, 18 - hop, OUTLN)
            rect(d, 10, 17 - hop, 11, 18 - hop, OUTLN)
            sheet.paste(im, (c * W, r * H))
    return sheet


CHARS: dict[str, Look] = {
    "player":     Look((92, 60, 40, 255), (216, 72, 56, 255), (52, 76, 128, 255), hat=(180, 40, 40, 255)),
    "ma":         Look((120, 76, 44, 255), (72, 150, 140, 255), (72, 150, 140, 255), dress=True, apron=True),
    "elder":      Look((208, 208, 200, 255), (88, 108, 76, 255), (88, 108, 76, 255), dress=True, gray_side=True),
    "acolyte":    Look((150, 110, 60, 255), (196, 148, 72, 255), (196, 148, 72, 255), hood=True, dress=True),
    "kid":        Look((132, 84, 40, 255), (240, 200, 72, 255), (92, 148, 84, 255), short=True),
    "fen":        Look((190, 190, 184, 255), (96, 120, 168, 255), (96, 120, 168, 255), hat=(214, 186, 120, 255)),
    "shopkeeper": Look((190, 96, 48, 255), (150, 96, 60, 255), (86, 70, 56, 255), apron=True),
    "sable":      Look((50, 46, 60, 255), (124, 84, 168, 255), (70, 70, 80, 255)),
    "brask":      Look((160, 64, 40, 255), (76, 72, 84, 255), (60, 56, 68, 255), scarf=(216, 72, 56, 255)),
    "villager":   Look((104, 72, 44, 255), (110, 150, 96, 255), (108, 88, 64, 255)),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    names = []
    for name, look in CHARS.items():
        build_sheet(look).save(OUT / f"{name}.png")
        names.append(name)
    build_pet().save(OUT / "pet.png")
    names.append("pet")
    MANIFEST.write_text(json.dumps({"frameW": W, "frameH": H, "chars": names}, indent=2) + "\n")
    print(f"{len(names)} character sheets -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
