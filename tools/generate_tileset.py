#!/usr/bin/env python3
"""
Dragonbound tileset generator — FireRed-inspired original pixel art.

Generates:
  public/assets/tiles/ground.png      16x16 ground/building tiles (8 columns)
  public/assets/tiles/props/*.png     y-sorted props (tree 16x32, well 16x24, ...)
  src/data/tileset.gen.json           name -> frame index manifest for ground.png

Design rules (what makes it read as GBA-era):
  - 3-tone shading per material (light / base / shadow), no gradients
  - 1px dark outlines on props and buildings
  - saturated but soft palette, warm paths, lush greens
Run: python3 tools/generate_tileset.py
"""
from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT_TILES = ROOT / "public" / "assets" / "tiles"
OUT_PROPS = OUT_TILES / "props"
MANIFEST = ROOT / "src" / "data" / "tileset.gen.json"

T = 16  # tile size
rng = random.Random(7)

# ── Palette ───────────────────────────────────────────────────────────────────
OUT = (34, 32, 36, 255)              # outline
GRASS = (104, 176, 88, 255)
GRASS_SH = (92, 160, 76, 255)
GRASS_DK = (76, 140, 64, 255)
MEADOW = (140, 200, 108, 255)
MEADOW_SH = (124, 184, 96, 255)
TALL = (56, 124, 52, 255)
TALL_HI = (76, 148, 64, 255)
PATH = (228, 204, 148, 255)
PATH_SH = (212, 188, 132, 255)
PATH_DK = (192, 168, 116, 255)
WATER = (72, 140, 224, 255)
WATER_HI = (132, 188, 248, 255)
WATER_DK = (48, 104, 184, 255)
FOAM = (224, 240, 252, 255)
TRUNK = (116, 84, 52, 255)
TRUNK_SH = (92, 64, 40, 255)
TREE_DK = (44, 100, 52, 255)
TREE_MD = (60, 132, 64, 255)
TREE_LT = (92, 168, 84, 255)
ROOF = (216, 96, 64, 255)
ROOF_HI = (240, 140, 96, 255)
ROOF_SH = (172, 64, 48, 255)
SLATE = (124, 148, 196, 255)
SLATE_HI = (164, 188, 228, 255)
SLATE_SH = (88, 108, 156, 255)
WALL = (240, 230, 204, 255)
WALL_SH = (216, 202, 172, 255)
WALL_LN = (192, 176, 144, 255)
STONE = (196, 196, 188, 255)
STONE_SH = (164, 164, 156, 255)
STONE_DK = (128, 128, 122, 255)
CAVE = (150, 132, 120, 255)
CAVE_SH = (124, 108, 98, 255)
CAVE_DK = (96, 82, 74, 255)
BRICK = (196, 120, 88, 255)
BRICK_SH = (164, 96, 68, 255)
DOOR = (146, 100, 60, 255)
DOOR_SH = (116, 78, 46, 255)
DOOR_HI = (176, 128, 84, 255)
GLASS = (120, 168, 208, 255)
GLASS_HI = (196, 228, 248, 255)
WOODF = (216, 176, 120, 255)
WOODF_SH = (200, 160, 106, 255)
WOODF_LN = (180, 142, 92, 255)
SFLOOR = (208, 200, 184, 255)
SFLOOR_SH = (192, 184, 168, 255)
RUG = (200, 72, 56, 255)
RUG_HI = (224, 112, 84, 255)
RUG_BD = (240, 200, 96, 255)
IWALL = (222, 200, 160, 255)
IWALL_SH = (200, 178, 140, 255)
IWALL_TOP = (72, 64, 84, 255)
FLAME_O = (248, 160, 56, 255)
FLAME_Y = (252, 220, 112, 255)
FENCE = (222, 196, 150, 255)
FENCE_SH = (196, 168, 122, 255)


def new_tile(w: int = T, h: int = T, bg=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (w, h), bg)


def speckle(d: ImageDraw.ImageDraw, w: int, h: int, color, n: int, seed: int) -> None:
    r = random.Random(seed)
    for _ in range(n):
        x, y = r.randrange(w), r.randrange(h)
        d.point((x, y), color)


