## A live drake with current HP, level, moves, and per-battle modifiers.

class_name DrakeInstance
extends RefCounted

var data: DrakeData
var nickname: String
var level: int
var xp: int
var current_hp: int
var moves: Array  ## Array[MoveData], up to 3

## Per-battle modifiers — reset at the start of each battle
var accuracy_mod: float = 1.0    ## Multiplier on this drake's outgoing accuracy
var evasion_chance: float = 0.0  ## 0–1 probability of dodging an incoming move
var defense_mod: float = 1.0     ## Multiplier on effective defense stat
var is_burned: bool = false       ## Takes max_hp * 10% damage each end-of-turn
var is_trapped: bool = false      ## Can't change bench target; can't flee
var bench_blocked_turns: int = 0  ## Remaining turns the bench combo is blocked
var is_fortified: bool = false    ## Skips attack next turn (set by Fortress)


func _init(p_data: DrakeData, p_level: int = 5) -> void:
	data = p_data
	nickname = p_data.drake_name
	level = p_level
	xp = 0
	moves = p_data.base_moves.slice(0, 3)
	current_hp = get_max_hp()


func get_max_hp() -> int:
	return data.base_hp + level * 3


func get_atk() -> int:
	return data.base_atk + level * 2


func get_def() -> int:
	return int((data.base_def + level * 2) * defense_mod)


func get_spd() -> int:
	return data.base_spd + level * 2


func is_fainted() -> bool:
	return current_hp <= 0


## Apply pre-calculated damage. Returns actual HP lost.
func take_damage(amount: int) -> int:
	var applied := maxi(1, amount)
	current_hp = max(0, current_hp - applied)
	return applied


## Restore HP up to max. Returns actual HP gained.
func heal(amount: int) -> int:
	var actual := mini(amount, get_max_hp() - current_hp)
	current_hp += actual
	return actual


func reset_battle_state() -> void:
	accuracy_mod = 1.0
	evasion_chance = 0.0
	defense_mod = 1.0
	is_burned = false
	is_trapped = false
	bench_blocked_turns = 0
	is_fortified = false


## Add XP. Returns true if the drake leveled up.
func gain_xp(amount: int) -> bool:
	xp += amount
	var threshold := level * level * 4
	if xp >= threshold:
		xp -= threshold
		level += 1
		current_hp = min(current_hp + 3, get_max_hp())
		return true
	return false
