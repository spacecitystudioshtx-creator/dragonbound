## Dustway Route 1 — First route, connects Kindra town to The Scald.
## Vertical route: enter from west (Kindra), travel north.
## Terrain (south→north): rocky entrance → tall grass → pond → dense clearing.
## Wild drakes: Flick (fire, common), Tuft (nature, common), Gulp (water, pond).

extends Node2D

const TILE_SIZE := 16
const MAP_W := 22
const MAP_H := 48

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set = tileset
	obstacle_layer.tile_set = tileset
	_build_map()
	_setup_camera_bounds()


func _build_map() -> void:
	var src := MapTiles.SRC_GROUND

	## ── Ground fill ──────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt: Vector2i = MapTiles.GRASS if (x * 3 + y * 7) % 11 != 0 else MapTiles.GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border: trees — west entrance at rows 40-42, north exit cols 10-12
	var west_entrance_rows := range(40, 43)
	var north_exit_cols := range(10, 13)
	## Top + bottom rows (stamp trees in pairs since tree is 2x2)
	for x in range(0, MAP_W, 2):
		if not (x in north_exit_cols):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, 0, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, MAP_H - 2, ground_layer, obstacle_layer)
	## Left + right columns
	for y in range(0, MAP_H, 2):
		if not (y in west_entrance_rows):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 0, y, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, MAP_W - 2, y, ground_layer, obstacle_layer)

	## North exit blocked by sign (The Scald not open yet)
	for x in north_exit_cols:
		obstacle_layer.set_cell(Vector2i(x, 1), src, MapTiles.SIGN)

	## ── Section 1: South — rocky entrance (rows 38-47) ───────────────────
	for x in range(0, 12):
		_set_ground(x, 41, MapTiles.DIRT_PATH)
	for y in range(36, 42):
		_set_ground(11, y, MapTiles.DIRT_PATH)

	## Tutorial sign
	obstacle_layer.set_cell(Vector2i(6, 40), src, MapTiles.SIGN)

	## Scattered rocks
	for pos in [Vector2i(4, 44), Vector2i(8, 43), Vector2i(15, 42), Vector2i(17, 44)]:
		obstacle_layer.set_cell(pos, src, MapTiles.ROCK)

	## ── Section 2: Tall grass zone (rows 28-37) ─────────────────────────
	for y in range(28, 37):
		_set_ground(11, y, MapTiles.DIRT_PATH)

	## West patch
	for x in range(3, 10):
		for y in range(29, 36):
			if not (x == 6 and y == 32):
				_set_ground(x, y, MapTiles.TALL_GRASS)
	## East patch
	for x in range(13, 20):
		for y in range(30, 37):
			_set_ground(x, y, MapTiles.TALL_GRASS)

	## Tree barriers channeling the path (big trees as pillars)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 2, 29, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 2, 33, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 19, 30, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 19, 34, ground_layer, obstacle_layer)

	## ── Section 3: Pond / stream (rows 18-27) ───────────────────────────
	for y in range(20, 29):
		_set_ground(11, y, MapTiles.DIRT_PATH)
	for x in range(6, 16):
		_set_ground(x, 20, MapTiles.DIRT_PATH)

	## Pond (6 wide × 5 tall, rounded)
	for x in range(4, 10):
		for y in range(22, 27):
			var is_corner := (x == 4 or x == 9) and (y == 22 or y == 26)
			if not is_corner:
				_set_ground(x, y, MapTiles.WATER)
				obstacle_layer.set_cell(Vector2i(x, y), src, MapTiles.WATER)

	## Trees around pond
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 3, 21, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 3, 26, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 10, 24, ground_layer, obstacle_layer)

	## Tall grass near pond (water-type encounters)
	for x in range(13, 18):
		for y in range(22, 26):
			_set_ground(x, y, MapTiles.TALL_GRASS)

	## ── Section 4: Dense clearing — rival area (rows 5-17) ──────────────
	for y in range(6, 21):
		_set_ground(11, y, MapTiles.DIRT_PATH)

	## Open clearing with flower grass variant
	for x in range(5, 18):
		for y in range(8, 14):
			_set_ground(x, y, MapTiles.GRASS_ALT)

	## Dense tall grass flanking the clearing
	for x in range(2, 5):
		for y in range(8, 14):
			_set_ground(x, y, MapTiles.TALL_GRASS)
	for x in range(17, 20):
		for y in range(8, 14):
			_set_ground(x, y, MapTiles.TALL_GRASS)

	## Flower decorations in the clearing
	_set_ground(8, 10, MapTiles.FLOWER)
	_set_ground(13, 11, MapTiles.FLOWER)

	## Big tree landmark at the top of the clearing (memorable vignette)
	MapTiles.stamp(MapTiles.PROP_TREE_BIG, 8, 4, ground_layer, obstacle_layer)

	## Sign near rival clearing
	obstacle_layer.set_cell(Vector2i(12, 14), src, MapTiles.SIGN)


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
