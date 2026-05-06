## Builds an original crisp 16x16 TileSet with classic GBA route readability.
##
## Source 0 is a compact ground strip matching MapTiles constants.
## Source 1 is a 20x12 prop atlas laid out to match the existing stamps.
##
## Solid tiles receive a 16×16 collision polygon on physics layer 1 (mask 2).

extends Node

const TILE_SIZE := 16

const STRIP_COUNT := 16
const INTERIOR_COUNT := 16
const KINDRA_SCREEN_PATH := "res://art/generated/backgrounds/kindra_town_style_benchmark_v2_flux2_live.png"
const ROOM_SCREEN_PATHS := {
	5: "res://art/generated/backgrounds/kindra_home_interior_live.png",
	6: "res://art/generated/backgrounds/kindra_shop_interior_live.png",
	7: "res://art/generated/backgrounds/kindra_house_interior_live.png",
	8: "res://art/generated/backgrounds/kindra_pyre_interior_live.png",
	9: "res://art/generated/backgrounds/kindra_elder_interior_live.png",
	10: "res://art/generated/backgrounds/kindra_east_exit_live.png",
	11: "res://art/generated/backgrounds/dustway_entry_live.png",
}

## Tiles in the strip that block movement.
const STRIP_SOLID := [2, 10, 11, 12, 13, 14, 15]

## Tiles in the village atlas (source 1) that block movement, as Vector2i.
## Any tile not listed is walkable. Used for props placed via stamp().
const VILLAGE_SOLID_COORDS := [
	## Small bushy tree (2x2 at cols 4-5 rows 6-7; (5,7) trunk base is walkable)
	Vector2i(4, 6), Vector2i(5, 6), Vector2i(4, 7),
	## Big tree trunk (2x3 at cols 0-1 rows 6-8)
	Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 7), Vector2i(0, 8),
	## Small house 3x3 (cols 10-12 rows 0-2)
	Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0),
	Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1),
	Vector2i(10, 2),                  Vector2i(12, 2),   ## 11,2 is door → walkable
	## Big house 4x6 (cols 13-16 rows 6-11)
	Vector2i(13,  6), Vector2i(14,  6), Vector2i(15,  6), Vector2i(16,  6),
	Vector2i(13,  7), Vector2i(14,  7), Vector2i(15,  7), Vector2i(16,  7),
	Vector2i(13,  8), Vector2i(14,  8), Vector2i(15,  8), Vector2i(16,  8),
	Vector2i(13,  9), Vector2i(14,  9), Vector2i(15,  9), Vector2i(16,  9),
	Vector2i(13, 10), Vector2i(14, 10), Vector2i(15, 10), Vector2i(16, 10),
	Vector2i(13, 11),                   Vector2i(15, 11), Vector2i(16, 11),
	## Stump, rock, grave
	Vector2i(4, 4), Vector2i(5, 4),
	Vector2i(6, 0), Vector2i(7, 0), Vector2i(6, 1), Vector2i(7, 1),
]


