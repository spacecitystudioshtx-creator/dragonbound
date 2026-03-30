## Loads tiles from ArMM1998 CC0 Overworld.png tileset atlas.
## Extracts specific tiles into a strip and builds a TileSet with collision.
##
## Tile indices (unchanged from before):
## 0=grass, 1=grass_alt, 2=tree, 3=path, 4=water,
## 5=building_wall, 6=roof, 7=door, 8=tall_grass, 9=fence

extends Node

const TILE_SIZE := 16

## Atlas coordinates in Overworld.png (40x36 grid of 16x16 tiles)
## Each entry is Vector2i(col, row) in the source atlas.
const ATLAS_COORDS := {
	0: Vector2i(0, 0),    ## Grass — solid green
	1: Vector2i(1, 4),    ## Grass alt — lighter variation
	2: Vector2i(5, 0),    ## Tree canopy — dark green treetop
	3: Vector2i(7, 5),    ## Path — dirt/sand
	4: Vector2i(17, 0),   ## Water — blue center tile
	5: Vector2i(28, 1),   ## Building wall — gray
	6: Vector2i(27, 18),  ## Roof — brown/orange
	7: Vector2i(9, 10),   ## Door — brown entrance
	8: Vector2i(2, 16),   ## Tall grass — bright green encounter grass
	9: Vector2i(7, 0),    ## Fence — wood post/rail
}

var _atlas_image: Image = null


static func create_placeholder_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 2)

	var cols := 10
	var strip := Image.create(TILE_SIZE * cols, TILE_SIZE, false, Image.FORMAT_RGBA8)

	## Load the source atlas
	var atlas_path := "res://art/tilesets/armm1998/gfx/Overworld.png"
	var atlas_img: Image = null

	if ResourceLoader.exists(atlas_path):
		var atlas_tex: Texture2D = load(atlas_path)
		if atlas_tex:
			atlas_img = atlas_tex.get_image()

	if atlas_img == null:
		## Fallback: try loading directly from disk
		atlas_img = Image.new()
		var abs_path := ProjectSettings.globalize_path(atlas_path)
		if atlas_img.load(abs_path) != OK:
			push_warning("PlaceholderTileset: Could not load Overworld.png, using fallback colors")
			atlas_img = null

	## Extract each tile from the atlas into our strip
	for i in cols:
		var src_coord: Vector2i = ATLAS_COORDS[i]
		var src_x := src_coord.x * TILE_SIZE
		var src_y := src_coord.y * TILE_SIZE
		var dst_x := i * TILE_SIZE

		if atlas_img != null:
			for y in TILE_SIZE:
				for x in TILE_SIZE:
					var px := src_x + x
					var py := src_y + y
					if px < atlas_img.get_width() and py < atlas_img.get_height():
						strip.set_pixel(dst_x + x, y, atlas_img.get_pixel(px, py))
					else:
						strip.set_pixel(dst_x + x, y, Color.MAGENTA)
		else:
			## Minimal fallback — solid colors
			var fallback_colors: Array[Color] = [
				Color(0.23, 0.75, 0.25),  ## grass
				Color(0.42, 0.87, 0.29),  ## grass alt
				Color(0.20, 0.56, 0.25),  ## tree
				Color(0.74, 0.60, 0.47),  ## path
				Color(0.12, 0.49, 0.72),  ## water
				Color(0.84, 0.84, 0.84),  ## wall
				Color(0.66, 0.47, 0.28),  ## roof
				Color(0.47, 0.35, 0.31),  ## door
				Color(0.18, 0.79, 0.36),  ## tall grass
				Color(0.47, 0.35, 0.31),  ## fence
			]
			for y in TILE_SIZE:
				for x in TILE_SIZE:
					strip.set_pixel(dst_x + x, y, fallback_colors[i])

	var tex := ImageTexture.create_from_image(strip)
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
