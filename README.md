# Dragonbound

A Pokémon FireRed-style 2D pixel art creature collector RPG for iOS. Collect, battle, and evolve dragon-themed creatures called **Drakes**. Built with an AI-first content pipeline so the world builds itself from creative direction.

## Status (as of 2026-05-05)

**Playable scaffolding:** grid movement, 3 connected zones (Kindra → Dustway → Zone 2), turn-based battle framework, 12 drakes with moves + synergies, FireRed-style dialog textbox, auto-save. Running in Godot 4.6.

**Current visual direction:** original IP with a very close GBA creature-RPG feel: 240×160 viewport, 16×16 grid movement, generated starter-town screen, generated-style room screens, original drake sprites, and FireRed-inspired battle staging.

**What works end-to-end:** walking, scene transitions, wild encounters, starter gift, save/load, generated drake sprites, starter-area screenshots, room screenshots.
**Not wired yet:** NPCs in the overworld, trial wardens, music, item/bag system, capture flow, production-quality full-route ComfyUI maps.

## FireRed-Shape Production Plan

Dragonbound’s art direction should now default to the ComfyUI pipeline, not hand-built placeholder boxes. The working standard is:

1. Generate a **240×160 screen mockup** for each room, town section, route segment, and battle background.
2. Slice that screen into **15×10 tiles of 16×16** inside Godot.
3. Add invisible deterministic collision on top.
4. Capture screenshots with `tools/render_map_snapshots.gd`.
5. Compare against FireRed composition references for density, tile clarity, sprite scale, UI placement, and camera framing.

Current generated-style sources:
- Starter town: `art/generated/backgrounds/kindra_town_style_benchmark_v2_flux2_live.png`
- Rooms: `art/generated/backgrounds/kindra_*_interior_live.png`
- Review screenshots: `art/generated/screenshots/*.png`

### Next 3-5 Codex Sessions

1. **Replace remaining route/town fallback areas with generated screens.** Generate dedicated 240×160 ComfyUI screens for Kindra west, Kindra east exit, and Dustway entry instead of reusing generic tile fills.
2. **ComfyUI interior pass.** Replace the current generated-style room placeholders with actual ComfyUI room outputs for home, shop, right house, elder house, and Pyre.
3. **Battle UI parity pass.** Finish FireRed-style command/menu flow: enemy HP upper-left, player HP lower-right, player sprite lower-left, enemy sprite upper-right, bottom text panel, then add Fight/Bag/Drakes/Run menu before move selection.
4. **Player/trainer sprite pipeline.** Generate a proper 4-direction chibi trainer sheet through ComfyUI or Aseprite-style pixel workflow and retire procedural trainer generation.
5. **Screenshot QA gate.** Make every visual task produce `art/generated/screenshots/*` and fail the session if old placeholder tiles, cut-off sprites, or blocked exits appear.

## Next steps

1. **Playtest the scaffolding.** Open the project in Godot, walk Kindra → Dustway → Zone 2, trigger an encounter, finish a battle. File whatever breaks.
2. **Design Warden Brask + The Scald.** First real boss. Add his team + dialog + the cave zone — use `/generate-zone` and `/generate-drake` skills.
3. **Queue nightly briefs.** Drop 2–3 creative prompts into `data/brief_queue.json` each evening (new drake line, a route, an NPC). The 02:16 AM task drafts them overnight.
4. **NPC interaction.** Add walk-up-to-NPC triggers that emit `SignalBus.dialog_requested` — unlocks the dialog system already built.
5. **Trainer battles.** Extend `battle_manager` to accept a team instead of a single wild drake; wire Sable's first encounter.
6. **Sprites for drakes 2+.** Current 12 front sprites are stub-quality. Queue sprite briefs in `data/sprite_briefs.json` for the Stable Diffusion pass once it's online.

Further out: music pass, iOS build, Roost base, Rift system.

---

## Concept

## Core Pillars
1. **Pokemon nostalgia** — GBA pixel art, chiptune music, tile-based exploration, minimal handholding
2. **Depth over breadth** — Team Synergy makes party building strategic, not just "pick the strongest"
3. **AI-generated content** — Everything is data-driven JSON. New zones, creatures, NPCs generated from text prompts
4. **Zero copyright infringement** — All original IP. Inspired by Pokemon, legally distinct

