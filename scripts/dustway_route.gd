## Dustway Route 1 — First route, connects Kindra town to The Scald.
## Vertical route: enter from west (Kindra), travel north.
## Terrain (south→north): rocky path → tall grass → pond → dense clearing.
## Wild drakes: Flick (fire, common), Tuft (nature, common), Gulp (water, pond).

extends Node2D

const TILE_SIZE := 16
const MAP_W := 20
const MAP_H := 45

## Tile atlas coords
const GRASS     := Vector2i(0, 0)
const GRASS_ALT := Vector2i(1, 0)
const TREE      := Vector2i(2, 0)
const PATH      := Vector2i(3, 0)
const WATER     := Vector2i(4, 0)
const WALL      := Vector2i(5, 0)
const ROOF      := Vector2i(6, 0)
const DOOR      := Vector2i(7, 0)
const TALL_GR   := Vector2i(8, 0)
const FENCE     := Vector2i(9, 0)

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
	var src := 0

	## ── Ground fill ──────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt := GRASS if (x * 3 + y * 7) % 11 != 0 else GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border trees ─────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var is_border := x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1
			## West entrance from Kindra — rows 38-40
			var is_west_entrance := x == 0 and y >= 38 and y <= 40
			## North exit to The Scald — cols 9-11
			var is_north_exit := y == 0 and x >= 9 and x <= 11
			if is_border and not is_west_entrance and not is_north_exit:
				obstacle_layer.set_cell(Vector2i(x, y), src, TREE)

	## North exit blocked by fence (The Scald not implemented yet)
	for x in range(9, 12):
		obstacle_layer.set_cell(Vector2i(x, 0), src, FENCE)

	## ── Section 1: South — Rocky entrance from Kindra (rows 36-44) ──────
	## Path from west entrance going east then north
	for x in range(0, 10):
		_set_ground(x, 39, PATH, src)
	for y in range(34, 40):
		_set_ground(10, y, PATH, src)

	## Tutorial NPC sign
	obstacle_layer.set_cell(Vector2i(5, 38), src, FENCE)

	## Scattered rocks (trees as boulders)
	for pos in [Vector2i(3, 42), Vector2i(7, 41), Vector2i(14, 40), Vector2i(16, 42)]:
		obstacle_layer.set_cell(pos, src, TREE)

	## ── Section 2: Tall grass zone (rows 26-35) ─────────────────────────
	## Main path continues north
	for y in range(26, 35):
		_set_ground(10, y, PATH, src)

	## Tall grass patches on both sides of path
	## West patch
	for x in range(3, 9):
		for y in range(27, 34):
			if not (x == 5 and y == 30):  ## Leave small gap
				_set_ground(x, y, TALL_GR, src)
	## East patch
	for x in range(12, 18):
		for y in range(28, 35):
			_set_ground(x, y, TALL_GR, src)

	## Tree barriers channeling the path
	for y in range(27, 34):
		obstacle_layer.set_cell(Vector2i(2, y), src, TREE)
	for y in range(28, 35):
		obstacle_layer.set_cell(Vector2i(18, y), src, TREE)

	## ── Section 3: Pond / stream area (rows 16-25) ──────────────────────
	## Path curves around the pond
	for y in range(18, 27):
		_set_ground(10, y, PATH, src)
	for x in range(6, 15):
		_set_ground(x, 18, PATH, src)

	## Pond (6 wide, 5 tall)
	for x in range(4, 10):
		for y in range(20, 25):
			## Rounded corners
			var is_corner := (x == 4 or x == 9) and (y == 20 or y == 24)
			if not is_corner:
				_set_ground(x, y, WATER, src)
				obstacle_layer.set_cell(Vector2i(x, y), src, WATER)

	## Trees around pond
	for pos in [Vector2i(3, 19), Vector2i(3, 24), Vector2i(10, 22)]:
		obstacle_layer.set_cell(pos, src, TREE)

	## Tall grass near pond (water-type encounters)
	for x in range(12, 17):
		for y in range(20, 24):
			_set_ground(x, y, TALL_GR, src)

	## ── Section 4: Dense clearing — rival area (rows 5-15) ──────────────
	## Path north to clearing
	for y in range(6, 19):
		_set_ground(10, y, PATH, src)

	## Open clearing
	for x in range(4, 16):
		for y in range(7, 13):
			_set_ground(x, y, GRASS_ALT, src)

	## Dense tall grass flanking the clearing
	for x in range(2, 5):
		for y in range(7, 13):
			_set_ground(x, y, TALL_GR, src)
	for x in range(15, 19):
		for y in range(7, 13):
			_set_ground(x, y, TALL_GR, src)

	## Tree walls around clearing
	for x in range(2, 19):
		obstacle_layer.set_cell(Vector2i(x, 6), src, TREE)
	## Leave gap for path at x=10
	obstacle_layer.erase_cell(Vector2i(10, 6))

	## Sign near rival clearing
	obstacle_layer.set_cell(Vector2i(11, 13), src, FENCE)

	## ── Path from clearing to north exit ─────────────────────────────────
	for y in range(1, 7):
		_set_ground(10, y, PATH, src)


func _set_ground(x: int, y: int, tile: Vector2i, src: int) -> void:
	ground_layer.set_cell(Vector2i(x, y), src, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
