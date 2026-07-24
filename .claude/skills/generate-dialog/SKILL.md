---
name: generate-dialog
description: Use when the user wants to write or expand NPC/sign dialog for a zone. Appends to data/dialog/<zone>.json following dialog schema v2 (flag-branched sections + inline commands). Example triggers — "write dialog for the elder", "add dialog to the Scald", "/generate-dialog".
---

# generate-dialog

## When to use
Writing or expanding NPC dialog, sign text, or story beats for a zone. Output goes in `data/dialog/<zone>.json`; the dialog runner in `src/scenes/WorldScene.ts` interprets it directly.

## Schema v2 (data/dialog/<zone>.json)
```json
{
  "_schema_version": 2,
  "npcs": {
    "simple_sign":  { "text": "One-liner shown on interact." },
    "chatty_npc":   { "name": "Fen", "lines": ["Page one.", "Page two."] },
    "branching_npc": {
      "name": "Elder Moss",
      "select": [
        { "unless_flag": "starter_given", "use": "intro" },
        { "if_flag": "sable_1_beaten", "use": "impressed" },
        { "use": "default" }
      ],
      "sections": { "intro": ["..."], "impressed": ["..."], "default": ["..."] }
    }
  }
}
```
- `select` rules are evaluated top-down; first match wins. Conditions: `if_flag`, `unless_flag`.
- Lines are strings (one textbox page each, auto-wrapped) or commands:
  - `{"set_flag": "flag_name"}` — record story progress
  - `{"start_battle": "trainer_id"}` — trainer battle (id must exist in data/trainers.json); ends the dialog
  - `{"give_starter": true}` — opens the starter picker (no-op if party non-empty)
  - `{"heal_party": true}` — full heal + "healed" message
- Maps reference entries as `"<zone-file>.<npc_id>"` (e.g. `"kindra.elder_moss"`).

## Voice guidance
- FireRed-era brevity: 1–3 short pages per talk. No walls of text.
- Kindra region voice: warm but weathered frontier folk; drakes are respected working partners, not pets. The Elder speaks in embers-and-flame metaphors. Sable is prickly, insecure, competitive. Brask is terse, judging, secretly fair.
- Signs are ALL-CAPS laconic: "DUSTWAY ROUTE 1 →   Tall grass ahead."

## Procedure
1. Read the zone's existing dialog file (if any) and the zone map JSON so names/ids line up.
2. Draft entries; branch on flags where story state matters (before/after a battle, before/after starter).
3. If a dialog starts a battle, ensure the trainer exists in `data/trainers.json` (team drakes must exist; `$rival_starter` resolves to the counter of the player's starter).
4. Run `python3 tools/validate_data.py` — it checks section refs, dialog refs from maps, and trainer integrity.
5. Playtest the conversation in the browser if it's story-critical (flags, battles).
