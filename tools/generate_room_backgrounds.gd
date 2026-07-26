extends SceneTree

const W := 240
const H := 160
const TILE := 16
const OUT := "res://art/generated/backgrounds"


func _initialize() -> void:
	DirAccess.open("res://").make_dir_recursive("art/generated/backgrounds")
	_save_room("kindra_home_interior_live.png", "home")
	_save_room("kindra_shop_interior_live.png", "shop")
	_save_room("kindra_house_interior_live.png", "house")
	_save_room("kindra_pyre_interior_live.png", "pyre")
	_save_room("kindra_elder_interior_live.png", "elder")
	quit(0)


func _save_room(file_name: String, variant: String) -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_draw_base(img)
	match variant:
		"shop":
			_draw_shop(img)
		"house":
			_draw_house(img)
		"pyre":
			_draw_pyre(img)
		"elder":
			_draw_elder(img)
		_:
			_draw_home(img)
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(file_name)))
	print("wrote ", file_name)


func _draw_base(img: Image) -> void:
	_rect(img, 0, 0, W - 1, H - 1, Color(0.86, 0.70, 0.46))
	for y in range(32, H, 16):
		_rect(img, 0, y, W - 1, y, Color(0.70, 0.54, 0.36))
	for x in range(8, W, 16):
		for y in range(40, H - 16, 16):
			_px(img, x, y, Color(0.96, 0.82, 0.56))
			_px(img, x + 8, y + 7, Color(0.64, 0.46, 0.30))

	_rect(img, 0, 0, W - 1, 15, Color(0.58, 0.42, 0.30))
	_rect(img, 0, 16, W - 1, 47, Color(0.78, 0.62, 0.44))
	for y in [22, 31, 40]:
		_rect(img, 0, y, W - 1, y + 1, Color(0.96, 0.80, 0.56))
	_rect(img, 0, 48, W - 1, 51, Color(0.40, 0.28, 0.20))

	_rect(img, 0, 0, 15, H - 1, Color(0.52, 0.38, 0.28))
	_rect(img, W - 16, 0, W - 1, H - 1, Color(0.52, 0.38, 0.28))
	for y in range(0, H, 16):
		_rect(img, 0, y, 15, y + 3, Color(0.86, 0.68, 0.48))
		_rect(img, W - 16, y, W - 1, y + 3, Color(0.86, 0.68, 0.48))

	_draw_exit(img)


func _draw_exit(img: Image) -> void:
	_rect(img, 104, 128, 135, 159, Color(0.62, 0.30, 0.24))
	_rect(img, 104, 128, 135, 131, Color(0.92, 0.68, 0.42))
	_rect(img, 104, 156, 135, 159, Color(0.38, 0.18, 0.14))


func _draw_home(img: Image) -> void:
	_draw_rug(img, 72, 84, 96, 44)
	_draw_table(img, 96, 82)
	_draw_chair(img, 72, 94)
	_draw_chair(img, 144, 94)
	_draw_tv(img, 32, 38)
	_draw_pc(img, 56, 38)
	_draw_bed(img, 168, 48)
	_draw_bed(img, 192, 48)
	_draw_plant(img, 192, 108)


func _draw_house(img: Image) -> void:
	_draw_rug(img, 80, 84, 80, 36)
	_draw_shelf(img, 32, 36)
	_draw_shelf(img, 56, 36)
	_draw_tv(img, 176, 40)
	_draw_table(img, 96, 82)
	_draw_table(img, 120, 82)
	_draw_chair(img, 80, 96)
	_draw_chair(img, 152, 96)
	_draw_plant(img, 192, 108)


func _draw_shop(img: Image) -> void:
	for x in range(40, 184, 16):
		_draw_counter(img, x, 54)
	_draw_shelf(img, 32, 36)
	_draw_shelf(img, 184, 36)
	_draw_table(img, 64, 98)
	_draw_table(img, 160, 98)
	_draw_plant(img, 32, 112)
	_draw_rug(img, 96, 104, 48, 28)


func _draw_pyre(img: Image) -> void:
	_draw_rug(img, 56, 68, 128, 64)
	_draw_shelf(img, 32, 36)
	_draw_shelf(img, 184, 36)
	_draw_table(img, 112, 66)
	_draw_chair(img, 96, 86)
	_draw_chair(img, 136, 86)
	_draw_plant(img, 40, 116)
	_draw_plant(img, 184, 116)


func _draw_elder(img: Image) -> void:
	_draw_shelf(img, 40, 36)
	_draw_shelf(img, 64, 36)
	_draw_stairs(img, 176, 36)
	_draw_table(img, 96, 68)
	_draw_table(img, 120, 68)
	_draw_chair(img, 80, 84)
	_draw_chair(img, 152, 84)
	_draw_rug(img, 80, 104, 80, 28)
	_draw_plant(img, 192, 116)


