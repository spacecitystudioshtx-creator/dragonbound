## GBA-style Kindra building interiors.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 15
const MAP_H := 10

@export var return_spawn := Vector2(168, 328)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var exit_zone: Area2D = $ExitToKindra
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set = tileset
	obstacle_layer.tile_set = tileset
	_build_room()
	exit_zone.spawn_position = return_spawn
	_setup_camera_bounds()


func _build_room() -> void:
	_stamp_room_screen(_room_source())
	_build_room_collision()


func _room_source() -> int:
	var room_name := name.to_lower()
	if "shop" in room_name:
		return MapTiles.SRC_ROOM_SHOP
	if "pyre" in room_name:
		return MapTiles.SRC_ROOM_PYRE
	if "elder" in room_name:
		return MapTiles.SRC_ROOM_ELDER
	if "house" in room_name:
		return MapTiles.SRC_ROOM_HOUSE
	return MapTiles.SRC_ROOM_HOME


func _stamp_room_screen(source_id: int) -> void:
	for x in MAP_W:
		for y in MAP_H:
			ground_layer.set_cell(Vector2i(x, y), source_id, Vector2i(x, y))
			obstacle_layer.erase_cell(Vector2i(x, y))


func _build_room_collision() -> void:
	for x in MAP_W:
		_collision(Vector2i(x, 0))
		_collision(Vector2i(x, 1))
		_collision(Vector2i(x, MAP_H - 1))
	for y in MAP_H:
		_collision(Vector2i(0, y))
		_collision(Vector2i(MAP_W - 1, y))

	obstacle_layer.erase_cell(Vector2i(7, MAP_H - 1))
	obstacle_layer.erase_cell(Vector2i(7, MAP_H - 2))

	var room_name := name.to_lower()
	if "shop" in room_name:
		for x in range(3, 12):
			_collision(Vector2i(x, 3))
		for pos in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(4, 6), Vector2i(10, 6), Vector2i(2, 7)]:
			_collision(pos)
	elif "pyre" in room_name:
		for pos in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(7, 3), Vector2i(6, 5), Vector2i(8, 5), Vector2i(3, 7), Vector2i(11, 7)]:
			_collision(pos)
	elif "elder" in room_name:
		for pos in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(11, 2), Vector2i(6, 4), Vector2i(7, 4), Vector2i(5, 5), Vector2i(9, 5), Vector2i(12, 7)]:
			_collision(pos)
	elif "house" in room_name:
		for pos in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(11, 2), Vector2i(6, 5), Vector2i(7, 5), Vector2i(5, 6), Vector2i(9, 6), Vector2i(12, 6)]:
			_collision(pos)
	else:
		for pos in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(6, 5), Vector2i(5, 6), Vector2i(9, 6), Vector2i(12, 6)]:
			_collision(pos)


func _build_home() -> void:
	_rug(Rect2i(5, 5, 5, 3))
	_solid(Vector2i(2, 2), MapTiles.INT_TV)
	_solid(Vector2i(3, 2), MapTiles.INT_PC)
	_solid(Vector2i(10, 2), MapTiles.INT_BED)
	_solid(Vector2i(11, 2), MapTiles.INT_BED)
	_solid(Vector2i(6, 5), MapTiles.INT_TABLE)
	_solid(Vector2i(5, 6), MapTiles.INT_CHAIR)
	_solid(Vector2i(9, 6), MapTiles.INT_CHAIR)
	_solid(Vector2i(12, 6), MapTiles.INT_PLANT)


func _build_house() -> void:
	_rug(Rect2i(5, 5, 5, 2))
	_solid(Vector2i(2, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(3, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(11, 2), MapTiles.INT_TV)
	_solid(Vector2i(6, 5), MapTiles.INT_TABLE)
	_solid(Vector2i(7, 5), MapTiles.INT_TABLE)
	_solid(Vector2i(5, 6), MapTiles.INT_CHAIR)
	_solid(Vector2i(9, 6), MapTiles.INT_CHAIR)
	_solid(Vector2i(12, 6), MapTiles.INT_PLANT)


func _build_shop() -> void:
	for x in range(3, 12):
		_solid(Vector2i(x, 3), MapTiles.INT_COUNTER)
	_solid(Vector2i(2, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(12, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(4, 6), MapTiles.INT_TABLE)
	_solid(Vector2i(10, 6), MapTiles.INT_TABLE)
	_solid(Vector2i(2, 7), MapTiles.INT_PLANT)
	_rug(Rect2i(6, 6, 3, 2))


func _build_pyre() -> void:
	_rug(Rect2i(4, 4, 7, 4))
	_solid(Vector2i(2, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(12, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(7, 3), MapTiles.INT_TABLE)
	_solid(Vector2i(6, 5), MapTiles.INT_CHAIR)
	_solid(Vector2i(8, 5), MapTiles.INT_CHAIR)
	_solid(Vector2i(3, 7), MapTiles.INT_PLANT)
	_solid(Vector2i(11, 7), MapTiles.INT_PLANT)


func _build_elder() -> void:
	_solid(Vector2i(3, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(4, 2), MapTiles.INT_SHELF)
	_solid(Vector2i(11, 2), MapTiles.INT_STAIRS)
	_solid(Vector2i(6, 4), MapTiles.INT_TABLE)
	_solid(Vector2i(7, 4), MapTiles.INT_TABLE)
	_solid(Vector2i(5, 5), MapTiles.INT_CHAIR)
	_solid(Vector2i(9, 5), MapTiles.INT_CHAIR)
	_solid(Vector2i(12, 7), MapTiles.INT_PLANT)
	_rug(Rect2i(5, 6, 5, 2))


func _rug(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			_ground(Vector2i(x, y), MapTiles.INT_RUG)


func _ground(pos: Vector2i, tile: Vector2i) -> void:
	ground_layer.set_cell(pos, MapTiles.SRC_INTERIOR, tile)


func _solid(pos: Vector2i, tile: Vector2i) -> void:
	ground_layer.set_cell(pos, MapTiles.SRC_INTERIOR, tile)
	obstacle_layer.set_cell(pos, MapTiles.SRC_COLLISION, MapTiles.COLLISION)


func _collision(pos: Vector2i) -> void:
	obstacle_layer.set_cell(pos, MapTiles.SRC_COLLISION, MapTiles.COLLISION)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