static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 2)

	## ── Source 0: 16-tile ground strip ───────────────────────────────────────
	var strip_img := _make_ground_strip()

	var strip_tex := ImageTexture.create_from_image(strip_img)
	var strip_src := TileSetAtlasSource.new()
	strip_src.texture = strip_tex
	strip_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in STRIP_COUNT:
		strip_src.create_tile(Vector2i(i, 0))
	tileset.add_source(strip_src, 0)
	var poly := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	for i in STRIP_SOLID:
		var td := strip_src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, poly)

	## ── Source 1: original prop atlas ────────────────────────────────────────
	var village_img := _make_prop_atlas()
	var village_tex := ImageTexture.create_from_image(village_img)
	var vsrc := TileSetAtlasSource.new()
	vsrc.texture = village_tex
	vsrc.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var vcols := village_img.get_width() / TILE_SIZE
	var vrows := village_img.get_height() / TILE_SIZE
	for c in vcols:
		for r in vrows:
			vsrc.create_tile(Vector2i(c, r))
	tileset.add_source(vsrc, 1)
	for coord in VILLAGE_SOLID_COORDS:
		if coord.x < vcols and coord.y < vrows:
			var td := vsrc.get_tile_data(coord, 0)
			if td != null:
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, poly)

	## ── Source 2: generated Kindra starter-screen atlas ─────────────────────
	var kindra_tex := _load_texture(KINDRA_SCREEN_PATH)
	if kindra_tex != null:
		var ksrc := TileSetAtlasSource.new()
		ksrc.texture = kindra_tex
		ksrc.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		for c in int(kindra_tex.get_width() / TILE_SIZE):
			for r in int(kindra_tex.get_height() / TILE_SIZE):
				ksrc.create_tile(Vector2i(c, r))
		tileset.add_source(ksrc, 2)

	## ── Source 3: invisible collision-only tile ─────────────────────────────
	var collision_img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	collision_img.fill(Color(0, 0, 0, 0))
	var collision_src := TileSetAtlasSource.new()
	collision_src.texture = ImageTexture.create_from_image(collision_img)
	collision_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	collision_src.create_tile(Vector2i.ZERO)
	tileset.add_source(collision_src, 3)
	var collision_td := collision_src.get_tile_data(Vector2i.ZERO, 0)
	collision_td.add_collision_polygon(0)
	collision_td.set_collision_polygon_points(0, 0, poly)

	## ── Source 4: original GBA-style interior atlas ────────────────────────
	var interior_img := _make_interior_atlas()
	var interior_src := TileSetAtlasSource.new()
	interior_src.texture = ImageTexture.create_from_image(interior_img)
	interior_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in INTERIOR_COUNT:
		interior_src.create_tile(Vector2i(i, 0))
	tileset.add_source(interior_src, 4)
	for i in [2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14]:
		var td := interior_src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, poly)

	## ── Sources 5-11: generated full-screen room/route backgrounds ─────────
	for source_id in ROOM_SCREEN_PATHS.keys():
		var room_tex := _load_texture(ROOM_SCREEN_PATHS[source_id])
		if room_tex == null:
			continue
		var room_src := TileSetAtlasSource.new()
		room_src.texture = room_tex
		room_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		for c in int(room_tex.get_width() / TILE_SIZE):
			for r in int(room_tex.get_height() / TILE_SIZE):
				room_src.create_tile(Vector2i(c, r))
		tileset.add_source(room_src, source_id)

	return tileset


static func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex:
			return tex
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(path)) == OK:
		return ImageTexture.create_from_image(img)
	return null


