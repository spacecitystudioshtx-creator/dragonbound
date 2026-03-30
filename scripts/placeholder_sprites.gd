## Generates a placeholder trainer sprite at runtime.
## Draws a Pokémon FireRed-proportioned character with clean outlines,
## shading, and visible detail at 16×16.
##
## Layout: 2 frames wide × 4 directions tall (16×16 each)
##   Row 0: Down  |  Row 1: Up  |  Row 2: Left  |  Row 3: Right

extends Node

const SPRITE_SIZE := 16

## Cached texture for reapply after scene changes
var _tex: ImageTexture = null

## ── Palette ─────────────────────────────────────────────────────────────────
const OL  := Color(0.06, 0.04, 0.02)   ## Black outline
const CAP := Color(0.82, 0.14, 0.14)   ## Red cap
const CPD := Color(0.58, 0.08, 0.08)   ## Cap shadow
const CPW := Color(0.92, 0.92, 0.88)   ## Cap white stripe
const SKN := Color(0.94, 0.76, 0.56)   ## Skin
const SKD := Color(0.78, 0.60, 0.40)   ## Skin shadow
const EYE := Color(0.08, 0.08, 0.20)   ## Eye
const HRS := Color(0.18, 0.10, 0.04)   ## Hair (dark brown)
const SHT := Color(0.12, 0.32, 0.78)   ## Shirt blue
const SHD := Color(0.08, 0.22, 0.55)   ## Shirt shadow
const PNT := Color(0.32, 0.30, 0.42)   ## Pants dark gray-blue
const PND := Color(0.22, 0.20, 0.30)   ## Pants shadow
const SHO := Color(0.15, 0.10, 0.06)   ## Shoes


func _ready() -> void:
	_generate_player_spritesheet()


func _generate_player_spritesheet() -> void:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_draw_down(img, 0, 0, false)
	_draw_down(img, 16, 0, true)
	_draw_up(img, 0, 16, false)
	_draw_up(img, 16, 16, true)
	_draw_side(img, 0, 32, false, false)   ## Left idle
	_draw_side(img, 16, 32, false, true)   ## Left walk
	_draw_side(img, 0, 48, true, false)    ## Right idle
	_draw_side(img, 16, 48, true, true)    ## Right walk

	_tex = ImageTexture.create_from_image(img)
	_apply_to_player(_tex)


## ── Down-facing frame ───────────────────────────────────────────────────────
func _draw_down(img: Image, ox: int, oy: int, step: bool) -> void:
	## Cap (rows 1-3)
	_hline(img, ox, oy, 5, 10, CAP)     ## top of cap
	_hline(img, ox, oy, 4, 11, CAP)     ## cap body row 1
	img.set_pixel(ox + 7, oy + 1, CPW)  ## white stripe
	img.set_pixel(ox + 8, oy + 1, CPW)
	_hline(img, ox, oy, 4, 11, CAP, 2)
	_hline(img, ox, oy, 3, 12, CPD, 3)  ## brim (darker)
	## Outline top
	_hline(img, ox, oy, 5, 10, OL, 0)
	img.set_pixel(ox + 4, oy + 1, OL)
	img.set_pixel(ox + 11, oy + 1, OL)
	img.set_pixel(ox + 3, oy + 2, OL)
	img.set_pixel(ox + 12, oy + 2, OL)

	## Face (rows 4-6)
	for y in range(4, 7):
		_hline(img, ox, oy, 4, 11, SKN, y)
	## Eyes
	img.set_pixel(ox + 5, oy + 5, EYE)
	img.set_pixel(ox + 6, oy + 5, EYE)
	img.set_pixel(ox + 9, oy + 5, EYE)
	img.set_pixel(ox + 10, oy + 5, EYE)
	## Face outline
	img.set_pixel(ox + 3, oy + 4, OL)
	img.set_pixel(ox + 12, oy + 4, OL)
	img.set_pixel(ox + 3, oy + 5, OL)
	img.set_pixel(ox + 12, oy + 5, OL)
	img.set_pixel(ox + 3, oy + 6, OL)
	img.set_pixel(ox + 12, oy + 6, OL)

	## Shirt (rows 7-10)
	for y in range(7, 11):
		_hline(img, ox, oy, 4, 11, SHT, y)
	## Shirt shadow on edges
	for y in range(7, 11):
		img.set_pixel(ox + 4, oy + y, SHD)
		img.set_pixel(ox + 11, oy + y, SHD)
	## Shirt outline
	for y in range(7, 11):
		img.set_pixel(ox + 3, oy + y, OL)
		img.set_pixel(ox + 12, oy + y, OL)

	## Arms (skin on sides of shirt)
	for y in range(7, 10):
		img.set_pixel(ox + 3, oy + y, SKN)
		img.set_pixel(ox + 12, oy + y, SKN)
		img.set_pixel(ox + 2, oy + y, OL)
		img.set_pixel(ox + 13, oy + y, OL)

	## Pants (rows 11-13)
	for y in range(11, 14):
		_hline(img, ox, oy, 4, 7, PNT, y)
		_hline(img, ox, oy, 8, 11, PNT, y)
	## Leg gap
	img.set_pixel(ox + 7, oy + 12, OL)
	img.set_pixel(ox + 8, oy + 12, OL)
	## Pants shadow
	for y in range(11, 14):
		img.set_pixel(ox + 4, oy + y, PND)
		img.set_pixel(ox + 11, oy + y, PND)

	## Shoes (rows 14-15)
	_hline(img, ox, oy, 3, 7, SHO, 14)
	_hline(img, ox, oy, 8, 12, SHO, 14)
	_hline(img, ox, oy, 3, 7, SHO, 15)
	_hline(img, ox, oy, 8, 12, SHO, 15)

	## Walk: shift one leg
	if step:
		_hline(img, ox, oy, 8, 11, PNT, 14)
		_hline(img, ox, oy, 8, 12, SHO, 15)
		img.set_pixel(ox + 7, oy + 14, Color(0, 0, 0, 0))


