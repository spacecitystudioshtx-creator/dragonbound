## Autoloaded singleton that handles scene transitions.
## When the player walks into a transition zone (Area2D on layer 3),
## this script fades out, loads the next scene, and fades back in.
##
## Usage from a transition trigger:
##   SceneTransition.change_scene("res://scenes/maps/zone_2.tscn", Vector2(32, 48))

extends CanvasLayer

# Fade duration in seconds
const FADE_DURATION := 0.3

# Reference to the fade overlay (ColorRect covering the whole screen)
@onready var fade_rect: ColorRect = $FadeRect
@onready var anim: AnimationPlayer = $AnimationPlayer

# Whether a transition is currently in progress
var is_transitioning := false


func _ready() -> void:
	# Start fully transparent
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Transition to a new scene, placing the player at spawn_pos.
func change_scene(scene_path: String, spawn_pos := Vector2(-1, -1)) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Fade to black
	await _fade_out()

	# Load the new scene
	get_tree().change_scene_to_file(scene_path)

	# Wait one frame for the new scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	# Move player to spawn point if specified
	if spawn_pos != Vector2(-1, -1):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.position = spawn_pos
			player.target_pos = spawn_pos

	# Fade back in
	await _fade_in()
	is_transitioning = false


## Fade the screen to black.
func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished


## Fade the screen back from black.
func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween.finished