static func _make_ground_strip() -> Image:
	var img := Image.create(TILE_SIZE * STRIP_COUNT, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in STRIP_COUNT:
		_draw_ground_tile(img, i * TILE_SIZE, i)
	return img


static func _draw_ground_tile(img: Image, ox: int, tile_id: int) -> void:
	match tile_id:
		0:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_grass_specks(img, ox, Color(0.26, 0.58, 0.38), Color(0.70, 0.90, 0.66))
		1:
			_fill_tile(img, ox, Color(0.55, 0.80, 0.56))
			_grass_specks(img, ox, Color(0.30, 0.62, 0.42), Color(0.76, 0.94, 0.70))
		2:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_draw_bush(img, ox, 0)
		3:
			_fill_tile(img, ox, Color(0.91, 0.80, 0.52))
			_sandy_path(img, ox)
		4:
			_fill_tile(img, ox, Color(0.80, 0.64, 0.42))
			_pebbles(img, ox, Color(0.58, 0.44, 0.30), Color(0.92, 0.76, 0.52))
		5:
			_fill_tile(img, ox, Color(0.86, 0.76, 0.50))
			_pebbles(img, ox, Color(0.72, 0.62, 0.38), Color(0.98, 0.88, 0.58))
		6:
			_fill_tile(img, ox, Color(0.78, 0.68, 0.44))
			_pebbles(img, ox, Color(0.62, 0.52, 0.34), Color(0.92, 0.82, 0.54))
		7:
			_fill_tile(img, ox, Color(0.82, 0.90, 0.90))
			_pebbles(img, ox, Color(0.68, 0.78, 0.82), Color(0.95, 0.98, 0.96))
		8:
			_fill_tile(img, ox, Color(0.42, 0.68, 0.34))
			for x in [1, 4, 7, 10, 13]:
				_line(img, ox + x, 14, ox + x + 1, 4, Color(0.14, 0.42, 0.22))
				_line(img, ox + x + 1, 14, ox + x + 2, 6, Color(0.72, 0.92, 0.48))
		9:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_grass_specks(img, ox, Color(0.26, 0.58, 0.38), Color(0.70, 0.90, 0.66))
			_flower(img, ox + 5, 7, Color(0.95, 0.42, 0.58))
			_flower(img, ox + 11, 10, Color(0.96, 0.88, 0.32))
		10:
			_fill_tile(img, ox, Color(0.34, 0.66, 0.86))
			_line(img, ox + 1, 5, ox + 14, 4, Color(0.68, 0.90, 0.96))
			_line(img, ox + 0, 11, ox + 12, 10, Color(0.20, 0.52, 0.76))
		11:
			_fill_tile(img, ox, Color(0.28, 0.58, 0.80))
			_line(img, ox + 2, 4, ox + 15, 3, Color(0.58, 0.84, 0.92))
			_line(img, ox + 1, 12, ox + 13, 11, Color(0.16, 0.44, 0.68))
		12:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_draw_picket_fence(img, ox)
		13:
			_fill_tile(img, ox, Color(0.53, 0.78, 0.36))
			_rect(img, ox + 7, 8, ox + 8, 15, Color(0.36, 0.20, 0.10))
			_rect(img, ox + 3, 3, ox + 12, 9, Color(0.80, 0.58, 0.30))
			_rect(img, ox + 4, 4, ox + 11, 8, Color(0.95, 0.80, 0.46))
			_rect(img, ox + 3, 3, ox + 12, 3, Color(0.22, 0.12, 0.08))
		14:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_rect(img, ox + 5, 6, ox + 11, 13, Color(0.42, 0.24, 0.12))
			_rect(img, ox + 4, 5, ox + 12, 7, Color(0.64, 0.42, 0.20))
			_rect(img, ox + 6, 5, ox + 10, 6, Color(0.86, 0.64, 0.32))
		15:
			_fill_tile(img, ox, Color(0.49, 0.76, 0.52))
			_rect(img, ox + 4, 7, ox + 12, 12, Color(0.42, 0.44, 0.44))
			_rect(img, ox + 6, 5, ox + 10, 8, Color(0.62, 0.64, 0.62))
			_rect(img, ox + 5, 12, ox + 11, 13, Color(0.24, 0.28, 0.26))


static func _make_prop_atlas() -> Image:
	var img := Image.create(20 * TILE_SIZE, 12 * TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for c in 20:
		for r in 12:
			_draw_transparent_base(img, c * TILE_SIZE)

	## Tree stamps.
	_draw_tree_tile(img, 4, 6, "tl")
	_draw_tree_tile(img, 5, 6, "tr")
	_draw_tree_tile(img, 4, 7, "bl")
	_draw_tree_tile(img, 5, 7, "br")
	_draw_big_tree_tile(img, 0, 6, "tl")
	_draw_big_tree_tile(img, 1, 6, "tr")
	_draw_big_tree_tile(img, 0, 7, "ml")
	_draw_big_tree_tile(img, 1, 7, "mr")
	_draw_big_tree_tile(img, 0, 8, "bl")
	_draw_big_tree_tile(img, 1, 8, "br")

	## Houses at existing coordinates.
	for c in range(10, 13):
		for r in range(0, 3):
			_draw_small_house_tile(img, c, r)
	for c in range(13, 17):
		for r in range(6, 12):
			_draw_big_house_tile(img, c, r)

	_draw_stump_at(img, 4, 4)
	_draw_stump_at(img, 5, 4)
	_draw_rock_at(img, 6, 0)
	_draw_rock_at(img, 7, 0)
	_draw_rock_at(img, 6, 1)
	_draw_rock_at(img, 7, 1)
	return img


static func _make_interior_atlas() -> Image:
	var img := Image.create(TILE_SIZE * INTERIOR_COUNT, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in INTERIOR_COUNT:
		_draw_interior_tile(img, i * TILE_SIZE, i)
	return img


static func _draw_interior_tile(img: Image, ox: int, tile_id: int) -> void:
	var floor := Color(0.86, 0.70, 0.46)
	var floor_lit := Color(0.96, 0.82, 0.56)
	var wall := Color(0.72, 0.56, 0.40)
	var wall_lit := Color(0.92, 0.78, 0.56)
	var line := Color(0.42, 0.30, 0.22)
	match tile_id:
		0:
			_fill_tile(img, ox, floor)
			_rect(img, ox, 15, ox + 15, 15, Color(0.70, 0.54, 0.36))
			_pixel(img, ox + 4, 6, floor_lit)
			_pixel(img, ox + 11, 10, Color(0.68, 0.50, 0.34))
		1:
			_fill_tile(img, ox, Color(0.90, 0.74, 0.50))
			_rect(img, ox, 15, ox + 15, 15, Color(0.72, 0.56, 0.38))
			_pixel(img, ox + 7, 5, floor_lit)
			_pixel(img, ox + 12, 12, Color(0.68, 0.50, 0.34))
		2:
			_fill_tile(img, ox, wall_lit)
			_rect(img, ox, 0, ox + 15, 2, Color(0.56, 0.42, 0.32))
			_rect(img, ox, 13, ox + 15, 15, line)
			_rect(img, ox + 2, 4, ox + 13, 5, Color(0.98, 0.88, 0.66))
		3:
			_fill_tile(img, ox, wall)
			_rect(img, ox, 0, ox + 15, 1, Color(0.96, 0.82, 0.58))
			_rect(img, ox, 14, ox + 15, 15, line)
			_rect(img, ox + 1, 6, ox + 14, 7, Color(0.62, 0.46, 0.34))
		4:
			_fill_tile(img, ox, wall)
			_rect(img, ox, 0, ox + 2, 15, line)
			_rect(img, ox + 13, 0, ox + 15, 15, line)
			_rect(img, ox + 4, 4, ox + 11, 11, wall_lit)
		5:
			_fill_tile(img, ox, Color(0.66, 0.24, 0.26))
			_rect(img, ox, 0, ox + 15, 1, Color(0.90, 0.72, 0.38))
			_rect(img, ox, 14, ox + 15, 15, Color(0.90, 0.72, 0.38))
			_rect(img, ox + 2, 3, ox + 13, 12, Color(0.78, 0.32, 0.32))
		6:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 2, 5, ox + 13, 12, Color(0.34, 0.20, 0.12))
			_rect(img, ox + 3, 4, ox + 12, 10, Color(0.72, 0.44, 0.22))
			_rect(img, ox + 4, 5, ox + 11, 6, Color(0.92, 0.66, 0.36))
			_rect(img, ox + 3, 12, ox + 4, 15, Color(0.28, 0.16, 0.10))
			_rect(img, ox + 11, 12, ox + 12, 15, Color(0.28, 0.16, 0.10))
		7:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 5, 4, ox + 10, 9, Color(0.34, 0.20, 0.12))
			_rect(img, ox + 6, 5, ox + 9, 8, Color(0.78, 0.48, 0.26))
			_rect(img, ox + 4, 10, ox + 11, 12, Color(0.46, 0.26, 0.14))
			_rect(img, ox + 5, 13, ox + 6, 15, Color(0.26, 0.14, 0.08))
			_rect(img, ox + 9, 13, ox + 10, 15, Color(0.26, 0.14, 0.08))
		8:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox, 5, ox + 15, 15, Color(0.36, 0.24, 0.18))
			_rect(img, ox, 3, ox + 15, 8, Color(0.76, 0.54, 0.34))
			_rect(img, ox, 3, ox + 15, 4, Color(0.96, 0.76, 0.46))
			_rect(img, ox + 3, 9, ox + 12, 11, Color(0.54, 0.36, 0.24))
		9:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 2, 2, ox + 13, 15, Color(0.34, 0.22, 0.14))
			_rect(img, ox + 3, 3, ox + 12, 14, Color(0.62, 0.42, 0.24))
			_rect(img, ox + 3, 6, ox + 12, 7, Color(0.26, 0.16, 0.10))
			_rect(img, ox + 3, 11, ox + 12, 12, Color(0.26, 0.16, 0.10))
			_rect(img, ox + 5, 4, ox + 6, 5, Color(0.84, 0.70, 0.38))
			_rect(img, ox + 9, 9, ox + 11, 10, Color(0.40, 0.62, 0.80))
		10:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 6, 8, ox + 9, 14, Color(0.44, 0.24, 0.12))
			_rect(img, ox + 4, 13, ox + 11, 15, Color(0.54, 0.28, 0.16))
			_rect(img, ox + 3, 3, ox + 12, 9, Color(0.08, 0.34, 0.18))
			_rect(img, ox + 5, 1, ox + 10, 6, Color(0.22, 0.60, 0.28))
			_rect(img, ox + 7, 2, ox + 13, 5, Color(0.46, 0.78, 0.34))
		11:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 1, 3, ox + 14, 15, Color(0.28, 0.18, 0.12))
			_rect(img, ox + 2, 4, ox + 13, 14, Color(0.76, 0.30, 0.32))
			_rect(img, ox + 3, 5, ox + 12, 8, Color(0.96, 0.88, 0.66))
			_rect(img, ox + 3, 10, ox + 12, 13, Color(0.88, 0.42, 0.42))
		12:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 3, 4, ox + 12, 12, Color(0.22, 0.24, 0.30))
			_rect(img, ox + 4, 5, ox + 11, 10, Color(0.48, 0.78, 0.88))
			_rect(img, ox + 6, 13, ox + 9, 15, Color(0.28, 0.28, 0.34))
		13:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			_rect(img, ox + 2, 4, ox + 13, 11, Color(0.18, 0.20, 0.24))
			_rect(img, ox + 4, 5, ox + 11, 9, Color(0.52, 0.76, 0.84))
			_rect(img, ox + 7, 12, ox + 8, 15, Color(0.28, 0.18, 0.12))
			_rect(img, ox + 4, 15, ox + 11, 15, Color(0.38, 0.22, 0.12))
		14:
			_fill_tile(img, ox, Color(0, 0, 0, 0))
			for yy in range(2, 15, 3):
				_rect(img, ox + 3, yy, ox + 13, yy + 1, Color(0.62, 0.42, 0.26))
			_rect(img, ox + 2, 1, ox + 4, 15, Color(0.32, 0.20, 0.12))
			_rect(img, ox + 12, 1, ox + 14, 15, Color(0.32, 0.20, 0.12))
		15:
			_fill_tile(img, ox, Color(0.64, 0.34, 0.26))
			_rect(img, ox, 0, ox + 15, 1, Color(0.92, 0.68, 0.42))
			_rect(img, ox, 14, ox + 15, 15, Color(0.42, 0.20, 0.16))