## ── Up-facing frame ─────────────────────────────────────────────────────────
func _draw_up(img: Image, ox: int, oy: int, step: bool) -> void:
	## Hair / back of cap (rows 0-3)
	_hline(img, ox, oy, 5, 10, HRS, 0)
	_hline(img, ox, oy, 4, 11, HRS, 1)
	_hline(img, ox, oy, 4, 11, HRS, 2)
	_hline(img, ox, oy, 4, 11, CAP, 3)  ## cap band visible from back
	## Outline
	_hline(img, ox, oy, 5, 10, OL, 0)
	img.set_pixel(ox + 4, oy + 1, OL)
	img.set_pixel(ox + 11, oy + 1, OL)

	## Back of head (rows 4-6)
	for y in range(4, 7):
		_hline(img, ox, oy, 4, 11, SKN, y)
		img.set_pixel(ox + 3, oy + y, OL)
		img.set_pixel(ox + 12, oy + y, OL)

	## Shirt back
	for y in range(7, 11):
		_hline(img, ox, oy, 4, 11, SHT, y)
		img.set_pixel(ox + 4, oy + y, SHD)
		img.set_pixel(ox + 11, oy + y, SHD)
	for y in range(7, 10):
		img.set_pixel(ox + 3, oy + y, SKN)
		img.set_pixel(ox + 12, oy + y, SKN)
		img.set_pixel(ox + 2, oy + y, OL)
		img.set_pixel(ox + 13, oy + y, OL)
	img.set_pixel(ox + 3, oy + 10, OL)
	img.set_pixel(ox + 12, oy + 10, OL)

	## Pants
	for y in range(11, 14):
		_hline(img, ox, oy, 4, 7, PNT, y)
		_hline(img, ox, oy, 8, 11, PNT, y)
	img.set_pixel(ox + 7, oy + 12, OL)
	img.set_pixel(ox + 8, oy + 12, OL)

	## Shoes
	_hline(img, ox, oy, 3, 7, SHO, 14)
	_hline(img, ox, oy, 8, 12, SHO, 14)
	_hline(img, ox, oy, 3, 7, SHO, 15)
	_hline(img, ox, oy, 8, 12, SHO, 15)

	if step:
		_hline(img, ox, oy, 8, 11, PNT, 14)
		_hline(img, ox, oy, 8, 12, SHO, 15)


## ── Side-facing frame (left or mirrored to right) ──────────────────────────
func _draw_side(img: Image, ox: int, oy: int, right: bool, step: bool) -> void:
	## For right-facing, we draw left then mirror
	var buf := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	buf.fill(Color(0, 0, 0, 0))

	## Cap
	_hline_buf(buf, 4, 10, CAP, 0)
	_hline_buf(buf, 3, 11, CAP, 1)
	buf.set_pixel(7, 1, CPW)
	_hline_buf(buf, 3, 11, CAP, 2)
	_hline_buf(buf, 2, 12, CPD, 3)  ## brim extends forward
	## Outline
	_hline_buf(buf, 4, 10, OL, 0)
	buf.set_pixel(3, 1, OL)
	buf.set_pixel(11, 1, OL)

	## Face (looking left = features on left side)
	for y in range(4, 7):
		_hline_buf(buf, 4, 11, SKN, y)
		buf.set_pixel(3, y, OL)
		buf.set_pixel(11, y, OL)
	## Eye (only one visible)
	buf.set_pixel(5, 5, EYE)
	buf.set_pixel(6, 5, EYE)

	## Shirt
	for y in range(7, 11):
		_hline_buf(buf, 4, 11, SHT, y)
		buf.set_pixel(4, y, SHD)
	## Arm (front)
	for y in range(7, 10):
		buf.set_pixel(3, y, SKN)
		buf.set_pixel(2, y, OL)
	buf.set_pixel(3, 10, OL)
	buf.set_pixel(11, 10, OL)

	## Pants
	for y in range(11, 14):
		_hline_buf(buf, 4, 7, PNT, y)
		_hline_buf(buf, 8, 11, PNT, y)
	buf.set_pixel(7, 12, OL)
	buf.set_pixel(8, 12, OL)

	## Shoes
	_hline_buf(buf, 3, 7, SHO, 14)
	_hline_buf(buf, 8, 12, SHO, 14)
	_hline_buf(buf, 3, 7, SHO, 15)
	_hline_buf(buf, 8, 12, SHO, 15)

	if step:
		_hline_buf(buf, 8, 11, PNT, 14)
		_hline_buf(buf, 8, 12, SHO, 15)

	## Mirror for right-facing
	if right:
		buf.flip_x()

	## Blit to main image
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var c := buf.get_pixel(x, y)
			if c.a > 0.01:
				img.set_pixel(ox + x, oy + y, c)


## ── Helpers ─────────────────────────────────────────────────────────────────
func _hline(img: Image, ox: int, oy: int, x1: int, x2: int, col: Color, row: int = 0) -> void:
	for x in range(x1, x2 + 1):
		img.set_pixel(ox + x, oy + row, col)

func _hline_buf(buf: Image, x1: int, x2: int, col: Color, row: int) -> void:
	for x in range(x1, x2 + 1):
		buf.set_pixel(x, row, col)


func _apply_to_player(tex: ImageTexture) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_do_apply(tex)


## Re-apply the cached texture to the current player — call after every scene change.
func reapply() -> void:
	if _tex != null:
		_do_apply(_tex)


func _do_apply(tex: ImageTexture) -> void:
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