func _draw_rug(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x, y, x + w - 1, y + h - 1, Color(0.62, 0.22, 0.24))
	_rect(img, x, y, x + w - 1, y + 3, Color(0.90, 0.68, 0.36))
	_rect(img, x, y + h - 4, x + w - 1, y + h - 1, Color(0.90, 0.68, 0.36))
	_rect(img, x + 8, y + 8, x + w - 9, y + h - 9, Color(0.76, 0.30, 0.30))


func _draw_table(img: Image, x: int, y: int) -> void:
	_rect(img, x, y + 5, x + 31, y + 22, Color(0.32, 0.18, 0.10))
	_rect(img, x + 2, y + 2, x + 29, y + 17, Color(0.72, 0.42, 0.20))
	_rect(img, x + 4, y + 4, x + 27, y + 6, Color(0.94, 0.66, 0.34))


func _draw_chair(img: Image, x: int, y: int) -> void:
	_rect(img, x + 4, y, x + 17, y + 14, Color(0.32, 0.18, 0.10))
	_rect(img, x + 6, y + 3, x + 15, y + 12, Color(0.72, 0.42, 0.22))
	_rect(img, x + 2, y + 15, x + 19, y + 20, Color(0.44, 0.24, 0.12))


func _draw_counter(img: Image, x: int, y: int) -> void:
	_rect(img, x, y + 8, x + 15, y + 31, Color(0.34, 0.22, 0.16))
	_rect(img, x, y + 2, x + 15, y + 13, Color(0.76, 0.54, 0.34))
	_rect(img, x, y + 2, x + 15, y + 4, Color(0.96, 0.76, 0.46))


func _draw_shelf(img: Image, x: int, y: int) -> void:
	_rect(img, x, y, x + 23, y + 31, Color(0.30, 0.18, 0.10))
	_rect(img, x + 2, y + 2, x + 21, y + 29, Color(0.58, 0.36, 0.20))
	_rect(img, x + 2, y + 12, x + 21, y + 14, Color(0.22, 0.12, 0.08))
	_rect(img, x + 2, y + 22, x + 21, y + 24, Color(0.22, 0.12, 0.08))
	_rect(img, x + 5, y + 5, x + 8, y + 9, Color(0.86, 0.72, 0.38))
	_rect(img, x + 14, y + 17, x + 19, y + 20, Color(0.42, 0.64, 0.80))


func _draw_bed(img: Image, x: int, y: int) -> void:
	_rect(img, x, y, x + 31, y + 47, Color(0.28, 0.16, 0.10))
	_rect(img, x + 2, y + 2, x + 29, y + 45, Color(0.76, 0.30, 0.32))
	_rect(img, x + 4, y + 4, x + 27, y + 17, Color(0.96, 0.88, 0.66))


func _draw_tv(img: Image, x: int, y: int) -> void:
	_rect(img, x, y, x + 23, y + 17, Color(0.18, 0.20, 0.24))
	_rect(img, x + 4, y + 3, x + 19, y + 13, Color(0.50, 0.76, 0.84))
	_rect(img, x + 10, y + 18, x + 13, y + 24, Color(0.28, 0.18, 0.12))


func _draw_pc(img: Image, x: int, y: int) -> void:
	_rect(img, x, y, x + 23, y + 23, Color(0.20, 0.22, 0.28))
	_rect(img, x + 3, y + 3, x + 20, y + 15, Color(0.48, 0.78, 0.88))
	_rect(img, x + 8, y + 24, x + 15, y + 29, Color(0.28, 0.28, 0.34))


func _draw_plant(img: Image, x: int, y: int) -> void:
	_rect(img, x + 8, y + 16, x + 15, y + 29, Color(0.42, 0.22, 0.12))
	_rect(img, x + 4, y + 26, x + 19, y + 31, Color(0.52, 0.26, 0.14))
	_rect(img, x + 2, y + 4, x + 21, y + 17, Color(0.08, 0.34, 0.18))
	_rect(img, x + 6, y, x + 17, y + 11, Color(0.22, 0.62, 0.28))
	_rect(img, x + 12, y + 2, x + 23, y + 9, Color(0.46, 0.78, 0.34))


func _draw_stairs(img: Image, x: int, y: int) -> void:
	for yy in range(0, 48, 8):
		_rect(img, x + 4, y + yy, x + 27, y + yy + 3, Color(0.62, 0.42, 0.26))
	_rect(img, x, y, x + 5, y + 47, Color(0.30, 0.18, 0.10))
	_rect(img, x + 26, y, x + 31, y + 47, Color(0.30, 0.18, 0.10))


func _rect(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	for y in range(maxi(0, y1), mini(img.get_height(), y2 + 1)):
		for x in range(maxi(0, x1), mini(img.get_width(), x2 + 1)):
			img.set_pixel(x, y, color)


func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)