# ── Ground tiles ──────────────────────────────────────────────────────────────
def t_grass(variant: int = 0) -> Image.Image:
    im = new_tile(bg=GRASS)
    d = ImageDraw.Draw(im)
    speckle(d, T, T, GRASS_SH, 14, 10 + variant)
    r = random.Random(20 + variant)
    for _ in range(3 + variant * 2):
        x, y = r.randrange(1, 14), r.randrange(1, 14)
        d.point([(x, y), (x + 1, y), (x, y - 1)], GRASS_DK)
    return im


def t_meadow() -> Image.Image:
    im = new_tile(bg=MEADOW)
    d = ImageDraw.Draw(im)
    speckle(d, T, T, MEADOW_SH, 12, 31)
    return im


def t_flowers(frame: int) -> Image.Image:
    im = t_grass(1)
    d = ImageDraw.Draw(im)
    spots = [(3, 4), (10, 3), (5, 11), (12, 10)]
    for i, (x, y) in enumerate(spots):
        sway = 1 if (frame + i) % 2 == 0 else 0
        petal = (248, 216, 96, 255) if i % 2 == 0 else (244, 148, 168, 255)
        d.point([(x - 1 + sway, y), (x + 1 + sway, y), (x + sway, y - 1), (x + sway, y + 1)], petal)
        d.point((x + sway, y), (252, 250, 240, 255))
        d.point((x, y + 2), GRASS_DK)
    return im


def t_path() -> Image.Image:
    im = new_tile(bg=PATH)
    d = ImageDraw.Draw(im)
    speckle(d, T, T, PATH_SH, 16, 40)
    speckle(d, T, T, PATH_DK, 5, 41)
    return im


def t_water(frame: int) -> Image.Image:
    im = new_tile(bg=WATER)
    d = ImageDraw.Draw(im)
    rows = [(2, 3), (7, 9), (12, 6)] if frame == 0 else [(3, 8), (8, 2), (13, 11)]
    for y, x in rows:
        d.line([(x, y), (x + 3, y)], WATER_HI)
        d.point((x + 1, y + 1), WATER_HI)
    speckle(d, T, T, WATER_DK, 6, 50 + frame)
    return im


# grass fringe overlays for path cells bordering grass (rounded organic edge)
def t_path_edge(side: str) -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    fringe = [GRASS, GRASS_SH]
    if side in ("n", "s"):
        y0 = 0 if side == "n" else T - 3
        for x in range(T):
            depth = 2 + (1 if (x % 4) in (1, 2) else 0)
            for i in range(depth):
                y = y0 + i if side == "n" else T - 1 - i
                d.point((x, y), fringe[i % 2] if i < depth - 1 else GRASS_DK)
    else:
        x0 = 0 if side == "w" else T - 3
        for y in range(T):
            depth = 2 + (1 if (y % 4) in (1, 2) else 0)
            for i in range(depth):
                x = x0 + i if side == "w" else T - 1 - i
                d.point((x, y), fringe[i % 2] if i < depth - 1 else GRASS_DK)
    return im


def t_water_edge(side: str) -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    if side == "n":
        d.rectangle([0, 0, T - 1, 1], fill=GRASS_DK)
        d.line([(0, 2), (T - 1, 2)], WATER_DK)
        for x in range(0, T, 3):
            d.point((x, 3), FOAM)
    elif side == "s":
        d.rectangle([0, T - 2, T - 1, T - 1], fill=GRASS_DK)
        d.line([(0, T - 3), (T - 1, T - 3)], WATER_DK)
    elif side == "w":
        d.rectangle([0, 0, 1, T - 1], fill=GRASS_DK)
        d.line([(2, 0), (2, T - 1)], WATER_DK)
    else:
        d.rectangle([T - 2, 0, T - 1, T - 1], fill=GRASS_DK)
        d.line([(T - 3, 0), (T - 3, T - 1)], WATER_DK)
    return im


# ── Building tiles ────────────────────────────────────────────────────────────
def t_roof_top(base, hi, sh) -> Image.Image:
    im = new_tile(bg=base)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, 1], fill=OUT)          # ridge outline
    d.rectangle([0, 2, T - 1, 3], fill=hi)           # ridge highlight
    d.line([(0, 9), (T - 1, 9)], sh)                 # shingle line
    d.line([(0, 15), (T - 1, 15)], sh)
    return im


def t_roof_mid(base, hi, sh) -> Image.Image:
    im = new_tile(bg=base)
    d = ImageDraw.Draw(im)
    d.line([(0, 4), (T - 1, 4)], sh)
    d.line([(0, 10), (T - 1, 10)], sh)
    for x in range(0, T, 4):
        d.point((x, 5), hi)
        d.point((x + 2, 11), hi)
    return im


