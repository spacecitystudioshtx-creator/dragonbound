## Generates placeholder tile textures at runtime.
## Styled after Pokémon FireRed — seamless grass, layered trees,
## buildings, roofs, paths, water, fences, and signs.

extends Node

const TILE_SIZE := 16

## ── Palette ─────────────────────────────────────────────────────────────────
## Grass
const G1 := Color(0.31, 0.64, 0.22)
const G2 := Color(0.36, 0.70, 0.27)
const G3 := Color(0.25, 0.54, 0.17)
const G4 := Color(0.28, 0.58, 0.19)

## Trees
const TL  := Color(0.18, 0.50, 0.14)
const TD  := Color(0.10, 0.34, 0.08)
const TK  := Color(0.06, 0.22, 0.04)
const TB  := Color(0.42, 0.28, 0.12)

## Path
const P1 := Color(0.78, 0.68, 0.48)
const P2 := Color(0.85, 0.76, 0.56)
const P3 := Color(0.65, 0.55, 0.38)
const P4 := Color(0.58, 0.48, 0.32)

## Water
const W1 := Color(0.22, 0.50, 0.85)
const W2 := Color(0.35, 0.62, 0.92)
const W3 := Color(0.14, 0.38, 0.70)
const W4 := Color(0.42, 0.72, 0.96)

## Buildings
const BW  := Color(0.88, 0.86, 0.82)   ## Wall white
const BWD := Color(0.72, 0.70, 0.66)   ## Wall shadow
const BR  := Color(0.82, 0.32, 0.18)   ## Roof red/orange
const BRD := Color(0.62, 0.22, 0.12)   ## Roof dark
const BDR := Color(0.38, 0.22, 0.10)   ## Door brown
const BWN := Color(0.55, 0.72, 0.88)   ## Window blue
const BWF := Color(0.38, 0.55, 0.72)   ## Window frame

## Tall grass (encounters)
const TG1 := Color(0.22, 0.52, 0.14)
const TG2 := Color(0.30, 0.62, 0.20)

## Fence / sign
const FN  := Color(0.60, 0.45, 0.25)
const FND := Color(0.42, 0.30, 0.15)

## Flowers
const FL1 := Color(0.95, 0.85, 0.20)
const FL2 := Color(0.95, 0.40, 0.30)

## Tile indices:
## 0=grass, 1=grass_alt, 2=tree, 3=path, 4=water,
## 5=building_wall, 6=roof, 7=door, 8=tall_grass, 9=fence/sign


static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 2)

	var cols := 10
	var img := Image.create(TILE_SIZE * cols, TILE_SIZE, false, Image.FORMAT_RGBA8)

	_draw_grass(img, 0)
	_draw_grass_alt(img, 1)
	_draw_tree(img, 2)
	_draw_path(img, 3)
	_draw_water(img, 4)
	_draw_wall(img, 5)
	_draw_roof(img, 6)
	_draw_door(img, 7)
	_draw_tall_grass(img, 8)
	_draw_fence(img, 9)

	var tex := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for i in cols:
		source.create_tile(Vector2i(i, 0))

	## Collision polygon (full tile)
	var poly := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	## Blocking tiles: tree(2), water(4), wall(5), roof(6), fence(9)
	for idx in [2, 4, 5, 6, 9]:
		source.get_tile_data(Vector2i(idx, 0), 0).add_collision_polygon(0)
		source.get_tile_data(Vector2i(idx, 0), 0).set_collision_polygon_points(0, 0, poly)

	tileset.add_source(source)
	return tileset


# ──────────────────────────────────────────────────────────────────────────────
# Tile drawing functions
# ──────────────────────────────────────────────────────────────────────────────

static func _draw_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G1)
	## Subtle dither
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 0:
				img.set_pixel(ox + x, y, G4)
	## Highlight blades
	for p in [[2,1],[5,3],[9,2],[13,5],[1,7],[6,10],[10,6],[14,9],[3,12],[7,14],[11,11],[8,8]]:
		img.set_pixel(ox + p[0], p[1], G2)
	for p in [[4,4],[10,9],[1,13],[14,2]]:
		img.set_pixel(ox + p[0], p[1], G3)


static func _draw_grass_alt(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G2)
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 2:
				img.set_pixel(ox + x, y, G1)
	for p in [[2,3],[8,1],[13,6],[5,11],[10,14]]:
		img.set_pixel(ox + p[0], p[1], G3)
	## Small flower
	img.set_pixel(ox + 6, 4, FL1)
	img.set_pixel(ox + 5, 5, FL1)
	img.set_pixel(ox + 7, 5, FL1)
	img.set_pixel(ox + 6, 6, FL1)
	img.set_pixel(ox + 6, 5, FL2)


