## Test map: 20x20 tiles with grass, trees around the border,
## a dirt path, and an exit zone on the right edge.
## Generates the tilemap programmatically using placeholder tiles.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 20
const MAP_H := 20

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	# Generate placeholder tileset and assign to both layers
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set = tileset
	obstacle_layer.tile_set = tileset

	_build_map()
	_setup_camera_bounds()


## Build the test map layout.
func _build_map() -> void:
	# Source ID 0 is our atlas. Tile coords:
	# (0,0)=grass  (1,0)=grass_alt  (2,0)=tree  (3,0)=path  (4,0)=water
	var src := 0

	for x in MAP_W:
		for y in MAP_H:
			# Default: grass ground
			var grass_type := Vector2i(0, 0)
			# Scatter alternate grass randomly
			if (x * 7 + y * 13) % 5 == 0:
				grass_type = Vector2i(1, 0)
			ground_layer.set_cell(Vector2i(x, y), src, grass_type)

			# Border trees (except the exit gap on the right)
			var is_border := x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1
			var is_exit_gap := x == MAP_W - 1 and y >= 9 and y <= 11
			if is_border and not is_exit_gap:
				obstacle_layer.set_cell(Vector2i(x, y), src, Vector2i(2, 0))

			# Interior tree clusters
			if _is_tree_cluster(x, y):
				obstacle_layer.set_cell(Vector2i(x, y), src, Vector2i(2, 0))

			# Small pond
			if _is_pond(x, y):
				ground_layer.set_cell(Vector2i(x, y), src, Vector2i(4, 0))
				obstacle_layer.set_cell(Vector2i(x, y), src, Vector2i(4, 0))

	# Dirt path from player spawn toward exit
	for x in range(3, MAP_W):
		ground_layer.set_cell(Vector2i(x, 10), src, Vector2i(3, 0))


## Returns true for positions that should have tree clusters.
func _is_tree_cluster(x: int, y: int) -> bool:
	# Cluster 1: top-left grove
	if x >= 3 and x <= 5 and y >= 3 and y <= 5:
		return true
	# Cluster 2: bottom area
	if x >= 12 and x <= 14 and y >= 14 and y <= 16:
		return true
	# Scattered individual trees
	if x == 8 and y == 4:
		return true
	if x == 15 and y == 6:
		return true
	return false


## Returns true for positions that should be water (small pond).
func _is_pond(x: int, y: int) -> bool:
	return x >= 6 and x <= 8 and y >= 14 and y <= 16


## Pass map bounds to the player's camera.
func _setup_camera_bounds() -> void:
	var bounds := Rect2(
		Vector2.ZERO,
		Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE)
	)
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