## Setting & Theme
- Dragon-themed creature world
- ~150 creatures ("Drakes") across 6 categories:
  - **True Dragons** (~30%) — classic fire/ice/storm dragons
  - **Wyrms & Serpents** (~15%) — snake-like, water/poison types
  - **Raptors & Wyverns** (~15%) — dinosaur-adjacent, fast/fierce
  - **Elementals** (~15%) — living fire, stone golems, storm spirits
  - **Beasts** (~15%) — wolf/bear-like with draconic features (horns, scales, wings)
  - **Ancients** (~10%) — legendary/mythic tier, fossils, god-dragons

## Core Mechanics

### Combat
- **Turn-based, 1v1 battles** (like Pokemon)
- **Type effectiveness** — 18 types (12 common + 6 rare)
- **4 moves per drake**, learn more and swap freely outside battle
- **Catch mechanic** — Runestones (not Pokeballs), skill/timing element

### Type System (18 Types)

**12 Common Types:**
Fire, Water, Earth, Wind, Lightning, Ice, Nature, Poison, Metal, Shadow, Light, Psychic

**6 Rare Types (legendaries/late-game):**
Void, Celestial, Ancient, Spirit, Crystal, Blood

### Team Synergy (Key Differentiator)
- Party of 6 drakes
- Certain combinations on your team unlock **passive bonuses** or **combo moves**
- Example: Fire + Wind drake on team = Fire drake learns "Inferno Gust"
- Example: 3 Wyrms on team = all Wyrms get +15% speed
- Rewards smart team building without being mandatory
- Adds massive replayability (discover all synergy combos)

### Progression
- Level cap: 100
- Evolution system (no breeding)
- No gear/equipment — purely level and move based
- **Codex** (not Pokedex) — tracks all discovered drakes

### The Roost (Home Base)
- Customizable base where your drakes live (visible, not just a PC box)
- **Roost Stone** — instant teleport there and back (no walking)
- Optional: feed, decorate, watch drakes interact (Stardew cozy element)
- Drake storage beyond your party of 6

## World Structure

### MVP (3 Zones)
1. **Starter Zone** — Your hometown + first route. Choose from 3 starter drakes. Rival introduction.
2. **Zone 2** — First wild area with diverse encounters. First Trial Warden.
3. **Zone 3** — Harder area, second Trial Warden. Rival rematch.

### Full Game (10 Zones at Launch)
- ~8 **Trial Wardens** (not gym leaders) — each specializes in a type
- **Dragon Council** (not Elite Four) — endgame boss gauntlet
- A rival who appears throughout the journey
- NPC trades available so every drake is obtainable solo
- Hidden areas, secret drakes, puzzle-locked legendaries

### Future Expansions
- More zones (goal: "all Pokemon games combined" worth of content)
- **Rift System** — procedurally generated dungeons with scaling difficulty (WoW endgame)
- Multiplayer co-op dungeons
- PvP battles
- Level cap increases

## Terminology (Original IP — No Pokemon Terms)

| Pokemon | Dragonbound |
|---------|-------------|
| Pokemon | Drakes |
| Pokeball | Runestone |
| Pokedex | Codex / Bestiary |
| Gym Leader | Trial Warden |
| Elite Four | Dragon Council |
| Pokemon Center | Hearthstone (or similar) |
| PC Box | The Roost |
| HM/TM | Scrolls |

## Tech Stack
- **Engine:** Godot 4.4 + GDScript
- **Maps:** Tiled map editor + JSON import
- **Art:** AI-generated pixel sprites (Stable Diffusion, local on Mac Mini)
- **Music:** Chiptune, AI-generated or free tools (BeepBox, Suno)
- **Content Pipeline:** All game content defined in JSON. AI generates from creative briefs.
- **Platform:** iOS (App Store), expandable to Android/Steam later

## AI Content Pipeline

### How It Works
1. You write a creative brief (in `data/brief_queue.json` for overnight, or inline during a session).
2. You invoke a skill (`/generate-drake`, `/generate-zone`, `/generate-dialog`), or wait for the nightly task.
3. The skill generates validated content and appends it to `data/` — new drakes, moves, zones, dialog.
4. `tools/validate_data.py` checks that every reference resolves before anything commits.
5. You review the diff in the morning, tweak direction, or approve.

