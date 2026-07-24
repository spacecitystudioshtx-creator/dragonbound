## Static species data for a drake. Runtime state lives in DrakeInstance.

class_name DrakeData
extends RefCounted

enum Type { FIRE, WATER, NATURE }
enum DrakeClass { TRUE_DRAGON, LEVIATHAN, BEAST }

var drake_name: String
var type: Type
var drake_class: DrakeClass
var base_hp: int
var base_atk: int
var base_def: int
var base_spd: int
var catch_rate: int        ## 0–255; higher = easier to catch
var evolution_level: int   ## 0 = never evolves
var evolution_id: String   ## Key into DrakeDatabase.drakes; "" = none
var base_moves: Array      ## Array[MoveData] assigned from DrakeDatabase


func _init(
		p_name: String,
		p_type: Type,
		p_class: DrakeClass,
		p_hp: int, p_atk: int, p_def: int, p_spd: int,
		p_catch: int = 128,
		p_evo_level: int = 0,
		p_evo_id: String = "") -> void:
	drake_name = p_name
	type = p_type
	drake_class = p_class
	base_hp = p_hp
	base_atk = p_atk
	base_def = p_def
	base_spd = p_spd
	catch_rate = p_catch
	evolution_level = p_evo_level
	evolution_id = p_evo_id
	base_moves = []
