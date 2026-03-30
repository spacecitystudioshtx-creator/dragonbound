## Kindra — Starter town. Volcanic hot spring village.
## Buildings: Player's Home, The Pyre (elder gives starter), Elder's House,
## Supply Shop, 2 NPC houses. Hot spring pool in the southeast.
## Exits: East → Dustway Route 1, North → blocked until trial complete.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 30
const MAP_H := 28

## Tile atlas coords (col, row=0)
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

	if not GameState.has_starter:
		GameState.give_starter("ember")


func _build_map() -> void:
	var src := 0

	## ── Ground fill ──────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt := GRASS if (x + y * 3) % 7 != 0 else GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border trees ─────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var is_border := x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1
			## East exit gap (to Dustway) — rows 13-15
			var is_east_exit := x == MAP_W - 1 and y >= 13 and y <= 15
			## North exit gap — cols 14-16, blocked by fence
			var is_north_gap := y == 0 and x >= 14 and x <= 16
			if is_border and not is_east_exit and not is_north_gap:
				obstacle_layer.set_cell(Vector2i(x, y), src, TREE)

	## North exit fence (blocked until trial complete)
	for x in range(14, 17):
		obstacle_layer.set_cell(Vector2i(x, 0), src, FENCE)

	## ── Path network ─────────────────────────────────────────────────────
	## Main east-west road (row 14)
	for x in range(2, MAP_W):
		_set_ground(x, 14, PATH, src)
	## Main north-south road (col 15)
	for y in range(2, MAP_H - 1):
		_set_ground(15, y, PATH, src)
	## Branch to player's home (row 21, from col 5 to 15)
	for x in range(5, 16):
		_set_ground(x, 21, PATH, src)
	## Branch south to player home door (col 8)
	for y in range(21, 24):
		_set_ground(8, y, PATH, src)
	## Branch to Supply Shop (col 22, from row 10 to 14)
	for y in range(10, 15):
		_set_ground(22, y, PATH, src)
	## Branch to Elder's house (col 10, from row 5 to 14)
	for y in range(5, 15):
		_set_ground(10, y, PATH, src)
	## Branch to The Pyre (row 7, from col 15 to 21)
	for x in range(15, 22):
		_set_ground(x, 7, PATH, src)

	## ── Player's Home (south-center) ─────────────────────────────────────
	## Roof: rows 22-23, cols 5-11
	## Walls: rows 24-25, cols 5-11
	## Door at col 8, row 25
	_place_building(5, 22, 7, 4, 8, src)

	## ── The Pyre — Elder gives starter (center-right) ────────────────────
	## Larger building: 9 wide, 4 tall
	_place_building(16, 3, 9, 4, 20, src)

	## ── Elder Moss's House (north-left) ──────────────────────────────────
	_place_building(3, 3, 6, 4, 6, src)

	## ── Supply Shop (east side) ──────────────────────────────────────────
	_place_building(20, 9, 6, 4, 22, src)

	## ── NPC House 1 (west side, mid) ─────────────────────────────────────
	_place_building(2, 10, 6, 4, 5, src)

	## ── NPC House 2 (south-east) ─────────────────────────────────────────
	_place_building(20, 19, 6, 4, 22, src)

	## ── Hot spring pool (south-east) ─────────────────────────────────────
	for x in range(23, 28):
		for y in range(24, 27):
			_set_ground(x, y, WATER, src)
			obstacle_layer.set_cell(Vector2i(x, y), src, WATER)
	## Fence around hot spring
	for x in range(22, 29):
		obstacle_layer.set_cell(Vector2i(x, 23), src, FENCE)
	obstacle_layer.set_cell(Vector2i(22, 24), src, FENCE)
	obstacle_layer.set_cell(Vector2i(22, 25), src, FENCE)
	obstacle_layer.set_cell(Vector2i(22, 26), src, FENCE)

	## ── Decorative trees / gardens ───────────────────────────────────────
	## Trees near The Pyre
	for pos in [Vector2i(16, 8), Vector2i(24, 8), Vector2i(14, 2), Vector2i(26, 2)]:
		obstacle_layer.set_cell(pos, src, TREE)
	## Trees near elder's house
	for pos in [Vector2i(2, 2), Vector2i(9, 2), Vector2i(2, 8)]:
		obstacle_layer.set_cell(pos, src, TREE)
	## Garden flowers near player's home
	for x in range(12, 15):
		for y in range(23, 25):
			_set_ground(x, y, GRASS_ALT, src)

	## ── Sign posts ───────────────────────────────────────────────────────
	obstacle_layer.set_cell(Vector2i(16, 14), src, FENCE)  ## Sign: "East → Dustway"
	obstacle_layer.set_cell(Vector2i(15, 1), src, FENCE)   ## Sign: "North — Road Closed"


## Place a rectangular building with roof, walls, and door.
## bx,by = top-left corner, bw = width, bh = height (2 roof + 2 wall rows min)
## door_x = x coordinate of the door tile (absolute)
func _place_building(bx: int, by: int, bw: int, bh: int, door_x: int, src: int) -> void:
	var roof_rows := bh / 2
	var wall_rows := bh - roof_rows
	## Roof
	for x in range(bx, bx + bw):
		for y in range(by, by + roof_rows):
			obstacle_layer.set_cell(Vector2i(x, y), src, ROOF)
	## Walls
	for x in range(bx, bx + bw):
		for y in range(by + roof_rows, by + bh):
			obstacle_layer.set_cell(Vector2i(x, y), src, WALL)
	## Door (bottom center-ish)
	var door_y := by + bh - 1
	obstacle_layer.set_cell(Vector2i(door_x, door_y), src, DOOR)
	## Clear the door from the obstacle layer so player can walk on it
	## (door is on ground, not blocking)
	ground_layer.set_cell(Vector2i(door_x, door_y), src, DOOR)
	obstacle_layer.erase_cell(Vector2i(door_x, door_y))
	## Path tile in front of door
	_set_ground(door_x, door_y + 1, PATH, src)


func _set_ground(x: int, y: int, tile: Vector2i, src: int) -> void:
	ground_layer.set_cell(Vector2i(x, y), src, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
