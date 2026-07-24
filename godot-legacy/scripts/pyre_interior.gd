## The Pyre — interior of Kindra's sacred drake shrine.
## Elder Moss lives here and gives the player their starter drake.
## Layout: 12×9 tiles. Bottom-center is the door back to Kindra.

extends Node2D

const TILE_SIZE := 16
const MAP_W     := 12
const MAP_H     := 9

## Kindra tile coords: player exits to 1 south of The Pyre door
const EXIT_TO_KINDRA_POS := Vector2(21 * 16 + 8, 9 * 16 + 8)

@onready var ground_layer:   TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set   = tileset
	obstacle_layer.tile_set = tileset
	_build_room()
	_spawn_npcs()
	_add_exit_zone()
	_setup_camera_bounds()


func _build_room() -> void:
	var src := MapTiles.SRC_GROUND

	## ── Warm stone floor throughout ─────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			ground_layer.set_cell(Vector2i(x, y), src, MapTiles.SAND_ALT)

	## ── Walls: top 2 rows, left/right columns, bottom except door gap ────────
	for x in MAP_W:
		obstacle_layer.set_cell(Vector2i(x, 0), src, MapTiles.FENCE)
		obstacle_layer.set_cell(Vector2i(x, 1), src, MapTiles.FENCE)
	for y in range(2, MAP_H):
		obstacle_layer.set_cell(Vector2i(0, y),          src, MapTiles.FENCE)
		obstacle_layer.set_cell(Vector2i(MAP_W - 1, y),  src, MapTiles.FENCE)
	## Bottom wall — leave cols 4-7 open as the doorway
	for x in MAP_W:
		if not x in range(4, 8):
			obstacle_layer.set_cell(Vector2i(x, MAP_H - 1), src, MapTiles.FENCE)

	## ── Door step (ground tile at doorway) ──────────────────────────────────
	for x in range(4, 8):
		_set_ground(x, MAP_H - 1, MapTiles.DIRT_PATH)

	## ── Sacred fire pedestal: center of room ────────────────────────────────
	obstacle_layer.set_cell(Vector2i(5, 4), src, MapTiles.ROCK)
	obstacle_layer.set_cell(Vector2i(6, 4), src, MapTiles.ROCK)
	_set_ground(5, 4, MapTiles.FLOWER)
	_set_ground(6, 4, MapTiles.FLOWER)

	## ── Bookshelves / shelves along top wall ────────────────────────────────
	for x in range(2, 5):
		obstacle_layer.set_cell(Vector2i(x, 2), src, MapTiles.ROCK)
	for x in range(7, 10):
		obstacle_layer.set_cell(Vector2i(x, 2), src, MapTiles.ROCK)

	## ── Decorative flowers along side walls ─────────────────────────────────
	_set_ground(1, 5, MapTiles.FLOWER)
	_set_ground(1, 6, MapTiles.FLOWER)
	_set_ground(MAP_W - 2, 5, MapTiles.FLOWER)
	_set_ground(MAP_W - 2, 6, MapTiles.FLOWER)

	## ── Floor accent: path from door to elder ───────────────────────────────
	for y in range(3, MAP_H - 1):
		_set_ground(5, y, MapTiles.SAND)
		_set_ground(6, y, MapTiles.SAND)


func _spawn_npcs() -> void:
	NPCSpawner.spawn(self, 5, 3, Vector2.DOWN, "pyre_interior", "elder_moss")


func _add_exit_zone() -> void:
	## Trigger fires when player steps into the doorway (bottom center)
	var area := Area2D.new()
	area.name            = "ExitZone"
	area.position        = Vector2(6 * TILE_SIZE, (MAP_H - 1) * TILE_SIZE + TILE_SIZE / 2)
	area.collision_layer = 4
	area.collision_mask  = 1

	var cshape := CollisionShape2D.new()
	var rect   := RectangleShape2D.new()
	rect.size  = Vector2(TILE_SIZE * 4, TILE_SIZE)
	cshape.shape = rect
	area.add_child(cshape)

	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			SceneTransition.change_scene(
				"res://scenes/maps/kindra_town.tscn", EXIT_TO_KINDRA_POS)
	)
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
