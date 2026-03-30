## Generates a placeholder trainer sprite at runtime.
## Draws a FireRed-proportioned character: cap, face, shirt, pants, shoes.
## Layout: 2 frames wide × 4 directions tall (16×16 each)
##   Row 0: Down  |  Row 1: Up  |  Row 2: Left  |  Row 3: Right

extends Node

const SPRITE_SIZE := 16

## Trainer color palette
const C_CAP       := Color(0.80, 0.15, 0.15)   ## Red cap
const C_CAP_BRIM  := Color(0.60, 0.10, 0.10)   ## Darker brim
const C_SKIN      := Color(0.95, 0.78, 0.58)   ## Face/hands
const C_EYE       := Color(0.10, 0.10, 0.22)   ## Eyes
const C_HAIR      := Color(0.20, 0.12, 0.05)   ## Hair under cap
const C_SHIRT     := Color(0.15, 0.35, 0.80)   ## Blue shirt
const C_SHIRT_D   := Color(0.10, 0.25, 0.60)   ## Shirt shadow
const C_PANTS     := Color(0.88, 0.82, 0.55)   ## Tan/khaki pants
const C_PANTS_D   := Color(0.70, 0.65, 0.42)   ## Pants shadow
const C_SHOES     := Color(0.18, 0.12, 0.08)   ## Dark shoes
const C_OUTLINE   := Color(0.08, 0.05, 0.02)   ## Near-black outline


func _ready() -> void:
	_generate_player_spritesheet()


func _generate_player_spritesheet() -> void:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_draw_frame(img,  0,  0, Vector2.DOWN,  false)
	_draw_frame(img, 16,  0, Vector2.DOWN,  true)
	_draw_frame(img,  0, 16, Vector2.UP,    false)
	_draw_frame(img, 16, 16, Vector2.UP,    true)
	_draw_frame(img,  0, 32, Vector2.LEFT,  false)
	_draw_frame(img, 16, 32, Vector2.LEFT,  true)
	_draw_frame(img,  0, 48, Vector2.RIGHT, false)
	_draw_frame(img, 16, 48, Vector2.RIGHT, true)

	var tex := ImageTexture.create_from_image(img)
	_apply_to_player(tex)


## Draw one 16×16 trainer frame at pixel offset (ox, oy).
func _draw_frame(img: Image, ox: int, oy: int, dir: Vector2, step: bool) -> void:
	## ── Cap (rows 0-3) ────────────────────────────────────────────────────
	if dir != Vector2.UP:
		## Cap top
		for x in range(4, 12):
			for y in range(0, 3):
				img.set_pixel(ox + x, oy + y, C_CAP)
		## Brim
		for x in range(3, 13):
			img.set_pixel(ox + x, oy + 3, C_CAP_BRIM)
		## Outline top
		for x in range(4, 12):
			img.set_pixel(ox + x, oy, C_OUTLINE)
		img.set_pixel(ox + 3, oy + 1, C_OUTLINE)
		img.set_pixel(ox + 12, oy + 1, C_OUTLINE)
	else:
		## From behind: just hair under cap
		for x in range(4, 12):
			for y in range(0, 4):
				img.set_pixel(ox + x, oy + y, C_HAIR)

	## ── Face (rows 3-7) ────────────────────────────────────────────────────
	if dir != Vector2.UP:
		for x in range(4, 12):
			for y in range(3, 8):
				img.set_pixel(ox + x, oy + y, C_SKIN)
		## Eyes
		match dir:
			Vector2.DOWN:
				img.set_pixel(ox + 6, oy + 5, C_EYE)
				img.set_pixel(ox + 9, oy + 5, C_EYE)
			Vector2.LEFT:
				img.set_pixel(ox + 5, oy + 5, C_EYE)
			Vector2.RIGHT:
				img.set_pixel(ox + 10, oy + 5, C_EYE)
		## Face outline
		img.set_pixel(ox + 3,  oy + 4, C_OUTLINE)
		img.set_pixel(ox + 12, oy + 4, C_OUTLINE)
		img.set_pixel(ox + 3,  oy + 7, C_OUTLINE)
		img.set_pixel(ox + 12, oy + 7, C_OUTLINE)
	else:
		## Back of head
		for x in range(4, 12):
			for y in range(3, 8):
				img.set_pixel(ox + x, oy + y, C_SKIN)

	## ── Shirt body (rows 7-11) ─────────────────────────────────────────────
	for x in range(3, 13):
		for y in range(7, 12):
			var shade := C_SHIRT_D if (x <= 4 or x >= 11) else C_SHIRT
			img.set_pixel(ox + x, oy + y, shade)
	## Arms at sides
	img.set_pixel(ox + 2,  oy + 7,  C_SKIN)
	img.set_pixel(ox + 2,  oy + 8,  C_SKIN)
	img.set_pixel(ox + 2,  oy + 9,  C_SKIN)
	img.set_pixel(ox + 13, oy + 7,  C_SKIN)
	img.set_pixel(ox + 13, oy + 8,  C_SKIN)
	img.set_pixel(ox + 13, oy + 9,  C_SKIN)

	## ── Pants (rows 11-14) ────────────────────────────────────────────────
	## Left leg
	for x in range(3, 8):
		for y in range(11, 15):
			img.set_pixel(ox + x, oy + y, C_PANTS if x < 7 else C_PANTS_D)
	## Right leg
	for x in range(8, 13):
		for y in range(11, 15):
			img.set_pixel(ox + x, oy + y, C_PANTS if x > 8 else C_PANTS_D)
	## Gap between legs
	img.set_pixel(ox + 7,  oy + 11, C_OUTLINE)
	img.set_pixel(ox + 8,  oy + 11, C_OUTLINE)

	## ── Shoes (row 15) ────────────────────────────────────────────────────
	for x in range(3, 8):
		img.set_pixel(ox + x, oy + 15, C_SHOES)
	for x in range(8, 13):
		img.set_pixel(ox + x, oy + 15, C_SHOES)

	## ── Walk animation: shift one leg forward ─────────────────────────────
	if step:
		## Shift right leg down 1px, left leg stays
		for x in range(8, 13):
			## move bottom of right leg down
			var old_col := img.get_pixel(ox + x, oy + 13)
			img.set_pixel(ox + x, oy + 14, old_col)
			img.set_pixel(ox + x, oy + 13, C_PANTS)
		img.set_pixel(ox + 8, oy + 15, C_SHOES)


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
	for anim_name in frames.get_animation_names():
		for i in frames.get_frame_count(anim_name):
			var atlas: AtlasTexture = frames.get_frame_texture(anim_name, i)
			if atlas:
				atlas.atlas = tex
