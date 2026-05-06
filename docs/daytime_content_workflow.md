# Daytime Content Workflow

This is the non-technical loop for building Dragonbound at scale.

## 1. Creative Direction

During the day, write short briefs in plain English:

- A new route.
- A town.
- A cave.
- A Trial Warden.
- A Drake evolution line.
- NPC dialog.
- A needed sprite or tile.

Codex should turn those into project files, data, maps, and art prompts.

## 2. Content Queues

Use these files as inboxes:

- `data/brief_queue.json`: zones, Drakes, dialog.
- `data/art_queue.json`: images for DiffusionBee or ComfyUI.
- `data/sprite_briefs.json`: Drake battle sprites.

## 3. Art Pass

1. Run:

   ```bash
   python3 tools/next_art_prompt.py
   ```

2. Paste the prompt into DiffusionBee.
3. Save the raw image to `~/Downloads/<id>_raw.png`.
4. Process it:

   ```bash
   tools/process_pixel_asset.sh ~/Downloads/<id>_raw.png <output> <size>
   ```

5. Launch the game and inspect it.

## 4. Recommended Scaling Path

Start:

- ComfyUI for scalable local image generation.
- ImageMagick scripts for sizing and crispness.
- Codex for queue management, implementation, and validation.

Current:

- `tools/comfyui_generate.py --list-checkpoints` lists local models.
- `tools/comfyui_generate.py --mark-done` generates the next art queue item.
- `tools/process_pixel_asset.sh` remains available for manual raw images.

Next:

- Save one repeatable workflow for Drake sprites.
- Save one repeatable workflow for trainer portraits.
- Save one repeatable workflow for 16x16 tiles.

Later:

- Batch-generate variants overnight.
- Have Codex pick the best candidate based on size, transparency, palette count,
  and visual fit.
- Keep manual taste-making for final approvals.

## 5. Quality Bar

An asset is ready when:

- It reads clearly at native size.
- It does not blur when scaled up.
- It uses a small palette.
- It has transparent or clean background edges.
- It matches the same camera and grid scale as the rest of the game.
- It makes Dragonbound feel more like a classic GBA creature RPG, not a new
  unrelated fantasy game.
