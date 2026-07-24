## Defines a single drake move: type, power, accuracy, and any special effect.

class_name MoveData
extends RefCounted

enum Type { FIRE, WATER, NATURE, NORMAL }

enum Effect {
	NONE,
	LOWER_ACCURACY,   ## Smoke Screen / Ash Cloud — reduces enemy outgoing accuracy
	RAISE_DEFENSE,    ## Harden — boosts user defense modifier
	REFLECT_DAMAGE,   ## Stone Wall / Molten Armor — raises defense
	RAISE_EVASION,    ## Slick Dodge — adds dodge chance
	BURN_DOT,         ## Wildfire — enemy takes HP loss each turn
	TRAP,             ## Riptide / Root Snare — enemy can't change bench target
	BLOCK_BENCH,      ## Drown Out — enemy can't use bench combo for N turns
	HEAL_SELF,        ## Overgrowth — restore user HP
	HEAL_TEAM,        ## Deep Roots — restore all party HP (small)
	IGNORE_DEF_BUFFS, ## Abyssal Crush — ignores enemy defense modifiers
	SELF_DAMAGE,      ## Meltdown — recoil damage to user
	FORTIFY,          ## Fortress — big defense boost; user skips attack next turn
	FLOOD,            ## Flood Surge — removes all enemy stat buffs
}

var move_name: String
var type: Type
var power: int       ## 0 for pure status moves
var accuracy: int    ## 0–100; 0 = always hits
var effect: Effect
var effect_value: float
var description: String


func _init(
		p_name: String,
		p_type: Type,
		p_power: int,
		p_accuracy: int = 100,
		p_effect: Effect = Effect.NONE,
		p_effect_value: float = 0.0,
		p_desc: String = "") -> void:
	move_name = p_name
	type = p_type
	power = p_power
	accuracy = p_accuracy
	effect = p_effect
	effect_value = p_effect_value
	description = p_desc
