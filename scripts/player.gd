## Player character controller.
## Handles grid-based movement, 4-direction animation, and input from
## keyboard (WASD / arrows) or the on-screen touch joystick.

extends CharacterBody2D

## Emitted each time the player snaps to a new tile position.
## EncounterZone listens to this to roll for wild encounters.
signal tile_stepped

# Movement speed in pixels per second — 128px/s = one 16px tile every ~0.125s
const SPEED := 128.0
# Size of one tile in pixels — used for grid-aligned movement
const TILE_SIZE := 16

# Current facing direction for animation
var facing := Vector2.DOWN
# Whether the player is currently moving between tiles
var is_moving := false
# Target position for grid-based movement
var target_pos := Vector2.ZERO

# Reference to the animated sprite
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# External joystick input (set by TouchJoystick)
var joystick_input := Vector2.ZERO


func _ready() -> void:
	# Snap to tile center (not corner) — floor to tile, then offset by half-tile
	position = (position / float(TILE_SIZE)).floor() * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	target_pos = position


func _physics_process(delta: float) -> void:
	if is_moving:
		_move_toward_target(delta)
	else:
		_handle_idle_input()


## Move the player toward the target tile position.
func _move_toward_target(delta: float) -> void:
	var move_vec := (target_pos - position)
	if move_vec.length() <= SPEED * delta:
		# Snap exactly to the tile — no overshoot
		position = target_pos
		is_moving = false
		tile_stepped.emit()
		# Chain the next step immediately (no turn delay while already walking)
		_try_start_move()
		if not is_moving:
			_play_idle()
	else:
		position += move_vec.normalized() * SPEED * delta


## Called each frame while standing still.
## Implements the Pokémon turn-before-move mechanic: pressing a new direction
## faces the character first; only holding it on the next frame begins walking.
func _handle_idle_input() -> void:
	var input_dir := _get_input_direction()
	if input_dir == Vector2.ZERO:
		_play_idle()
		return
	if input_dir != facing:
		# Turn to face — don't step yet (brief tap just rotates the sprite)
		facing = input_dir
		_play_idle()
		return
	# Same direction held → begin the step
	_try_start_move()


## Start a grid-based move in the current input direction.
## Used for step chaining (no turn delay applied here).
func _try_start_move() -> void:
	var input_dir := _get_input_direction()
	if input_dir == Vector2.ZERO:
		_play_idle()
		return

	facing = input_dir
	_play_walk()

	# Raycast one tile ahead to check for obstacles
	var next_pos := position + input_dir * TILE_SIZE
	if _can_move_to(next_pos):
		target_pos = next_pos
		is_moving = true


## Combine keyboard and joystick input into a single direction.
## Only allows cardinal directions (no diagonals).
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	# Keyboard input
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")

	# Joystick input (overrides keyboard if active)
	if joystick_input.length() > 0.3:
		dir = joystick_input

	# Snap to dominant axis — no diagonal movement
	if dir == Vector2.ZERO:
		return Vector2.ZERO
	if abs(dir.x) > abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))


## Check if the target position is walkable via a short raycast.
func _can_move_to(target: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		position, target, 2  # Collision mask layer 2 = obstacles
	)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()


## Play the idle animation for the current facing direction.
func _play_idle() -> void:
	match facing:
		Vector2.DOWN:  sprite.play("idle_down")
		Vector2.UP:    sprite.play("idle_up")
		Vector2.LEFT:  sprite.play("idle_left")
		Vector2.RIGHT: sprite.play("idle_right")


## Play the walk animation for the current facing direction.
func _play_walk() -> void:
	match facing:
		Vector2.DOWN:  sprite.play("walk_down")
		Vector2.UP:    sprite.play("walk_up")
		Vector2.LEFT:  sprite.play("walk_left")
		Vector2.RIGHT: sprite.play("walk_right")
