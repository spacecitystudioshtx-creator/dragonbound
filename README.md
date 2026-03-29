# Dragonbound — Game Design Document

## Concept
A Pokemon Fire Red-style 2D pixel art creature collector RPG for iOS. Collect, battle, and evolve dragon-themed creatures called **Drakes**. Turn-based combat with a unique **Team Synergy** system that rewards strategic party composition. Built with an AI-first content pipeline so the world builds itself from creative direction.

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
1. You write a creative brief: "Zone 4 is a haunted swamp. Shadow and Poison drakes. Creepy but lighthearted."
2. AI generates:
   - `zone_4_swamp.json` — tilemap, encounter tables, NPC placements
   - New drake definitions — stats, moves, types, evolutions, synergies
   - Trial Warden — personality, dialog, team composition
   - Placeholder sprites (Stable Diffusion → pixel art conversion)
3. You review, tweak direction, regenerate as needed
4. Content drops into the game engine automatically (data-driven)

### Data Schemas (To Be Built)
- `drakes.json` — All creature definitions
- `moves.json` — All move definitions
- `types.json` — Type effectiveness chart
- `zones/*.json` — Zone maps, encounters, NPCs
- `synergies.json` — Team synergy definitions
- `wardens.json` — Trial Warden definitions
- `dialog/*.json` — All NPC dialog trees

## Art Style
- GBA-era pixel art (16x16 or 32x32 tiles, 64x64 creature sprites)
- Nearest-neighbor scaling (crisp pixels, no smoothing)
- Limited color palette per sprite (GBA authentic)
- Overworld: top-down, tile-based, Fire Red camera style

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
