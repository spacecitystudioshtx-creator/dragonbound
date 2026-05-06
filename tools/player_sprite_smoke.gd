extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/player.tscn")
	if packed == null:
		push_error("failed to load player scene")
		quit(1)
		return
	var player: Node = packed.instantiate()
	root.add_child(player)
	await process_frame
	await process_frame
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		push_error("player has no AnimatedSprite2D")
		quit(1)
		return
	var tex := sprite.sprite_frames.get_frame_texture("idle_down", 0)
	if tex == null:
		push_error("idle_down has no texture")
		quit(1)
		return
	var img := tex.get_image()
	if img == null:
		push_error("active player frame has no image")
		quit(1)
		return
	img.save_png("/private/tmp/dragonbound_active_player_frame.png")
	print("saved active player frame")
	quit(0)
