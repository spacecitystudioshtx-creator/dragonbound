## Generates placeholder tile textures at runtime.
## Creates pixel-art-style tiles for grass, trees, path, and water
## until real pixel art tilesets are ready.

extends Node

const TILE_SIZE := 16

## Base colors
const GRASS_MID   := Color(0.35, 0.65, 0.22)
const GRASS_LIGHT := Color(0.42, 0.72, 0.28)
const GRASS_DARK  := Color(0.26, 0.52, 0.16)
const TREE_CANOPY := Color(0.14, 0.40, 0.10)
const TREE_SHADE  := Color(0.10, 0.30, 0.07)
const TREE_TRUNK  := Color(0.42, 0.28, 0.12)
const TREE_TRUNK_D := Color(0.30, 0.20, 0.08)
const PATH_BASE   := Color(0.75, 0.65, 0.45)
const PATH_DARK   := Color(0.62, 0.53, 0.36)
const PATH_LIGHT  := Color(0.84, 0.74, 0.54)
const WATER_MID   := Color(0.20, 0.48, 0.82)
const WATER_LIGHT := Color(0.35, 0.62, 0.92)
const WATER_DARK  := Color(0.12, 0.34, 0.64)
const FLOWER_COL  := Color(0.95, 0.88, 0.20)
const FLOWER_CEN  := Color(0.95, 0.55, 0.10)


## Create a TileSet with placeholder tile images.
static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 2)

	var img := Image.create(TILE_SIZE * 5, TILE_SIZE, false, Image.FORMAT_RGBA8)

	_draw_grass(img, 0)
	_draw_grass_alt(img, 1)
	_draw_tree(img, 2)
	_draw_path(img, 3)
	_draw_water(img, 4)

	var tex    := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture              = tex
	source.texture_region_size  = Vector2i(TILE_SIZE, TILE_SIZE)

	for i in 5:
		source.create_tile(Vector2i(i, 0))

	## Collision on tree (index 2) and water (index 4)
	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	source.get_tile_data(Vector2i(2, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(2, 0), 0).set_collision_polygon_points(0, 0, polygon)
	source.get_tile_data(Vector2i(4, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(4, 0), 0).set_collision_polygon_points(0, 0, polygon)

	tileset.add_source(source)
	return tileset


## Grass tile — base fill + checkerboard-style texture + thin border lines.
static func _draw_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base fill
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_MID)
	## Darker 1px right and bottom edges (tile border shadow)
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, GRASS_DARK)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, GRASS_DARK)
	## Light pixel highlights scattered for texture
	var pts := [[2, 3], [5, 1], [9, 4], [12, 2], [1, 9], [6, 12], [10, 8], [13, 11],
				[3, 14], [8, 6], [14, 7], [4, 10]]
	for p in pts:
		img.set_pixel(ox + p[0], p[1], GRASS_LIGHT)
	## A few dark blades
	img.set_pixel(ox + 7,  2, GRASS_DARK)
	img.set_pixel(ox + 11, 5, GRASS_DARK)
	img.set_pixel(ox + 3,  8, GRASS_DARK)


## Alt grass tile — slightly lighter with a small yellow flower.
static func _draw_grass_alt(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_LIGHT)
	## Border
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, GRASS_MID)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, GRASS_MID)
	## Dark grass texture
	var pts := [[1, 2], [4, 5], [8, 3], [12, 6], [2, 11], [9, 13], [14, 9]]
	for p in pts:
		img.set_pixel(ox + p[0], p[1], GRASS_DARK)
	## 3-pixel flower at (6, 6)
	img.set_pixel(ox + 6,  5, FLOWER_COL)
	img.set_pixel(ox + 5,  6, FLOWER_COL)
	img.set_pixel(ox + 7,  6, FLOWER_COL)
	img.set_pixel(ox + 6,  7, FLOWER_COL)
	img.set_pixel(ox + 6,  6, FLOWER_CEN)   ## center


## Tree tile — canopy oval + trunk, with grass base.
static func _draw_tree(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Grass base
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_MID)
	## Canopy ellipse
	for x in range(1, 15):
		for y in range(0, 10):
			var dx := (x - 7.5) / 6.5
			var dy := (y - 4.5) / 4.5
			if dx * dx + dy * dy <= 1.0:
				## Shade top-left to give depth
				var shade_dx := (x - 5.0) / 6.5
				var shade_dy := (y - 3.0) / 4.5
				var c := TREE_SHADE if shade_dx * shade_dx + shade_dy * shade_dy < 0.25 else TREE_CANOPY
				img.set_pixel(ox + x, y, c)
	## Trunk
	for x in range(6, 10):
		for y in range(9, 14):
			var c := TREE_TRUNK_D if x == 6 or y == 13 else TREE_TRUNK
			img.set_pixel(ox + x, y, c)
	## 1px dark outline on left/top of canopy for crispness
	for x in range(1, 15):
		if img.get_pixel(ox + x, 0) == TREE_CANOPY or img.get_pixel(ox + x, 0) == TREE_SHADE:
			pass  ## already at edge
		if x > 0 and (img.get_pixel(ox + x - 1, 0).a < 0.5 or
				img.get_pixel(ox + x - 1, 0) == GRASS_MID):
			img.set_pixel(ox + x, 0, TREE_SHADE)


## Dirt path tile — tan base with pebble dots and lighter center strip.
static func _draw_path(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, PATH_BASE)
	## Lighter center strip (worn path)
	for x in range(4, 12):
		for y in range(4, 12):
			img.set_pixel(ox + x, y, PATH_LIGHT)
	## Dark edge shadow (bottom + right)
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, PATH_DARK)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, PATH_DARK)
	## Pebble dots
	var pebbles := [[2, 2], [13, 3], [1, 10], [14, 12], [5, 14], [10, 1], [3, 7], [12, 8]]
	for p in pebbles:
		img.set_pixel(ox + p[0], p[1], PATH_DARK)


## Water tile — blue base with animated-style horizontal highlight lines.
static func _draw_water(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, WATER_MID)
	## Dark edge at bottom
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, WATER_DARK)
	## Wave highlight lines
	for x in range(1, 7):
		img.set_pixel(ox + x, 3, WATER_LIGHT)
		img.set_pixel(ox + x, 4, WATER_LIGHT)
	for x in range(9, 15):
		img.set_pixel(ox + x, 9, WATER_LIGHT)
		img.set_pixel(ox + x, 10, WATER_LIGHT)
	## Dark trough between waves
	img.set_pixel(ox + 7, 5, WATER_DARK)
	img.set_pixel(ox + 8, 5, WATER_DARK)
