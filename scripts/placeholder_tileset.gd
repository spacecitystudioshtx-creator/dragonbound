## Generates placeholder tile textures at runtime.
## Creates colored rectangles for grass, trees, path, and water
## until real pixel art tilesets are ready.

extends Node

# Tile type colors
const GRASS_COLOR := Color(0.28, 0.63, 0.21)       # Green grass
const GRASS_ALT_COLOR := Color(0.32, 0.68, 0.24)   # Slightly lighter grass
const TREE_COLOR := Color(0.12, 0.35, 0.10)         # Dark green tree top
const TRUNK_COLOR := Color(0.45, 0.30, 0.15)        # Brown trunk
const PATH_COLOR := Color(0.72, 0.62, 0.42)         # Dirt path
const WATER_COLOR := Color(0.18, 0.40, 0.75)        # Blue water
const FLOWER_COLOR := Color(0.9, 0.3, 0.3)          # Red flower accent

const TILE_SIZE := 16


## Create a TileSet with placeholder tile images.
static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create physics layers
	tileset.add_physics_layer()  # Layer 0: walkable
	tileset.set_physics_layer_collision_layer(0, 2)  # Collision layer 2 = obstacles

	# Create tile atlas from generated image
	var img := Image.create(TILE_SIZE * 5, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Tile 0: Grass
	_draw_grass(img, 0)
	# Tile 1: Grass (alternate)
	_draw_grass_alt(img, 1)
	# Tile 2: Tree
	_draw_tree(img, 2)
	# Tile 3: Path
	_draw_path(img, 3)
	# Tile 4: Water
	_draw_water(img, 4)

	var tex := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create tiles in the atlas
	for i in 5:
		source.create_tile(Vector2i(i, 0))

	# Add collision to tree tile (index 2) — blocks movement
	source.get_tile_data(Vector2i(2, 0), 0).add_collision_polygon(0)
	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	source.get_tile_data(Vector2i(2, 0), 0).set_collision_polygon_points(0, 0, polygon)

	# Add collision to water tile (index 4) — blocks movement
	source.get_tile_data(Vector2i(4, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(4, 0), 0).set_collision_polygon_points(0, 0, polygon)

	tileset.add_source(source)
	return tileset


## Draw a grass tile at column index.
static func _draw_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_COLOR)
	# Add a few darker spots for texture
	img.set_pixel(ox + 3, 5, GRASS_ALT_COLOR)
	img.set_pixel(ox + 10, 3, GRASS_ALT_COLOR)
	img.set_pixel(ox + 7, 11, GRASS_ALT_COLOR)
	img.set_pixel(ox + 12, 8, GRASS_ALT_COLOR)


## Draw an alternate grass tile with a flower.
static func _draw_grass_alt(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_ALT_COLOR)
	# Small flower
	img.set_pixel(ox + 8, 6, FLOWER_COLOR)
	img.set_pixel(ox + 7, 7, FLOWER_COLOR)
	img.set_pixel(ox + 9, 7, FLOWER_COLOR)
	img.set_pixel(ox + 8, 8, FLOWER_COLOR)


## Draw a tree tile with canopy and trunk.
static func _draw_tree(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	# Fill with grass underneath
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, GRASS_COLOR)
	# Tree canopy (round-ish blob)
	for x in range(2, 14):
		for y in range(1, 10):
			var cx := 8.0
			var cy := 5.0
			var dx := (x - cx) / 6.0
			var dy := (y - cy) / 4.5
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(ox + x, y, TREE_COLOR)
	# Trunk
	for x in range(6, 10):
		for y in range(9, 15):
			img.set_pixel(ox + x, y, TRUNK_COLOR)


## Draw a dirt path tile.
static func _draw_path(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, PATH_COLOR)
	# Add texture variation
	img.set_pixel(ox + 4, 4, PATH_COLOR.darkened(0.1))
	img.set_pixel(ox + 11, 7, PATH_COLOR.darkened(0.1))
	img.set_pixel(ox + 6, 12, PATH_COLOR.lightened(0.1))


## Draw a water tile.
static func _draw_water(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for x in TILE_SIZE:
		for y in TILE_SIZE:
			img.set_pixel(ox + x, y, WATER_COLOR)
	# Wave highlights
	img.set_pixel(ox + 3, 4, WATER_COLOR.lightened(0.2))
	img.set_pixel(ox + 4, 4, WATER_COLOR.lightened(0.2))
	img.set_pixel(ox + 10, 9, WATER_COLOR.lightened(0.2))
	img.set_pixel(ox + 11, 9, WATER_COLOR.lightened(0.2))
