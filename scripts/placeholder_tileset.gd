## Generates placeholder tile textures at runtime.
## Uses actual Pokémon FireRed GBA palette values (from pret/pokefirered).
## Each tile is 16×16 with multiple shades, dithering, and detail.

extends Node

const TILE_SIZE := 16

## ── Palette (from pokefirered general/palettes/00-04.pal) ──────────────────
## Grass — palette 00
const G1 := Color8(131, 213, 98)   ## Main grass green
const G2 := Color8(189, 255, 139)  ## Light grass highlight
const G3 := Color8(57, 148, 49)    ## Dark grass shadow
const G4 := Color8(57, 90, 16)     ## Deepest grass/tree shadow

## Trees — palette 00
const TL := Color8(131, 213, 98)   ## Canopy light
const TD := Color8(57, 148, 49)    ## Canopy medium
const TK := Color8(57, 90, 16)     ## Canopy dark
const TB := Color8(115, 98, 98)    ## Trunk (gray-brown from palette 00)
const TBD := Color8(65, 57, 49)    ## Trunk dark

## Path — palette 00 warm tones
const P1 := Color8(255, 197, 115)  ## Path main
const P2 := Color8(238, 213, 197)  ## Path light (from palette 01)
const P3 := Color8(222, 197, 164)  ## Path medium (from palette 01)
const P4 := Color8(189, 148, 139)  ## Path dark/pebble

## Water — palette 03/04 blues
const W1 := Color8(106, 164, 230)  ## Water main
const W2 := Color8(156, 213, 255)  ## Water light/highlight
const W3 := Color8(74, 131, 197)   ## Water medium
const W4 := Color8(49, 98, 164)    ## Water dark

## Buildings — palette 01/02
const BW  := Color8(222, 230, 230) ## Wall white
const BWL := Color8(230, 238, 238) ## Wall highlight
const BWD := Color8(172, 189, 205) ## Wall shadow
const BR  := Color8(238, 131, 106) ## Roof main (salmon)
const BRD := Color8(197, 49, 65)   ## Roof dark (deep red)
const BRL := Color8(238, 148, 115) ## Roof light
const BDR := Color8(123, 74, 74)   ## Door dark
const BDRL := Color8(148, 106, 106) ## Door lighter
const BWN := Color8(139, 164, 255) ## Window blue (from palette 04)
const BWF := Color8(90, 90, 115)   ## Window frame (dark blue-gray)

## Tall grass — darker greens for encounters
const TG1 := Color8(57, 148, 49)   ## Tall grass dark blade
const TG2 := Color8(131, 213, 98)  ## Tall grass base
const TG3 := Color8(189, 255, 139) ## Tall grass highlight tip

## Fence / sign — wood tones from palette 01
const FN  := Color8(222, 197, 164) ## Fence main
const FND := Color8(148, 106, 106) ## Fence shadow
const FNL := Color8(238, 213, 197) ## Fence highlight

## Accents
const FL1 := Color8(238, 230, 139) ## Flower yellow (palette 04)
const FL2 := Color8(238, 131, 106) ## Flower red/pink

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

	var poly := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
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
	## Base fill — main green
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G1)
	## 2×2 checkerboard dither with dark green (GBA-style seamless pattern)
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 0:
				img.set_pixel(ox + x, y, G3)
	## Scattered highlight blades
	for p in [[2,1],[5,3],[9,2],[13,5],[1,7],[6,10],[10,6],[14,9],[3,12],[7,14],[11,11],[8,8]]:
		img.set_pixel(ox + p[0], p[1], G2)
	## A few dark accents
	for p in [[4,4],[10,9],[1,13],[14,2],[7,6]]:
		img.set_pixel(ox + p[0], p[1], G3)


static func _draw_grass_alt(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Lighter base grass
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G2)
	## Dither back to G1
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 2:
				img.set_pixel(ox + x, y, G1)
	for p in [[2,3],[8,1],[13,6],[5,11],[10,14]]:
		img.set_pixel(ox + p[0], p[1], G3)
	## Small cross-shaped flower
	img.set_pixel(ox + 6, 4, FL1)
	img.set_pixel(ox + 5, 5, FL1)
	img.set_pixel(ox + 7, 5, FL1)
	img.set_pixel(ox + 6, 6, FL1)
	img.set_pixel(ox + 6, 5, FL2)