def t_roof_eave(base, hi, sh) -> Image.Image:
    im = new_tile(bg=base)
    d = ImageDraw.Draw(im)
    d.line([(0, 6), (T - 1, 6)], sh)
    d.rectangle([0, 12, T - 1, 13], fill=sh)
    d.rectangle([0, 14, T - 1, 15], fill=OUT)        # eave shadow/outline
    return im


def t_wall(base, sh, ln) -> Image.Image:
    im = new_tile(bg=base)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, 0], fill=sh)           # under-eave shade
    d.line([(0, 6), (T - 1, 6)], ln)
    d.line([(0, 12), (T - 1, 12)], ln)
    d.rectangle([0, 14, T - 1, 15], fill=sh)         # base course
    return im


def t_wall_stone() -> Image.Image:
    im = new_tile(bg=STONE)
    d = ImageDraw.Draw(im)
    for y in (4, 9, 14):
        d.line([(0, y), (T - 1, y)], STONE_DK)
    for i, y in enumerate((0, 5, 10)):
        off = 0 if i % 2 == 0 else 4
        for x in range(off, T, 8):
            d.line([(x, y), (x, y + 4)], STONE_DK)
    speckle(d, T, T, STONE_SH, 10, 60)
    return im


def t_window() -> Image.Image:
    im = t_wall(WALL, WALL_SH, WALL_LN)
    d = ImageDraw.Draw(im)
    d.rectangle([3, 3, 12, 11], fill=OUT)
    d.rectangle([4, 4, 11, 10], fill=GLASS)
    d.line([(5, 5), (7, 5)], GLASS_HI)
    d.point((5, 6), GLASS_HI)
    d.line([(8, 4), (8, 10)], OUT)
    return im


def t_door(open_frac: float = 0.0) -> Image.Image:
    """Door in a wall. open_frac 0=closed, 0.5=half, 1=open (dark doorway)."""
    im = t_wall(WALL, WALL_SH, WALL_LN)
    d = ImageDraw.Draw(im)
    d.rectangle([3, 1, 12, 15], fill=OUT)                    # frame
    if open_frac >= 1.0:
        d.rectangle([4, 2, 11, 14], fill=(24, 20, 28, 255))  # open: dark interior
    else:
        d.rectangle([4, 2, 11, 14], fill=DOOR)
        d.rectangle([4, 2, 11, 3], fill=DOOR_HI)
        d.line([(4, 8), (11, 8)], DOOR_SH)
        d.point((10, 9), (232, 200, 120, 255))               # knob
        if open_frac > 0:
            d.rectangle([4, 2, 7, 14], fill=(24, 20, 28, 255))
    return im


def t_cave_wall() -> Image.Image:
    im = new_tile(bg=CAVE)
    d = ImageDraw.Draw(im)
    for y in (5, 11):
        d.line([(0, y), (T - 1, y)], CAVE_DK)
    for i, y in enumerate((0, 6)):
        off = 0 if i % 2 == 0 else 5
        for x in range(off, T, 9):
            d.line([(x, y), (x, y + 5)], CAVE_DK)
    speckle(d, T, T, CAVE_SH, 12, 70)
    return im


def t_brick() -> Image.Image:
    im = new_tile(bg=BRICK)
    d = ImageDraw.Draw(im)
    for y in (3, 7, 11, 15):
        d.line([(0, y), (T - 1, y)], BRICK_SH)
    for i in range(4):
        off = 0 if i % 2 == 0 else 4
        for x in range(off, T, 8):
            d.line([(x, i * 4), (x, i * 4 + 3)], BRICK_SH)
    return im


def t_fence() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.rectangle([0, 6, T - 1, 8], fill=FENCE)
    d.line([(0, 8), (T - 1, 8)], FENCE_SH)
    for x in (2, 8, 14):
        d.rectangle([x - 1, 3, x + 1, 13], fill=FENCE)
        d.line([(x + 1, 3), (x + 1, 13)], FENCE_SH)
        d.point([(x - 1, 3), (x, 2), (x + 1, 3)], FENCE_SH)
        d.line([(x - 1, 13), (x + 1, 13)], OUT)
    return im


