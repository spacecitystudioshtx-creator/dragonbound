## Kindra — Starter town. Volcanic hot spring village.
## Buildings: Player's Home, The Pyre (elder gives starter), Elder's House,
## Supply Shop, NPC house. Hot spring pool in the southeast.
## Exits: East → Dustway Route 1, North → blocked until trial complete.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 36
const MAP_H := 30

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
	var src := MapTiles.SRC_GROUND

	## ── Ground fill (grass with occasional variation) ───────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt: Vector2i = MapTiles.GRASS if (x + y * 3) % 7 != 0 else MapTiles.GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border: ring of big trees ────────────────────────────────────────
	## East exit (to Dustway) at rows 14-16. North exit gap at cols 17-19.
	var east_exit_rows := range(14, 17)
	var north_exit_cols := range(17, 20)
	## Top + bottom rows
	for x in range(0, MAP_W, 2):
		if not (x in north_exit_cols):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, 0, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, MAP_H - 2, ground_layer, obstacle_layer)
	## Left + right columns
	for y in range(0, MAP_H, 2):
		if not (y in east_exit_rows):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, MAP_W - 2, y, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 0, y, ground_layer, obstacle_layer)

	## North exit fence (blocked — trial not complete)
	for x in north_exit_cols:
		obstacle_layer.set_cell(Vector2i(x, 1), src, MapTiles.FENCE)

	## ── Path network ─────────────────────────────────────────────────────
	## Main east-west road (row 15)
	for x in range(2, MAP_W):
		_set_ground(x, 15, MapTiles.DIRT_PATH)
	## Main north-south road (col 18)
	for y in range(2, MAP_H - 1):
		_set_ground(18, y, MapTiles.DIRT_PATH)
	## Branch to player's home (row 23, cols 8-18)
	for x in range(8, 19):
		_set_ground(x, 23, MapTiles.DIRT_PATH)
	## Branch south to player home door (col 10)
	for y in range(23, 26):
		_set_ground(10, y, MapTiles.DIRT_PATH)
	## Branch to Supply Shop (col 26, rows 10-15)
	for y in range(10, 16):
		_set_ground(26, y, MapTiles.DIRT_PATH)
	## Branch to Elder's house (col 12, rows 5-15)
	for y in range(5, 16):
		_set_ground(12, y, MapTiles.DIRT_PATH)
	## Branch to The Pyre (row 8, cols 18-23)
	for x in range(18, 24):
		_set_ground(x, 8, MapTiles.DIRT_PATH)

	## ── Buildings — use village-atlas stamps ─────────────────────────────
	## Player's Home (3×3 small house) — south-center
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  9, 24, ground_layer, obstacle_layer)
	## The Pyre (4×6 big house) — northeast, where elder gives starter
	MapTiles.stamp(MapTiles.PROP_HOUSE_BIG,   20,  3, ground_layer, obstacle_layer)
	## Elder Moss's House (3×3) — north-left
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  4,  4, ground_layer, obstacle_layer)
	## Supply Shop (3×3) — east side
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL, 24, 10, ground_layer, obstacle_layer)
	## NPC House (3×3) — west side mid
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  3, 11, ground_layer, obstacle_layer)

	## ── Garden — tall grass patch where starters encounter ──────────────
	## Covers the GardenEncounter Area2D in the scene.
	for x in range(14, 18):
		for y in range(24, 26):
			_set_ground(x, y, MapTiles.TALL_GRASS)
	## Flower decorations flanking the garden
	_set_ground(13, 24, MapTiles.FLOWER)
	_set_ground(13, 25, MapTiles.FLOWER)
	_set_ground(18, 24, MapTiles.FLOWER)
	_set_ground(18, 25, MapTiles.FLOWER)

	## ── Hot spring pool (southeast) ──────────────────────────────────────
	for x in range(28, 33):
		for y in range(25, 28):
			_set_ground(x, y, MapTiles.WATER)
			obstacle_layer.set_cell(Vector2i(x, y), src, MapTiles.WATER)
	## Fence around hot spring
	for x in range(27, 34):
		obstacle_layer.set_cell(Vector2i(x, 24), src, MapTiles.FENCE)
	for y in range(24, 28):
		obstacle_layer.set_cell(Vector2i(27, y), src, MapTiles.FENCE)

	## ── Decorative scatter: small trees near buildings ───────────────────
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 28, 4, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 2, 24, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 14, 6, ground_layer, obstacle_layer)

	## Signs
	obstacle_layer.set_cell(Vector2i(19, 15), src, MapTiles.SIGN)  ## "East → Dustway"
	obstacle_layer.set_cell(Vector2i(18,  2), src, MapTiles.SIGN)  ## "North — Road Closed"


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
