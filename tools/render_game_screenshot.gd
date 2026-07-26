extends SceneTree

var _frames := 0


func _initialize() -> void:
	root.size = Vector2i(240, 160)
	var packed := load("res://scenes/maps/kindra_town.tscn")
	if packed == null:
		push_error("failed to load Kindra town")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 6:
		var player := get_first_node_in_group("player")
		if player:
			player.position = Vector2(120, 88)
			if "target_pos" in player:
				player.target_pos = player.position
	if _frames < 16:
		return false

	var tex := root.get_texture()
	if tex == null:
		push_error("could not capture viewport texture")
		quit(1)
		return true
	var img := tex.get_image()
	if img == null:
		push_error("could not capture viewport image")
		quit(1)
		return true
	img.save_png("/private/tmp/dragonbound_kindra_runtime.png")
	print("saved runtime screenshot")
	quit(0)
	return true
