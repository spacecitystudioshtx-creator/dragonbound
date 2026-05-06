## Kindra — Starter town. Volcanic hot spring village.
## Buildings: Player's Home, The Pyre (elder gives starter), Elder's House,
## Supply Shop, NPC house. Hot spring pool in the southeast.
## Exits: East → Dustway Route 1, North → blocked until trial complete.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 36
const MAP_H := 30
const STARTER_SCREEN_ORIGIN := Vector2i(3, 15)
const STARTER_SCREEN_SIZE := Vector2i(15, 10)

const KINDRA_GRASS_TILES := [Vector2i(0, 3), Vector2i(5, 0), Vector2i(6, 1), Vector2i(9, 5), Vector2i(14, 5)]
const KINDRA_PATH := Vector2i(1, 4)
const KINDRA_PATH_DOT := Vector2i(7, 4)
const KINDRA_VERTICAL_PATH := Vector2i(7, 1)
const KINDRA_FENCE := Vector2i(2, 8)
const KINDRA_HEDGE := Vector2i(2, 9)
const KINDRA_SIGN := Vector2i(1, 6)
const KINDRA_BOULDER := Vector2i(11, 7)
const KINDRA_TREE_LEFT := Vector2i(0, 7)
const KINDRA_TREE_RIGHT := Vector2i(14, 7)

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
			## Sparse alt tile for subtle variation (1 in 19 ≈ 5%, was 1 in 7 — too busy)
			var gt: Vector2i = MapTiles.GRASS if (x * 5 + y * 3) % 19 != 0 else MapTiles.GRASS_ALT
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
	## The starter view is a proper town screen: a broad pale road, buildings
	## above it, fence/hedge texture below it, and a clear east exit.
	for x in range(0, MAP_W):
		for y in range(18, 23):
			_set_ground(x, y, MapTiles.DIRT_PATH)
	for y in range(2, 23):
		for x in range(17, 20):
			_set_ground(x, y, MapTiles.DIRT_PATH)
	for x in range(4, 14):
		for y in range(11, 18):
			_set_ground(x, y, MapTiles.DIRT_PATH)
	for x in range(22, 31):
		for y in range(12, 18):
			_set_ground(x, y, MapTiles.DIRT_PATH)
	for x in range(8, 18):
		_set_ground(x, 24, MapTiles.DIRT_PATH)
	for y in range(23, 27):
		_set_ground(10, y, MapTiles.DIRT_PATH)
	for x in range(5, 18):
		_set_ground(x, 6, MapTiles.DIRT_PATH)
	for y in range(6, 18):
		_set_ground(12, y, MapTiles.DIRT_PATH)
	for x in range(18, 22):
		_set_ground(x, 8, MapTiles.DIRT_PATH)

	## ── Buildings — use village-atlas stamps ─────────────────────────────
	## Player's Home (3×3 small house) — south-center
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  9, 24, ground_layer, obstacle_layer)
	## Market-like hall and home visible from the starting road.
	MapTiles.stamp(MapTiles.PROP_HOUSE_BIG,    3, 10, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL, 23, 13, ground_layer, obstacle_layer)
	## The Pyre and elder house remain up the north road.
	MapTiles.stamp(MapTiles.PROP_HOUSE_BIG,   20,  3, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  4,  4, ground_layer, obstacle_layer)

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

	## GBA-town foreground fence/hedge line under the main road.
	for x in range(1, 17):
		obstacle_layer.set_cell(Vector2i(x, 25), src, MapTiles.BUSH)
	for x in range(17, 26):
		obstacle_layer.set_cell(Vector2i(x, 25), src, MapTiles.FENCE)
	for x in range(26, 35):
		obstacle_layer.set_cell(Vector2i(x, 25), src, MapTiles.BUSH)

	## ── Decorative scatter: small trees near buildings ───────────────────
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 28, 4, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 2, 24, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 14, 6, ground_layer, obstacle_layer)

	## Signs
	obstacle_layer.set_cell(Vector2i(20, 17), src, MapTiles.SIGN)  ## "East → Dustway"
	obstacle_layer.set_cell(Vector2i(18,  2), src, MapTiles.SIGN)  ## "North — Road Closed"

	_paint_full_kindra_theme()
	_stamp_generated_starter_screen()
	_clear_east_exit()


