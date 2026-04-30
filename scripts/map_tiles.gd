## Map tile + prop reference.
## Autoloaded as MapTiles. Gives map scripts named constants for every tile
## and a simple "stamp" API for multi-tile props (trees, buildings) sourced
## from the Ninja Adventure CC0 asset pack.
##
## Two TileSet sources are used:
##   Source 0 — "ground strip"   (built by placeholder_tileset.gd, 16 tiles)
##   Source 1 — "village atlas"  (tileset_village_abandoned.png, full 20×12)
##
## Ground strip indices (source 0):
##   0 GRASS        | 5 SAND         | 10 PATH_EDGE_N    | 13 WATER
##   1 GRASS_ALT    | 6 SAND_ALT     | 11 PATH_EDGE_S    | 14 WATER_ALT
##   2 BUSH         | 7 SNOW         | 12 PATH_EDGE_E    | 15 FLOWER
##   3 DIRT_PATH    | 8 TALL_GRASS
##   4 DIRT_ALT     | 9 PATH_EDGE_W

extends Node

## Atlas source ids
const SRC_GROUND := 0
const SRC_VILLAGE := 1

## ── Ground strip indices (source 0) ──────────────────────────────────────────
const GRASS        := Vector2i(0, 0)
const GRASS_ALT    := Vector2i(1, 0)
const BUSH         := Vector2i(2, 0)
const DIRT_PATH    := Vector2i(3, 0)
const DIRT_ALT     := Vector2i(4, 0)
const SAND         := Vector2i(5, 0)
const SAND_ALT     := Vector2i(6, 0)
const SNOW         := Vector2i(7, 0)
const TALL_GRASS   := Vector2i(8, 0)
const FLOWER       := Vector2i(9, 0)
const WATER        := Vector2i(10, 0)
const WATER_ALT    := Vector2i(11, 0)
const FENCE        := Vector2i(12, 0)
const SIGN         := Vector2i(13, 0)
const STUMP        := Vector2i(14, 0)
const ROCK         := Vector2i(15, 0)

## Back-compat aliases (old map scripts expected these names from the 10-tile
## strip). Kept so existing scripts don't all have to change at once.
const TREE     := BUSH          ## small bush as single-tile tree fallback
const WALL     := FENCE         ## generic obstacle fallback
const ROOF     := FENCE
const DOOR     := DIRT_PATH
const TALL_GR  := TALL_GRASS

## ── Village atlas stamps (source 1) ──────────────────────────────────────────
## Each stamp is an array of {offset: Vector2i, coord: Vector2i, solid: bool}.
## Origin is the top-left tile of the bounding box.
##
## Coordinates below were read from /tmp/village_labeled.png (grid overlay).

## Small round 2×2 tree (bushy oak) — Ninja Adventure village atlas.
## Atlas (4,6)-(5,7). Old (0,3)-(1,4) coords pointed to a peach pottery prop.
const PROP_TREE_SMALL := [
	{"dx": 0, "dy": 0, "c":  4, "r": 6, "solid": true},
	{"dx": 1, "dy": 0, "c":  5, "r": 6, "solid": true},
	{"dx": 0, "dy": 1, "c":  4, "r": 7, "solid": true},
	{"dx": 1, "dy": 1, "c":  5, "r": 7, "solid": false},  ## trunk base walkable behind
]

## Large 2×3 tree (trunk + canopy).
const PROP_TREE_BIG := [
	{"dx": 0, "dy": 0, "c":  0, "r": 6, "solid": true},
	{"dx": 1, "dy": 0, "c":  1, "r": 6, "solid": true},
	{"dx": 0, "dy": 1, "c":  0, "r": 7, "solid": true},
	{"dx": 1, "dy": 1, "c":  1, "r": 7, "solid": true},
	{"dx": 0, "dy": 2, "c":  0, "r": 8, "solid": true},
	{"dx": 1, "dy": 2, "c":  1, "r": 8, "solid": false},
]

## Small brown house 3×3 (Pyre-style / player's home scale).
const PROP_HOUSE_SMALL := [
	{"dx": 0, "dy": 0, "c": 10, "r": 0, "solid": true},
	{"dx": 1, "dy": 0, "c": 11, "r": 0, "solid": true},
	{"dx": 2, "dy": 0, "c": 12, "r": 0, "solid": true},
	{"dx": 0, "dy": 1, "c": 10, "r": 1, "solid": true},
	{"dx": 1, "dy": 1, "c": 11, "r": 1, "solid": true},
	{"dx": 2, "dy": 1, "c": 12, "r": 1, "solid": true},
	{"dx": 0, "dy": 2, "c": 10, "r": 2, "solid": true},
	{"dx": 1, "dy": 2, "c": 11, "r": 2, "solid": false},  ## door
	{"dx": 2, "dy": 2, "c": 12, "r": 2, "solid": true},
]