static func _draw_tree(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Dark shadow grass base
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G4)
	## Trunk — centered, gray-brown with shading
	for x in range(6, 10):
		for y in range(11, 15):
			var c: Color = TB if x > 6 else TBD
			img.set_pixel(ox + x, y, c)
	img.set_pixel(ox + 7, 11, TBD)  ## knot
	## Canopy — filled ellipse with 3-tone GBA shading
	for y in range(0, 12):
		for x in range(0, 16):
			var dx := (float(x) - 7.5) / 7.5
			var dy := (float(y) - 5.0) / 5.5
			if dx * dx + dy * dy <= 1.0:
				## Light from top-left, shadow bottom-right
				var shade := dx * 0.4 + dy * 0.6
				var c: Color
				if shade < -0.25:
					c = TL   ## bright highlight
				elif shade < 0.25:
					c = TD   ## medium
				else:
					c = TK   ## dark shadow
				img.set_pixel(ox + x, y, c)
	## Canopy highlight spots (dappled light)
	for p in [[3,2],[5,3],[4,5],[7,1],[9,4]]:
		img.set_pixel(ox + p[0], p[1], G2)
	## Dark edge pixels for outline effect
	for p in [[2,0],[13,0],[0,4],[15,4],[0,8],[15,8],[3,11],[12,11]]:
		img.set_pixel(ox + p[0], p[1], G4)


static func _draw_path(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Edge fill
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, P3)
	## Lighter center (worn-in walking area)
	for y in range(1, 15):
		for x in range(1, 15):
			img.set_pixel(ox + x, y, P1)
	## Bright center highlight
	for y in range(3, 13):
		for x in range(3, 13):
			img.set_pixel(ox + x, y, P2)
	## Edge shadow bottom and right
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 15, P4)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, P4)
	## Pebble details
	for p in [[4,3],[11,5],[3,9],[13,11],[7,13],[9,2],[6,7],[12,8]]:
		img.set_pixel(ox + p[0], p[1], P4)
	for p in [[5,5],[10,10],[8,4]]:
		img.set_pixel(ox + p[0], p[1], P3)


static func _draw_water(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base blue
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, W1)
	## Wave pattern — dark troughs every 4 rows
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 3, W3)
		img.set_pixel(ox + x, 7, W3)
		img.set_pixel(ox + x, 11, W3)
		img.set_pixel(ox + x, 15, W3)
	## Wave crests — light highlights, offset for motion feel
	for x in range(0, 8):
		img.set_pixel(ox + x, 1, W2)
		img.set_pixel(ox + x, 5, W2)
	for x in range(4, 12):
		img.set_pixel(ox + x, 9, W2)
	for x in range(8, 16):
		img.set_pixel(ox + x, 13, W2)
	## Sparkle highlights
	img.set_pixel(ox + 3, 1, Color8(189, 222, 255))
	img.set_pixel(ox + 10, 5, Color8(189, 222, 255))
	img.set_pixel(ox + 6, 9, Color8(189, 222, 255))
	## Deep shadow in troughs
	img.set_pixel(ox + 7, 3, W4)
	img.set_pixel(ox + 2, 7, W4)
	img.set_pixel(ox + 12, 11, W4)


static func _draw_wall(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## White wall fill
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, BW)
	## Highlight stripe at top
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 0, BWL)
		img.set_pixel(ox + x, 1, BWL)
	## Shadow on right and bottom edges (3D depth)
	for y in TILE_SIZE:
		img.set_pixel(ox + 15, y, BWD)
		img.set_pixel(ox + 14, y, BWD)
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 14, BWD)
		img.set_pixel(ox + x, 15, BWD)
	## Window (centered, 6×5) with proper frame
	for x in range(5, 11):
		for y in range(4, 9):
			img.set_pixel(ox + x, y, BWN)
	## Window frame
	for x in range(4, 12):
		img.set_pixel(ox + x, 3, BWF)
		img.set_pixel(ox + x, 9, BWF)
	for y in range(3, 10):
		img.set_pixel(ox + 4, y, BWF)
		img.set_pixel(ox + 11, y, BWF)
	## Window cross bars
	for y in range(4, 9):
		img.set_pixel(ox + 7, y, BWF)
	for x in range(5, 11):
		img.set_pixel(ox + x, 6, BWF)
	## Window reflection highlight
	img.set_pixel(ox + 5, 4, Color8(189, 222, 255))
	img.set_pixel(ox + 6, 4, Color8(156, 213, 255))


