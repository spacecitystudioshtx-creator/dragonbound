## Autoloaded singleton. Holds all static drake species and move definitions.
##
## Usage:
##   DrakeDatabase.drakes["ember"]          → DrakeData
##   DrakeDatabase.make_drake("flick", 4)   → DrakeInstance at level 4
##   DrakeDatabase.get_combo_move(0, 1)     → MoveData for Fire+Water combo

extends Node

## All drake species, keyed by lowercase ID string
var drakes: Dictionary = {}

## Combo moves keyed by "minType_maxType" (uses DrakeData.Type enum ints)
var combo_moves: Dictionary = {}


func _ready() -> void:
	_init_database()


func _init_database() -> void:
	# ── Moves ────────────────────────────────────────────────────────────────
	# Ember line
	var spark_snap    := MoveData.new("Spark Snap",   MoveData.Type.FIRE,   35, 100)
	var smoke_screen  := MoveData.new("Smoke Screen", MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.LOWER_ACCURACY, 0.2, "Lowers enemy accuracy 20%.")
	var tail_whip     := MoveData.new("Tail Whip",    MoveData.Type.NORMAL, 30, 100)
	var flame_rush    := MoveData.new("Flame Rush",   MoveData.Type.FIRE,   60,  90)
	var ash_cloud     := MoveData.new("Ash Cloud",    MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.LOWER_ACCURACY, 0.3, "Lowers enemy accuracy 30%.")
	var meltdown      := MoveData.new("Meltdown",     MoveData.Type.FIRE,   90,  80,
			MoveData.Effect.SELF_DAMAGE, 0.1, "Massive blast. User takes 10% recoil.")
	var molten_armor  := MoveData.new("Molten Armor", MoveData.Type.FIRE,    0, 100,
			MoveData.Effect.REFLECT_DAMAGE, 0.0, "Raises defense. Reflects contact damage.")

	# Ripple line
	var splash_bite   := MoveData.new("Splash Bite",    MoveData.Type.WATER,  35, 100)
	var slick_dodge   := MoveData.new("Slick Dodge",    MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.RAISE_EVASION, 0.2, "Adds 20% dodge chance.")
	var headbutt      := MoveData.new("Headbutt",       MoveData.Type.NORMAL, 30, 100)
	var riptide       := MoveData.new("Riptide",        MoveData.Type.WATER,  50,  90,
			MoveData.Effect.TRAP, 2.0, "Pulls enemy in. Can't change bench target.")
	var pressure_wave := MoveData.new("Pressure Wave",  MoveData.Type.NORMAL, 50, 100)
	var abyssal_crush := MoveData.new("Abyssal Crush",  MoveData.Type.WATER,  80,  85,
			MoveData.Effect.IGNORE_DEF_BUFFS, 0.0, "Ignores enemy defense buffs.")
	var drown_out     := MoveData.new("Drown Out",      MoveData.Type.WATER,   0, 100,
			MoveData.Effect.BLOCK_BENCH, 2.0, "Blocks enemy bench combo for 2 turns.")

	# Sprig line
	var vine_lash   := MoveData.new("Vine Lash",   MoveData.Type.NATURE, 35, 100)
	var harden      := MoveData.new("Harden",       MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.RAISE_DEFENSE, 0.3, "Boosts defense 30%.")
	var pebble_toss := MoveData.new("Pebble Toss",  MoveData.Type.NORMAL, 30,  95)
	var stone_wall  := MoveData.new("Stone Wall",   MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.REFLECT_DAMAGE, 0.0, "Raises defense. Reflects contact damage.")
	var root_snare  := MoveData.new("Root Snare",   MoveData.Type.NATURE,  0,  90,
			MoveData.Effect.TRAP, 1.0, "Traps enemy for 1 turn.")
	var quake_bloom := MoveData.new("Quake Bloom",  MoveData.Type.NATURE, 75,  85)
	var fortress    := MoveData.new("Fortress",     MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.FORTIFY, 0.6, "Massive defense boost. Can't attack next turn.")

	# Fodder moves
	var ember_bite  := MoveData.new("Ember Bite",  MoveData.Type.FIRE,   30, 100)
	var scratch     := MoveData.new("Scratch",     MoveData.Type.NORMAL, 25, 100)
	var leaflet     := MoveData.new("Leaflet",     MoveData.Type.NATURE, 30, 100)
	var growl       := MoveData.new("Growl",       MoveData.Type.NORMAL,  0, 100,
			MoveData.Effect.LOWER_ACCURACY, 0.1)
	var water_gun   := MoveData.new("Water Gun",   MoveData.Type.WATER,  30, 100)
	var splash_atk  := MoveData.new("Splash",      MoveData.Type.NORMAL, 25, 100)

	# ── Drake species ─────────────────────────────────────────────────────────
	# Starters — catch_rate 45 (hard to catch, like Pokémon starters)
	drakes["ember"] = DrakeData.new("Ember", DrakeData.Type.FIRE, DrakeData.DrakeClass.TRUE_DRAGON,
			45, 35, 30, 32,  45, 16, "scornn")
	drakes["ember"].base_moves = [spark_snap, smoke_screen, tail_whip]

	drakes["scornn"] = DrakeData.new("Scornn", DrakeData.Type.FIRE, DrakeData.DrakeClass.TRUE_DRAGON,
			55, 48, 40, 42,  45, 36, "ashvane")
	drakes["scornn"].base_moves = [spark_snap, flame_rush, ash_cloud]

	drakes["ashvane"] = DrakeData.new("Ashvane", DrakeData.Type.FIRE, DrakeData.DrakeClass.TRUE_DRAGON,
			70, 65, 55, 55,  45)
	drakes["ashvane"].base_moves = [flame_rush, meltdown, molten_armor]

	drakes["ripple"] = DrakeData.new("Ripple", DrakeData.Type.WATER, DrakeData.DrakeClass.LEVIATHAN,
			42, 32, 35, 40,  45, 16, "undertow")
	drakes["ripple"].base_moves = [splash_bite, slick_dodge, headbutt]

	drakes["undertow"] = DrakeData.new("Undertow", DrakeData.Type.WATER, DrakeData.DrakeClass.LEVIATHAN,
			52, 45, 45, 55,  45, 36, "tidewrath")
	drakes["undertow"].base_moves = [splash_bite, riptide, pressure_wave]

	drakes["tidewrath"] = DrakeData.new("Tidewrath", DrakeData.Type.WATER, DrakeData.DrakeClass.LEVIATHAN,
			65, 60, 60, 70,  45)
	drakes["tidewrath"].base_moves = [riptide, abyssal_crush, drown_out]

	drakes["sprig"] = DrakeData.new("Sprig", DrakeData.Type.NATURE, DrakeData.DrakeClass.BEAST,
			48, 30, 40, 28,  45, 16, "thicket")
	drakes["sprig"].base_moves = [vine_lash, harden, pebble_toss]

	drakes["thicket"] = DrakeData.new("Thicket", DrakeData.Type.NATURE, DrakeData.DrakeClass.BEAST,
			60, 42, 58, 35,  45, 36, "ironbark")
	drakes["thicket"].base_moves = [vine_lash, stone_wall, root_snare]

	drakes["ironbark"] = DrakeData.new("Ironbark", DrakeData.Type.NATURE, DrakeData.DrakeClass.BEAST,
			78, 55, 78, 40,  45)
	drakes["ironbark"].base_moves = [stone_wall, quake_bloom, fortress]

	# Fodder — catch_rate 150 (easy to catch)
	drakes["flick"] = DrakeData.new("Flick", DrakeData.Type.FIRE,   DrakeData.DrakeClass.BEAST,
			32, 28, 22, 30,  150)
	drakes["flick"].base_moves = [ember_bite, scratch]

	drakes["tuft"] = DrakeData.new("Tuft", DrakeData.Type.NATURE, DrakeData.DrakeClass.BEAST,
			35, 22, 28, 25,  150)
	drakes["tuft"].base_moves = [leaflet, growl]

	drakes["gulp"] = DrakeData.new("Gulp", DrakeData.Type.WATER,  DrakeData.DrakeClass.BEAST,
			33, 25, 30, 28,  150)
	drakes["gulp"].base_moves = [water_gun, splash_atk]

	# ── Combo moves ──────────────────────────────────────────────────────────
	# Key: "minType_maxType" using DrakeData.Type ints (FIRE=0, WATER=1, NATURE=2)
	combo_moves["0_0"] = MoveData.new("Eruption",    MoveData.Type.FIRE,   90, 80,
			MoveData.Effect.NONE, 0.0, "Pure power fire nuke.")
	combo_moves["0_1"] = MoveData.new("Steam Burst", MoveData.Type.FIRE,   50, 90,
			MoveData.Effect.LOWER_ACCURACY, 0.2, "Damage + drops enemy accuracy.")
	combo_moves["0_2"] = MoveData.new("Wildfire",    MoveData.Type.FIRE,   40, 95,
			MoveData.Effect.BURN_DOT, 0.0, "Inflicts a burning DoT on the enemy.")
	combo_moves["1_1"] = MoveData.new("Flood Surge", MoveData.Type.WATER,  70, 90,
			MoveData.Effect.FLOOD, 0.0, "Removes all enemy stat buffs.")
	combo_moves["1_2"] = MoveData.new("Overgrowth",  MoveData.Type.NATURE,  0, 100,
			MoveData.Effect.HEAL_SELF, 0.4, "Heals active drake 40% max HP.")
	combo_moves["2_2"] = MoveData.new("Deep Roots",  MoveData.Type.NATURE,  0, 100,
			MoveData.Effect.HEAL_TEAM, 0.1, "Heals all party drakes 10% max HP.")


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
