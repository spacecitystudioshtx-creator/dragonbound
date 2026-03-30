## Generates placeholder tile textures at runtime.
## Styled after Pokémon FireRed — seamless grass, layered trees with shadow,
## worn dirt path, rippling water.

extends Node

const TILE_SIZE := 16

## ── Palette (matched to GBA Pokémon style) ──────────────────────────────────
## Grass
const G1 := Color(0.31, 0.64, 0.22)   ## Base grass
const G2 := Color(0.36, 0.70, 0.27)   ## Lighter grass highlight
const G3 := Color(0.25, 0.54, 0.17)   ## Darker grass shadow
const G4 := Color(0.28, 0.58, 0.19)   ## Mid-tone grass

## Trees
const TL  := Color(0.18, 0.50, 0.14)  ## Canopy light
const TD  := Color(0.10, 0.34, 0.08)  ## Canopy dark/shadow
const TK  := Color(0.06, 0.22, 0.04)  ## Canopy deepest shadow
const TB  := Color(0.42, 0.28, 0.12)  ## Trunk brown
const TBD := Color(0.30, 0.18, 0.07)  ## Trunk dark

## Path
const P1 := Color(0.78, 0.68, 0.48)   ## Path base
const P2 := Color(0.85, 0.76, 0.56)   ## Path highlight
const P3 := Color(0.65, 0.55, 0.38)   ## Path shadow/edge
const P4 := Color(0.58, 0.48, 0.32)   ## Pebble dark

## Water
const W1 := Color(0.22, 0.50, 0.85)   ## Water base
const W2 := Color(0.35, 0.62, 0.92)   ## Wave highlight
const W3 := Color(0.14, 0.38, 0.70)   ## Water dark
const W4 := Color(0.42, 0.72, 0.96)   ## Bright sparkle

## Tall grass (encounter zones)
const TG1 := Color(0.24, 0.56, 0.16)  ## Tall grass dark
const TG2 := Color(0.32, 0.65, 0.22)  ## Tall grass mid

## Flower accents
const FL1 := Color(0.95, 0.85, 0.20)  ## Yellow flower
const FL2 := Color(0.95, 0.40, 0.30)  ## Red flower center


