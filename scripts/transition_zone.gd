## Attach to an Area2D that triggers a scene transition.
## When the player enters this area, it calls SceneTransition to
## load the target scene and place the player at the spawn position.

extends Area2D

# Path to the scene to load
@export_file("*.tscn") var target_scene: String = ""
# Where the player spawns in the new scene (in pixels)
@export var spawn_position := Vector2(32, 32)


func _ready() -> void:
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Only trigger for the player
	if body.is_in_group("player"):
		SceneTransition.change_scene(target_scene, spawn_position)
