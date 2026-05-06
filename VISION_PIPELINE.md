# Dragonbound Visual And Content Pipeline

## North Star

Dragonbound should feel like a familiar GBA-era grid creature RPG with original
worldbuilding, creatures, names, maps, dialog, bosses, and progression.

The infrastructure should evoke the muscle memory of Pokemon FireRed:

- 16x16 overworld tiles.
- One-tile player footprint.
- Pressing a new direction turns the player first.
- Holding or pressing the same direction moves exactly one tile.
- Top-down towns, routes, doors, signs, tree borders, ledges, tall grass, water,
  and clean rectangular paths.
- Dialog, battle flow, encounter pacing, and route readability should be
  immediately familiar.

The content must remain Dragonbound:

- Drakes, Runestones, Codex, Trial Wardens, Dragon Council, Roost.
- Original sprites, tiles, names, maps, dialog, UI colors, and designs.
- No ripped assets, exact copied sprites, exact copied UI frames, or protected
  names.

## Daily Workflow

1. Use ChatGPT during the day for creative direction:
   - New zone briefs.
   - NPC dialog.
   - Warden concepts.
   - Drake evolution lines.
   - Route themes and landmarks.

2. Codex executes in the background:
   - Turns briefs into JSON content.
   - Adds maps and encounters.
   - Wires scenes into the existing grid/battle/dialog systems.
   - Runs validation.

3. ComfyUI is for scalable art passes:
   - Drake front sprites.
   - Trainer portraits.
   - Special landmark tiles.
   - Keep outputs original, then clean them into pixel art that matches the
     16x16 overworld and 64x64 battle sprite constraints.
   - DiffusionBee can still be used as a manual scratchpad.

See also:

- `docs/art_direction.md` for the visual target and asset specs.
- `docs/daytime_content_workflow.md` for the daily queue workflow.
- `docs/comfyui_setup.md` for local ComfyUI generation.
- `data/art_queue.json` for image-generation jobs.
- `tools/next_art_prompt.py` to print the next art prompt.
- `tools/comfyui_generate.py` to generate queued assets through ComfyUI.
- `tools/process_pixel_asset.sh` to turn generated images into crisp game art.

## Prompt Shape For Creative Briefs

Use this shape when giving Codex or ChatGPT direction:

```text
Create a Dragonbound zone in the style of a classic GBA creature RPG.
It should use 16x16 grid movement, clear paths, tree borders, signs, tall grass,
and one memorable original landmark.

Zone name:
Purpose in the story:
Connected zones:
Wild Drakes:
NPCs:
Boss or Warden:
Special visual idea:
Dialog tone:
```

## Guardrails

- Build the playable skeleton first, then improve art.
- Prefer clear, readable maps over decorative maps.
- Every route needs a path, a reason to explore, and a way back.
- Every new art pass should make the game feel more like a classic GBA
  creature RPG, not like a different fantasy RPG.
