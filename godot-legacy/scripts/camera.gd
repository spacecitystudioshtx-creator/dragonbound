## Camera that follows the player and clamps to map bounds.
## Attach this to a Camera2D node that is a child of the player,
## or set the target_path to the player node.
##
## Map bounds are detected automatically from the parent TileMapLayer
## or can be set manually via set_bounds().

extends Camera2D

# How many pixels of padding inside the map edges
@export var margin := Vector2(0, 0)

# Map boundaries in pixels (set by the map script)
var map_rect := Rect2()
# Half the viewport size — used for clamping
var half_screen := Vector2.ZERO


func _ready() -> void:
	# Calculate half-screen from the project's viewport size
	half_screen = get_viewport_rect().size / 2.0
	position = Vector2.ZERO
	# Make this camera active
	make_current()


func _process(_delta: float) -> void:
	if map_rect.size != Vector2.ZERO:
		_clamp_to_bounds()


## Clamp the camera so it never shows area outside the map.
func _clamp_to_bounds() -> void:
	var target := get_parent() as Node2D
	var pos := target.global_position if target else global_position
	var min_x := map_rect.position.x + half_screen.x + margin.x
	var max_x := map_rect.end.x - half_screen.x - margin.x
	var min_y := map_rect.position.y + half_screen.y + margin.y
	var max_y := map_rect.end.y - half_screen.y - margin.y

	if min_x > max_x:
		pos.x = map_rect.get_center().x
	else:
		pos.x = clamp(pos.x, min_x, max_x)

	if min_y > max_y:
		pos.y = map_rect.get_center().y
	else:
		pos.y = clamp(pos.y, min_y, max_y)

	global_position = pos


## Set the map boundaries for camera clamping.
## Call this from the map script when the map loads.
func set_bounds(rect: Rect2) -> void:
	map_rect = rect
	var player := get_parent()
	if player and player.has_method("set_map_bounds"):
		player.set_map_bounds(rect)
