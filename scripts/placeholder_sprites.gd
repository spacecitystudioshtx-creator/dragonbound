## Generates placeholder colored rectangle sprites at runtime.
## This autoload creates a spritesheet texture that the player
## AnimatedSprite2D can reference until real pixel art is ready.
##
## Layout: 2 frames wide x 4 directions tall (16x16 each)
## Row 0: Down  |  Row 1: Up  |  Row 2: Left  |  Row 3: Right

extends Node

const SPRITE_SIZE := 16
const BODY_COLOR := Color(0.2, 0.5, 0.9)       # Blue body
const HEAD_COLOR := Color(0.9, 0.8, 0.5)        # Tan head/face
const ACCENT_COLOR := Color(0.15, 0.35, 0.7)    # Darker blue for frame 2


func _ready() -> void:
	_generate_player_spritesheet()


## Create a 32x64 spritesheet image and save it to the player scene.
func _generate_player_spritesheet() -> void:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background

	# Draw each direction, 2 frames each
	_draw_character(img, 0, 0, Vector2.DOWN, false)   # Down idle
	_draw_character(img, 16, 0, Vector2.DOWN, true)    # Down walk
	_draw_character(img, 0, 16, Vector2.UP, false)     # Up idle
	_draw_character(img, 16, 16, Vector2.UP, true)     # Up walk
	_draw_character(img, 0, 32, Vector2.LEFT, false)   # Left idle
	_draw_character(img, 16, 32, Vector2.LEFT, true)   # Left walk
	_draw_character(img, 0, 48, Vector2.RIGHT, false)  # Right idle
	_draw_character(img, 16, 48, Vector2.RIGHT, true)  # Right walk

	# Create texture and apply to player sprite
	var tex := ImageTexture.create_from_image(img)
	_apply_to_player(tex)


## Draw a single 16x16 character frame at the given position.
func _draw_character(img: Image, ox: int, oy: int, dir: Vector2, walking: bool) -> void:
	var body := BODY_COLOR if not walking else ACCENT_COLOR
	# Body (8x8 rectangle, centered)
	for x in range(4, 12):
		for y in range(6, 14):
			img.set_pixel(ox + x, oy + y, body)
	# Head (6x5 rectangle, centered, on top of body)
	for x in range(5, 11):
		for y in range(2, 7):
			img.set_pixel(ox + x, oy + y, HEAD_COLOR)
	# Eyes (depending on direction)
	var eye_color := Color(0.1, 0.1, 0.2)
	match dir:
		Vector2.DOWN:
			img.set_pixel(ox + 6, oy + 4, eye_color)
			img.set_pixel(ox + 9, oy + 4, eye_color)
		Vector2.UP:
			pass  # No eyes visible from behind
		Vector2.LEFT:
			img.set_pixel(ox + 6, oy + 4, eye_color)
		Vector2.RIGHT:
			img.set_pixel(ox + 9, oy + 4, eye_color)
	# Walk animation: shift legs
	if walking:
		img.set_pixel(ox + 5, oy + 14, body)
		img.set_pixel(ox + 10, oy + 14, body)


## Find the player's AnimatedSprite2D and update all frame textures.
func _apply_to_player(tex: ImageTexture) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return

	var frames := sprite.sprite_frames
	# Update each animation's atlas textures to use our generated sheet
	for anim_name in frames.get_animation_names():
		for i in frames.get_frame_count(anim_name):
			var atlas: AtlasTexture = frames.get_frame_texture(anim_name, i)
			if atlas:
				atlas.atlas = tex
