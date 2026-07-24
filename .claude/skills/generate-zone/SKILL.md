---
name: generate-zone
description: Use when the user wants to add a new zone/map/route to the game from a creative brief. Generates a JSON map (ASCII grid + legend) in data/maps/, wires exits to adjacent zones, adds encounter tables, and validates. Example triggers — "add a zone", "new route: ...", "generate a haunted swamp", "/generate-zone".
---

# generate-zone

## When to use
The user describes a new zone — town, route, cave, dungeon — with a brief like "a haunted swamp, creepy but lighthearted" or "the Scald: volcanic trial cave". Output is a playable map JSON that the engine renders directly. No engine code changes needed.

## Map format (data/maps/<zone_id>.json)
```json
{
  "id": "zone_id",
  "name": "DISPLAY NAME",
  "legend": {
    "T": { "tile": "tree" },
    ".": { "tile": "grass" },
    "t": { "tile": "tall_grass", "encounter": true },
    "s": { "tile": "sign", "dialog": "<zone>.<sign_id>" }
  },
  "rows": ["TTTT...", "..."],
  "npcs": [{ "id": "...", "x": 0, "y": 0, "sprite": "villager_a", "facing": "down", "dialog": "<zone>.<npc_id>", "vanish_flag": "optional_flag" }],
  "exits": [{ "x": 0, "y": 5, "to": "adjacent_map_id", "spawn": "spawn_name_in_target" }],
  "spawns": { "default": { "x": 1, "y": 5, "facing": "right" } },
  "encounters": { "rate": 0.14, "table": [{ "drake": "flick", "min": 2, "max": 4, "weight": 40 }] }
}
```
- Every char used in `rows` must exist in `legend`. All rows must be the same width.
- `tile` names come from the registry in `src/core/tiles.ts` (grass, grass_pale, flowers, tall_grass, water, tree, pine, bush, path, stone_wall, brick, roof, wood_wall, window, door, sign, well, torch, chest, rock, void). Add new registry entries there only if the zone truly needs a new tile — verify the index with `/?debug=tiles`.
- Legend entries can override `solid`, add `encounter: true`, or attach a `dialog` ref (signs, locked doors).
- NPC `sprite` values: villager_a..villager_d, slime, ghost, bird, spider (see NPC_SPRITES in src/scenes/WorldScene.ts).

## Procedure
1. **Read two existing maps** (`data/maps/kindra_town.json`, `data/maps/dustway_route.json`) to match conventions and difficulty curve.
2. **Draft the layout** — towns ~22×15, routes ~36×11, caves ~18×12. Border with solid tiles (trees outdoors, stone_wall in caves), leave exit gaps that line up with the `exits` coordinates.
3. **Write dialog first** — create/extend `data/dialog/<zone_id>.json` (see /generate-dialog for schema) so every `dialog` ref in the map resolves.
4. **Wire both directions** — add exits in this map AND a matching exit + spawn in the adjacent map so the player can come back.
5. **Encounters** — rate 0.08 early zones, 0.14–0.18 mid. Levels scale with distance from Kindra (+2 per zone). Only reference drakes that exist in `data/drakes.json`.
6. **Validate** — run `python3 tools/validate_data.py`. Fix all errors.
7. **Playtest** — start the dev server (`.claude/launch.json` → dragonbound), then drive the game from the browser console with the built-in harness: `__seq('z')`, `__tap('right')`, etc. Walk to the new zone and screenshot it. Check: tiles look right, exits work both ways, NPCs talk.
8. **Summarize** — report zone name, connections, encounter table, and any new dialog/NPCs.

## Anti-patterns
- Don't hand-edit tile indices in map JSON — maps only use tile *names*.
- Don't create unreachable areas or exits onto solid tiles.
- Don't skip the return exit in the adjacent zone.
