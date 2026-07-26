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
const SPRITE_W := 16
const SPRITE_H := 16
const TRAINER_SHEET_PATH := "res://art/player/kindra_trainer_sheet.png"

# Current facing direction for animation
var facing := Vector2.DOWN
# Whether the player is currently moving between tiles
var is_moving := false
# Target position for grid-based movement
var target_pos := Vector2.ZERO
var map_bounds := Rect2()

# Reference to the animated sprite
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# External joystick input (set by TouchJoystick)
var joystick_input := Vector2.ZERO


func _ready() -> void:
	_apply_trainer_sheet()
	# Snap to tile center (not corner) — floor to tile, then offset by half-tile
	position = (position / float(TILE_SIZE)).floor() * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	target_pos = position


func _physics_process(delta: float) -> void:
	## Freeze movement unless the game is in the OVERWORLD mode.
	## (Dialog / Battle / Menu / Transition all suspend walking.)
	if GameMode and GameMode.current() != GameMode.Mode.OVERWORLD:
		if is_moving:
			## Finish the current step then stop.
			_move_toward_target(delta)
		else:
			_play_idle()
		return

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


## Check if the target position is walkable.
## Uses direct tile lookup on the obstacle layer (data-driven, like Pokémon)
## with a physics raycast as fallback for non-tile obstacles.
func _can_move_to(target: Vector2) -> bool:
	if map_bounds.size != Vector2.ZERO:
		var min_pos := map_bounds.position + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		var max_pos := map_bounds.end - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		if target.x < min_pos.x or target.x > max_pos.x or target.y < min_pos.y or target.y > max_pos.y:
			return false

	## Direct tile check — any tile on the obstacle layer blocks movement
	var tile_coord := Vector2i(int(target.x / TILE_SIZE), int(target.y / TILE_SIZE))
	var obs := _get_obstacle_layer()
	if obs and obs.get_cell_source_id(tile_coord) != -1:
		return false
	## Physics raycast fallback (for Area2D or StaticBody2D obstacles)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		position, target, 2  # Collision mask layer 2 = obstacles
	)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()


func set_map_bounds(bounds: Rect2) -> void:
	map_bounds = bounds


var _obs_layer_cache: TileMapLayer = null

func _get_obstacle_layer() -> TileMapLayer:
	if _obs_layer_cache:
		return _obs_layer_cache
	var parent := get_parent()
	if parent:
		_obs_layer_cache = parent.get_node_or_null("ObstacleLayer") as TileMapLayer
	return _obs_layer_cache


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


func _apply_trainer_sheet() -> void:
	var img := Image.new()
	var err := img.load(ProjectSettings.globalize_path(TRAINER_SHEET_PATH))
	if err != OK:
		push_warning("player: could not load trainer sheet at %s" % TRAINER_SHEET_PATH)
		return
	var tex := ImageTexture.create_from_image(img)
	var frames := sprite.sprite_frames
	if frames == null:
		return
	for anim_name in frames.get_animation_names():
		for i in frames.get_frame_count(anim_name):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = _trainer_region_for_anim(String(anim_name), i)
			var duration := frames.get_frame_duration(anim_name, i)
			frames.set_frame(anim_name, i, atlas, duration)


func _trainer_region_for_anim(anim_name: String, frame_idx: int) -> Rect2:
	var row := 0
	if anim_name.ends_with("_up"):
		row = 1
	elif anim_name.ends_with("_left"):
		row = 2
	elif anim_name.ends_with("_right"):
		row = 3
	var col := 0
	if anim_name.begins_with("walk_"):
		col = 1 if frame_idx == 0 else 3
	return Rect2(col * SPRITE_W, row * SPRITE_H, SPRITE_W, SPRITE_H)


func refresh_trainer_sheet() -> void:
	_apply_trainer_sheet()
