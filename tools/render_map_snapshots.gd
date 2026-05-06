extends SceneTree

const TILE_SIZE := 16
const VIEW_SIZE := Vector2i(240, 160)
const OUT_DIR := "res://art/generated/screenshots"
const PLAYER_SHEET := "res://art/player/kindra_trainer_sheet.png"

const SHOTS := [
	{"scene": "res://scenes/maps/kindra_town.tscn", "name": "kindra_starter", "center": Vector2(168, 328), "size": Vector2i(36, 30)},
	{"scene": "res://scenes/maps/kindra_town.tscn", "name": "kindra_right_house", "center": Vector2(264, 296), "size": Vector2i(36, 30)},
	{"scene": "res://scenes/maps/kindra_town.tscn", "name": "kindra_east_exit", "center": Vector2(552, 248), "size": Vector2i(36, 30)},
	{"scene": "res://scenes/maps/kindra_home_interior.tscn", "name": "home_interior", "center": Vector2(120, 120), "size": Vector2i(15, 10)},
	{"scene": "res://scenes/maps/kindra_shop_interior.tscn", "name": "shop_interior", "center": Vector2(120, 120), "size": Vector2i(15, 10)},
	{"scene": "res://scenes/maps/kindra_house_interior.tscn", "name": "right_house_interior", "center": Vector2(120, 120), "size": Vector2i(15, 10)},
	{"scene": "res://scenes/maps/kindra_pyre_interior.tscn", "name": "pyre_interior", "center": Vector2(120, 120), "size": Vector2i(15, 10)},
	{"scene": "res://scenes/maps/kindra_elder_interior.tscn", "name": "elder_interior", "center": Vector2(120, 120), "size": Vector2i(15, 10)},
	{"scene": "res://scenes/maps/dustway_route.tscn", "name": "dustway_entry", "center": Vector2(40, 656), "size": Vector2i(22, 48)},
]

var _frame := 0
var _scene: Node = null
var _shot: Dictionary
var _index := 0


func _initialize() -> void:
	DirAccess.open("res://").make_dir_recursive("art/generated/screenshots")
	_load_next()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	_render_current()
	_index += 1
	if _index >= SHOTS.size():
		quit(0)
	else:
		_load_next()
	return false


func _load_next() -> void:
	if _scene:
		_scene.queue_free()
	_scene = null
	_frame = 0
	_shot = SHOTS[_index]
	var packed := load(String(_shot["scene"]))
	if packed == null:
		push_error("could not load " + String(_shot["scene"]))
		quit(1)
		return
	_scene = packed.instantiate()
	root.add_child(_scene)


func _render_current() -> void:
	var ground: TileMapLayer = _scene.get_node_or_null("GroundLayer")
	var obstacles: TileMapLayer = _scene.get_node_or_null("ObstacleLayer")
	if ground == null or obstacles == null:
		push_error("missing tile layers in " + String(_shot["scene"]))
		quit(1)
		return

	var center: Vector2 = _shot["center"]
	var map_tiles: Vector2i = _shot["size"]
	var map_size := Vector2(map_tiles * TILE_SIZE)
	var top_left := center - Vector2(VIEW_SIZE) / 2.0
	top_left.x = clampf(top_left.x, 0, maxf(0, map_size.x - VIEW_SIZE.x))
	top_left.y = clampf(top_left.y, 0, maxf(0, map_size.y - VIEW_SIZE.y))

	var out := Image.create(VIEW_SIZE.x, VIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 1))
	_draw_layer(out, ground, top_left)
	_draw_layer(out, obstacles, top_left)
	_draw_player(out, center, top_left)
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(String(_shot["name"]) + ".png"))
	out.save_png(path)
	print("saved ", path)


func _draw_layer(out: Image, layer: TileMapLayer, top_left: Vector2) -> void:
	var first := Vector2i(floori(top_left.x / TILE_SIZE), floori(top_left.y / TILE_SIZE))
	var last := Vector2i(ceili((top_left.x + VIEW_SIZE.x) / TILE_SIZE), ceili((top_left.y + VIEW_SIZE.y) / TILE_SIZE))
	for tx in range(first.x, last.x + 1):
		for ty in range(first.y, last.y + 1):
			var cell := Vector2i(tx, ty)
			var source_id := layer.get_cell_source_id(cell)
			if source_id == -1:
				continue
			if source_id == MapTiles.SRC_COLLISION:
				continue
			var atlas := layer.get_cell_atlas_coords(cell)
			var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
			if source == null or source.texture == null:
				continue
			var src_img := source.texture.get_image()
			if src_img.get_format() != Image.FORMAT_RGBA8:
				src_img.convert(Image.FORMAT_RGBA8)
			var src_rect := Rect2i(atlas * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE))
			var dst := Vector2i(roundi(tx * TILE_SIZE - top_left.x), roundi(ty * TILE_SIZE - top_left.y))
			out.blend_rect(src_img, src_rect, dst)


func _draw_player(out: Image, center: Vector2, top_left: Vector2) -> void:
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(PLAYER_SHEET)) != OK:
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var dst := Vector2i(roundi(center.x - top_left.x - 8), roundi(center.y - top_left.y - 8))
	out.blend_rect(img, Rect2i(0, 0, 16, 16), dst)
