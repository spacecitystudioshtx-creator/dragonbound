# Dragonbound Art Direction

## Target Feel

Dragonbound should feel like a GBA-era grid creature RPG:

- Native canvas: 240x160 reference feel, scaled cleanly by Godot.
- Overworld tiles: 16x16.
- Overworld character footprint: one tile.
- Battle creature sprites: 64x64.
- Party/menu icons: 32x32.
- Palettes: small, readable, usually 16 colors per sprite family.
- Edges: crisp pixel outlines, no painterly gradients, no soft anti-aliasing.

This is a style target, not an asset target. Do not copy protected sprites,
screenshots, maps, UI frames, names, or exact layouts. Dragonbound uses original
Drakes, Runestones, Trial Wardens, maps, and UI details.

## What Makes The Reference Work

The classic look comes from constraints more than detail:

- Small readable silhouettes.
- Clear tile repetition.
- Strong contrast between walkable paths, blockers, tall grass, water, and doors.
- Sparse decoration.
- Consistent camera scale.
- Simple rectangular UI panels with dark outlines and pale interiors.
- Battle fields with simple color bands, oval platforms, and large 64x64
  creature sprites.

## Dragonbound Asset Specs

| Asset | Size | Notes |
|---|---:|---|
| Overworld tile | 16x16 | Terrain, props, signs, water, paths |
| Player/NPC overworld frame | 16x16 | One-grid footprint for Dragonbound |
| Large NPC overworld frame | 16x32 | Use only when intentionally taller |
| Drake battle front | 64x64 | Transparent background |
| Drake battle back | 64x64 | Later, for player-side battle view |
| Party icon | 32x32 | Two-frame animation optional |
| Trainer/warden battle portrait | 64x64 | 16-color indexed look |
| Dialog portrait | 48x48 or 64x64 | Optional later |

## DiffusionBee Prompt Pattern

```text
crisp GBA-era pixel art sprite, original creature design, 64x64 game sprite,
front-facing battle pose, full body visible, strong dark pixel outline,
limited 16-color palette, cel shaded, no smooth gradients, transparent or pure
white background, centered on canvas, readable silhouette

Subject:
<describe the Drake, colors, body shape, personality>

Negative:
photorealistic, painterly, soft brush, smooth gradient, 3d render, detailed
background, realistic texture, blurry, anti-aliased, cropped, text, watermark
```

For overworld tiles, replace `64x64 game sprite` with `16x16 top-down tile` and
keep the subject extremely simple.

## Recommended Local Image Stack

ComfyUI should be the main scalable generator on the Mac mini:

- ComfyUI: best scalable pipeline because prompts, models, upscalers,
  ControlNet/reference inputs, and batch jobs can be saved as workflows.
- DiffusionBee: useful as a quick manual scratchpad.
- Aseprite or Pixelorama: best final hand cleanup.
- ImageMagick: automatic sizing, palette reduction, transparency, and crisp
  nearest-neighbor resizing.

Use `tools/comfyui_generate.py` for queued assets and
`tools/process_pixel_asset.sh` for any manually saved raw images.