static func _draw_transparent_base(_img: Image, _ox: int) -> void:
	pass


static func _draw_tree_tile(img: Image, c: int, r: int, part: String) -> void:
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	var outline := Color(0.04, 0.20, 0.12)
	var dark := Color(0.08, 0.34, 0.18)
	var mid := Color(0.16, 0.54, 0.24)
	var light := Color(0.42, 0.78, 0.32)
	if part == "tl":
		_rect_abs(img, ox + 3, oy + 3, ox + 15, oy + 15, outline)
		_rect_abs(img, ox + 4, oy + 4, ox + 15, oy + 15, dark)
		_rect_abs(img, ox + 6, oy + 2, ox + 15, oy + 12, mid)
		_rect_abs(img, ox + 10, oy + 4, ox + 15, oy + 7, light)
	elif part == "tr":
		_rect_abs(img, ox + 0, oy + 3, ox + 12, oy + 15, outline)
		_rect_abs(img, ox + 0, oy + 4, ox + 11, oy + 15, dark)
		_rect_abs(img, ox + 0, oy + 2, ox + 9, oy + 12, mid)
		_rect_abs(img, ox + 1, oy + 4, ox + 5, oy + 7, light)
	elif part == "bl":
		_rect_abs(img, ox + 4, oy + 0, ox + 15, oy + 8, outline)
		_rect_abs(img, ox + 5, oy + 0, ox + 15, oy + 7, dark)
		_rect_abs(img, ox + 7, oy + 0, ox + 15, oy + 4, mid)
		_rect_abs(img, ox + 11, oy + 0, ox + 14, oy + 2, light)
	else:
		_rect_abs(img, ox + 0, oy + 0, ox + 11, oy + 8, outline)
		_rect_abs(img, ox + 0, oy + 0, ox + 10, oy + 7, dark)
		_rect_abs(img, ox + 0, oy + 0, ox + 8, oy + 4, mid)
		_rect_abs(img, ox + 7, oy + 6, ox + 10, oy + 15, Color(0.42, 0.24, 0.12))
		_rect_abs(img, ox + 8, oy + 6, ox + 9, oy + 15, Color(0.66, 0.42, 0.20))