# ── Interior tiles ────────────────────────────────────────────────────────────
def t_floor_wood() -> Image.Image:
    im = new_tile(bg=WOODF)
    d = ImageDraw.Draw(im)
    # long horizontal planks, subtle grain — no vertical joints (reads as brick)
    d.line([(0, 7), (T - 1, 7)], WOODF_SH)
    d.line([(0, 15), (T - 1, 15)], WOODF_SH)
    d.line([(2, 3), (5, 3)], WOODF_SH)
    d.line([(9, 11), (13, 11)], WOODF_SH)
    return im


def t_floor_stone() -> Image.Image:
    im = new_tile(bg=SFLOOR)
    d = ImageDraw.Draw(im)
    d.line([(0, 7), (T - 1, 7)], SFLOOR_SH)
    d.line([(7, 0), (7, 7)], SFLOOR_SH)
    d.line([(3, 8), (3, 15)], SFLOOR_SH)
    d.line([(11, 8), (11, 15)], SFLOOR_SH)
    return im


def t_rug() -> Image.Image:
    im = new_tile(bg=RUG)
    d = ImageDraw.Draw(im)
    speckle(d, T, T, RUG_HI, 8, 90)
    return im


def t_rug_edge(side: str) -> Image.Image:
    im = t_rug()
    d = ImageDraw.Draw(im)
    if side == "n":
        d.rectangle([0, 0, T - 1, 1], fill=RUG_BD)
    elif side == "s":
        d.rectangle([0, T - 2, T - 1, T - 1], fill=RUG_BD)
    elif side == "w":
        d.rectangle([0, 0, 1, T - 1], fill=RUG_BD)
    else:
        d.rectangle([T - 2, 0, T - 1, T - 1], fill=RUG_BD)
    return im


def t_mat() -> Image.Image:
    im = t_floor_wood()
    d = ImageDraw.Draw(im)
    d.rectangle([2, 3, 13, 13], fill=(96, 148, 108, 255))
    d.rectangle([2, 3, 13, 13], outline=(72, 116, 84, 255))
    d.polygon([(8, 10), (5, 7), (11, 7)], fill=(228, 236, 224, 255))
    d.rectangle([7, 4, 9, 7], fill=(228, 236, 224, 255))
    return im


def t_iwall() -> Image.Image:
    im = new_tile(bg=IWALL)
    d = ImageDraw.Draw(im)
    d.line([(0, 5), (T - 1, 5)], IWALL_SH)
    d.line([(0, 11), (T - 1, 11)], IWALL_SH)
    d.rectangle([0, 14, T - 1, 15], fill=IWALL_SH)
    return im


def t_iwall_top() -> Image.Image:
    return new_tile(bg=IWALL_TOP)


def t_counter() -> Image.Image:
    im = new_tile(bg=WOODF)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, 9], fill=DOOR_HI)
    d.rectangle([0, 0, T - 1, 1], fill=(232, 200, 150, 255))
    d.rectangle([0, 8, T - 1, 9], fill=DOOR_SH)
    d.rectangle([0, 10, T - 1, 11], fill=OUT)
    return im


def t_shelf() -> Image.Image:
    im = new_tile(bg=DOOR_SH)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, T - 1], outline=OUT)
    for y in (4, 10):
        d.rectangle([2, y, 13, y + 3], fill=DOOR_HI)
        for i, x in enumerate(range(3, 13, 3)):
            c = [(220, 120, 100, 255), (120, 170, 220, 255), (230, 210, 120, 255)][i % 3]
            d.rectangle([x, y, x + 1, y + 3], fill=c)
    return im


def t_table() -> Image.Image:
    im = t_floor_wood()
    d = ImageDraw.Draw(im)
    d.rectangle([2, 3, 13, 11], fill=OUT)
    d.rectangle([3, 4, 12, 9], fill=DOOR_HI)
    d.rectangle([3, 4, 12, 5], fill=(232, 200, 150, 255))
    d.point([(4, 12), (11, 12)], OUT)
    return im


def t_lava(frame: int) -> Image.Image:
    im = new_tile(bg=(200, 70, 30, 255))
    d = ImageDraw.Draw(im)
    spots = [(2, 3), (9, 6), (5, 12), (12, 11)] if frame == 0 else [(4, 5), (11, 3), (7, 10), (13, 13)]
    for x, y in spots:
        d.ellipse([x - 1, y - 1, x + 2, y + 1], fill=(248, 160, 56, 255))
        d.point((x, y), (252, 220, 112, 255))
    speckle(d, T, T, (160, 48, 24, 255), 8, 100 + frame)
    return im


