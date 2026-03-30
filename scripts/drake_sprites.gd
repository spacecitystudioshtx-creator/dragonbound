## Autoloaded singleton — generates 64×64 pixel art battle sprites for all
## drakes at runtime. Each sprite is hand-drawn in code with GBA-era palette
## constraints and clean outlines, matching Pokémon FireRed's front-sprite style.
##
## The generated textures are cached and served via get_sprite(drake_name).
## Falls back to res://art/drakes/ PNGs if they exist.

extends Node

const SIZE := 64

## Outline color used by all sprites
const OL := Color(0.04, 0.04, 0.06)

## Cached textures keyed by lowercase drake name
var _cache: Dictionary = {}


func _ready() -> void:
	_generate_all()


func get_sprite(drake_name: String) -> Texture2D:
	var key := drake_name.to_lower()
	if _cache.has(key):
		return _cache[key]
	return null


func _generate_all() -> void:
	_gen("ember",     _draw_ember)
	_gen("scornn",    _draw_scornn)
	_gen("ashvane",   _draw_ashvane)
	_gen("ripple",    _draw_ripple)
	_gen("undertow",  _draw_undertow)
	_gen("tidewrath", _draw_tidewrath)
	_gen("sprig",     _draw_sprig)
	_gen("thicket",   _draw_thicket)
	_gen("ironbark",  _draw_ironbark)
	_gen("flick",     _draw_flick)
	_gen("tuft",      _draw_tuft)
	_gen("gulp",      _draw_gulp)


func _gen(name: String, draw_fn: Callable) -> void:
	## Check for file-based art first
	var path := "res://art/drakes/" + name + "_front.png"
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex:
			_cache[name] = tex
			return
	## Generate procedurally
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	draw_fn.call(img)
	_cache[name] = ImageTexture.create_from_image(img)


# ─────────────────────────────────────────────────────────────────────────────
# Drawing helpers
# ─────────────────────────────────────────────────────────────────────────────

func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var x0 := maxi(0, int(cx - rx))
	var x1 := mini(SIZE - 1, int(cx + rx))
	var y0 := maxi(0, int(cy - ry))
	var y1 := mini(SIZE - 1, int(cy + ry))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)

func _outline_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for angle in range(0, 360, 2):
		var rad := deg_to_rad(float(angle))
		var px := int(cx + cos(rad) * rx)
		var py := int(cy + sin(rad) * ry)
		if px >= 0 and px < SIZE and py >= 0 and py < SIZE:
			img.set_pixel(px, py, col)

func _fill_rect(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color) -> void:
	for y in range(maxi(0, y1), mini(SIZE, y2 + 1)):
		for x in range(maxi(0, x1), mini(SIZE, x2 + 1)):
			img.set_pixel(x, y, col)

