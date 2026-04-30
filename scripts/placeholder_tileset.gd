## Builds a TileSet from the Ninja Adventure CC0 asset pack.
##
## Two sources:
##   Source 0 — 16-tile ground strip (curated from tileset_floor.png +
##              tileset_animated.png + tileset_village_abandoned.png).
##              Layout matches MapTiles constants (GRASS=0, GRASS_ALT=1, ...).
##   Source 1 — full village atlas (20×12) used for multi-tile props via
##              MapTiles.stamp().
##
## Solid tiles receive a 16×16 collision polygon on physics layer 1 (mask 2).

extends Node

const TILE_SIZE := 16

const FLOOR_PATH    := "res://art/tilesets/ninja_adventure/tileset_floor.png"
const VILLAGE_PATH  := "res://art/tilesets/ninja_adventure/tileset_village_abandoned.png"
const ANIMATED_PATH := "res://art/tilesets/ninja_adventure/tileset_animated.png"

## Source 0 strip. Each entry is (source_atlas_path, col, row) in the source PNG.
## Order MUST match MapTiles constants (index = strip position).
const STRIP := [
	["floor",    2, 11],   ## 0  GRASS         pure green
	["floor",    1, 12],   ## 1  GRASS_ALT     another green variant
	["village",  2,  1],   ## 2  BUSH          small bush (single-tile tree)
	["floor",   13, 17],   ## 3  DIRT_PATH     solid dirt
	["floor",   14, 17],   ## 4  DIRT_ALT
	["floor",    2,  1],   ## 5  SAND
	["floor",    3,  1],   ## 6  SAND_ALT
	["floor",    2, 17],   ## 7  SNOW
	["animated", 0,  0],   ## 8  TALL_GRASS    encounter grass
	["floor",    5,  2],   ## 9  FLOWER        decorative
	["floor",    2, 22],   ## 10 WATER         pale blue
	["floor",    1, 22],   ## 11 WATER_ALT
	["village",  0,  8],   ## 12 FENCE
	["village", 12, 10],   ## 13 SIGN          (falls back to bush-ish)
	["village",  4,  4],   ## 14 STUMP
	["village",  5,  4],   ## 15 ROCK
]

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

	var floor_img := _load_image(FLOOR_PATH)
	var village_img := _load_image(VILLAGE_PATH)
	var animated_img := _load_image(ANIMATED_PATH)
	var images := {"floor": floor_img, "village": village_img, "animated": animated_img}

	## ── Source 0: 16-tile ground strip ───────────────────────────────────────
	var cols := STRIP.size()
	var strip_img := Image.create(TILE_SIZE * cols, TILE_SIZE, false, Image.FORMAT_RGBA8)
	strip_img.fill(Color(1, 0, 1, 1))

	for i in cols:
		var entry: Array = STRIP[i]
		var src_name: String = entry[0]
		var sc: int = entry[1]
		var sr: int = entry[2]
		var src_img: Image = images.get(src_name)
		var dx := i * TILE_SIZE

		if src_img != null:
			for y in TILE_SIZE:
				for x in TILE_SIZE:
					var px := sc * TILE_SIZE + x
					var py := sr * TILE_SIZE + y
					if px < src_img.get_width() and py < src_img.get_height():
						var c := src_img.get_pixel(px, py)
						strip_img.set_pixel(dx + x, y, c)

	var strip_tex := ImageTexture.create_from_image(strip_img)
	var strip_src := TileSetAtlasSource.new()
	strip_src.texture = strip_tex
	strip_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in cols:
		strip_src.create_tile(Vector2i(i, 0))
	tileset.add_source(strip_src, 0)
	var poly := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	for i in STRIP_SOLID:
		var td := strip_src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, poly)

	## ── Source 1: full village atlas ─────────────────────────────────────────
	if village_img != null:
		var village_tex: Texture2D = load(VILLAGE_PATH)
		if village_tex == null:
			village_tex = ImageTexture.create_from_image(village_img)
		var vsrc := TileSetAtlasSource.new()
		vsrc.texture = village_tex
		vsrc.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		var vcols := village_img.get_width() / TILE_SIZE
		var vrows := village_img.get_height() / TILE_SIZE
		for c in vcols:
			for r in vrows:
				vsrc.create_tile(Vector2i(c, r))
		tileset.add_source(vsrc, 1)
		## Apply collision to listed coords.
		for coord in VILLAGE_SOLID_COORDS:
			if coord.x < vcols and coord.y < vrows:
				var td := vsrc.get_tile_data(coord, 0)
				if td != null:
					td.add_collision_polygon(0)
					td.set_collision_polygon_points(0, 0, poly)

	return tileset


static func _load_image(path: String) -> Image:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex:
			return tex.get_image()
	var img := Image.new()
	var abs_path := ProjectSettings.globalize_path(path)
	if img.load(abs_path) == OK:
		return img
	push_warning("placeholder_tileset: could not load %s" % path)
	return null