def t_basalt() -> Image.Image:
    im = new_tile(bg=(88, 74, 70, 255))
    d = ImageDraw.Draw(im)
    d.line([(0, 7), (T - 1, 7)], (70, 58, 55, 255))
    d.line([(7, 0), (7, 7)], (70, 58, 55, 255))
    d.line([(3, 8), (3, 15)], (70, 58, 55, 255))
    d.line([(11, 8), (11, 15)], (70, 58, 55, 255))
    speckle(d, T, T, (104, 88, 82, 255), 8, 110)
    return im


def t_lava_edge(side: str) -> Image.Image:
    """Dark basalt lip where lava meets floor."""
    im = new_tile()
    d = ImageDraw.Draw(im)
    dk = (56, 44, 42, 255)
    if side == "n":
        d.rectangle([0, 0, T - 1, 1], fill=dk)
        for x in range(0, T, 3):
            d.point((x, 2), (248, 160, 56, 255))
    elif side == "s":
        d.rectangle([0, T - 2, T - 1, T - 1], fill=dk)
    elif side == "w":
        d.rectangle([0, 0, 1, T - 1], fill=dk)
    else:
        d.rectangle([T - 2, 0, T - 1, T - 1], fill=dk)
    return im


def t_banner() -> Image.Image:
    """Wall banner with ember sigil, drawn over wall_stone."""
    im = t_wall_stone()
    d = ImageDraw.Draw(im)
    d.rectangle([4, 0, 11, 12], fill=(160, 48, 40, 255))
    d.polygon([(4, 12), (11, 12), (10, 14), (7, 12), (5, 14)], fill=(160, 48, 40, 255))
    d.rectangle([4, 0, 11, 1], fill=(120, 34, 30, 255))
    d.polygon([(7, 4), (5, 9), (8, 8), (10, 9)], fill=(240, 180, 70, 255))
    px = d.point
    px((7, 5), (252, 220, 112, 255))
    return im


def t_painting() -> Image.Image:
    im = t_iwall()
    d = ImageDraw.Draw(im)
    d.rectangle([3, 2, 12, 10], fill=(120, 84, 48, 255))
    d.rectangle([4, 3, 11, 9], fill=(150, 196, 220, 255))
    d.polygon([(4, 9), (7, 5), (9, 8), (11, 6), (11, 9)], fill=(88, 132, 84, 255))
    d.ellipse([8, 4, 10, 6], fill=(248, 232, 150, 255))
    return im


def t_window_int() -> Image.Image:
    im = t_iwall()
    d = ImageDraw.Draw(im)
    d.rectangle([3, 2, 12, 11], fill=OUT)
    d.rectangle([4, 3, 11, 10], fill=(150, 200, 240, 255))
    d.line([(4, 4), (6, 4)], (222, 240, 252, 255))
    d.line([(8, 3), (8, 10)], OUT)
    d.line([(4, 7), (11, 7)], OUT)
    return im


def t_stove() -> Image.Image:
    im = new_tile(bg=(96, 96, 104, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, T - 1], outline=OUT)
    d.rectangle([2, 2, 13, 7], fill=(60, 60, 70, 255))
    d.ellipse([3, 3, 7, 6], fill=(40, 40, 46, 255))
    d.ellipse([9, 3, 12, 6], fill=(40, 40, 46, 255))
    d.rectangle([2, 10, 13, 14], fill=(126, 126, 136, 255))
    d.rectangle([6, 11, 9, 13], fill=(248, 160, 56, 255))
    return im


def t_sink() -> Image.Image:
    im = new_tile(bg=(200, 204, 208, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, T - 1, T - 1], outline=OUT)
    d.rectangle([3, 4, 12, 12], fill=(160, 168, 176, 255))
    d.ellipse([5, 6, 10, 11], fill=(120, 150, 176, 255))
    d.rectangle([7, 1, 8, 4], fill=(90, 96, 104, 255))
    return im


def t_stool() -> Image.Image:
    im = t_floor_wood()
    d = ImageDraw.Draw(im)
    d.ellipse([4, 4, 11, 10], fill=DOOR_HI, outline=OUT)
    d.point([(5, 11), (10, 11)], OUT)
    return im


