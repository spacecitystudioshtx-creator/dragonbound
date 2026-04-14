---
name: generate-zone
description: Use when the user wants to add a new zone/map/route to the game from a creative brief. Generates a new Godot scene + GDScript map builder using the MapTiles + stamp system, with encounter tables and transition zones wired up. Example triggers — "add a zone", "new route: ...", "generate a haunted swamp", "/generate-zone".
---

# generate-zone

## When to use
The user describes a new zone — town, route, cave, dungeon — with a brief like "a haunted swamp with shadow and poison drakes, creepy but lighthearted" or "the Scald: volcanic trial cave with molten pools". Output is a fully playable Godot scene + script.

## Output contract
A new zone is **valid** when:
1. A new `scripts/<zone_id>.gd` exists, extending `Node2D`, using `PlaceholderTileset.create_placeholder_tileset()` and `MapTiles` constants + `MapTiles.stamp()` for props.
2. A new `scenes/maps/<zone_id>.tscn` exists, referencing the script, with `GroundLayer`, `ObstacleLayer`, `Player`, a `CanvasLayer` hosting `TouchJoystick`, and at least one `ExitTo*` transition zone back to an adjacent scene.
3. Encounter `Area2D` zones are placed over any tall-grass/water regions, each with:
   - `encounter_table` (dict of drake_id → weight summing to 100)
   - `level_min`, `level_max` (sane progression vs distance from Kindra)
   - `encounter_rate` (0.08 early, 0.15–0.18 mid routes)
4. The adjacent zone's scene has been updated with a return transition zone.
5. The zone id follows kebab-case conventions (`dustway_route`, `scald_cave`, `haunted_swamp`).

## Map-builder conventions (from existing code)
Read `scripts/kindra_town.gd` and `scripts/dustway_route.gd` before writing a new zone — stay consistent with their style. Key patterns:
- Ground layer is filled with GRASS (with occasional GRASS_ALT for variation).
- Border is ringed with `PROP_TREE_SMALL` stamped in 2-tile steps.
- Paths are DIRT_PATH rows/columns using `_set_ground()`.
- Buildings are `PROP_HOUSE_SMALL` (3×3) or `PROP_HOUSE_BIG` (4×6) via stamp.
- Tall grass patches (encounters) use `TALL_GRASS`.
- Water uses `WATER` on both ground and obstacle layers.
- Signs use `SIGN` on the obstacle layer.

## Procedure
1. **Read existing maps** to match style — especially `scripts/kindra_town.gd` and `scripts/dustway_route.gd`.
2. **Draft the layout** — pick MAP_W and MAP_H (towns 30×30, routes 22×48 vertical, caves 20×30). Sketch sections on paper: entrance → main area → exit → key landmarks.
3. **Write the script** — follow the `_build_map()` pattern. Place:
   - Ground fill
   - Border trees (ring, with entrance/exit gaps)
   - Paths
   - Buildings or cave obstacles
   - Tall grass patches (for wild encounters)
   - Decorative props
   - Signs at exits and landmarks
4. **Write the scene** — mirror `scenes/maps/dustway_route.tscn`:
   - GroundLayer, ObstacleLayer
   - Player instance with a spawn position
   - ExitTo<AdjacentZone> Area2D with collision shape, `target_scene` and `spawn_position`
   - One or more encounter Area2Ds sized to cover tall-grass patches
   - CanvasLayer with TouchJoystick
5. **Add the return transition** — open the adjacent zone's scene and add a new Area2D that sends the player back. Use Edit, not Write, so you don't clobber the rest of the scene.
6. **Draft encounter tables** — keep to 2-4 drakes per zone. Levels scale by distance from Kindra (Route 1: 3-7, Route 2: 8-12, etc).
7. **Append dialog placeholders** — create `data/dialog/<zone_id>.json` with sign texts and any NPC intros.
8. **Validate** — run `python3 tools/validate_data.py` then check that the scene+script load by reading them back.
9. **Summarize** — tell the user what's built and any TODOs (music, warden placeholder, etc).

## Progression guidance
| Zone index | Level range | Encounter rate | Drakes per zone |
|-----------|-------------|----------------|-----------------|
| Route 1   | 3 – 7       | 0.15           | 2 – 3           |
| Route 2   | 8 – 13      | 0.17           | 3 – 4           |
| Cave      | 10 – 16     | 0.20           | 3 – 5           |
| Route 3   | 14 – 20     | 0.18           | 4 – 5           |

## Anti-patterns
- Don't hand-pick every tile coord from the atlas. Use `MapTiles` constants and `stamp()`.
- Don't forget the return transition. An unreachable zone is a bug.
- Don't create zones larger than 60×60 tiles — camera bounds get unwieldy and exploration feels slow.
