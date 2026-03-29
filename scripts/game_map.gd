## Base script for all game maps.
## Attach to the root Node2D of each map scene.
## Automatically calculates map bounds from the TileMapLayer
## and passes them to the player's camera.

extends Node2D

# Tile size in pixels
const TILE_SIZE := 16

# Map dimensions in tiles (set per-map)
@export var map_width := 20
@export var map_height := 20


func _ready() -> void:
	# Calculate pixel bounds from tile dimensions
	var bounds := Rect2(
		Vector2.ZERO,
		Vector2(map_width * TILE_SIZE, map_height * TILE_SIZE)
	)

	# Find the player's camera and set bounds
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
