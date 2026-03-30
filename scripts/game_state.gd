## Autoloaded singleton. Persistent game state: party, flags, and battle return info.

extends Node

## Active team. Index 0 = battling drake, 1-3 = bench drakes.
var party: Array = []  ## Array[DrakeInstance]

## Which bench slot is the active combo target (0–2)
var selected_bench_slot: int = 0

## Scene/position to return to after a battle ends
var return_scene: String = ""
var return_pos: Vector2 = Vector2.ZERO

## Steps remaining before wild encounters can trigger again (prevents instant re-encounters)
var battle_cooldown_steps: int = 0

## Story and world flags
var flags: Dictionary = {}

## Whether the player has received their starter drake
var has_starter: bool = false


## Give the player their starter drake. Clears any existing party.
func give_starter(id: String) -> void:
	var drake := DrakeDatabase.make_drake(id, 5)
	if drake:
		party.clear()
		party.append(drake)
		has_starter = true


## Add a drake to the party. Returns false if party is full (max 4).
func add_to_party(drake: DrakeInstance) -> bool:
	if party.size() >= 4:
		return false
	party.append(drake)
	return true


## The currently active (battling) drake.
func get_active() -> DrakeInstance:
	if party.is_empty():
		return null
	return party[0]


## Bench drakes (party slots 1–3).
func get_bench() -> Array:
	return party.slice(1)


## The bench drake currently selected as combo target.
func get_combo_bench() -> DrakeInstance:
	var bench := get_bench()
	if bench.is_empty() or selected_bench_slot >= bench.size():
		return null
	return bench[selected_bench_slot]


## Reset all drake battle modifiers after a fight.
func reset_party_battle_state() -> void:
	for drake in party:
		drake.reset_battle_state()


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)