static func _draw_big_tree_tile(img: Image, c: int, r: int, part: String) -> void:
	_draw_tree_tile(img, c, r, part.replace("m", "b"))
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	if part.begins_with("b"):
		_rect_abs(img, ox + 6, oy + 0, ox + 12, oy + 15, Color(0.42, 0.24, 0.12))
		_rect_abs(img, ox + 8, oy + 0, ox + 10, oy + 15, Color(0.66, 0.42, 0.20))


static func _draw_small_house_tile(img: Image, c: int, r: int) -> void:
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	var lx := c - 10
	var ly := r
	if ly == 0:
		_rect_abs(img, ox, oy + 4, ox + 15, oy + 15, Color(0.26, 0.46, 0.58))
		for yy in range(5, 15, 3):
			_rect_abs(img, ox, oy + yy, ox + 15, oy + yy, Color(0.50, 0.75, 0.84))
		_rect_abs(img, ox, oy + 14, ox + 15, oy + 15, Color(0.18, 0.30, 0.46))
	elif ly == 1:
		_rect_abs(img, ox, oy, ox + 15, oy + 15, Color(0.74, 0.62, 0.42))
		_rect_abs(img, ox, oy, ox + 15, oy + 2, Color(0.22, 0.36, 0.46))
		if lx == 0:
			_rect_abs(img, ox + 4, oy + 6, ox + 11, oy + 11, Color(0.55, 0.82, 0.92))
			_rect_abs(img, ox + 4, oy + 6, ox + 11, oy + 7, Color(0.18, 0.34, 0.48))
		elif lx == 1:
			_rect_abs(img, ox + 1, oy, ox + 3, oy + 15, Color(0.34, 0.66, 0.28))
			_rect_abs(img, ox + 4, oy + 3, ox + 13, oy + 15, Color(0.24, 0.24, 0.24))
			_rect_abs(img, ox + 5, oy + 4, ox + 12, oy + 15, Color(0.72, 0.62, 0.42))
			_rect_abs(img, ox + 10, oy + 9, ox + 11, oy + 10, Color(0.96, 0.82, 0.34))
		else:
			_rect_abs(img, ox + 3, oy + 6, ox + 12, oy + 11, Color(0.55, 0.82, 0.92))
			_rect_abs(img, ox + 3, oy + 6, ox + 12, oy + 7, Color(0.18, 0.34, 0.48))
	else:
		_rect_abs(img, ox, oy, ox + 15, oy + 15, Color(0.76, 0.62, 0.38))
		if lx == 1:
			_rect_abs(img, ox + 3, oy + 0, ox + 12, oy + 15, Color(0.24, 0.18, 0.12))
			_rect_abs(img, ox + 4, oy + 1, ox + 11, oy + 15, Color(0.62, 0.40, 0.22))
			_rect_abs(img, ox + 9, oy + 7, ox + 10, oy + 8, Color(0.96, 0.82, 0.34))


