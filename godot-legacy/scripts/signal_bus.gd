## Global event bus. Autoloaded as SignalBus.
## Any system can emit or listen without wiring direct references.

extends Node

## ── Dialog ───────────────────────────────────────────────────────────────────
## Request the dialog system to show a dialog tree.
##   dialog_file — path or key (e.g. "kindra")
##   node_id     — npc/sign id inside that file (e.g. "elder_moss" or "sign_east")
signal dialog_requested(dialog_file: String, node_id: String)
signal dialog_advanced()         ## player pressed Enter / tapped
signal dialog_closed()            ## textbox dismissed
signal dialog_flag_set(flag: String)

## ── Battle ───────────────────────────────────────────────────────────────────
signal battle_started(enemy_id: String, level: int, trainer_id: String)
signal battle_ended(result: String)  ## "won" | "lost" | "fled" | "caught"

## ── Menu / UI ────────────────────────────────────────────────────────────────
signal menu_opened(menu_id: String)
signal menu_closed(menu_id: String)

## ── Overworld ────────────────────────────────────────────────────────────────
signal tile_stepped(tile: Vector2i)
signal zone_entered(zone_id: String)

## ── Save / flags ─────────────────────────────────────────────────────────────
signal flag_set(flag_name: String, value: Variant)
signal game_saved()
signal game_loaded()
