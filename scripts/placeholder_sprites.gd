## Generates a placeholder trainer sprite at runtime.
## 16×32 FireRed-proportioned character — chibi style with head = top half.
##
## Spritesheet: 32×128 (2 frames wide × 4 directions tall, 16×32 each)
##   Row 0: Down  |  Row 1: Up  |  Row 2: Left  |  Row 3: Right

extends Node

const SW := 16
const SH := 32

var _tex: ImageTexture = null

## ── Palette ─────────────────────────────────────────────────────────────────
const OL  := Color(0.04, 0.04, 0.06)   ## Outline
const CAP := Color(0.82, 0.14, 0.14)   ## Red cap
const CPD := Color(0.60, 0.10, 0.08)   ## Cap shadow
const CPW := Color(0.95, 0.95, 0.90)   ## Cap white stripe
const SKN := Color(0.96, 0.78, 0.58)   ## Skin
const SKD := Color(0.80, 0.62, 0.42)   ## Skin shadow
const EYE := Color(0.06, 0.06, 0.18)   ## Eye
const EYW := Color(1.00, 1.00, 1.00)   ## Eye white
const HRS := Color(0.20, 0.12, 0.06)   ## Hair
const SHT := Color(0.14, 0.34, 0.80)   ## Shirt blue
const SHD := Color(0.10, 0.24, 0.58)   ## Shirt shadow
const BLT := Color(0.22, 0.20, 0.18)   ## Belt
const PNT := Color(0.30, 0.28, 0.40)   ## Pants
const PND := Color(0.20, 0.18, 0.28)   ## Pants shadow
const SHO := Color(0.14, 0.10, 0.06)   ## Shoes
const SHL := Color(0.24, 0.18, 0.12)   ## Shoe highlight


func _ready() -> void:
	_generate_player_spritesheet()


