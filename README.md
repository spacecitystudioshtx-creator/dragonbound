# Dragonbound

A Pokémon FireRed-style 2D pixel art creature collector RPG that runs in any web browser. Collect, battle, and evolve dragon-themed creatures called **Drakes**. Built with an AI-first content pipeline so the world builds itself from creative direction.

## Status (as of 2026-07-24)

**Engine pivot complete: Godot → TypeScript + Phaser 4 + Vite.** The game now runs in the browser. The old Godot project is archived in `godot-legacy/` (delete once we're confident nothing else needs porting).

**Playable end-to-end today:** title screen → new game/continue → Kindra town → starter choice from Elder Moss (Ember/Ripple/Sprig, sprites on screen) → Dustway Route 1 wild encounters → full FireRed-style battle (fight/runestone-catch/swap/run, type chart, XP, level-ups, evolution) → rival Sable trainer battle (picks your counter) → Scald gate + Warden Brask (flag-aware dialog) → auto-save to localStorage, whiteout on party wipe.

**Verified by automated in-browser playtest**: the whole loop above was driven end-to-end by the built-in test harness (see Dev Workflow).

### How to run
```
npm install
npm run dev      # → http://localhost:5173
```
Controls: arrows/WASD to move, Z/Space/Enter = A (interact/confirm), X/Esc = B (cancel). `npm run typecheck` for TS, `python3 tools/validate_data.py` for content.

### Next steps
1. **Content wave** — use `/generate-drake` + `/generate-zone` to grow toward the 30-drake / 3-zone MVP. The pipeline is fully data-driven now: new zones and drakes need **zero engine code**.
2. **The Scald trial** — Warden Brask's cave zone + boss battle (extend trainers.json to multi-drake teams — already supported).
3. **Bench synergy combos** — data exists in `data/synergies.json`; battle UI hook not built yet. This is the flagship differentiator.
4. **Party/Codex menu** — view drakes outside battle, reorder party.
5. **Audio** — chiptune loop for town/route/battle (Web Audio, no assets yet).
6. **Mobile controls** — touch D-pad + A/B overlay (the game already scales to phone screens; it just needs inputs).
7. **Deploy** — `npm run build` produces a static site; host anywhere (GitHub Pages / itch.io / Cloudflare).

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
- **Type effectiveness** — 18 types planned (12 common + 6 rare); 4 wired so far
- **4 moves per drake**, learn more and swap freely outside battle
- **Catch mechanic** — Runestones (not Pokeballs), weaken-then-throw

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
1. **Starter Zone** — Kindra town + Dustway Route 1. Choose from 3 starter drakes. Rival introduction. ✅ built
2. **The Scald** — Warden Brask's volcanic trial cave. Gate zone built; trial interior next.
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
- **Engine:** TypeScript + [Phaser 4](https://phaser.io) + Vite — runs in any browser, deploys as a static site
- **Resolution:** GBA-native 240×160, integer-scaled, `pixelArt` rendering; Press Start 2P font
- **Maps:** JSON (ASCII grid + legend) in `data/maps/` — no map editor needed, AI-writable
- **Art:** CC0 tilesets (16×16) + AI-generated drake sprites (80×80, Stable Diffusion via `tools/generate_sprites.py`)
- **Music:** Chiptune, AI-generated or free tools (BeepBox, Suno) — not wired yet
- **Content Pipeline:** All game content defined in JSON. AI generates from creative briefs.
- **Platform:** Web first (desktop + mobile browsers). iOS/Android later via Capacitor wrap if wanted.

## Repo Layout
```
index.html, vite.config.ts     web app entry
src/main.ts                    Phaser config + automated playtest harness
src/core/                      db (JSON access), drake instances, battle math, state/save, tile registry
src/scenes/                    Boot, Title, World (data-driven maps), Battle, Debug tile viewer
src/ui/Textbox.ts              FireRed textbox + choice menus
data/                          THE GAME — drakes, moves, types, synergies, trainers, maps/, dialog/
art/                           source art (tilesets, drake sprites); copies served from public/assets/
tools/                         validate_data.py (content CI), generate_sprites.py (SD sprite gen)
godot-legacy/                  archived Godot prototype
```

## AI Content Pipeline

### How It Works
1. You write a creative brief (in `data/brief_queue.json` for overnight, or inline during a session).
2. You invoke a skill (`/generate-drake`, `/generate-zone`, `/generate-dialog`), or wait for the nightly task.
3. The skill generates validated content and appends it to `data/` — new drakes, moves, zones, dialog. **No engine code needed for any of these.**
4. `python3 tools/validate_data.py` checks every cross-reference (moves, evolutions, map legends, exits, dialog refs, trainers) before anything commits.
5. Claude playtests the change in a real browser via the built-in harness, screenshots it, and reports.

### Data Schemas (Implemented)
- `data/drakes.json`    — all creature definitions (type, class, stats, evolution, base_moves)
- `data/moves.json`     — all move definitions (type, power, accuracy, effect)
- `data/types.json`     — type effectiveness chart
- `data/synergies.json` — bench-combo moves + placeholder passive bonuses
- `data/trainers.json`  — trainer battles (`$rival_starter` resolves to your starter's counter)
- `data/maps/*.json`    — zones: ASCII rows + legend + NPCs + exits + spawns + encounters
- `data/dialog/*.json`  — NPC/sign dialog, schema v2: flag-branched sections + inline commands
- `data/sprite_briefs.json` — queue of sprite prompts for the Stable Diffusion pass
- `data/brief_queue.json`   — overnight creative-brief queue

### Skills (`.claude/skills/`)
- **generate-drake**  — brief → new species + any moves it needs (placeholder sprite auto-renders until art lands)
- **generate-zone**   — brief → map JSON + dialog + encounters + two-way exits
- **generate-dialog** — brief → flag-aware dialog for a zone's NPCs/signs

### Dev Workflow (how Claude iterates)
- `.claude/launch.json` starts `npm run dev` on port 5173 for the in-app browser.
- `src/main.ts` exposes a console harness: `__seq('z','up','left')`, `__tap('right')`, `__pump(ms)`, `__state` — Claude drives full playthroughs headlessly (works even when the tab is hidden and rAF is paused) and verifies with screenshots.
- `/?debug=ground` (or `characters`, `player`) shows every sheet frame with its index — used to keep `src/core/tiles.ts` honest.
- The overworld tileset is ORIGINAL art generated by `tools/generate_tileset.py` (FireRed-inspired: 3-tone shading, 1px outlines, soft saturated palette). Edit the draw functions there and rerun to change the world's look.

### Nightly AFK pipeline
A scheduled task runs at 02:16 AM daily. It reads `data/brief_queue.json`, processes up to 3 pending briefs through the appropriate skill, validates, and commits the batch. Morning log in `data/nightly_log.md`.

## Art Style

### Overall Aesthetic
Pokémon FireRed / LeafGreen (GBA Gen 3). That is the single reference point for all visual decisions.

### Tiles & Overworld
- **16×16 px tiles**, nearest-neighbor scaling (no anti-aliasing, ever)
- Top-down tile grid, FireRed camera locked to player; props (trees, wells, braziers) y-sort so the player walks behind them
- Tiles are ORIGINAL generated art: `tools/generate_tileset.py` → `public/assets/tiles/` + manifest; names registered in `src/core/tiles.ts`
- Animated water + flowers; paths and ponds auto-edge into grass; doors animate open and lead into real interiors

### Drake Battle Sprites — Target Style
Reference image: official Gen-3 Pokémon battle sprites (FireRed, Emerald era).

| Property | Spec |
|---|---|
| **Resolution** | 80×80 px stored; shown near-native in battle |
| **Background** | Transparent (flood-filled from black by the generator) |
| **Outline** | Bold 1–2 px black, no anti-aliasing |
| **Shading** | Flat cell shading only — no gradients, no airbrushing |
| **Palette** | Limited GBA-style (~32 colors max per sprite) |
| **Pose** | Front 3/4 view, facing the viewer |
| **Silhouette** | Strong, readable at small size |

### Adding a New Drake Sprite
1. Add a brief to `data/sprite_briefs.json` (shapes + flat colors only)
2. `HF_TOKEN=hf_... python3 tools/generate_sprites.py`
3. Copy the PNG from `art/drakes/` to `public/assets/drakes/` — it appears in battle on next reload

## Music & Audio
- Chiptune soundtrack (8-10 tracks for MVP)
- Tracks needed: title screen, starter town, route theme, battle (wild), battle (trainer), battle (warden), victory fanfare, Roost theme, cave/dungeon
- Sound effects: menu select, attack hits, capture, level up, evolution

## Monetization (Later)
- Free at launch
- If successful: premium version or cosmetic IAP
- No gacha, no pay-to-win
- Potential: expansion packs as paid DLC

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
