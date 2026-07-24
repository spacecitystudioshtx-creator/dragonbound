## On-screen virtual joystick for mobile touch input.
## Renders a circular joystick that feeds input to the player.
## Only visible on touchscreen devices (or when emulating touch).

extends Control

# Maximum distance the knob can move from center (in pixels)
const MAX_RADIUS := 24.0

# Visual elements
@onready var bg: TextureRect = $Background
@onready var knob: TextureRect = $Knob

# Joystick state
var is_pressed := false
var touch_index := -1
var center_pos := Vector2.ZERO
var output := Vector2.ZERO


func _ready() -> void:
	# Position joystick in bottom-left corner
	center_pos = bg.size / 2.0
	knob.position = bg.position + (bg.size - knob.size) / 2.0
	# Only show on mobile / touch devices
	visible = DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


## Handle touch start/end.
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only respond if touch is within the joystick area
		if _is_in_joystick_area(event.position):
			is_pressed = true
			touch_index = event.index
			_update_knob(event.position)
	else:
		if event.index == touch_index:
			_reset()


## Handle touch drag (movement).
func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_pressed and event.index == touch_index:
		_update_knob(event.position)


## Check if a screen position is within the joystick's touch area.
func _is_in_joystick_area(screen_pos: Vector2) -> bool:
	var local := screen_pos - global_position - bg.position
	var dist := local.distance_to(center_pos)
	return dist < MAX_RADIUS * 2.5  # Generous touch area


## Update knob position and output vector from a touch position.
func _update_knob(screen_pos: Vector2) -> void:
	var local := screen_pos - global_position - bg.position
	var delta := local - center_pos
	# Clamp to max radius
	if delta.length() > MAX_RADIUS:
		delta = delta.normalized() * MAX_RADIUS
	# Move the knob visual
	knob.position = bg.position + (bg.size - knob.size) / 2.0 + delta
	# Normalize output to -1..1 range
	output = delta / MAX_RADIUS
	# Send to player
	_send_to_player()


## Reset the joystick to center.
func _reset() -> void:
	is_pressed = false
	touch_index = -1
	knob.position = bg.position + (bg.size - knob.size) / 2.0
	output = Vector2.ZERO
	_send_to_player()


## Feed the joystick output to the player node.
func _send_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.joystick_input = output
