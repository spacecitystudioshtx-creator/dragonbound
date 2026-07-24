## Attach to an Area2D placed over grass tiles.
## Each time the player steps onto a new tile inside this zone, there is a
## chance of triggering a wild drake encounter.
##
## Usage in the editor:
##   - Set collision_layer = 8 (layer 4, separate from obstacles/transitions)
##   - Populate encounter_table: { "flick": 60, "tuft": 40 }  (weights, not %)
##   - Adjust level_min/max and encounter_rate as needed

extends Area2D

## Drake IDs that can appear here, mapped to relative spawn weights.
@export var encounter_table: Dictionary = {}
## Level range for wild drakes spawned in this zone.
@export var level_min: int = 3
@export var level_max: int = 5
## Probability per tile step that an encounter triggers (0.0–1.0).
@export var encounter_rate: float = 0.15

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if not body.tile_stepped.is_connected(_on_tile_stepped):
		body.tile_stepped.connect(_on_tile_stepped)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if body.tile_stepped.is_connected(_on_tile_stepped):
		body.tile_stepped.disconnect(_on_tile_stepped)


func _on_tile_stepped() -> void:
	if not _player_inside:
		return
	if not GameState.has_starter:
		return
	if GameState.battle_cooldown_steps > 0:
		GameState.battle_cooldown_steps -= 1
		return
	if SceneTransition.is_transitioning:
		return
	if encounter_table.is_empty():
		return
	if randf() > encounter_rate:
		return

	var id    := _weighted_pick()
	var level := randi_range(level_min, level_max)
	var enemy := DrakeDatabase.make_drake(id, level)
	if enemy == null:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	BattleManager.start_wild_battle(
			enemy,
			get_tree().current_scene.scene_file_path,
			player.position)


## Pick a drake ID using the weighted encounter_table.
func _weighted_pick() -> String:
	var total := 0
	for w in encounter_table.values():
		total += w

	var roll := randi() % maxi(total, 1)
	var cumulative := 0
	for id in encounter_table:
		cumulative += encounter_table[id]
		if roll < cumulative:
			return id

	return encounter_table.keys()[0]