static func _draw_big_house_tile(img: Image, c: int, r: int) -> void:
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	var lx := c - 13
	var ly := r - 6
	if ly < 2:
		_rect_abs(img, ox, oy + 4, ox + 15, oy + 15, Color(0.62, 0.72, 0.76))
		for yy in range(5, 15, 3):
			_rect_abs(img, ox, oy + yy, ox + 15, oy + yy, Color(0.80, 0.88, 0.90))
		_rect_abs(img, ox, oy + 14, ox + 15, oy + 15, Color(0.36, 0.46, 0.54))
	elif ly < 5:
		_rect_abs(img, ox, oy, ox + 15, oy + 15, Color(0.64, 0.64, 0.66))
		_rect_abs(img, ox, oy, ox + 15, oy + 2, Color(0.34, 0.40, 0.46))
		if ly == 3 and (lx == 0 or lx == 3):
			_rect_abs(img, ox + 4, oy + 5, ox + 11, oy + 10, Color(0.82, 0.94, 0.96))
			_rect_abs(img, ox + 4, oy + 5, ox + 11, oy + 6, Color(0.30, 0.52, 0.68))
		if ly == 4:
			_rect_abs(img, ox, oy + 2, ox + 15, oy + 9, Color(0.94, 0.72, 0.30))
			for sx in range(1, 16, 4):
				_rect_abs(img, ox + sx, oy + 2, ox + sx + 1, oy + 9, Color(0.98, 0.90, 0.46))
	else:
		_rect_abs(img, ox, oy, ox + 15, oy + 15, Color(0.56, 0.56, 0.58))
		if lx == 1:
			_rect_abs(img, ox + 2, oy, ox + 13, oy + 15, Color(0.24, 0.22, 0.20))
			_rect_abs(img, ox + 4, oy + 2, ox + 11, oy + 15, Color(0.74, 0.64, 0.48))
			_rect_abs(img, ox + 9, oy + 8, ox + 10, oy + 9, Color(0.96, 0.82, 0.34))


