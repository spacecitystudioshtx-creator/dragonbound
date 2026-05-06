# ComfyUI Background Pipeline

Dragonbound's overworld art should be developed from generated style targets,
then cleaned into deterministic game assets.

## Current Quality Target

- Screen benchmark:
  `art/generated/backgrounds/kindra_town_style_benchmark_v2_flux2.png`
- Comparison sheet:
  `art/generated/backgrounds/kindra_town_benchmark_compare.png`
- Tileset reference:
  `art/generated/tilesets/kindra_town_tileset_reference_v2_flux2.png`

The benchmark is the target feel: flat 240x160, orthographic, 16x16 grid logic,
pale sandy roads, mint grass, blue roofs, signs, fences, and clean GBA-like
pixel clusters. It is original Dragonbound art direction, not copied source art.

## Queue Assets

Use:

```bash
python3 tools/queue_background_assets.py
```

Then generate a queued asset through local ComfyUI:

```bash
python3 tools/comfyui_generate.py --id kindra-town-style-benchmark-v2-flux2 --mark-done --timeout 1200
```

For tileset references:

```bash
python3 tools/comfyui_generate.py --id kindra-town-tileset-reference-v2-flux2 --mark-done --timeout 1200
```

## Model Choice

Creature sprites still use the FLUX 2 pixel LoRA profile in
`config/comfyui.json`.

Backgrounds can override model settings per asset in `data/art_queue.json`.
Useful settings so far:

- `workflow: "flux2"` with `pixel-art-lora.safetensors` for flat, readable
  screen benchmarks and tile references.
- `workflow: "checkpoint"` with `AziibPixelMix_Full.safetensors` can produce
  polished environments, but it tends to drift into angled/isometric scenes.

## Production Rule

Do not ship the generated benchmark directly as the playable map. Use it as a
visual target and the tileset reference as source material. The production step
is:

1. Generate benchmark screen.
2. Generate tile reference sheet.
3. Slice or hand-clean the useful tiles into a true 16x16 atlas.
4. Replace `PlaceholderTileset` drawing logic with atlas-backed tiles.
5. Keep collision and map scripts deterministic.

This keeps the game playable and scalable while letting ComfyUI drive the visual
quality bar.
