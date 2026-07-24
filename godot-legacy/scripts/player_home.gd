## Player's Home interior — cozy bedroom with a save computer.
## Layout: 10×8 tiles. Bottom-center is the door back to Kindra.

extends Node2D

const TILE_SIZE := 16
const MAP_W     := 10
const MAP_H     := 8

## Kindra tile coords: player exits to 1 south of Player's Home door
const EXIT_TO_KINDRA_POS := Vector2(10 * 16 + 8, 27 * 16 + 8)

@onready var ground_layer:   TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set   = tileset
	obstacle_layer.tile_set = tileset
	_build_room()
	_add_exit_zone()
	_add_save_computer()
	_setup_camera_bounds()


func _build_room() -> void:
	var src := MapTiles.SRC_GROUND

	## ── Earthy warm floor ───────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			ground_layer.set_cell(Vector2i(x, y), src, MapTiles.DIRT_ALT)

	## ── Walls: top 2 rows, left/right columns, bottom except door ────────────
	for x in MAP_W:
		obstacle_layer.set_cell(Vector2i(x, 0), src, MapTiles.FENCE)
		obstacle_layer.set_cell(Vector2i(x, 1), src, MapTiles.FENCE)
	for y in range(2, MAP_H):
		obstacle_layer.set_cell(Vector2i(0, y),         src, MapTiles.FENCE)
		obstacle_layer.set_cell(Vector2i(MAP_W - 1, y), src, MapTiles.FENCE)
	for x in MAP_W:
		if not x in [4, 5]:
			obstacle_layer.set_cell(Vector2i(x, MAP_H - 1), src, MapTiles.FENCE)

	## ── Door step ────────────────────────────────────────────────────────────
	_set_ground(4, MAP_H - 1, MapTiles.DIRT_PATH)
	_set_ground(5, MAP_H - 1, MapTiles.DIRT_PATH)

	## ── Bed (top-left, 2×2 tiles) — warm sand color ─────────────────────────
	for dx in 2:
		for dy in 2:
			_set_ground(2 + dx, 2 + dy, MapTiles.SAND)
	## Bed frame/pillow accent
	_set_ground(2, 2, MapTiles.SAND_ALT)
	_set_ground(3, 2, MapTiles.SAND_ALT)
	## Bed is solid (can't walk on it)
	obstacle_layer.set_cell(Vector2i(2, 2), src, MapTiles.STUMP)
	obstacle_layer.set_cell(Vector2i(3, 2), src, MapTiles.STUMP)

	## ── Desk / computer (top-right) ─────────────────────────────────────────
	obstacle_layer.set_cell(Vector2i(7, 2), src, MapTiles.STUMP)
	obstacle_layer.set_cell(Vector2i(8, 2), src, MapTiles.STUMP)

	## ── Bookshelf along top wall ─────────────────────────────────────────────
	obstacle_layer.set_cell(Vector2i(4, 1), src, MapTiles.ROCK)
	obstacle_layer.set_cell(Vector2i(5, 1), src, MapTiles.ROCK)
	obstacle_layer.set_cell(Vector2i(6, 1), src, MapTiles.ROCK)

	## ── Rug / floor accent ───────────────────────────────────────────────────
	for x in range(3, 8):
		_set_ground(x, 5, MapTiles.DIRT_PATH)


func _add_exit_zone() -> void:
	var area := Area2D.new()
	area.name            = "ExitZone"
	area.position        = Vector2(4 * TILE_SIZE + TILE_SIZE, (MAP_H - 1) * TILE_SIZE + TILE_SIZE / 2)
	area.collision_layer = 4
	area.collision_mask  = 1

	var cshape := CollisionShape2D.new()
	var rect   := RectangleShape2D.new()
	rect.size  = Vector2(TILE_SIZE * 2, TILE_SIZE)
	cshape.shape = rect
	area.add_child(cshape)

	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			SceneTransition.change_scene(
				"res://scenes/maps/kindra_town.tscn", EXIT_TO_KINDRA_POS)
	)
	add_child(area)


func _add_save_computer() -> void:
	## Interactable Area2D in front of the desk — press A to save
	var area := Area2D.new()
	area.name     = "SaveComputer"
	area.position = Vector2(7 * TILE_SIZE + TILE_SIZE, 3 * TILE_SIZE + TILE_SIZE / 2)
	area.add_to_group("interactable")
	area.set_meta("dialog_file", "player_home")
	area.set_meta("node_id",     "save_computer")

	var cshape := CollisionShape2D.new()
	var rect   := RectangleShape2D.new()
	rect.size  = Vector2(TILE_SIZE * 2, TILE_SIZE)
	cshape.shape = rect
	area.add_child(cshape)
	add_child(area)


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var cam := p.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
