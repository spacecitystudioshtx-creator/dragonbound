## Loads the player character sprite from ArMM1998 CC0 character.png.
## Extracts the first character's walk cycle into a 32×128 spritesheet
## matching our AnimatedSprite2D atlas layout.
##
## Layout: 2 frames wide × 4 directions tall (16×32 each)
##   Row 0 (y=0):  Down   |  Row 1 (y=32): Up
##   Row 2 (y=64): Left   |  Row 3 (y=96): Right

extends Node

const SPRITE_W := 16
const SPRITE_H := 32

## Source layout in character.png (first character, cols 0-3):
##   Row 0 (y=0):  Down   |  Row 1 (y=32): Left
##   Row 2 (y=64): Right  |  Row 3 (y=96): Up
## We remap to match our animation names.
const SRC_ROW := {
	"down":  0,   ## character.png row 0 → our row 0
	"up":    3,   ## character.png row 3 → our row 1
	"left":  1,   ## character.png row 1 → our row 2
	"right": 2,   ## character.png row 2 → our row 3
}
const DST_ROW := {
	"down":  0,
	"up":    1,
	"left":  2,
	"right": 3,
}

var _tex: ImageTexture = null


func _ready() -> void:
	_generate_player_spritesheet()


func _generate_player_spritesheet() -> void:
	var sheet := Image.create(SPRITE_W * 2, SPRITE_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	var char_img: Image = null
	var char_path := "res://art/tilesets/armm1998/gfx/character.png"

	if ResourceLoader.exists(char_path):
		var char_tex: Texture2D = load(char_path)
		if char_tex:
			char_img = char_tex.get_image()

	if char_img == null:
		char_img = Image.new()
		var abs_path := ProjectSettings.globalize_path(char_path)
		if char_img.load(abs_path) != OK:
			push_warning("PlaceholderSprites: Could not load character.png, using fallback")
			_generate_fallback(sheet)
			_tex = ImageTexture.create_from_image(sheet)
			_apply_to_player(_tex)
			return

	## Extract 2 frames per direction from the first character
	for dir_name in ["down", "up", "left", "right"]:
		var src_row: int = SRC_ROW[dir_name]
		var dst_row: int = DST_ROW[dir_name]
		var src_y := src_row * SPRITE_H
		var dst_y := dst_row * SPRITE_H

		## Frame 0: idle (col 0 in source)
		_blit(char_img, 0, src_y, sheet, 0, dst_y, SPRITE_W, SPRITE_H)
		## Frame 1: walk (col 1 in source)
		_blit(char_img, SPRITE_W, src_y, sheet, SPRITE_W, dst_y, SPRITE_W, SPRITE_H)

	_tex = ImageTexture.create_from_image(sheet)
	_apply_to_player(_tex)


func _blit(src: Image, sx: int, sy: int, dst: Image, dx: int, dy: int, w: int, h: int) -> void:
	for y in h:
		for x in w:
			var px := sx + x
			var py := sy + y
			if px < src.get_width() and py < src.get_height():
				var c := src.get_pixel(px, py)
				if c.a > 0.01:
					dst.set_pixel(dx + x, dy + y, c)


func _generate_fallback(sheet: Image) -> void:
	## Minimal colored rectangles as fallback
	var colors := {
		0: Color(0.82, 0.14, 0.14),  ## down - red
		1: Color(0.14, 0.14, 0.82),  ## up - blue
		2: Color(0.14, 0.82, 0.14),  ## left - green
		3: Color(0.82, 0.82, 0.14),  ## right - yellow
	}
	for row in 4:
		var col: Color = colors[row]
		for frame in 2:
			var ox := frame * SPRITE_W
			var oy := row * SPRITE_H
			for y in range(6, 28):
				for x in range(2, 14):
					sheet.set_pixel(ox + x, oy + y, col)


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
