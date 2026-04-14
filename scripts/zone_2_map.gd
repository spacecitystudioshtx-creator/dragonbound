## Zone 2: A second small test map to demonstrate scene transitions.
## The player arrives from the left edge and can exit back via the left.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 20
const MAP_H := 20

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

	## Ground fill
	for x in MAP_W:
		for y in MAP_H:
			var gt: Vector2i = MapTiles.GRASS_ALT if (x + y) % 3 != 0 else MapTiles.GRASS
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## Border trees (pair-stamped); leave a 3-row entrance on the west
	var west_entrance := range(9, 12)
	for x in range(0, MAP_W, 2):
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, 0, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, x, MAP_H - 2, ground_layer, obstacle_layer)
	for y in range(0, MAP_H, 2):
		if not (y in west_entrance):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 0, y, ground_layer, obstacle_layer)
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, MAP_W - 2, y, ground_layer, obstacle_layer)

	## Path from entrance across the zone
	for x in range(0, MAP_W - 2):
		_set_ground(x, 10, MapTiles.DIRT_PATH)

	## Scattered decorations
	MapTiles.stamp(MapTiles.PROP_TREE_BIG, 6, 4, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 14, 14, ground_layer, obstacle_layer)
	obstacle_layer.set_cell(Vector2i(4, 14), src, MapTiles.ROCK)
	obstacle_layer.set_cell(Vector2i(13, 6), src, MapTiles.STUMP)


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
