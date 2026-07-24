## Autoloaded singleton. Holds all drake species + move definitions, loaded
## from res://data/ JSON files. Public API is unchanged so existing battle
## code keeps working.
##
## Usage:
##   DrakeDatabase.drakes["ember"]        → DrakeData
##   DrakeDatabase.moves["spark_snap"]    → MoveData (new accessor)
##   DrakeDatabase.make_drake("flick", 4) → DrakeInstance at level 4
##   DrakeDatabase.get_combo_move(0, 1)   → MoveData for Fire+Water combo
##   DrakeDatabase.type_effectiveness(att_type, def_type) → float multiplier

extends Node

const DRAKES_PATH    := "res://data/drakes.json"
const MOVES_PATH     := "res://data/moves.json"
const TYPES_PATH     := "res://data/types.json"
const SYNERGIES_PATH := "res://data/synergies.json"

## All drake species, keyed by lowercase ID string.
var drakes: Dictionary = {}
## All moves, keyed by lowercase ID string.
var moves: Dictionary = {}
## Combo moves keyed by "minType_maxType" (DrakeData.Type ints, legacy format).
var combo_moves: Dictionary = {}
## Type effectiveness chart: chart[attacker][defender] → float.
var _type_chart: Dictionary = {}


## String → int maps for translating JSON enum names.
const _MOVE_TYPE := {
	"fire": MoveData.Type.FIRE,
	"water": MoveData.Type.WATER,
	"nature": MoveData.Type.NATURE,
	"normal": MoveData.Type.NORMAL,
}

const _DRAKE_TYPE := {
	"fire": DrakeData.Type.FIRE,
	"water": DrakeData.Type.WATER,
	"nature": DrakeData.Type.NATURE,
}

const _DRAKE_CLASS := {
	"true_dragon": DrakeData.DrakeClass.TRUE_DRAGON,
	"leviathan":   DrakeData.DrakeClass.LEVIATHAN,
	"beast":       DrakeData.DrakeClass.BEAST,
}

const _EFFECT := {
	"none":             MoveData.Effect.NONE,
	"lower_accuracy":   MoveData.Effect.LOWER_ACCURACY,
	"raise_defense":    MoveData.Effect.RAISE_DEFENSE,
	"reflect_damage":   MoveData.Effect.REFLECT_DAMAGE,
	"raise_evasion":    MoveData.Effect.RAISE_EVASION,
	"burn_dot":         MoveData.Effect.BURN_DOT,
	"trap":             MoveData.Effect.TRAP,
	"block_bench":      MoveData.Effect.BLOCK_BENCH,
	"heal_self":        MoveData.Effect.HEAL_SELF,
	"heal_team":        MoveData.Effect.HEAL_TEAM,
	"ignore_def_buffs": MoveData.Effect.IGNORE_DEF_BUFFS,
	"self_damage":      MoveData.Effect.SELF_DAMAGE,
	"fortify":          MoveData.Effect.FORTIFY,
	"flood":            MoveData.Effect.FLOOD,
}


func _ready() -> void:
	_load_all()


func _load_all() -> void:
	_load_moves()
	_load_drakes()
	_load_types()
	_load_synergies()


## ── Loaders ──────────────────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("DrakeDatabase: could not read %s" % path)
		return {}
	var txt := f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("DrakeDatabase: invalid JSON in %s" % path)
		return {}
	return parsed


func _load_moves() -> void:
	var j := _load_json(MOVES_PATH)
	var raw: Dictionary = j.get("moves", {})
	for id in raw.keys():
		moves[id] = _parse_move(raw[id])


func _parse_move(d: Dictionary) -> MoveData:
	var type_id: int = _MOVE_TYPE.get(d.get("type", "normal"), MoveData.Type.NORMAL)
	var effect_id: int = _EFFECT.get(d.get("effect", "none"), MoveData.Effect.NONE)
	return MoveData.new(
		d.get("name", "?"),
		type_id,
		int(d.get("power", 0)),
		int(d.get("accuracy", 100)),
		effect_id,
		float(d.get("effect_value", 0.0)),
		d.get("description", "")
	)


func _load_drakes() -> void:
	var j := _load_json(DRAKES_PATH)
	var raw: Dictionary = j.get("drakes", {})
	for id in raw.keys():
		var d: Dictionary = raw[id]
		var type_id: int = _DRAKE_TYPE.get(d.get("type", "fire"), DrakeData.Type.FIRE)
		var class_id: int = _DRAKE_CLASS.get(d.get("class", "beast"), DrakeData.DrakeClass.BEAST)
		var stats: Dictionary = d.get("base_stats", {})
		var evo: Dictionary = d.get("evolution", {}) if d.get("evolution") != null else {}
		var evo_level := int(evo.get("level", 0))
		var evo_id: String = evo.get("to", "")

		var drake := DrakeData.new(
			d.get("name", id.capitalize()),
			type_id,
			class_id,
			int(stats.get("hp",  30)),
			int(stats.get("atk", 25)),
			int(stats.get("def", 25)),
			int(stats.get("spd", 40)),
			int(d.get("catch_rate", 128)),
			evo_level,
			evo_id
		)
		var move_ids: Array = d.get("base_moves", [])
		var resolved: Array = []
		for mid in move_ids:
			if moves.has(mid):
				resolved.append(moves[mid])
			else:
				push_warning("DrakeDatabase: drake '%s' references unknown move '%s'" % [id, mid])
		drake.base_moves = resolved
		drakes[id] = drake


func _load_types() -> void:
	var j := _load_json(TYPES_PATH)
	_type_chart = j.get("chart", {})


func _load_synergies() -> void:
	var j := _load_json(SYNERGIES_PATH)
	var combos: Dictionary = j.get("combos", {})
	for key in combos.keys():
		## key format: "fire+water" — convert to int tuple key used by
		## get_combo_move(active_type, bench_type).
		var parts := String(key).split("+")
		if parts.size() != 2:
			continue
		var a: int = _MOVE_TYPE.get(parts[0], -1)
		var b: int = _MOVE_TYPE.get(parts[1], -1)
		if a == -1 or b == -1:
			continue
		## Use DrakeData.Type convention (FIRE=0, WATER=1, NATURE=2).
		## MoveData.Type enum numbers match for fire/water/nature.
		var int_key := "%d_%d" % [mini(a, b), maxi(a, b)]
		combo_moves[int_key] = _parse_move(combos[key])


## ── Public API ───────────────────────────────────────────────────────────────

## Returns the combo MoveData for the given active + bench drake types.
func get_combo_move(active_type: int, bench_type: int) -> MoveData:
	var key := "%d_%d" % [mini(active_type, bench_type), maxi(active_type, bench_type)]
	return combo_moves.get(key, null)


## Creates a fresh DrakeInstance by species ID at the given level.
func make_drake(id: String, lv: int = 5) -> DrakeInstance:
	if not drakes.has(id):
		push_error("DrakeDatabase: unknown id '%s'" % id)
		return null
	return DrakeInstance.new(drakes[id], lv)


## Type-effectiveness multiplier. Types as strings ("fire", "water", ...).
func type_effectiveness(attacker: String, defender: String) -> float:
	var row: Dictionary = _type_chart.get(attacker, {})
	return float(row.get(defender, 1.0))