## Large brown 2-story house 4×6 (The Pyre / elder's house).
const PROP_HOUSE_BIG := [
	## Roof rows
	{"dx": 0, "dy": 0, "c": 13, "r": 6, "solid": true},
	{"dx": 1, "dy": 0, "c": 14, "r": 6, "solid": true},
	{"dx": 2, "dy": 0, "c": 15, "r": 6, "solid": true},
	{"dx": 3, "dy": 0, "c": 16, "r": 6, "solid": true},
	{"dx": 0, "dy": 1, "c": 13, "r": 7, "solid": true},
	{"dx": 1, "dy": 1, "c": 14, "r": 7, "solid": true},
	{"dx": 2, "dy": 1, "c": 15, "r": 7, "solid": true},
	{"dx": 3, "dy": 1, "c": 16, "r": 7, "solid": true},
	## Upper wall rows
	{"dx": 0, "dy": 2, "c": 13, "r": 8, "solid": true},
	{"dx": 1, "dy": 2, "c": 14, "r": 8, "solid": true},
	{"dx": 2, "dy": 2, "c": 15, "r": 8, "solid": true},
	{"dx": 3, "dy": 2, "c": 16, "r": 8, "solid": true},
	{"dx": 0, "dy": 3, "c": 13, "r": 9, "solid": true},
	{"dx": 1, "dy": 3, "c": 14, "r": 9, "solid": true},
	{"dx": 2, "dy": 3, "c": 15, "r": 9, "solid": true},
	{"dx": 3, "dy": 3, "c": 16, "r": 9, "solid": true},
	## Lower wall + door row
	{"dx": 0, "dy": 4, "c": 13, "r": 10, "solid": true},
	{"dx": 1, "dy": 4, "c": 14, "r": 10, "solid": true},
	{"dx": 2, "dy": 4, "c": 15, "r": 10, "solid": true},
	{"dx": 3, "dy": 4, "c": 16, "r": 10, "solid": true},
	{"dx": 0, "dy": 5, "c": 13, "r": 11, "solid": true},
	{"dx": 1, "dy": 5, "c": 14, "r": 11, "solid": false},  ## door
	{"dx": 2, "dy": 5, "c": 15, "r": 11, "solid": true},
	{"dx": 3, "dy": 5, "c": 16, "r": 11, "solid": true},
]

## Wooden stump (1×1 obstacle, decoration).
const PROP_STUMP := [
	{"dx": 0, "dy": 0, "c": 4, "r": 4, "solid": true},
]

## Gravestone cross (2×2, for graveyards / trial-cave entrance).
const PROP_GRAVE := [
	{"dx": 0, "dy": 0, "c": 6, "r": 0, "solid": true},
	{"dx": 1, "dy": 0, "c": 7, "r": 0, "solid": true},
	{"dx": 0, "dy": 1, "c": 6, "r": 1, "solid": true},
	{"dx": 1, "dy": 1, "c": 7, "r": 1, "solid": true},
]


## Stamp a prop onto the obstacle layer at tile (ox, oy).
## Non-solid tiles go on the ground layer instead (e.g. door, trunk base).
static func stamp(prop: Array, ox: int, oy: int,
		ground: TileMapLayer, obstacles: TileMapLayer) -> void:
	for t in prop:
		var pos := Vector2i(ox + t["dx"], oy + t["dy"])
		var coord := Vector2i(t["c"], t["r"])
		if t["solid"]:
			obstacles.set_cell(pos, SRC_VILLAGE, coord)
		else:
			## Place visually on ground, but clear any obstacle there.
			ground.set_cell(pos, SRC_VILLAGE, coord)
			obstacles.erase_cell(pos)


## Width / height of a prop (inclusive bounding box).
static func prop_size(prop: Array) -> Vector2i:
	var w := 0
	var h := 0
	for t in prop:
		w = maxi(w, int(t["dx"]) + 1)
		h = maxi(h, int(t["dy"]) + 1)
	return Vector2i(w, h)