static func _draw_roof(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Gradient fill: dark at top → lighter at bottom
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var t := float(y) / 15.0
			img.set_pixel(ox + x, y, BRD.lerp(BR, t))
	## Light highlight at very bottom
	for x in range(1, 15):
		img.set_pixel(ox + x, 14, BRL)
		img.set_pixel(ox + x, 15, BRL)
	## Horizontal shingle lines
	for row in [0, 4, 8, 12]:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, row, BRD)
	## Edge shadow for 3D depth
	for y in TILE_SIZE:
		img.set_pixel(ox + 0, y, BRD.darkened(0.15))
		img.set_pixel(ox + 15, y, BRD.darkened(0.15))
	## Highlight on shingle edges
	for x in range(2, 14):
		img.set_pixel(ox + x, 1, BR)
		img.set_pixel(ox + x, 5, BR)
		img.set_pixel(ox + x, 9, BR)


static func _draw_door(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Wall background
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, BW)
	## Door rectangle (8×13, centered)
	for x in range(4, 12):
		for y in range(1, 14):
			img.set_pixel(ox + x, y, BDRL)
	## Door darker inner panel
	for x in range(5, 11):
		for y in range(2, 13):
			img.set_pixel(ox + x, y, BDR)
	## Door frame outline
	for y in range(1, 14):
		img.set_pixel(ox + 4, y, BWF)
		img.set_pixel(ox + 11, y, BWF)
	for x in range(4, 12):
		img.set_pixel(ox + x, 1, BWF)
	## Door handle
	img.set_pixel(ox + 9, 7, FL1)
	img.set_pixel(ox + 9, 8, FL1)
	## Door panel lines
	img.set_pixel(ox + 7, 3, BDRL)
	img.set_pixel(ox + 8, 3, BDRL)
	## Step at bottom
	for x in range(3, 13):
		img.set_pixel(ox + x, 14, P3)
		img.set_pixel(ox + x, 15, P4)


static func _draw_tall_grass(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Base — same as main grass
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, TG2)
	## Dither pattern
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 0:
				img.set_pixel(ox + x, y, G3)
	## V-shaped blade clusters (4 clusters, taller than regular grass)
	for bx in [1, 5, 9, 13]:
		for by in [2, 9]:
			img.set_pixel(ox + bx, by, TG1)
			img.set_pixel(ox + bx, by - 1, TG1)
			if bx > 0:
				img.set_pixel(ox + bx - 1, by - 1, TG1)
			if bx < 15:
				img.set_pixel(ox + bx + 1, by - 1, TG1)
			## Tip highlight
			if bx > 0:
				img.set_pixel(ox + bx - 1, by - 2, TG3)
			if bx < 15:
				img.set_pixel(ox + bx + 1, by - 2, TG3)
	## Extra scattered blades
	for p in [[3,5],[7,12],[11,4],[2,14],[14,7],[6,8],[10,13]]:
		img.set_pixel(ox + p[0], p[1], TG1)
	## Light tips
	for p in [[2,1],[6,7],[10,1],[14,8],[4,12],[8,5]]:
		img.set_pixel(ox + p[0], p[1], TG3)


static func _draw_fence(img: Image, col: int) -> void:
	var ox := col * TILE_SIZE
	## Grass base
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			img.set_pixel(ox + x, y, G1)
	## Dither grass
	for y in range(0, TILE_SIZE, 2):
		for x in range(0, TILE_SIZE, 2):
			if (x + y) % 4 == 0:
				img.set_pixel(ox + x, y, G3)
	## Horizontal rails (wood colored)
	for x in TILE_SIZE:
		for dy in [4, 5, 10, 11]:
			img.set_pixel(ox + x, dy, FN)
	## Rail highlight on top edge
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 4, FNL)
		img.set_pixel(ox + x, 10, FNL)
	## Rail shadow on bottom edge
	for x in TILE_SIZE:
		img.set_pixel(ox + x, 5, FND)
		img.set_pixel(ox + x, 11, FND)
	## Vertical posts
	for post_x in [2, 7, 12]:
		for y in range(2, 14):
			img.set_pixel(ox + post_x, y, FN)
		## Post caps (darker)
		img.set_pixel(ox + post_x, 2, FND)
		img.set_pixel(ox + post_x, 13, FND)
		## Post highlight
		img.set_pixel(ox + post_x, 3, FNL)