static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 2)

	var img := Image.create(TILE_SIZE * 5, TILE_SIZE, false, Image.FORMAT_RGBA8)

	_draw_grass(img, 0)
	_draw_grass_alt(img, 1)
	_draw_tree(img, 2)
	_draw_path(img, 3)
	_draw_water(img, 4)

	var tex    := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture             = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for i in 5:
		source.create_tile(Vector2i(i, 0))

	## Collision on tree (2) and water (4)
	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	source.get_tile_data(Vector2i(2, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(2, 0), 0).set_collision_polygon_points(0, 0, polygon)
	source.get_tile_data(Vector2i(4, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(4, 0), 0).set_collision_polygon_points(0, 0, polygon)

	tileset.add_source(source)
	return tileset


## ── Grass: seamless base tile with subtle dithered texture ──────────────────
static func _draw_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Fill base
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G1)

	## Checkerboard-style subtle dither for texture (every other 2px block)
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 0:
				img.set_pixel(ox + x, y, G4)

	## Scattered highlight blades
	var highlights := [[2,1],[5,3],[9,2],[13,5],[1,7],[6,10],[10,6],[14,9],
					   [3,12],[7,14],[11,11],[4,6],[8,8],[12,13],[0,4],[15,10]]
	for p in highlights:
		img.set_pixel(ox + p[0], p[1], G2)

	## Dark blade accents (sparse)
	var darks := [[4,4],[10,9],[1,13],[14,2],[7,7],[12,0]]
	for p in darks:
		img.set_pixel(ox + p[0], p[1], G3)


## ── Grass alt: lighter variant with small flower cluster ────────────────────
static func _draw_grass_alt(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base — slightly lighter
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G2)

	## Same dither pattern
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 2:
				img.set_pixel(ox + x, y, G1)

	## Dark texture
	var darks := [[2,3],[8,1],[13,6],[5,11],[10,14],[0,8]]
	for p in darks:
		img.set_pixel(ox + p[0], p[1], G3)

	## Flower cluster at (6,5) — 5-pixel cross with center
	img.set_pixel(ox + 6, 4, FL1)
	img.set_pixel(ox + 5, 5, FL1)
	img.set_pixel(ox + 7, 5, FL1)
	img.set_pixel(ox + 6, 6, FL1)
	img.set_pixel(ox + 6, 5, FL2)

	## Second smaller flower at (11, 10)
	img.set_pixel(ox + 11, 9, FL1)
	img.set_pixel(ox + 11, 10, FL2)
	img.set_pixel(ox + 10, 10, FL1)
	img.set_pixel(ox + 12, 10, FL1)


## ── Tree: layered canopy with shading, trunk, ground shadow ─────────────────
static func _draw_tree(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Grass base underneath
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G3)  ## Slightly darker = tree shadow

	## Ground shadow (bottom)
	for x in range(2, 14):
		img.set_pixel(ox + x, 14, G3.darkened(0.15))
		img.set_pixel(ox + x, 15, G3.darkened(0.10))

	## Trunk (centered, rows 10-13)
	for x in range(6, 10):
		for y in range(10, 14):
			img.set_pixel(ox + x, y, TB if x > 6 else TBD)
	## Trunk highlight
	img.set_pixel(ox + 8, 10, TB.lightened(0.15))
	img.set_pixel(ox + 8, 11, TB.lightened(0.10))

	## Canopy — large ellipse (rows 0-10)
	for y in range(0, 11):
		for x in range(0, 16):
			var cx := 7.5
			var cy := 4.5
			var rx := 7.5
			var ry := 5.0
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				## 3-tone shading: top-left = light, center = mid, bottom-right = dark
				var shade_val := dx * 0.5 + dy * 0.6
				var c: Color
				if shade_val < -0.2:
					c = TL
				elif shade_val < 0.3:
					c = TD
				else:
					c = TK
				img.set_pixel(ox + x, y, c)

	## Canopy highlight spots (dappled light)
	var spots := [[4,2],[6,3],[3,5],[8,1],[10,4],[5,7]]
	for p in spots:
		if p[0] < 16 and p[1] < 16:
			img.set_pixel(ox + p[0], p[1], TL.lightened(0.12))

	## Dark outline on canopy edges for crispness
	for y in range(0, 11):
		for x in range(0, 16):
			var cx := 7.5
			var cy := 4.5
			var rx := 7.5
			var ry := 5.0
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			var dist := dx * dx + dy * dy
			## If this pixel is just outside the canopy edge
			if dist > 1.0 and dist < 1.25:
				## Check if any neighbor is inside
				for nx in [-1, 0, 1]:
					for ny in [-1, 0, 1]:
						var ndx: float = (x + nx - cx) / rx
						var ndy: float = (y + ny - cy) / ry
						if ndx * ndx + ndy * ndy <= 1.0:
							var cur := img.get_pixel(ox + x, y)
							if cur != TL and cur != TD and cur != TK:
								img.set_pixel(ox + x, y, TK)


## ── Path: worn dirt with lighter center, darker edges, pebble details ───────
static func _draw_path(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Edge fill
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, P3)

	## Main body (inset 1px)
	for y in range(1, 15):
		for x in range(1, 15):
			img.set_pixel(ox + x, y, P1)

	## Lighter worn center strip
	for y in range(3, 13):
		for x in range(3, 13):
			img.set_pixel(ox + x, y, P2)

	## Pebble/grain details
	var pebbles := [[4,2],[11,4],[2,8],[13,10],[6,13],[9,1],[1,5],[14,7],
					 [7,6],[10,11],[3,14],[5,9],[12,3],[8,12]]
	for p in pebbles:
		img.set_pixel(ox + p[0], p[1], P4)

	## Subtle highlight dots
	img.set_pixel(ox + 5, 5, P2.lightened(0.08))
	img.set_pixel(ox + 10, 8, P2.lightened(0.08))
	img.set_pixel(ox + 7, 10, P2.lightened(0.08))


## ── Water: rippling surface with wave highlights and deep shadows ───────────
static func _draw_water(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base fill
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, W1)

	## Darker wave troughs (horizontal bands)
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 3, W3)
		img.set_pixel(ox + x, 7, W3)
		img.set_pixel(ox + x, 11, W3)
		img.set_pixel(ox + x, 15, W3)

	## Wave highlight crests (offset from troughs)
	for x in range(0, 8):
		img.set_pixel(ox + x, 1, W2)
		img.set_pixel(ox + x, 5, W2)
	for x in range(4, 12):
		img.set_pixel(ox + x, 9, W2)
	for x in range(8, 16):
		img.set_pixel(ox + x, 13, W2)

	## Sparkle highlights
	img.set_pixel(ox + 3, 1, W4)
	img.set_pixel(ox + 10, 5, W4)
	img.set_pixel(ox + 6, 9, W4)
	img.set_pixel(ox + 13, 13, W4)

	## Subtle dither between trough and base
	for y in [4, 8, 12]:
		for x in range(0, TILE_SIZE, 3):
			img.set_pixel(ox + x, y, W3.lightened(0.08))