func _paint_full_kindra_theme() -> void:
	for x in MAP_W:
		for y in MAP_H:
			var tile: Vector2i = KINDRA_GRASS_TILES[(x * 3 + y * 5) % KINDRA_GRASS_TILES.size()]
			_set_kindra_ground(Vector2i(x, y), tile)
			obstacle_layer.erase_cell(Vector2i(x, y))

	## Broad town roads, using the same pale path tiles as the generated screen.
	for x in range(0, MAP_W):
		for y in range(18, 23):
			_set_kindra_ground(Vector2i(x, y), KINDRA_PATH if (x + y) % 5 != 0 else KINDRA_PATH_DOT)
	for y in range(1, 23):
		for x in range(16, 19):
			_set_kindra_ground(Vector2i(x, y), KINDRA_VERTICAL_PATH if x == 17 else KINDRA_PATH)
	for y in range(7, 18):
		for x in range(8, 13):
			_set_kindra_ground(Vector2i(x, y), KINDRA_PATH)
	for y in range(8, 18):
		for x in range(23, 29):
			_set_kindra_ground(Vector2i(x, y), KINDRA_PATH)
	for y in range(23, 27):
		for x in range(8, 13):
			_set_kindra_ground(Vector2i(x, y), KINDRA_PATH)

	## Buildings are copied from the generated town source, so the rest of
	## Kindra no longer falls back to the older placeholder building style.
	_stamp_kindra_rect(Vector2i(1, 0), Vector2i(4, 4), Vector2i(2, 9), true)
	_stamp_kindra_rect(Vector2i(10, 0), Vector2i(4, 4), Vector2i(23, 9), true)
	_stamp_kindra_rect(Vector2i(10, 0), Vector2i(4, 4), Vector2i(5, 3), true)
	_stamp_kindra_rect(Vector2i(1, 0), Vector2i(4, 4), Vector2i(20, 2), true)
	_stamp_kindra_rect(Vector2i(10, 0), Vector2i(4, 4), Vector2i(8, 24), true)

	for door in [Vector2i(4, 12), Vector2i(25, 12), Vector2i(7, 6), Vector2i(22, 5), Vector2i(10, 27)]:
		obstacle_layer.erase_cell(door)

	## Fences, hedges, trees, signs, and rocks from the same generated atlas.
	for x in range(1, 16):
		_set_kindra_obstacle(Vector2i(x, 25), KINDRA_HEDGE)
	for x in range(16, 29):
		_set_kindra_obstacle(Vector2i(x, 25), KINDRA_FENCE)
	for x in range(29, 35):
		_set_kindra_obstacle(Vector2i(x, 25), KINDRA_HEDGE)
	for x in range(0, MAP_W):
		if x < 15 or x > 19:
			_set_kindra_obstacle(Vector2i(x, 0), KINDRA_HEDGE)
			_set_kindra_obstacle(Vector2i(x, MAP_H - 1), KINDRA_HEDGE)
	for y in range(0, MAP_H):
		if y < 17 or y > 22:
			_set_kindra_obstacle(Vector2i(0, y), KINDRA_HEDGE)
		if y < 18 or y > 22:
			_set_kindra_obstacle(Vector2i(MAP_W - 1, y), KINDRA_HEDGE)

	for pos in [Vector2i(1, 14), Vector2i(34, 8), Vector2i(34, 14), Vector2i(1, 26), Vector2i(32, 24)]:
		_set_kindra_obstacle(pos, KINDRA_TREE_LEFT if pos.x < MAP_W / 2 else KINDRA_TREE_RIGHT)
	for pos in [Vector2i(14, 17), Vector2i(20, 17), Vector2i(11, 6), Vector2i(17, 2)]:
		_set_kindra_obstacle(pos, KINDRA_SIGN)
	for pos in [Vector2i(28, 16), Vector2i(13, 24), Vector2i(18, 24)]:
		_set_kindra_obstacle(pos, KINDRA_BOULDER)


func _stamp_generated_starter_screen() -> void:
	## This is the first production use of the ComfyUI background pipeline:
	## the generated 240x160 benchmark is sliced into 16x16 tiles and placed
	## into the playable map. Collision remains deterministic and invisible.
	for lx in STARTER_SCREEN_SIZE.x:
		for ly in STARTER_SCREEN_SIZE.y:
			var pos := STARTER_SCREEN_ORIGIN + Vector2i(lx, ly)
			ground_layer.set_cell(pos, MapTiles.SRC_KINDRA_SCREEN, Vector2i(lx, ly))
			obstacle_layer.erase_cell(pos)

	for lx in [0, 1, 2, 3, 4, 9, 10, 11, 12, 13, 14]:
		for ly in range(0, 4):
			_set_collision(STARTER_SCREEN_ORIGIN + Vector2i(lx, ly))
	for lx in range(0, 5):
		_set_collision(STARTER_SCREEN_ORIGIN + Vector2i(lx, 7))
	for lx in range(9, 15):
		_set_collision(STARTER_SCREEN_ORIGIN + Vector2i(lx, 7))
	for lx in range(0, 15):
		_set_collision(STARTER_SCREEN_ORIGIN + Vector2i(lx, 9))

	## Keep visible doors walkable/enterable.
	for local_door in [Vector2i(2, 3), Vector2i(13, 3)]:
		obstacle_layer.erase_cell(STARTER_SCREEN_ORIGIN + local_door)


func _clear_east_exit() -> void:
	for x in [34, 35]:
		for y in range(14, 17):
			obstacle_layer.erase_cell(Vector2i(x, y))
			ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_KINDRA_SCREEN, KINDRA_PATH)


func _set_kindra_ground(tile: Vector2i, atlas: Vector2i) -> void:
	ground_layer.set_cell(tile, MapTiles.SRC_KINDRA_SCREEN, atlas)


func _set_kindra_obstacle(tile: Vector2i, atlas: Vector2i) -> void:
	ground_layer.set_cell(tile, MapTiles.SRC_KINDRA_SCREEN, atlas)
	obstacle_layer.set_cell(tile, MapTiles.SRC_COLLISION, MapTiles.COLLISION)


func _stamp_kindra_rect(source: Vector2i, size: Vector2i, dest: Vector2i, solid: bool) -> void:
	for lx in size.x:
		for ly in size.y:
			var pos := dest + Vector2i(lx, ly)
			ground_layer.set_cell(pos, MapTiles.SRC_KINDRA_SCREEN, source + Vector2i(lx, ly))
			if solid:
				obstacle_layer.set_cell(pos, MapTiles.SRC_COLLISION, MapTiles.COLLISION)


func _set_collision(tile: Vector2i) -> void:
	obstacle_layer.set_cell(tile, MapTiles.SRC_COLLISION, MapTiles.COLLISION)


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