static func _draw_stump_at(img: Image, c: int, r: int) -> void:
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	_rect_abs(img, ox + 4, oy + 5, ox + 12, oy + 13, Color(0.44, 0.24, 0.12))
	_rect_abs(img, ox + 3, oy + 4, ox + 13, oy + 7, Color(0.70, 0.46, 0.22))
	_rect_abs(img, ox + 6, oy + 5, ox + 10, oy + 6, Color(0.90, 0.66, 0.34))


static func _draw_rock_at(img: Image, c: int, r: int) -> void:
	var ox := c * TILE_SIZE
	var oy := r * TILE_SIZE
	_rect_abs(img, ox + 3, oy + 8, ox + 12, oy + 13, Color(0.34, 0.38, 0.38))
	_rect_abs(img, ox + 5, oy + 5, ox + 11, oy + 10, Color(0.58, 0.62, 0.60))
	_rect_abs(img, ox + 6, oy + 5, ox + 10, oy + 6, Color(0.78, 0.80, 0.74))


static func _fill_tile(img: Image, ox: int, color: Color) -> void:
	_rect(img, ox, 0, ox + 15, 15, color)


static func _sandy_path(img: Image, ox: int) -> void:
	for p in [Vector2i(2, 4), Vector2i(8, 2), Vector2i(13, 6), Vector2i(5, 12), Vector2i(11, 13)]:
		_pixel(img, ox + p.x, p.y, Color(0.70, 0.54, 0.34))
		_pixel(img, ox + p.x + 1, p.y, Color(0.98, 0.90, 0.62))


static func _hline_tile(img: Image, ox: int, y: int, color: Color) -> void:
	for x in range(0, 16):
		_pixel(img, ox + x, y, color)


static func _grass_specks(img: Image, ox: int, dark: Color, light: Color) -> void:
	for p in [Vector2i(2, 4), Vector2i(10, 3), Vector2i(5, 11), Vector2i(13, 12)]:
		_pixel(img, ox + p.x, p.y, dark)
		_pixel(img, ox + p.x + 1, p.y, light)


static func _pebbles(img: Image, ox: int, dark: Color, light: Color) -> void:
	for p in [Vector2i(3, 5), Vector2i(9, 3), Vector2i(12, 11), Vector2i(5, 13)]:
		_pixel(img, ox + p.x, p.y, dark)
		_pixel(img, ox + p.x + 1, p.y, light)


static func _draw_bush(img: Image, ox: int, oy: int) -> void:
	_rect(img, ox + 2, oy + 5, ox + 13, oy + 13, Color(0.04, 0.22, 0.12))
	_rect(img, ox + 3, oy + 6, ox + 12, oy + 13, Color(0.08, 0.36, 0.18))
	_rect(img, ox + 4, oy + 3, ox + 11, oy + 11, Color(0.18, 0.58, 0.24))
	_rect(img, ox + 6, oy + 4, ox + 12, oy + 7, Color(0.46, 0.80, 0.32))


static func _draw_picket_fence(img: Image, ox: int) -> void:
	for x in [1, 5, 9, 13]:
		_rect(img, ox + x, 5, ox + x + 2, 14, Color(0.40, 0.42, 0.56))
		_rect(img, ox + x + 1, 4, ox + x + 1, 4, Color(0.86, 0.88, 0.92))
	_rect(img, ox, 8, ox + 15, 10, Color(0.76, 0.78, 0.86))
	_rect(img, ox, 13, ox + 15, 14, Color(0.56, 0.58, 0.70))


static func _flower(img: Image, cx: int, cy: int, color: Color) -> void:
	_pixel(img, cx, cy - 1, color)
	_pixel(img, cx - 1, cy, color)
	_pixel(img, cx + 1, cy, color)
	_pixel(img, cx, cy + 1, color)
	_pixel(img, cx, cy, Color(0.96, 0.90, 0.28))


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_pixel(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


static func _rect(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	for y in range(maxi(0, y1), mini(img.get_height(), y2 + 1)):
		for x in range(maxi(0, x1), mini(img.get_width(), x2 + 1)):
			img.set_pixel(x, y, color)


static func _rect_abs(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	_rect(img, x1, y1, x2, y2, color)


static func _pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)
