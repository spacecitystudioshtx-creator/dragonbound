## Dustway Route 1 — First route, connects Kindra town to The Scald.
## Vertical route: enter from west (Kindra), travel north.
## Terrain (south→north): rocky entrance → tall grass → pond → dense clearing.
## Wild drakes: Flick (fire, common), Tuft (nature, common), Gulp (water, pond).

extends Node2D

const TILE_SIZE := 16
const MAP_W := 22
const MAP_H := 48
const NORTH_EXIT_COLS    := [10, 11, 12]   ## Col indices of north → The Scald opening
const WEST_ENTRANCE_ROWS := [40, 41, 42]   ## Row indices of west ← Kindra entrance

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set = tileset
	obstacle_layer.tile_set = tileset
	_build_map()
	_add_perimeter_walls()
	_setup_camera_bounds()


func _build_map() -> void:
	var src := MapTiles.SRC_GROUND

	## ── Ground fill ──────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt: Vector2i = MapTiles.GRASS if (x * 3 + y * 7) % 11 != 0 else MapTiles.GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border: tree-line around the map edge ───────────────────────────────────
	## Collision is sealed by the StaticBody2D perimeter wall in _add_perimeter_walls.
	var bx := 0
	while bx < MAP_W - 1:        ## top border (skip north exit cols)
		if not (bx in NORTH_EXIT_COLS or (bx + 1) in NORTH_EXIT_COLS):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, bx, 0, ground_layer, obstacle_layer)
		bx += 2
	bx = 0
	while bx < MAP_W - 1:        ## bottom border
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, bx, MAP_H - 2, ground_layer, obstacle_layer)
		bx += 2
	var by := 0
	while by < MAP_H - 1:        ## left border (skip west entrance rows)
		if not (by in WEST_ENTRANCE_ROWS or (by + 1) in WEST_ENTRANCE_ROWS):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 0, by, ground_layer, obstacle_layer)
		by += 2
	by = 0
	while by < MAP_H - 1:        ## right border
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, MAP_W - 2, by, ground_layer, obstacle_layer)
		by += 2

	## North exit blocked by sign (The Scald not open yet)
	for xc in NORTH_EXIT_COLS:
		obstacle_layer.set_cell(Vector2i(xc, 1), src, MapTiles.SIGN)

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

	## Pond — water visuals on ground_layer only; invisible body blocks entry.
	for x in range(4, 10):
		for y in range(22, 27):
			var is_corner := (x == 4 or x == 9) and (y == 22 or y == 26)
			if not is_corner:
				_set_ground(x, y, MapTiles.WATER)
	add_child(_make_static_box(
		Vector2(4 * TILE_SIZE, 22 * TILE_SIZE),
		Vector2(6 * TILE_SIZE, 5 * TILE_SIZE)))

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


func _make_static_box(top_left: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask  = 0
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = size
	cs.position  = top_left + size * 0.5
	cs.shape     = rect
	body.add_child(cs)
	return body


## Invisible StaticBody2D wall sealing the map border, leaving only intended exits open.
func _add_perimeter_walls() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask  = 0
	var W   := float(MAP_W * TILE_SIZE)
	var H   := float(MAP_H * TILE_SIZE)
	var T   := float(TILE_SIZE)
	var nx0 := float(NORTH_EXIT_COLS[0])       * T
	var nx1 := float(NORTH_EXIT_COLS[-1] + 1)  * T
	var wy0 := float(WEST_ENTRANCE_ROWS[0])    * T
	var wy1 := float(WEST_ENTRANCE_ROWS[-1] + 1) * T
	_wall_seg(wall, 0.0,     0.0,     nx0,     T)         ## top-left of north gap
	_wall_seg(wall, nx1,     0.0,     W - nx1, T)         ## top-right of north gap
	_wall_seg(wall, 0.0,     H - T,   W,       T)         ## bottom
	_wall_seg(wall, 0.0,     0.0,     T,       wy0)       ## left-top of west gap
	_wall_seg(wall, 0.0,     wy1,     T,       H - wy1)   ## left-bottom of west gap
	_wall_seg(wall, W - T,   0.0,     T,       H)         ## right
	add_child(wall)


func _wall_seg(parent: StaticBody2D, x: float, y: float, w: float, h: float) -> void:
	if w <= 0.0 or h <= 0.0:
		return
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size   = Vector2(w, h)
	cs.position = Vector2(x + w * 0.5, y + h * 0.5)
	cs.shape    = rect
	parent.add_child(cs)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