def t_chimney() -> Image.Image:
    im = t_roof_top(ROOF, ROOF_HI, ROOF_SH)
    d = ImageDraw.Draw(im)
    d.rectangle([5, 1, 10, 9], fill=(150, 132, 120, 255), outline=OUT)
    d.line([(6, 3), (9, 3)], (124, 108, 98, 255))
    d.line([(6, 6), (9, 6)], (124, 108, 98, 255))
    for i, (sx, sy) in enumerate(((7, -1), (9, -3))):
        d.point((sx, max(0, sy + 2)), (220, 220, 224, 220))
    return im


def t_window_box() -> Image.Image:
    im = t_window()
    d = ImageDraw.Draw(im)
    d.rectangle([2, 11, 13, 13], fill=(120, 84, 48, 255), outline=OUT)
    for x, c in ((4, (244, 148, 168, 255)), (7, (248, 216, 96, 255)), (10, (244, 148, 168, 255))):
        d.point((x, 10), c)
        d.point((x + 1, 10), (92, 168, 84, 255))
    return im


def t_doorstep() -> Image.Image:
    im = t_grass(0)
    d = ImageDraw.Draw(im)
    d.rectangle([2, 2, 13, 13], fill=STONE_SH)
    d.rectangle([3, 3, 12, 12], fill=STONE)
    d.line([(3, 12), (12, 12)], STONE_DK)
    return im


# ── Props (separate images, y-sorted in engine) ───────────────────────────────
def p_tree() -> Image.Image:
    im = new_tile(16, 32)
    d = ImageDraw.Draw(im)
    # trunk
    d.rectangle([6, 25, 9, 31], fill=TRUNK)
    d.line([(6, 25), (6, 31)], TRUNK_SH)
    d.line([(5, 30), (10, 30)], TRUNK_SH)
    # canopy: wide lower bush + upper dome, single dark outline silhouette
    d.ellipse([0, 10, 15, 26], fill=TREE_MD, outline=OUT)
    d.ellipse([1, 1, 14, 17], fill=TREE_MD, outline=OUT)
    d.ellipse([2, 2, 13, 16], fill=TREE_MD)          # erase inner seam
    d.ellipse([1, 12, 14, 24], fill=TREE_MD)
    # highlight (upper-left light) and shadow clumps (lower-right)
    d.ellipse([3, 3, 9, 9], fill=TREE_LT)
    d.point([(5, 4), (4, 6), (7, 4)], (136, 204, 116, 255))
    for x, y in ((10, 8), (12, 13), (4, 15), (8, 17), (11, 19), (5, 21), (9, 22)):
        d.point([(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)], TREE_DK)
    d.arc([1, 11, 14, 25], 20, 160, fill=TREE_DK)    # lower canopy shading
    return im


def p_pine() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.rectangle([7, 20, 8, 23], fill=TRUNK)
    for i, (w, y) in enumerate(((4, 2), (6, 7), (8, 12))):
        d.polygon([(8 - w, y + 6), (8 + w - 1, y + 6), (7, y)], fill=TREE_MD, outline=OUT)
        d.line([(8 - w + 2, y + 5), (8, y + 1)], TREE_LT)
    return im


def p_bush() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.ellipse([1, 4, 14, 15], fill=TREE_MD, outline=OUT)
    d.ellipse([3, 6, 9, 11], fill=TREE_LT)
    d.point([(11, 8), (9, 12)], TREE_DK)
    return im


def p_tallgrass() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    for x in range(0, T, 4):
        d.line([(x + 1, 15), (x + 1, 6)], TALL)
        d.line([(x + 2, 15), (x + 2, 8)], TALL_HI)
        d.line([(x + 3, 15), (x + 3, 5)], TALL)
        d.point((x, 9), TALL_HI)
    d.rectangle([0, 14, 15, 15], fill=TALL)
    return im


def p_sign() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.rectangle([7, 9, 8, 14], fill=TRUNK_SH)
    d.rectangle([2, 2, 13, 9], fill=DOOR_HI, outline=OUT)
    d.line([(4, 4), (11, 4)], DOOR_SH)
    d.line([(4, 6), (9, 6)], DOOR_SH)
    return im


def p_rock() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.polygon([(2, 13), (1, 8), (5, 4), (11, 3), (14, 8), (13, 13)], fill=STONE, outline=OUT)
    d.line([(4, 6), (7, 5)], (228, 228, 220, 255))
    d.line([(3, 12), (12, 12)], STONE_DK)
    d.line([(8, 6), (10, 9)], STONE_DK)
    return im


