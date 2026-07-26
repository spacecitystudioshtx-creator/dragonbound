---
name: generate-dialog
description: Use when the user wants to write or expand NPC/sign dialog for a zone. Appends to data/dialog/<zone>.json following the schema already used by the dialog runner. Example triggers — "write dialog for the elder", "add dialog to the Scald", "/generate-dialog".
---

# generate-dialog

## When to use
The user wants in-game text — NPC lines, sign posts, item descriptions, warden speeches, rival taunts. The dialog runner reads from `data/dialog/<zone_id>.json`, so all text lives there.

## Schema (already implemented by scripts/ui/dialog_box.gd)
```json
{
  "_schema_version": 1,
  "npcs": {
    "<npc_id>": {
      "name": "<Display Name>",
      "intro": [ <line>, ... ],
      "post_starter": [ <line>, ... ],
      "post_warden": [ <line>, ... ]
    },
    "<sign_id>": {"text": "..."}
  }
}
```

A `<line>` is either:
- A string — shown verbatim, letter-by-letter.
- `{"text": "..."}` — same as a string.
- `{"set_flag": "<flag_name>"}` — sets a GameState flag, no text.
- `{"start_battle": "<trainer_id>"}` — triggers a battle (trainer_id not yet wired).

Variants (`intro`, `post_starter`, `post_warden`) are chosen at runtime based on flag state. The runner currently picks `post_starter` if `starter_given` is set, else `intro`. Extend the runner if you need new variants.

## Voice guide
- **Elder Moss**: slow, mystical, speaks in two-sentence beats. "The fire in your bones draws you to the Pyre."
- **Brask (warden of the Scald)**: gruff, impatient, commands rather than asks. Short sentences.
- **Sable (rival)**: cocky, testing, never loses composure. Shows up in three places: starter choice, mid-route, trial peak.
- **Signs**: one sentence, uppercase zone name + directional arrow where relevant. "DUSTWAY ROUTE 1 → Keep to the path. Tall grass stirs."
- **Shopkeepers**: warm, transactional. Keep lines short.

Never use:
- Modern slang (no "lol", "dude", "bro")
- Pokémon-specific terminology (no "Pokéball", "Gym", "Pokédex")
- More than 3 lines per intro unless the scene warrants it

## Procedure
1. **Read existing dialog files** in `data/dialog/` to match tone and file structure (especially `kindra.json`).
2. **Identify the NPC + variants needed** (usually intro + post-major-story-beat).
3. **Draft lines** — follow the voice guide. Keep each line under ~60 characters so it wraps cleanly in the textbox.
4. **Mark flag/battle hooks** with the object-form line. Don't invent new directives; if you need one, tell the user and propose it.
5. **Edit the JSON file** — preserve `_schema_version` and `_doc`. Use Edit if the file exists, Write if new.
6. **Report back** — summarize the new dialog and call out any flags the game state needs to track.

## Anti-patterns
- Don't write dialog that depends on UI features that don't exist yet (branching choices, item-gated replies) without first noting them as TODO.
- Don't exceed 5 lines per dialog node unless it's a flashback or lore moment.
- Don't use `[b]`, `[color]`, or other BBCode tags yet — the textbox doesn't parse them.