### Data Schemas (Implemented)
- `data/drakes.json`    — all creature definitions (type, class, stats, evolution, base_moves)
- `data/moves.json`     — all move definitions (type, power, accuracy, effect)
- `data/types.json`     — type effectiveness chart
- `data/synergies.json` — bench-combo moves + placeholder passive bonuses
- `data/dialog/*.json`  — NPC + sign dialog trees (one file per zone)
- `data/sprite_briefs.json` — queue of sprite prompts for when Stable Diffusion is online
- `data/brief_queue.json`   — overnight creative-brief queue

### Skills (`.claude/skills/`)
- **generate-drake**  — brief → new species + any moves it needs
- **generate-zone**   — brief → Godot scene + map script + encounter tables + return transition
- **generate-dialog** — brief → dialog tree for a zone's NPCs/signs

### Nightly AFK pipeline
A scheduled task runs at 02:16 AM daily. It reads `data/brief_queue.json`, processes up to 3 pending briefs through the appropriate skill, validates, and commits the batch. Morning log in `data/nightly_log.md`.

## Art Style
- 16×16 tiles, nearest-neighbor scaling, crisp pixels
- Overworld: top-down, tile-based, Fire Red camera style
- Characters: 16×16 4-frame walk per direction (Ninja Adventure CC0 pack)
- Tile assets: Pixel-Boy's **Ninja Adventure Asset Pack** (CC0) — `art/tilesets/ninja_adventure/`
- Drake sprites: AI-generated 64×64, stored in `art/drakes/`

## Engine Architecture
- `project.godot` autoloads (load order matters):
  - `SignalBus` — global event bus (dialog/battle/menu/save signals)
  - `GameMode`  — mode stack (OVERWORLD / DIALOG / BATTLE / MENU / TRANSITION)
  - `DrakeDatabase` — loads `data/*.json` and exposes `drakes`, `moves`, `make_drake`, `get_combo_move`, `type_effectiveness`
  - `GameState` — party, flags, return-from-battle info
  - `SaveSystem` — reads/writes `user://save.json`; auto-saves on battle end + flag set
  - `DialogBox`  — FireRed-style textbox (letter-reveal, advance on Enter/tap)
  - `MapTiles`, `PlaceholderTileset`, `PlaceholderSprites` — tile/prop/sprite loaders for the Ninja Adventure atlases
- Maps are built procedurally in GDScript using `MapTiles` constants + `MapTiles.stamp()` for multi-tile props (trees, houses).

## Music & Audio
- Chiptune soundtrack (8-10 tracks for MVP)
- Tracks needed: title screen, starter town, route theme, battle (wild), battle (trainer), battle (warden), victory fanfare, Roost theme, cave/dungeon
- Sound effects: menu select, attack hits, capture, level up, evolution

## Monetization (Later)
- Free at launch
- If successful: premium version or cosmetic IAP
- No gacha, no pay-to-win
- Potential: expansion packs as paid DLC

## MVP Timeline (6-8 Weeks)

| Week | Focus |
|------|-------|
| 1 | Godot project setup, core engine (movement, tiles, scenes, save) |
| 2 | Battle system (turns, types, moves, catching, party) |
| 3 | AI content pipeline (creature gen, map gen, dialog gen) |
| 4 | Generate MVP content (30 drakes, 3 zones, 2 wardens) |
| 5 | Team Synergy, polish, menus, music |
| 6 | iOS build, playtesting, bug fixes, App Store submission |

## Design Principles (From Pokemon Nostalgia Research)
1. Every tile has meaning — no decorative filler
2. Mystery and discovery — hidden areas, secret drakes, earned rewards
3. Real difficulty — resource management across dungeons, no handholding
4. Non-linear exploration — multi-path caves, optional detours
5. Memorable vignettes — moments that break the formula
6. A personal rival — shows up unexpectedly, actually challenges you
7. Clean hero's journey — hometown → 8 trials → Dragon Council
8. NPC trades that simulate multiplayer — every drake obtainable solo
9. Optional side content — Roost customization, synergy discovery, Codex completion
10. Pixel art that engages imagination — low fidelity lets the player's brain fill in details