func _fill_triangle(img: Image, ax: float, ay: float, bx: float, by: float, cx: float, cy: float, col: Color) -> void:
	var min_x := maxi(0, int(minf(minf(ax, bx), cx)))
	var max_x := mini(SIZE - 1, int(maxf(maxf(ax, bx), cx)))
	var min_y := maxi(0, int(minf(minf(ay, by), cy)))
	var max_y := mini(SIZE - 1, int(maxf(maxf(ay, by), cy)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _point_in_tri(float(x), float(y), ax, ay, bx, by, cx, cy):
				img.set_pixel(x, y, col)

func _point_in_tri(px: float, py: float, ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> bool:
	var d1 := (px - bx) * (ay - by) - (ax - bx) * (py - by)
	var d2 := (px - cx) * (by - cy) - (bx - cx) * (py - cy)
	var d3 := (px - ax) * (cy - ay) - (cx - ax) * (py - ay)
	var has_neg := (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos := (d1 > 0) or (d2 > 0) or (d3 > 0)
	return not (has_neg and has_pos)

func _hline(img: Image, x1: int, x2: int, y: int, col: Color) -> void:
	for x in range(maxi(0, x1), mini(SIZE, x2 + 1)):
		if y >= 0 and y < SIZE:
			img.set_pixel(x, y, col)

func _pixel(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < SIZE and y >= 0 and y < SIZE:
		img.set_pixel(x, y, col)


# ─────────────────────────────────────────────────────────────────────────────
# Fire line
# ─────────────────────────────────────────────────────────────────────────────

func _draw_ember(img: Image) -> void:
	var body := Color(0.92, 0.52, 0.18)
	var belly := Color(0.96, 0.82, 0.52)
	var dark := Color(0.72, 0.32, 0.08)
	var eye := Color(0.10, 0.08, 0.06)
	var flame := Color(1.0, 0.65, 0.10)
	var flame2 := Color(1.0, 0.40, 0.08)

	## Body — small round dragon
	_fill_ellipse(img, 32, 38, 14, 12, body)
	_outline_ellipse(img, 32, 38, 14, 12, OL)
	## Belly
	_fill_ellipse(img, 32, 42, 8, 7, belly)
	## Head
	_fill_ellipse(img, 32, 22, 11, 10, body)
	_outline_ellipse(img, 32, 22, 11, 10, OL)
	## Snout
	_fill_ellipse(img, 32, 27, 6, 4, body)
	_fill_ellipse(img, 32, 28, 4, 3, belly)
	## Eyes
	_fill_rect(img, 26, 19, 28, 22, Color.WHITE)
	_fill_rect(img, 27, 20, 28, 21, eye)
	_fill_rect(img, 35, 19, 37, 22, Color.WHITE)
	_fill_rect(img, 36, 20, 37, 21, eye)
	## Nostrils
	_pixel(img, 30, 26, dark)
	_pixel(img, 34, 26, dark)
	## Small horns
	_fill_triangle(img, 24, 16, 22, 8, 26, 14, dark)
	_fill_triangle(img, 40, 16, 42, 8, 38, 14, dark)
	## Stubby arms
	_fill_ellipse(img, 20, 36, 4, 3, body)
	_outline_ellipse(img, 20, 36, 4, 3, OL)
	_fill_ellipse(img, 44, 36, 4, 3, body)
	_outline_ellipse(img, 44, 36, 4, 3, OL)
	## Feet
	_fill_ellipse(img, 24, 50, 5, 3, body)
	_outline_ellipse(img, 24, 50, 5, 3, OL)
	_fill_ellipse(img, 40, 50, 5, 3, body)
	_outline_ellipse(img, 40, 50, 5, 3, OL)
	## Tail flame
	_fill_ellipse(img, 48, 44, 3, 2, body)
	_fill_ellipse(img, 52, 42, 4, 5, flame)
	_fill_ellipse(img, 53, 41, 2, 3, flame2)
	_outline_ellipse(img, 52, 42, 4, 5, OL)


func _draw_scornn(img: Image) -> void:
	var body := Color(0.78, 0.28, 0.12)
	var belly := Color(0.92, 0.68, 0.42)
	var dark := Color(0.52, 0.18, 0.08)
	var eye := Color(0.10, 0.08, 0.06)
	var horn := Color(0.45, 0.30, 0.15)

	## Body — medium armored dragon
	_fill_ellipse(img, 32, 36, 16, 14, body)
	_outline_ellipse(img, 32, 36, 16, 14, OL)
	_fill_ellipse(img, 32, 40, 10, 9, belly)
	## Head
	_fill_ellipse(img, 32, 18, 12, 11, body)
	_outline_ellipse(img, 32, 18, 12, 11, OL)
	## Curved horns
	_fill_triangle(img, 22, 14, 16, 4, 24, 10, horn)
	_outline_ellipse(img, 19, 9, 3, 5, OL)
	_fill_triangle(img, 42, 14, 48, 4, 40, 10, horn)
	_outline_ellipse(img, 45, 9, 3, 5, OL)
	## Eyes (fierce)
	_fill_rect(img, 25, 15, 28, 19, Color.WHITE)
	_fill_rect(img, 26, 16, 28, 18, eye)
	_fill_rect(img, 35, 15, 38, 19, Color.WHITE)
	_fill_rect(img, 36, 16, 38, 18, eye)
	## Armor plates
	_hline(img, 20, 44, 30, dark)
	_hline(img, 22, 42, 34, dark)
	_hline(img, 24, 40, 38, dark)
	## Small wings
	_fill_triangle(img, 16, 28, 6, 18, 18, 34, dark)
	_outline_ellipse(img, 11, 23, 5, 8, OL)
	_fill_triangle(img, 48, 28, 58, 18, 46, 34, dark)
	_outline_ellipse(img, 53, 23, 5, 8, OL)
	## Feet
	_fill_ellipse(img, 24, 50, 6, 4, body)
	_outline_ellipse(img, 24, 50, 6, 4, OL)
	_fill_ellipse(img, 40, 50, 6, 4, body)
	_outline_ellipse(img, 40, 50, 6, 4, OL)
	## Claws
	for dx in [-1, 0, 1]:
		_pixel(img, 24 + dx * 3, 54, OL)
		_pixel(img, 40 + dx * 3, 54, OL)


func _draw_ashvane(img: Image) -> void:
	var body := Color(0.45, 0.38, 0.35)
	var belly := Color(0.85, 0.55, 0.30)
	var dark := Color(0.30, 0.22, 0.18)
	var red := Color(0.82, 0.22, 0.10)
	var eye := Color(1.0, 0.50, 0.10)

	## Body — large volcanic dragon
	_fill_ellipse(img, 32, 38, 18, 16, body)
	_outline_ellipse(img, 32, 38, 18, 16, OL)
	_fill_ellipse(img, 32, 42, 12, 10, belly)
	## Head
	_fill_ellipse(img, 32, 16, 13, 12, body)
	_outline_ellipse(img, 32, 16, 13, 12, OL)
	## Glowing eyes
	_fill_rect(img, 24, 13, 28, 17, eye)
	_fill_rect(img, 25, 14, 27, 16, Color(1.0, 0.85, 0.20))
	_fill_rect(img, 36, 13, 40, 17, eye)
	_fill_rect(img, 37, 14, 39, 16, Color(1.0, 0.85, 0.20))
	## Lava cracks on body
	_hline(img, 22, 42, 32, red)
	_hline(img, 24, 40, 36, red)
	_hline(img, 26, 38, 40, red)
	## Massive wings
	_fill_triangle(img, 14, 26, 2, 8, 18, 40, dark)
	_fill_triangle(img, 50, 26, 62, 8, 46, 40, dark)
	_outline_ellipse(img, 8, 17, 6, 12, OL)
	_outline_ellipse(img, 56, 17, 6, 12, OL)
	## Wing membrane detail
	_hline(img, 4, 14, 20, body)
	_hline(img, 50, 60, 20, body)
	## Feet with claws
	_fill_ellipse(img, 22, 54, 7, 4, body)
	_outline_ellipse(img, 22, 54, 7, 4, OL)
	_fill_ellipse(img, 42, 54, 7, 4, body)
	_outline_ellipse(img, 42, 54, 7, 4, OL)
	## Horns
	_fill_triangle(img, 22, 8, 18, 0, 26, 6, dark)
	_fill_triangle(img, 42, 8, 46, 0, 38, 6, dark)


# ─────────────────────────────────────────────────────────────────────────────
# Water line
# ─────────────────────────────────────────────────────────────────────────────

func _draw_ripple(img: Image) -> void:
	var body := Color(0.45, 0.72, 0.92)
	var belly := Color(0.75, 0.88, 0.96)
	var dark := Color(0.25, 0.48, 0.72)
	var fin := Color(0.35, 0.58, 0.82)
	var eye := Color(0.06, 0.06, 0.15)

	## Body — small serpentine
	_fill_ellipse(img, 32, 36, 12, 14, body)
	_outline_ellipse(img, 32, 36, 12, 14, OL)
	_fill_ellipse(img, 32, 40, 8, 8, belly)
	## Head
	_fill_ellipse(img, 32, 20, 10, 9, body)
	_outline_ellipse(img, 32, 20, 10, 9, OL)
	## Cute big eyes
	_fill_ellipse(img, 27, 18, 4, 4, Color.WHITE)
	_fill_ellipse(img, 28, 19, 2, 2, eye)
	_pixel(img, 27, 17, Color.WHITE)
	_fill_ellipse(img, 37, 18, 4, 4, Color.WHITE)
	_fill_ellipse(img, 38, 19, 2, 2, eye)
	_pixel(img, 37, 17, Color.WHITE)
	## Fin ears
	_fill_triangle(img, 22, 16, 16, 8, 24, 12, fin)
	_fill_triangle(img, 42, 16, 48, 8, 40, 12, fin)
	## Small tail fin
	_fill_triangle(img, 32, 50, 26, 58, 38, 58, fin)
	_outline_ellipse(img, 32, 54, 6, 4, OL)
	## Flippers
	_fill_ellipse(img, 20, 38, 4, 3, fin)
	_fill_ellipse(img, 44, 38, 4, 3, fin)


func _draw_undertow(img: Image) -> void:
	var body := Color(0.22, 0.48, 0.78)
	var belly := Color(0.58, 0.78, 0.92)
	var dark := Color(0.12, 0.30, 0.55)
	var fin := Color(0.30, 0.55, 0.85)
	var eye := Color(0.06, 0.06, 0.15)

	## Body — medium sea serpent
	_fill_ellipse(img, 32, 34, 14, 16, body)
	_outline_ellipse(img, 32, 34, 14, 16, OL)
	_fill_ellipse(img, 32, 38, 9, 10, belly)
	## Head
	_fill_ellipse(img, 32, 16, 11, 10, body)
	_outline_ellipse(img, 32, 16, 11, 10, OL)
	## Eyes
	_fill_rect(img, 24, 13, 28, 17, Color.WHITE)
	_fill_rect(img, 25, 14, 27, 16, eye)
	_fill_rect(img, 36, 13, 40, 17, Color.WHITE)
	_fill_rect(img, 37, 14, 39, 16, eye)
	## Flowing fin crest
	_fill_triangle(img, 32, 8, 26, 2, 38, 2, fin)
	_fill_triangle(img, 32, 6, 28, 0, 36, 0, dark)
	## Side fins
	_fill_triangle(img, 18, 30, 8, 22, 20, 38, fin)
	_fill_triangle(img, 46, 30, 56, 22, 44, 38, fin)
	## Tail
	_fill_ellipse(img, 32, 50, 6, 4, body)
	_fill_triangle(img, 32, 54, 24, 62, 40, 62, fin)
	## Scale pattern
	for row in [28, 34, 40]:
		_hline(img, 24, 40, row, dark)


func _draw_tidewrath(img: Image) -> void:
	var body := Color(0.14, 0.35, 0.62)
	var belly := Color(0.42, 0.68, 0.82)
	var dark := Color(0.08, 0.22, 0.42)
	var teal := Color(0.15, 0.55, 0.55)
	var eye := Color(0.90, 0.20, 0.10)

	## Body — massive leviathan
	_fill_ellipse(img, 32, 34, 18, 18, body)
	_outline_ellipse(img, 32, 34, 18, 18, OL)
	_fill_ellipse(img, 32, 38, 12, 12, belly)
	## Head with massive jaw
	_fill_ellipse(img, 32, 14, 14, 12, body)
	_outline_ellipse(img, 32, 14, 14, 12, OL)
	## Open jaw
	_fill_rect(img, 22, 18, 42, 24, dark)
	## Teeth
	for tx in [24, 28, 32, 36, 40]:
		_fill_triangle(img, float(tx), 18, float(tx) - 1, 16, float(tx) + 1, 16, Color.WHITE)
		_fill_triangle(img, float(tx), 24, float(tx) - 1, 26, float(tx) + 1, 26, Color.WHITE)
	## Glowing eyes
	_fill_rect(img, 22, 10, 26, 14, eye)
	_fill_rect(img, 23, 11, 25, 13, Color(1.0, 0.5, 0.2))
	_fill_rect(img, 38, 10, 42, 14, eye)
	_fill_rect(img, 39, 11, 41, 13, Color(1.0, 0.5, 0.2))
	## Tidal energy aura (teal glow marks)
	_fill_ellipse(img, 12, 28, 3, 6, teal)
	_fill_ellipse(img, 52, 28, 3, 6, teal)
	_fill_ellipse(img, 8, 38, 2, 4, teal)
	_fill_ellipse(img, 56, 38, 2, 4, teal)
	## Tail
	_fill_ellipse(img, 32, 52, 8, 4, body)
	_fill_triangle(img, 32, 56, 20, 62, 44, 62, dark)


# ─────────────────────────────────────────────────────────────────────────────
# Nature line
# ─────────────────────────────────────────────────────────────────────────────

func _draw_sprig(img: Image) -> void:
	var body := Color(0.42, 0.72, 0.32)
	var belly := Color(0.68, 0.88, 0.52)
	var dark := Color(0.25, 0.50, 0.18)
	var wood := Color(0.48, 0.35, 0.18)
	var eye := Color(0.08, 0.08, 0.15)

	## Body — small leafy creature
	_fill_ellipse(img, 32, 38, 12, 12, body)
	_outline_ellipse(img, 32, 38, 12, 12, OL)
	_fill_ellipse(img, 32, 42, 8, 7, belly)
	## Head
	_fill_ellipse(img, 32, 22, 10, 10, body)
	_outline_ellipse(img, 32, 22, 10, 10, OL)
	## Big cute eyes
	_fill_ellipse(img, 27, 20, 4, 4, Color.WHITE)
	_fill_ellipse(img, 28, 21, 2, 2, eye)
	_pixel(img, 26, 19, Color.WHITE)
	_fill_ellipse(img, 37, 20, 4, 4, Color.WHITE)
	_fill_ellipse(img, 38, 21, 2, 2, eye)
	_pixel(img, 36, 19, Color.WHITE)
	## Twig antlers
	_fill_rect(img, 25, 10, 26, 16, wood)
	_fill_rect(img, 23, 8, 28, 10, dark)
	_pixel(img, 23, 7, dark)
	_pixel(img, 28, 7, dark)
	_fill_rect(img, 38, 10, 39, 16, wood)
	_fill_rect(img, 36, 8, 41, 10, dark)
	_pixel(img, 36, 7, dark)
	_pixel(img, 41, 7, dark)
	## Leaf on head
	_fill_triangle(img, 32, 8, 28, 14, 36, 14, Color(0.35, 0.65, 0.25))
	## Stubby feet
	_fill_ellipse(img, 25, 50, 5, 3, body)
	_outline_ellipse(img, 25, 50, 5, 3, OL)
	_fill_ellipse(img, 39, 50, 5, 3, body)
	_outline_ellipse(img, 39, 50, 5, 3, OL)


func _draw_thicket(img: Image) -> void:
	var body := Color(0.35, 0.58, 0.25)
	var bark := Color(0.42, 0.30, 0.16)
	var dark := Color(0.22, 0.42, 0.15)
	var vine := Color(0.30, 0.55, 0.20)
	var eye := Color(0.85, 0.65, 0.10)

	## Body — bark-armored beast
	_fill_ellipse(img, 32, 36, 16, 14, body)
	_outline_ellipse(img, 32, 36, 16, 14, OL)
	## Bark armor plates
	_fill_rect(img, 22, 28, 42, 34, bark)
	_fill_rect(img, 24, 34, 40, 40, bark)
	## Head
	_fill_ellipse(img, 32, 18, 12, 10, body)
	_outline_ellipse(img, 32, 18, 12, 10, OL)
	## Eyes (amber)
	_fill_rect(img, 25, 15, 28, 19, eye)
	_fill_rect(img, 26, 16, 27, 18, Color(0.15, 0.10, 0.05))
	_fill_rect(img, 36, 15, 39, 19, eye)
	_fill_rect(img, 37, 16, 38, 18, Color(0.15, 0.10, 0.05))
	## Vine whips (arms)
	_fill_rect(img, 12, 30, 16, 32, vine)
	_fill_rect(img, 8, 28, 12, 30, vine)
	_fill_rect(img, 48, 30, 52, 32, vine)
	_fill_rect(img, 52, 28, 56, 30, vine)
	## Leaf details on head
	_fill_triangle(img, 26, 10, 22, 4, 30, 8, dark)
	_fill_triangle(img, 38, 10, 42, 4, 34, 8, dark)
	## Feet
	_fill_ellipse(img, 24, 50, 6, 4, bark)
	_outline_ellipse(img, 24, 50, 6, 4, OL)
	_fill_ellipse(img, 40, 50, 6, 4, bark)
	_outline_ellipse(img, 40, 50, 6, 4, OL)


func _draw_ironbark(img: Image) -> void:
	var body := Color(0.38, 0.30, 0.18)
	var bark := Color(0.28, 0.22, 0.12)
	var moss := Color(0.32, 0.52, 0.22)
	var eye := Color(0.92, 0.72, 0.15)
	var glow := Color(0.95, 0.80, 0.25)

	## Body — massive tree golem
	_fill_ellipse(img, 32, 36, 20, 18, body)
	_outline_ellipse(img, 32, 36, 20, 18, OL)
	## Bark texture lines
	for row in [26, 30, 34, 38, 42]:
		_hline(img, 18, 46, row, bark)
	## Moss patches
	_fill_ellipse(img, 24, 28, 4, 3, moss)
	_fill_ellipse(img, 42, 32, 5, 3, moss)
	## Head (tree stump)
	_fill_ellipse(img, 32, 14, 14, 12, body)
	_outline_ellipse(img, 32, 14, 14, 12, OL)
	## Glowing amber eyes
	_fill_rect(img, 23, 11, 27, 15, eye)
	_fill_rect(img, 24, 12, 26, 14, glow)
	_fill_rect(img, 37, 11, 41, 15, eye)
	_fill_rect(img, 38, 12, 40, 14, glow)
	## Crown of leaves
	_fill_triangle(img, 20, 6, 16, 0, 24, 2, moss)
	_fill_triangle(img, 32, 2, 28, -2, 36, -2, moss)
	_fill_triangle(img, 44, 6, 40, 0, 48, 2, moss)
	## Root legs
	_fill_rect(img, 18, 50, 24, 58, body)
	_fill_rect(img, 40, 50, 46, 58, body)
	_outline_ellipse(img, 21, 56, 4, 3, OL)
	_outline_ellipse(img, 43, 56, 4, 3, OL)
	## Massive arms
	_fill_rect(img, 8, 28, 14, 34, body)
	_fill_rect(img, 4, 32, 8, 38, body)
	_fill_rect(img, 50, 28, 56, 34, body)
	_fill_rect(img, 56, 32, 60, 38, body)


# ─────────────────────────────────────────────────────────────────────────────
# Fodder
# ─────────────────────────────────────────────────────────────────────────────

func _draw_flick(img: Image) -> void:
	var body := Color(0.55, 0.62, 0.42)
	var belly := Color(0.78, 0.82, 0.62)
	var dark := Color(0.38, 0.45, 0.28)
	var eye := Color(0.08, 0.08, 0.12)

	## Body — tiny quick lizard
	_fill_ellipse(img, 32, 36, 10, 8, body)
	_outline_ellipse(img, 32, 36, 10, 8, OL)
	_fill_ellipse(img, 32, 38, 6, 5, belly)
	## Head
	_fill_ellipse(img, 32, 24, 8, 7, body)
	_outline_ellipse(img, 32, 24, 8, 7, OL)
	## Alert big eyes
	_fill_ellipse(img, 27, 22, 3, 3, Color.WHITE)
	_fill_ellipse(img, 28, 23, 1.5, 1.5, eye)
	_fill_ellipse(img, 37, 22, 3, 3, Color.WHITE)
	_fill_ellipse(img, 38, 23, 1.5, 1.5, eye)
	## Long tail
	_fill_rect(img, 42, 34, 44, 36, body)
	_fill_rect(img, 44, 32, 48, 34, body)
	_fill_rect(img, 48, 30, 54, 32, dark)
	## Tiny feet
	_fill_ellipse(img, 26, 44, 3, 2, body)
	_fill_ellipse(img, 38, 44, 3, 2, body)


func _draw_tuft(img: Image) -> void:
	var body := Color(0.82, 0.78, 0.68)
	var fluff := Color(0.92, 0.88, 0.82)
	var dark := Color(0.62, 0.58, 0.48)
	var eye := Color(0.15, 0.12, 0.08)
	var cheek := Color(0.92, 0.65, 0.55)

	## Body — round fluffy ball
	_fill_ellipse(img, 32, 34, 14, 14, body)
	_outline_ellipse(img, 32, 34, 14, 14, OL)
	## Fluffy texture
	_fill_ellipse(img, 28, 30, 8, 8, fluff)
	_fill_ellipse(img, 38, 32, 6, 6, fluff)
	## Big curious eyes
	_fill_ellipse(img, 26, 30, 5, 5, Color.WHITE)
	_fill_ellipse(img, 27, 31, 3, 3, eye)
	_pixel(img, 25, 28, Color.WHITE)
	_fill_ellipse(img, 38, 30, 5, 5, Color.WHITE)
	_fill_ellipse(img, 39, 31, 3, 3, eye)
	_pixel(img, 37, 28, Color.WHITE)
	## Cheek blush
	_fill_ellipse(img, 22, 36, 3, 2, cheek)
	_fill_ellipse(img, 42, 36, 3, 2, cheek)
	## Small ears
	_fill_triangle(img, 22, 22, 18, 16, 26, 20, body)
	_fill_triangle(img, 42, 22, 46, 16, 38, 20, body)
	## Tiny feet
	_fill_ellipse(img, 26, 48, 4, 2, dark)
	_fill_ellipse(img, 38, 48, 4, 2, dark)
	## Leaf tuft on head
	_fill_triangle(img, 32, 16, 28, 24, 36, 24, Color(0.45, 0.72, 0.35))


func _draw_gulp(img: Image) -> void:
	var body := Color(0.35, 0.62, 0.38)
	var belly := Color(0.72, 0.82, 0.55)
	var dark := Color(0.22, 0.45, 0.25)
	var spot := Color(0.28, 0.52, 0.30)
	var eye := Color(0.08, 0.06, 0.10)

	## Body — wide toad
	_fill_ellipse(img, 32, 38, 16, 12, body)
	_outline_ellipse(img, 32, 38, 16, 12, OL)
	_fill_ellipse(img, 32, 42, 12, 8, belly)
	## Head (wide, flat)
	_fill_ellipse(img, 32, 24, 14, 8, body)
	_outline_ellipse(img, 32, 24, 8, 8, OL)
	## Wide grin
	_hline(img, 24, 40, 28, OL)
	_pixel(img, 23, 27, OL)
	_pixel(img, 41, 27, OL)
	## Bulging eyes (on top of head)
	_fill_ellipse(img, 24, 18, 5, 5, Color.WHITE)
	_outline_ellipse(img, 24, 18, 5, 5, OL)
	_fill_ellipse(img, 25, 19, 2, 2, eye)
	_fill_ellipse(img, 40, 18, 5, 5, Color.WHITE)
	_outline_ellipse(img, 40, 18, 5, 5, OL)
	_fill_ellipse(img, 41, 19, 2, 2, eye)
	## Bumpy spots
	_fill_ellipse(img, 22, 34, 2, 2, spot)
	_fill_ellipse(img, 42, 36, 3, 2, spot)
	_fill_ellipse(img, 28, 44, 2, 2, spot)
	_fill_ellipse(img, 38, 42, 2, 2, spot)
	## Stubby feet
	_fill_ellipse(img, 22, 50, 5, 3, body)
	_outline_ellipse(img, 22, 50, 5, 3, OL)
	_fill_ellipse(img, 42, 50, 5, 3, body)
	_outline_ellipse(img, 42, 50, 5, 3, OL)