func _generate_player_spritesheet() -> void:
	var img := Image.create(32, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_draw_down(img, 0, 0, false)
	_draw_down(img, 16, 0, true)
	_draw_up(img, 0, 32, false)
	_draw_up(img, 16, 32, true)
	_draw_side(img, 0, 64, false, false)   ## Left idle
	_draw_side(img, 16, 64, false, true)   ## Left walk
	_draw_side(img, 0, 96, true, false)    ## Right idle
	_draw_side(img, 16, 96, true, true)    ## Right walk

	_tex = ImageTexture.create_from_image(img)
	_apply_to_player(_tex)


## ── Down-facing ─────────────────────────────────────────────────────────────
func _draw_down(img: Image, ox: int, oy: int, step: bool) -> void:
	## ─ HEAD (rows 0-15) ─
	## Hair top
	_hline(img, ox, oy, 5, 10, HRS, 0)
	_hline(img, ox, oy, 4, 11, HRS, 1)

	## Cap
	_hline(img, ox, oy, 4, 11, CAP, 2)
	_hline(img, ox, oy, 3, 12, CAP, 3)
	_hline(img, ox, oy, 3, 12, CAP, 4)
	_px(img, ox + 7, oy + 3, CPW)
	_px(img, ox + 8, oy + 3, CPW)
	_hline(img, ox, oy, 2, 13, CPD, 5)  ## brim

	## Cap outline
	_px(img, ox + 5, oy + 0, OL); _px(img, ox + 10, oy + 0, OL)
	_px(img, ox + 4, oy + 1, OL); _px(img, ox + 11, oy + 1, OL)
	_px(img, ox + 3, oy + 2, OL); _px(img, ox + 12, oy + 2, OL)
	_px(img, ox + 2, oy + 3, OL); _px(img, ox + 13, oy + 3, OL)
	_px(img, ox + 1, oy + 5, OL); _px(img, ox + 14, oy + 5, OL)

	## Face
	for y in range(6, 12):
		_hline(img, ox, oy, 3, 12, SKN, y)
	## Hair sides (sideburns)
	for y in range(6, 9):
		_px(img, ox + 3, oy + y, HRS)
		_px(img, ox + 12, oy + y, HRS)

	## Eyes
	_px(img, ox + 5, oy + 8, EYW); _px(img, ox + 6, oy + 8, EYE)
	_px(img, ox + 5, oy + 9, EYW); _px(img, ox + 6, oy + 9, EYE)
	_px(img, ox + 9, oy + 8, EYE); _px(img, ox + 10, oy + 8, EYW)
	_px(img, ox + 9, oy + 9, EYE); _px(img, ox + 10, oy + 9, EYW)

	## Mouth
	_px(img, ox + 7, oy + 10, SKD)
	_px(img, ox + 8, oy + 10, SKD)

	## Chin
	_hline(img, ox, oy, 4, 11, SKN, 12)
	_hline(img, ox, oy, 5, 10, SKD, 13)

	## Face outline
	for y in range(6, 13):
		_px(img, ox + 2, oy + y, OL)
		_px(img, ox + 13, oy + y, OL)
	_hline(img, ox, oy, 3, 12, OL, 13)

	## ─ BODY (rows 14-31) ─
	## Neck
	_hline(img, ox, oy, 6, 9, SKN, 14)

	## Shirt
	for y in range(15, 22):
		_hline(img, ox, oy, 4, 11, SHT, y)
	## Shirt shadow
	for y in range(15, 22):
		_px(img, ox + 4, oy + y, SHD)
		_px(img, ox + 11, oy + y, SHD)
	## Shirt collar
	_px(img, ox + 6, oy + 15, SHD)
	_px(img, ox + 9, oy + 15, SHD)
	## Shirt outline
	for y in range(15, 22):
		_px(img, ox + 3, oy + y, OL)
		_px(img, ox + 12, oy + y, OL)

	## Arms
	for y in range(16, 21):
		_px(img, ox + 3, oy + y, SKN)
		_px(img, ox + 2, oy + y, SKN)
		_px(img, ox + 1, oy + y, OL)
		_px(img, ox + 12, oy + y, SKN)
		_px(img, ox + 13, oy + y, SKN)
		_px(img, ox + 14, oy + y, OL)
	## Hands
	_px(img, ox + 2, oy + 21, SKD)
	_px(img, ox + 13, oy + 21, SKD)

	## Belt
	_hline(img, ox, oy, 4, 11, BLT, 22)

	## Pants
	for y in range(23, 28):
		_hline(img, ox, oy, 4, 7, PNT, y)
		_hline(img, ox, oy, 8, 11, PNT, y)
	## Leg gap
	_px(img, ox + 7, oy + 25, OL)
	_px(img, ox + 8, oy + 25, OL)
	_px(img, ox + 7, oy + 26, OL)
	_px(img, ox + 8, oy + 26, OL)
	## Pants shadow
	for y in range(23, 28):
		_px(img, ox + 4, oy + y, PND)
		_px(img, ox + 11, oy + y, PND)
	## Pants outline
	for y in range(23, 28):
		_px(img, ox + 3, oy + y, OL)
		_px(img, ox + 12, oy + y, OL)

	## Shoes
	_hline(img, ox, oy, 3, 7, SHO, 28)
	_hline(img, ox, oy, 8, 12, SHO, 28)
	_hline(img, ox, oy, 2, 7, SHO, 29)
	_hline(img, ox, oy, 8, 13, SHO, 29)
	_hline(img, ox, oy, 2, 7, SHL, 30)
	_hline(img, ox, oy, 8, 13, SHL, 30)
	## Shoe outline
	_hline(img, ox, oy, 2, 7, OL, 31)
	_hline(img, ox, oy, 8, 13, OL, 31)

	## Walk frame: shift right leg forward
	if step:
		for y in range(27, 30):
			_hline(img, ox, oy, 8, 11, PNT, y)
		_hline(img, ox, oy, 8, 12, SHO, 30)
		_hline(img, ox, oy, 8, 13, SHL, 31)
		_px(img, ox + 7, oy + 28, Color(0, 0, 0, 0))


## ── Up-facing ───────────────────────────────────────────────────────────────
func _draw_up(img: Image, ox: int, oy: int, step: bool) -> void:
	## Hair back
	_hline(img, ox, oy, 5, 10, HRS, 0)
	_hline(img, ox, oy, 4, 11, HRS, 1)
	_hline(img, ox, oy, 3, 12, HRS, 2)
	_hline(img, ox, oy, 3, 12, HRS, 3)
	_hline(img, ox, oy, 3, 12, HRS, 4)
	_hline(img, ox, oy, 2, 13, CAP, 5)  ## cap band
	## Outline
	_px(img, ox + 5, oy + 0, OL); _px(img, ox + 10, oy + 0, OL)
	_px(img, ox + 4, oy + 1, OL); _px(img, ox + 11, oy + 1, OL)
	_px(img, ox + 3, oy + 2, OL); _px(img, ox + 12, oy + 2, OL)
	_px(img, ox + 1, oy + 5, OL); _px(img, ox + 14, oy + 5, OL)

	## Back of head
	for y in range(6, 12):
		_hline(img, ox, oy, 3, 12, HRS, y)
	## Neck/skin at bottom of head
	_hline(img, ox, oy, 4, 11, SKN, 12)
	## Outline
	for y in range(6, 13):
		_px(img, ox + 2, oy + y, OL)
		_px(img, ox + 13, oy + y, OL)
	_hline(img, ox, oy, 3, 12, OL, 13)

	## Neck
	_hline(img, ox, oy, 6, 9, SKN, 14)

	## Shirt back
	for y in range(15, 22):
		_hline(img, ox, oy, 4, 11, SHT, y)
		_px(img, ox + 4, oy + y, SHD)
		_px(img, ox + 11, oy + y, SHD)
		_px(img, ox + 3, oy + y, OL)
		_px(img, ox + 12, oy + y, OL)
	## Arms
	for y in range(16, 21):
		_px(img, ox + 3, oy + y, SKN)
		_px(img, ox + 2, oy + y, SKN)
		_px(img, ox + 1, oy + y, OL)
		_px(img, ox + 12, oy + y, SKN)
		_px(img, ox + 13, oy + y, SKN)
		_px(img, ox + 14, oy + y, OL)

	## Belt
	_hline(img, ox, oy, 4, 11, BLT, 22)

	## Pants
	for y in range(23, 28):
		_hline(img, ox, oy, 4, 7, PNT, y)
		_hline(img, ox, oy, 8, 11, PNT, y)
		_px(img, ox + 3, oy + y, OL)
		_px(img, ox + 12, oy + y, OL)
	_px(img, ox + 7, oy + 25, OL)
	_px(img, ox + 8, oy + 25, OL)

	## Shoes
	_hline(img, ox, oy, 2, 7, SHO, 28)
	_hline(img, ox, oy, 8, 13, SHO, 28)
	_hline(img, ox, oy, 2, 7, SHO, 29)
	_hline(img, ox, oy, 8, 13, SHO, 29)
	_hline(img, ox, oy, 2, 7, SHL, 30)
	_hline(img, ox, oy, 8, 13, SHL, 30)
	_hline(img, ox, oy, 2, 7, OL, 31)
	_hline(img, ox, oy, 8, 13, OL, 31)

	if step:
		for y in range(27, 30):
			_hline(img, ox, oy, 8, 11, PNT, y)
		_hline(img, ox, oy, 8, 12, SHO, 30)
		_hline(img, ox, oy, 8, 13, SHL, 31)


## ── Side-facing ─────────────────────────────────────────────────────────────
func _draw_side(img: Image, ox: int, oy: int, right: bool, step: bool) -> void:
	var buf := Image.create(SW, SH, false, Image.FORMAT_RGBA8)
	buf.fill(Color(0, 0, 0, 0))

	## Hair
	_hline_b(buf, 5, 10, HRS, 0)
	_hline_b(buf, 4, 11, HRS, 1)

	## Cap
	_hline_b(buf, 3, 11, CAP, 2)
	_hline_b(buf, 3, 12, CAP, 3)
	_hline_b(buf, 3, 12, CAP, 4)
	_bp(buf, 7, 3, CPW)
	_hline_b(buf, 2, 13, CPD, 5)  ## brim extends forward
	## Cap outline
	_bp(buf, 5, 0, OL); _bp(buf, 10, 0, OL)
	_bp(buf, 4, 1, OL); _bp(buf, 11, 1, OL)
	_bp(buf, 2, 2, OL); _bp(buf, 12, 2, OL)
	_bp(buf, 1, 5, OL); _bp(buf, 14, 5, OL)

	## Face side
	for y in range(6, 12):
		_hline_b(buf, 3, 12, SKN, y)
		_bp(buf, 2, y, OL)
		_bp(buf, 12, y, OL)
	## Sideburn
	for y in range(6, 9):
		_bp(buf, 12, y, HRS)
	## Eye (one visible)
	_bp(buf, 5, 8, EYW); _bp(buf, 6, 8, EYE)
	_bp(buf, 5, 9, EYW); _bp(buf, 6, 9, EYE)
	## Chin
	_hline_b(buf, 4, 11, SKN, 12)
	_hline_b(buf, 3, 12, OL, 13)

	## Neck
	_hline_b(buf, 6, 9, SKN, 14)

	## Shirt
	for y in range(15, 22):
		_hline_b(buf, 4, 11, SHT, y)
		_bp(buf, 4, y, SHD)
		_bp(buf, 3, y, OL)
		_bp(buf, 12, y, OL)
	## Arm (front, extends past body)
	for y in range(16, 21):
		_bp(buf, 3, y, SKN)
		_bp(buf, 2, y, SKN)
		_bp(buf, 1, y, OL)

	## Belt
	_hline_b(buf, 4, 11, BLT, 22)

	## Pants
	for y in range(23, 28):
		_hline_b(buf, 4, 7, PNT, y)
		_hline_b(buf, 8, 11, PNT, y)
		_bp(buf, 3, y, OL)
		_bp(buf, 12, y, OL)
	_bp(buf, 7, 25, OL)
	_bp(buf, 8, 25, OL)

	## Shoes
	_hline_b(buf, 2, 7, SHO, 28)
	_hline_b(buf, 8, 13, SHO, 28)
	_hline_b(buf, 2, 7, SHO, 29)
	_hline_b(buf, 8, 13, SHO, 29)
	_hline_b(buf, 2, 7, SHL, 30)
	_hline_b(buf, 8, 13, SHL, 30)
	_hline_b(buf, 2, 7, OL, 31)
	_hline_b(buf, 8, 13, OL, 31)

	if step:
		for y in range(27, 30):
			_hline_b(buf, 8, 11, PNT, y)
		_hline_b(buf, 8, 12, SHO, 30)
		_hline_b(buf, 8, 13, SHL, 31)

	if right:
		buf.flip_x()

	## Blit to main image
	for y in SH:
		for x in SW:
			var c := buf.get_pixel(x, y)
			if c.a > 0.01:
				img.set_pixel(ox + x, oy + y, c)


## ── Helpers ─────────────────────────────────────────────────────────────────
func _hline(img: Image, ox: int, oy: int, x1: int, x2: int, col: Color, row: int) -> void:
	for x in range(x1, x2 + 1):
		img.set_pixel(ox + x, oy + row, col)

func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

func _hline_b(buf: Image, x1: int, x2: int, col: Color, row: int) -> void:
	for x in range(x1, x2 + 1):
		if x >= 0 and x < SW and row >= 0 and row < SH:
			buf.set_pixel(x, row, col)

func _bp(buf: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < SW and y >= 0 and y < SH:
		buf.set_pixel(x, y, col)


func _apply_to_player(tex: ImageTexture) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_do_apply(tex)


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
