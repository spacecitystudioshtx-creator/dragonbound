## Autoloaded singleton. Stores battle configuration and initiates scene transitions
## into the battle scene. Read by BattleScene on _ready().

extends Node

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

## Set before switching to the battle scene
var enemy_party: Array = []       ## Array[DrakeInstance]
var is_trainer_battle: bool = false
var can_catch: bool = true
var trainer_name: String = ""


## Trigger a wild encounter.
func start_wild_battle(enemy: DrakeInstance, from_scene: String, from_pos: Vector2) -> void:
	enemy_party = [enemy]
	is_trainer_battle = false
	can_catch = true
	trainer_name = ""
	GameState.return_scene = from_scene
	GameState.return_pos = from_pos
	SceneTransition.change_scene(BATTLE_SCENE)


## Trigger a trainer battle.
func start_trainer_battle(
		enemies: Array,
		trainer: String,
		from_scene: String,
		from_pos: Vector2) -> void:
	enemy_party = enemies
	is_trainer_battle = true
	can_catch = false
	trainer_name = trainer
	GameState.return_scene = from_scene
	GameState.return_pos = from_pos
	SceneTransition.change_scene(BATTLE_SCENE)
