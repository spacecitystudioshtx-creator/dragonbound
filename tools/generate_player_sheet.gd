extends SceneTree

const SPRITE_W := 16
const SPRITE_H := 16
const COLS := 4
const ROWS := 4
const OUT_PATH := "res://art/player/kindra_trainer_sheet.png"


func _initialize() -> void:
	var img := Image.create(SPRITE_W * COLS, SPRITE_H * ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for row in ROWS:
		for col in COLS:
			_draw_trainer(img, col * SPRITE_W, row * SPRITE_H, row, col)
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive("art/player")
	var err := img.save_png(OUT_PATH)
	if err != OK:
		push_error("failed to save " + OUT_PATH)
		quit(1)
		return
	print("wrote ", OUT_PATH)
	quit(0)


func _draw_trainer(img: Image, ox: int, oy: int, dir: int, frame: int) -> void:
	var outline := Color(0.05, 0.06, 0.08)
	var skin := Color(0.94, 0.70, 0.52)
	var skin_dark := Color(0.70, 0.38, 0.25)
	var hair := Color(0.20, 0.12, 0.08)
	var cap := Color(0.82, 0.10, 0.14)
	var cap_light := Color(0.98, 0.92, 0.76)
	var jacket := Color(0.10, 0.34, 0.70)
	var jacket_light := Color(0.30, 0.56, 0.88)
	var shirt := Color(0.96, 0.84, 0.56)
	var pack := Color(0.64, 0.48, 0.24)
	var pants := Color(0.12, 0.18, 0.34)
	var shoe := Color(0.04, 0.04, 0.05)
	var step := -1 if frame == 1 else (1 if frame == 3 else 0)
	var flip := dir == 3

	## Boxy one-tile overworld proportions: oversized head, squat body,
	## short legs, strong outline.
	_rect(img, ox + 3, oy + 14, ox + 12, oy + 15, Color(0.02, 0.03, 0.04, 0.22))
	_rect(img, ox + 5 - step, oy + 12, ox + 6 - step, oy + 14, pants)
	_rect(img, ox + 9 + step, oy + 12, ox + 10 + step, oy + 14, pants)
	_rect(img, ox + 4 - step, oy + 14, ox + 6 - step, oy + 15, shoe)
	_rect(img, ox + 9 + step, oy + 14, ox + 11 + step, oy + 15, shoe)

	if dir == 1:
		_rect(img, ox + 3, oy + 7, ox + 12, oy + 12, outline)
		_rect(img, ox + 4, oy + 8, ox + 11, oy + 12, jacket)
		_rect(img, ox + 5, oy + 8, ox + 10, oy + 10, pack)
		_rect(img, ox + 3, oy + 1, ox + 12, oy + 8, outline)
		_rect(img, ox + 4, oy + 3, ox + 11, oy + 8, hair)
		_rect(img, ox + 3, oy + 1, ox + 12, oy + 4, cap)
		_rect(img, ox + 5, oy + 0, ox + 10, oy + 2, cap_light)
		_rect(img, ox + 5, oy + 6, ox + 10, oy + 7, cap)
	elif dir == 0:
		_rect(img, ox + 3, oy + 7, ox + 12, oy + 12, outline)
		_rect(img, ox + 4, oy + 8, ox + 11, oy + 12, jacket)
		_rect(img, ox + 6, oy + 8, ox + 9, oy + 11, shirt)
		_rect(img, ox + 2 + step, oy + 8, ox + 4 + step, oy + 11, outline)
		_rect(img, ox + 11 - step, oy + 8, ox + 13 - step, oy + 11, outline)
		_rect(img, ox + 4, oy + 1, ox + 11, oy + 8, outline)
		_rect(img, ox + 5, oy + 3, ox + 10, oy + 8, skin)
		_rect(img, ox + 3, oy + 1, ox + 12, oy + 4, cap)
		_rect(img, ox + 5, oy + 0, ox + 10, oy + 2, cap)
		_rect(img, ox + 7, oy + 1, ox + 11, oy + 2, cap_light)
		_rect(img, ox + 2, oy + 4, ox + 5, oy + 5, cap)
		_pixel(img, ox + 5, oy + 5, outline)
		_pixel(img, ox + 10, oy + 5, outline)
		_rect(img, ox + 6, oy + 7, ox + 9, oy + 7, skin_dark)
	else:
		_rect(img, ox + 3, oy + 7, ox + 12, oy + 12, outline)
		_rect(img, ox + 4, oy + 8, ox + 11, oy + 12, jacket)
		_rect(img, ox + 6, oy + 10, ox + 9, oy + 11, jacket_light)
		_rect(img, ox + 2 + step, oy + 8, ox + 4 + step, oy + 11, outline)
		_rect(img, ox + 11 - step, oy + 8, ox + 13 - step, oy + 11, outline)
		_rect(img, ox + 4, oy + 1, ox + 11, oy + 8, outline)
		_rect(img, ox + 5, oy + 3, ox + 10, oy + 8, skin)
		_rect(img, ox + 3, oy + 1, ox + 12, oy + 4, cap)
		_rect(img, ox + 5, oy + 0, ox + 10, oy + 2, cap)
		if flip:
			_rect(img, ox + 10, oy + 4, ox + 13, oy + 5, cap)
			_rect(img, ox + 4, oy + 8, ox + 5, oy + 10, pack)
			_pixel(img, ox + 10, oy + 5, outline)
			_pixel(img, ox + 11, oy + 7, skin_dark)
		else:
			_rect(img, ox + 2, oy + 4, ox + 5, oy + 5, cap)
			_rect(img, ox + 10, oy + 8, ox + 11, oy + 10, pack)
			_pixel(img, ox + 5, oy + 5, outline)
			_pixel(img, ox + 4, oy + 7, skin_dark)


func _rect(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	for y in range(maxi(0, y1), mini(img.get_height(), y2 + 1)):
		for x in range(maxi(0, x1), mini(img.get_width(), x2 + 1)):
			img.set_pixel(x, y, color)


func _pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)
