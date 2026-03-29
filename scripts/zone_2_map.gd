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
	var src := 0

	for x in MAP_W:
		for y in MAP_H:
			# Ground: mostly alternate grass for visual difference
			var grass_type := Vector2i(1, 0) if (x + y) % 3 != 0 else Vector2i(0, 0)
			ground_layer.set_cell(Vector2i(x, y), src, grass_type)

			# Border trees (gap on left for entrance)
			var is_border := x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1
			var is_entrance := x == 0 and y >= 9 and y <= 11
			if is_border and not is_entrance:
				obstacle_layer.set_cell(Vector2i(x, y), src, Vector2i(2, 0))

	# Path from entrance
	for x in range(0, 10):
		ground_layer.set_cell(Vector2i(x, 10), src, Vector2i(3, 0))


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
