## Loads the player character sprite from the Ninja Adventure CC0 ninja_blue
## sheet and applies it to the player's AnimatedSprite2D at runtime.
##
## Source layout (64×112, 4 cols × 7 rows at 16×16):
##   Row 0: Down  (4-frame walk cycle across cols 0-3)
##   Row 1: Up
##   Row 2: Left
##   Row 3: Right
##   Rows 4-6: weapon animations (unused)
##
## We copy the top 4 rows into a 64×64 sheet whose layout matches the regions
## defined in scenes/player.tscn. The .tscn's AtlasTextures don't set `atlas`
## at edit time — we poke it here after the scene loads.

extends Node

const SPRITE_W := 16
const SPRITE_H := 16
const FRAMES := 4

const SOURCE_PATH := "res://art/characters/player/player_sheet.png"

## Source-row → destination-row in our baked sheet.
const DIRS := {
	"down":  {"src_row": 0, "dst_row": 0},
	"up":    {"src_row": 1, "dst_row": 1},
	"left":  {"src_row": 2, "dst_row": 2},
	"right": {"src_row": 3, "dst_row": 3},
}

var _tex: ImageTexture = null


func _ready() -> void:
	_generate()
	get_tree().node_added.connect(_on_node_added)


func _generate() -> void:
	var sheet := Image.create(SPRITE_W * FRAMES, SPRITE_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	var src := _load_source()
	if src == null:
		push_warning("placeholder_sprites: source not found, using fallback")
		_fallback(sheet)
	else:
		for dir_name in DIRS.keys():
			var info: Dictionary = DIRS[dir_name]
			var src_y: int = int(info["src_row"]) * SPRITE_H
			var dst_y: int = int(info["dst_row"]) * SPRITE_H
			for f in FRAMES:
				_blit(src, f * SPRITE_W, src_y, sheet, f * SPRITE_W, dst_y, SPRITE_W, SPRITE_H)

	_tex = ImageTexture.create_from_image(sheet)
	_apply_deferred()


func _load_source() -> Image:
	if ResourceLoader.exists(SOURCE_PATH):
		var tex: Texture2D = load(SOURCE_PATH)
		if tex:
			return tex.get_image()
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(SOURCE_PATH)) == OK:
		return img
	return null


func _blit(src: Image, sx: int, sy: int, dst: Image, dx: int, dy: int, w: int, h: int) -> void:
	for y in h:
		for x in w:
			var px := sx + x
			var py := sy + y
			if px < src.get_width() and py < src.get_height():
				var c := src.get_pixel(px, py)
				if c.a > 0.01:
					dst.set_pixel(dx + x, dy + y, c)


func _fallback(sheet: Image) -> void:
	var colors := [
		Color(0.82, 0.14, 0.14), Color(0.14, 0.14, 0.82),
		Color(0.14, 0.82, 0.14), Color(0.82, 0.82, 0.14),
	]
	for row in 4:
		for frame in FRAMES:
			var ox := frame * SPRITE_W
			var oy := row * SPRITE_H
			for y in range(3, 13):
				for x in range(3, 13):
					sheet.set_pixel(ox + x, oy + y, colors[row])


func _apply_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_to_player()


func _on_node_added(node: Node) -> void:
	## Scene transitions swap in a fresh player — re-apply the texture.
	if node.is_in_group("player"):
		call_deferred("_apply_to_player")


func _apply_to_player() -> void:
	if _tex == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	var frames := sprite.sprite_frames
	if frames == null:
		return
	for anim_name in frames.get_animation_names():
		for i in frames.get_frame_count(anim_name):
			var atlas: AtlasTexture = frames.get_frame_texture(anim_name, i)
			if atlas:
				atlas.atlas = _tex


func reapply() -> void:
	_apply_to_player()