static func _draw_tree(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Dark grass base (shadow)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G3)
	## Trunk
	for x in range(6, 10):
		for y in range(10, 14):
			img.set_pixel(ox + x, y, TB if x > 6 else TB.darkened(0.2))
	## Canopy ellipse with 3-tone shading
	for y in range(0, 11):
		for x in range(0, 16):
			var dx := (x - 7.5) / 7.5
			var dy := (y - 4.5) / 5.0
			if dx * dx + dy * dy <= 1.0:
				var shade := dx * 0.5 + dy * 0.6
				var c: Color = TL if shade < -0.2 else (TD if shade < 0.3 else TK)
				img.set_pixel(ox + x, y, c)
	## Highlight spots
	for p in [[4,2],[6,3],[3,5],[8,1]]:
		img.set_pixel(ox + p[0], p[1], TL.lightened(0.12))


static func _draw_path(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, P1)
	## Lighter center
	for y in range(2, 14):
		for x in range(2, 14):
			img.set_pixel(ox + x, y, P2)
	## Edge shadow
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, P3)
		img.set_pixel(ox + x, 0, P3)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, P3)
		img.set_pixel(ox, y, P3)
	## Pebbles
	for p in [[4,2],[11,4],[2,8],[13,10],[6,13],[9,1],[7,6],[10,11]]:
		img.set_pixel(ox + p[0], p[1], P4)


static func _draw_water(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, W1)
	## Wave troughs
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 3, W3)
		img.set_pixel(ox + x, 7, W3)
		img.set_pixel(ox + x, 11, W3)
		img.set_pixel(ox + x, 15, W3)
	## Wave highlights
	for x in range(0, 8):
		img.set_pixel(ox + x, 1, W2)
		img.set_pixel(ox + x, 5, W2)
	for x in range(4, 12):
		img.set_pixel(ox + x, 9, W2)
	for x in range(8, 16):
		img.set_pixel(ox + x, 13, W2)
	## Sparkles
	img.set_pixel(ox + 3, 1, W4)
	img.set_pixel(ox + 10, 5, W4)
	img.set_pixel(ox + 6, 9, W4)


static func _draw_wall(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## White wall fill
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, BW)
	## Shadow on right and bottom edges
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, BWD)
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, BWD)
	## Window (centered, 6x5)
	for x in range(5, 11):
		for y in range(4, 9):
			img.set_pixel(ox + x, y, BWN)
	## Window frame
	for x in range(5, 11):
		img.set_pixel(ox + x, 4, BWF)
		img.set_pixel(ox + x, 8, BWF)
	for y in range(4, 9):
		img.set_pixel(ox + 5, y, BWF)
		img.set_pixel(ox + 10, y, BWF)
	img.set_pixel(ox + 7, 4, BWF)  ## cross bar
	img.set_pixel(ox + 8, 4, BWF)
	for y in range(4, 9):
		img.set_pixel(ox + 7, y, BWF)  ## vertical divider


static func _draw_roof(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			## Gradient: darker at top, lighter at bottom
			var t := float(y) / 15.0
			img.set_pixel(ox + x, y, BRD.lerp(BR, t))
	## Horizontal shingle lines every 4px
	for row in [0, 4, 8, 12]:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, row, BRD)
	## Edge shadow
	for y in TILE_SIZE:
		img.set_pixel(ox, y, BRD.darkened(0.15))
		img.set_pixel(ox + 15, y, BRD.darkened(0.15))


static func _draw_door(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Wall background
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, BW)
	## Door (centered, 8x12)
	for x in range(4, 12):
		for y in range(2, 16):
			img.set_pixel(ox + x, y, BDR)
	## Door frame (darker outline)
	for y in range(2, 16):
		img.set_pixel(ox + 4, y, BDR.darkened(0.2))
		img.set_pixel(ox + 11, y, BDR.darkened(0.2))
	for x in range(4, 12):
		img.set_pixel(ox + x, 2, BDR.darkened(0.2))
	## Door handle
	img.set_pixel(ox + 9, 9, FL1)
	img.set_pixel(ox + 9, 10, FL1)
	## Step at bottom
	for x in range(3, 13):
		img.set_pixel(ox + x, 15, P3)


static func _draw_tall_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base grass
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, TG2)
	## Dark grass blades pattern (V shapes scattered)
	for base_x in [1, 5, 9, 13]:
		for base_y in [2, 8]:
			img.set_pixel(ox + base_x, base_y, TG1)
			img.set_pixel(ox + base_x + 1, base_y - 1, TG1)
			if base_x > 0:
				img.set_pixel(ox + base_x - 1, base_y - 1, TG1)
	## Extra dark highlights
	for p in [[3,5],[7,11],[11,4],[2,13],[14,7]]:
		img.set_pixel(ox + p[0], p[1], TG1)
	## Light tips
	for p in [[2,1],[6,7],[10,1],[14,8],[4,12]]:
		img.set_pixel(ox + p[0], p[1], G2)


static func _draw_fence(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Grass base
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G1)
	## Horizontal rails
	for x in TILE_SIZE:
		for dy in [4, 5, 10, 11]:
			img.set_pixel(ox + x, dy, FN)
	## Vertical posts every 5px
	for post_x in [2, 7, 12]:
		for y in range(2, 14):
			img.set_pixel(ox + post_x, y, FN)
		## Post caps
		img.set_pixel(ox + post_x, 2, FND)
		img.set_pixel(ox + post_x, 13, FND)
	## Shadow on rails
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 5, FND)
		img.set_pixel(ox + x, 11, FND)
