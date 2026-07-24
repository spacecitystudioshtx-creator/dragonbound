## Kindra — Starter town. Volcanic hot spring village.
## Buildings: Player's Home, The Pyre (elder gives starter inside), Elder's House,
## Supply Shop, NPC house. Hot spring pool in the southeast.
## Exits: East → Dustway Route 1, North → blocked until trial complete.

extends Node2D

const TILE_SIZE := 16
const MAP_W := 36
const MAP_H := 30
const EAST_EXIT_ROWS  := [14, 15, 16]   ## Row indices of east → Dustway opening
const NORTH_EXIT_COLS := [17, 18, 19]   ## Col indices of north → The Scald opening

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	var tileset := PlaceholderTileset.create_placeholder_tileset()
	ground_layer.tile_set = tileset
	obstacle_layer.tile_set = tileset
	_build_map()
	_spawn_npcs()
	_add_interactive_zones()
	_add_perimeter_walls()
	_setup_camera_bounds()

	if not GameState.has_starter:
		GameState.give_starter("ember")


func _build_map() -> void:
	var src := MapTiles.SRC_GROUND

	## ── Ground fill ─────────────────────────────────────────────────────────
	for x in MAP_W:
		for y in MAP_H:
			var gt: Vector2i = MapTiles.GRASS if (x + y * 3) % 7 != 0 else MapTiles.GRASS_ALT
			ground_layer.set_cell(Vector2i(x, y), src, gt)

	## ── Border: tree-line around the map edge ───────────────────────────────────
	## Collision is sealed by the invisible StaticBody2D perimeter wall added in
	## _add_perimeter_walls(). Trees give the natural Pokémon forest-edge look.
	## Skip any position that overlaps an exit gap.
	var bx := 0
	while bx < MAP_W - 1:        ## top border
		if not (bx in NORTH_EXIT_COLS or (bx + 1) in NORTH_EXIT_COLS):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, bx, 0, ground_layer, obstacle_layer)
		bx += 2
	bx = 0
	while bx < MAP_W - 1:        ## bottom border
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, bx, MAP_H - 2, ground_layer, obstacle_layer)
		bx += 2
	var by := 0
	while by < MAP_H - 1:        ## left border
		MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 0, by, ground_layer, obstacle_layer)
		by += 2
	by = 0
	while by < MAP_H - 1:        ## right border (skip east exit rows)
		if not (by in EAST_EXIT_ROWS or (by + 1) in EAST_EXIT_ROWS):
			MapTiles.stamp(MapTiles.PROP_TREE_SMALL, MAP_W - 2, by, ground_layer, obstacle_layer)
		by += 2

	## North exit: sign blocks passage until trial complete
	for xc in NORTH_EXIT_COLS:
		obstacle_layer.set_cell(Vector2i(xc, 1), src, MapTiles.SIGN)

	## ── Path network ─────────────────────────────────────────────────────────
	for x in range(2, MAP_W):
		_set_ground(x, 15, MapTiles.DIRT_PATH)
	for y in range(2, MAP_H - 1):
		_set_ground(18, y, MapTiles.DIRT_PATH)
	for x in range(8, 19):
		_set_ground(x, 23, MapTiles.DIRT_PATH)
	for y in range(26, 29):
		_set_ground(10, y, MapTiles.DIRT_PATH)  ## south approach to Player's Home door
	for y in range(10, 16):
		_set_ground(26, y, MapTiles.DIRT_PATH)
	for y in range(5, 16):
		_set_ground(12, y, MapTiles.DIRT_PATH)
	for x in range(18, 24):
		_set_ground(x, 8, MapTiles.DIRT_PATH)
	## Path up to Pyre door
	for y in range(9, 15):
		_set_ground(21, y, MapTiles.DIRT_PATH)

	## ── Buildings ────────────────────────────────────────────────────────────
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  9, 24, ground_layer, obstacle_layer)  ## Player's Home
	MapTiles.stamp(MapTiles.PROP_HOUSE_BIG,   20,  3, ground_layer, obstacle_layer)  ## The Pyre
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  4,  4, ground_layer, obstacle_layer)  ## Elder's House
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL, 24, 10, ground_layer, obstacle_layer)  ## Supply Shop
	MapTiles.stamp(MapTiles.PROP_HOUSE_SMALL,  3, 11, ground_layer, obstacle_layer)  ## NPC House

	## ── Fix door tiles ───────────────────────────────────────────────────────
	## Active doors: the atlas door tile sits on ground_layer (non-solid).
	## Add DIRT_PATH one step south so the approach path is obvious.
	_set_ground(21, 8,  MapTiles.DIRT_PATH)  ## The Pyre — south approach step
	_set_ground(10, 27, MapTiles.DIRT_PATH)  ## Player's Home — south approach step
	## Block locked building doors so the player can't enter empty buildings.
	obstacle_layer.set_cell(Vector2i(5, 6),   src, MapTiles.FENCE)  ## Elder's House
	obstacle_layer.set_cell(Vector2i(25, 12), src, MapTiles.FENCE)  ## Supply Shop
	obstacle_layer.set_cell(Vector2i(4, 13),  src, MapTiles.FENCE)  ## NPC House

	## ── Garden — tall grass for starter encounters ───────────────────────────
	for x in range(14, 18):
		for y in range(24, 26):
			_set_ground(x, y, MapTiles.TALL_GRASS)
	_set_ground(13, 24, MapTiles.FLOWER)
	_set_ground(13, 25, MapTiles.FLOWER)
	_set_ground(18, 24, MapTiles.FLOWER)
	_set_ground(18, 25, MapTiles.FLOWER)

	## ── Hot spring pool (southeast) ──────────────────────────────────────────
	## Water is purely visual on ground_layer; an invisible StaticBody2D blocks entry.
	for x in range(28, 33):
		for y in range(25, 28):
			_set_ground(x, y, MapTiles.WATER)
	add_child(_make_static_box(
		Vector2(28 * TILE_SIZE, 25 * TILE_SIZE),
		Vector2(5 * TILE_SIZE,  3 * TILE_SIZE)))

	## ── Decorative trees ─────────────────────────────────────────────────────
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 28, 4,  ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 2,  24, ground_layer, obstacle_layer)
	MapTiles.stamp(MapTiles.PROP_TREE_SMALL, 14, 6,  ground_layer, obstacle_layer)

	## ── Signs ────────────────────────────────────────────────────────────────
	obstacle_layer.set_cell(Vector2i(19, 15), src, MapTiles.SIGN)  ## East → Dustway
	obstacle_layer.set_cell(Vector2i(18,  2), src, MapTiles.SIGN)  ## North — Closed


