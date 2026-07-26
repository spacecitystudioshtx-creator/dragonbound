---
name: generate-drake
description: Use when the user wants to add a new drake (creature) to the game from a creative brief. Generates a validated JSON entry + any new moves it needs, appends them to data/drakes.json and data/moves.json, and runs the data validator. Example triggers — "add a drake", "new drake: ...", "generate a shadow-type drake line", "/generate-drake".
---

# generate-drake

## When to use
Whenever the user wants to add a new drake — either a single creature or an evolution line (typically 3 stages). The brief can be anything from a one-liner ("a cursed ice serpent") to a full design doc. Your job is to fill in the JSON so the new drake works end-to-end in-game.

## Output contract
A new drake is **valid** when:
1. Its `id` is unique in `data/drakes.json`.
2. Its `type` is one of: fire, water, nature, normal (or a rare type once those are wired).
3. Its `class` is one of: true_dragon, leviathan, beast.
4. `base_stats` has hp/atk/def/spd ints. Starters total around **142** (rough sum of base stats at stage 1), mid-stage **186**, final **248**. Fodder total **120**. Don't over-stat.
5. `catch_rate` is 45 (starter-class / legendary), 90 (uncommon), or 150 (fodder).
6. `evolution` is either `null` (no evolution) or `{"level": <int>, "to": "<drake_id>"}` where the target drake will also exist after this operation.
7. Every id in `base_moves` exists in `data/moves.json` after this operation (create new moves if needed).

Moves must follow the existing schema in `data/moves.json`. Effect must be one of the enum strings listed in the file header.

## Procedure
1. **Read current state** — load `data/drakes.json` and `data/moves.json` so you don't duplicate ids or overwrite anything.
2. **Draft the drake(s)** — pick an `id` (lowercase, kebab-free), name, type, class. Balance stats against the tier guidance above. For evolution lines, draft all stages at once and link them via `evolution.to`.
3. **Draft any new moves** — ideally 2-3 signature moves per stage. Use existing moves where possible; only add new ones that are thematically essential.
4. **Write changes** — use Edit/Write to extend the JSON files. Preserve file formatting and the leading `_schema_version` / `_doc` keys.
5. **Validate** — run `python3 tools/validate_data.py`. If it reports errors, fix and re-run until clean.
6. **Queue a sprite brief** — append an entry to `data/sprite_briefs.json` describing the visual (pose, colors, silhouette) so when Stable Diffusion is available we can batch-generate sprites. Format:
   ```json
   {"drake_id": "...", "brief": "16x16 pixel art, ...", "queued_at": "ISO timestamp"}
   ```
7. **Summarize** — report to the user: what was added, its synergy neighbors, and what the next-step creative call is (evolution naming, next drake to design, etc.).

## Stat guidance reference
| Tier     | Total base stats | Catch rate |
|----------|------------------|------------|
| Fodder   | ~120             | 150        |
| Starter-1| ~142             | 45         |
| Starter-2| ~186             | 45         |
| Starter-3| ~248             | 45         |
| Warden   | ~230             | 45         |
| Legendary| ~300             | 3          |

## Anti-patterns
- Don't invent new `type` values (e.g. "shadow", "ice") unless the user explicitly asked to expand the type system. Map to an existing type and note the narrative flavor instead.
- Don't edit existing drakes without the user asking — append only.
- Don't skip the validator step. If it fails, fix it before returning.