def p_well() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.polygon([(2, 2), (13, 2), (11, 6), (4, 6)], fill=ROOF_SH, outline=OUT)
    d.rectangle([3, 6, 4, 12], fill=TRUNK)
    d.rectangle([11, 6, 12, 12], fill=TRUNK)
    d.rectangle([2, 12, 13, 20], fill=STONE)
    d.rectangle([2, 12, 13, 20], outline=OUT)
    d.rectangle([4, 14, 11, 17], fill=(40, 48, 64, 255))
    d.line([(3, 19), (12, 19)], STONE_DK)
    return im


def p_brazier() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.polygon([(5, 23), (10, 23), (9, 19), (6, 19)], fill=STONE_DK)
    d.rectangle([4, 15, 11, 19], fill=STONE, outline=OUT)
    d.polygon([(7, 4), (4, 10), (5, 13), (10, 13), (11, 9)], fill=FLAME_O)
    d.polygon([(7, 7), (6, 11), (9, 11), (8, 8)], fill=FLAME_Y)
    return im


def p_bed() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.rectangle([1, 2, 14, 21], fill=(88, 60, 40, 255), outline=OUT)
    d.rectangle([2, 3, 13, 8], fill=(236, 236, 228, 255))   # pillow
    d.rectangle([2, 9, 13, 20], fill=(200, 84, 72, 255))    # blanket
    d.line([(2, 10), (13, 10)], (232, 132, 108, 255))
    d.line([(2, 20), (13, 20)], (150, 60, 52, 255))
    return im


def p_bookshelf() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.rectangle([1, 0, 14, 23], fill=DOOR_SH, outline=OUT)
    for y in (3, 10, 17):
        d.rectangle([3, y, 12, y + 4], fill=(64, 44, 30, 255))
        for i, x in enumerate(range(3, 12, 2)):
            c = [(200, 96, 80, 255), (110, 160, 205, 255), (222, 200, 110, 255), (130, 180, 110, 255)][i % 4]
            d.rectangle([x, y, x + 1, y + 4], fill=c)
    d.rectangle([1, 22, 14, 23], fill=OUT)
    return im


def p_statue() -> Image.Image:
    """Stone drake statue for halls and the Scald."""
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.rectangle([3, 19, 12, 23], fill=STONE_SH, outline=OUT)
    d.ellipse([4, 8, 11, 19], fill=STONE, outline=OUT)
    d.ellipse([6, 3, 13, 10], fill=STONE, outline=OUT)
    d.point((11, 6), OUT)
    d.polygon([(7, 3), (8, 0), (9, 3)], fill=STONE_SH, outline=OUT)
    d.polygon([(4, 12), (0, 8), (4, 16)], fill=STONE_SH, outline=OUT)
    d.line([(5, 17), (10, 17)], STONE_DK)
    return im


def p_cinder_grass() -> Image.Image:
    """Ember-lit tall grass for the Scald (encounter tile)."""
    im = new_tile()
    d = ImageDraw.Draw(im)
    for x in range(0, T, 4):
        d.line([(x + 1, 15), (x + 1, 7)], (120, 70, 44, 255))
        d.line([(x + 2, 15), (x + 2, 9)], (168, 96, 48, 255))
        d.line([(x + 3, 15), (x + 3, 6)], (120, 70, 44, 255))
        d.point((x + 3, 6), (248, 160, 56, 255))
        d.point((x + 1, 8), (248, 160, 56, 255))
    d.rectangle([0, 14, 15, 15], fill=(104, 62, 40, 255))
    return im


def p_barrel() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.ellipse([3, 2, 12, 15], fill=DOOR, outline=OUT)
    d.line([(4, 5), (11, 5)], (90, 60, 36, 255))
    d.line([(4, 11), (11, 11)], (90, 60, 36, 255))
    d.ellipse([5, 3, 10, 6], fill=DOOR_HI)
    return im


def p_crate() -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.rectangle([2, 4, 13, 15], fill=DOOR_HI, outline=OUT)
    d.line([(2, 4), (13, 15)], DOOR_SH)
    d.line([(13, 4), (2, 15)], DOOR_SH)
    d.rectangle([2, 4, 13, 5], fill=(200, 160, 110, 255))
    return im


def p_plant() -> Image.Image:
    im = new_tile(16, 24)
    d = ImageDraw.Draw(im)
    d.polygon([(5, 23), (10, 23), (11, 17), (4, 17)], fill=(190, 110, 70, 255), outline=OUT)
    d.ellipse([2, 4, 13, 16], fill=TREE_MD, outline=OUT)
    d.ellipse([4, 6, 9, 11], fill=TREE_LT)
    return im