func _spawn_npcs() -> void:
	## Elder Moss has moved INSIDE The Pyre — approach the door to enter.
	NPCSpawner.spawn(self, 7,  22, Vector2.RIGHT, "kindra", "neighbor_fen")
	NPCSpawner.spawn(self, 25, 14, Vector2.DOWN,  "kindra", "shopkeeper")
	NPCSpawner.spawn(self, 33, 15, Vector2.LEFT,  "kindra", "rival_sable")


func _add_interactive_zones() -> void:
	## ── Door zones: walk onto step tile → enter building ─────────────────────
	_add_door_zone(21, 8,
		"res://scenes/maps/pyre_interior.tscn",
		Vector2(88, 120))   ## spawn inside Pyre at tile (5,7)

	_add_door_zone(10, 26,
		"res://scenes/maps/player_home.tscn",
		Vector2(72, 104))   ## spawn inside Home at tile (4,6)

	## ── Sign read zones: press A facing sign ─────────────────────────────────
	_add_sign_zone(19, 15, "kindra", "sign_east")
	_add_sign_zone(18,  2, "kindra", "sign_north")

	## ── Locked door prompts: press A facing a locked door ────────────────────
	_add_sign_zone(5,  7,  "kindra", "door_locked")  ## Elder's House (1 south of blocked door)
	_add_sign_zone(25, 13, "kindra", "door_locked")  ## Supply Shop
	_add_sign_zone(4,  14, "kindra", "door_locked")  ## NPC House


func _add_door_zone(tile_x: int, tile_y: int, target: String, spawn: Vector2) -> void:
	var area := Area2D.new()
	area.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE / 2,
							tile_y * TILE_SIZE + TILE_SIZE / 2)
	area.collision_layer = 4
	area.collision_mask  = 1
	var cshape := CollisionShape2D.new()
	var rect   := RectangleShape2D.new()
	rect.size  = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	cshape.shape = rect
	area.add_child(cshape)
	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			SceneTransition.change_scene(target, spawn)
	)
	add_child(area)


func _add_sign_zone(tile_x: int, tile_y: int, df: String, nid: String) -> void:
	var area := Area2D.new()
	area.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE / 2,
							tile_y * TILE_SIZE + TILE_SIZE / 2)
	area.add_to_group("interactable")
	area.set_meta("dialog_file", df)
	area.set_meta("node_id",     nid)
	var cshape := CollisionShape2D.new()
	var shape  := CircleShape2D.new()
	shape.radius = float(TILE_SIZE) * 0.55
	cshape.shape = shape
	area.add_child(cshape)
	add_child(area)


func _set_ground(x: int, y: int, tile: Vector2i) -> void:
	ground_layer.set_cell(Vector2i(x, y), MapTiles.SRC_GROUND, tile)


## Invisible physics blocker for water bodies — no tiles on obstacle_layer so
## nothing renders visually.
func _make_static_box(top_left: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask  = 0
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = size
	cs.position  = top_left + size * 0.5
	cs.shape     = rect
	body.add_child(cs)
	return body


## Invisible StaticBody2D wall around the entire map, leaving only the intended exits open.
## This seals trunk-base gaps in border trees so the player can never walk off-screen.
func _add_perimeter_walls() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask  = 0
	var W  := float(MAP_W * TILE_SIZE)
	var H  := float(MAP_H * TILE_SIZE)
	var T  := float(TILE_SIZE)
	var nx0 := float(NORTH_EXIT_COLS[0])      * T
	var nx1 := float(NORTH_EXIT_COLS[-1] + 1) * T
	var ey0 := float(EAST_EXIT_ROWS[0])       * T
	var ey1 := float(EAST_EXIT_ROWS[-1] + 1)  * T
	_wall_seg(wall, 0.0,     0.0,     nx0,     T)         ## top-left of north gap
	_wall_seg(wall, nx1,     0.0,     W - nx1, T)         ## top-right of north gap
	_wall_seg(wall, 0.0,     H - T,   W,       T)         ## bottom
	_wall_seg(wall, 0.0,     0.0,     T,       H)         ## left
	_wall_seg(wall, W - T,   0.0,     T,       ey0)       ## right-top of east gap
	_wall_seg(wall, W - T,   ey1,     T,       H - ey1)   ## right-bottom of east gap
	add_child(wall)


func _wall_seg(parent: StaticBody2D, x: float, y: float, w: float, h: float) -> void:
	if w <= 0.0 or h <= 0.0:
		return
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size   = Vector2(w, h)
	cs.position = Vector2(x + w * 0.5, y + h * 0.5)
	cs.shape    = rect
	parent.add_child(cs)


func _setup_camera_bounds() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE))
	await get_tree().process_frame
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam.has_method("set_bounds"):
			cam.set_bounds(bounds)