# ── Assemble sheet + manifest ─────────────────────────────────────────────────
def main() -> None:
    tiles: list[tuple[str, Image.Image]] = [
        ("grass", t_grass(0)),
        ("grass2", t_grass(2)),
        ("meadow", t_meadow()),
        ("flowers_0", t_flowers(0)),
        ("flowers_1", t_flowers(1)),
        ("path", t_path()),
        ("water_0", t_water(0)),
        ("water_1", t_water(1)),
        ("path_n", t_path_edge("n")),
        ("path_s", t_path_edge("s")),
        ("path_e", t_path_edge("e")),
        ("path_w", t_path_edge("w")),
        ("water_n", t_water_edge("n")),
        ("water_s", t_water_edge("s")),
        ("water_e", t_water_edge("e")),
        ("water_w", t_water_edge("w")),
        ("roof_red_top", t_roof_top(ROOF, ROOF_HI, ROOF_SH)),
        ("roof_red_mid", t_roof_mid(ROOF, ROOF_HI, ROOF_SH)),
        ("roof_red_eave", t_roof_eave(ROOF, ROOF_HI, ROOF_SH)),
        ("roof_slate_top", t_roof_top(SLATE, SLATE_HI, SLATE_SH)),
        ("roof_slate_mid", t_roof_mid(SLATE, SLATE_HI, SLATE_SH)),
        ("roof_slate_eave", t_roof_eave(SLATE, SLATE_HI, SLATE_SH)),
        ("wall", t_wall(WALL, WALL_SH, WALL_LN)),
        ("wall_stone", t_wall_stone()),
        ("window", t_window()),
        ("door", t_door(0.0)),
        ("door_half", t_door(0.5)),
        ("door_open", t_door(1.0)),
        ("cave_wall", t_cave_wall()),
        ("brick", t_brick()),
        ("fence", t_fence()),
        ("floor_wood", t_floor_wood()),
        ("floor_stone", t_floor_stone()),
        ("rug", t_rug()),
        ("rug_n", t_rug_edge("n")),
        ("rug_s", t_rug_edge("s")),
        ("mat", t_mat()),
        ("iwall", t_iwall()),
        ("iwall_top", t_iwall_top()),
        ("counter", t_counter()),
        ("shelf", t_shelf()),
        ("table", t_table()),
        ("lava_0", t_lava(0)),
        ("lava_1", t_lava(1)),
        ("lava_n", t_lava_edge("n")),
        ("lava_s", t_lava_edge("s")),
        ("lava_e", t_lava_edge("e")),
        ("lava_w", t_lava_edge("w")),
        ("basalt", t_basalt()),
        ("banner", t_banner()),
        ("painting", t_painting()),
        ("window_int", t_window_int()),
        ("stove", t_stove()),
        ("sink", t_sink()),
        ("stool", t_stool()),
        ("chimney", t_chimney()),
        ("window_box", t_window_box()),
        ("doorstep", t_doorstep()),
    ]

    cols = 8
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * T, rows * T), (0, 0, 0, 0))
    manifest: dict = {"frameSize": T, "columns": cols, "tiles": {}}
    for i, (name, im) in enumerate(tiles):
        x, y = (i % cols) * T, (i // cols) * T
        sheet.paste(im, (x, y))
        manifest["tiles"][name] = i

    OUT_TILES.mkdir(parents=True, exist_ok=True)
    OUT_PROPS.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT_TILES / "ground.png")

    props = {
        "tree": p_tree(),
        "pine": p_pine(),
        "bush": p_bush(),
        "tallgrass": p_tallgrass(),
        "sign": p_sign(),
        "rock": p_rock(),
        "well": p_well(),
        "brazier": p_brazier(),
        "bed": p_bed(),
        "plant": p_plant(),
        "bookshelf": p_bookshelf(),
        "statue": p_statue(),
        "cindergrass": p_cinder_grass(),
        "barrel": p_barrel(),
        "crate": p_crate(),
    }
    manifest["props"] = {}
    for name, im in props.items():
        im.save(OUT_PROPS / f"{name}.png")
        manifest["props"][name] = {"w": im.width, "h": im.height}

    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"ground.png: {len(tiles)} tiles ({cols}x{rows}); {len(props)} props; manifest -> {MANIFEST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
