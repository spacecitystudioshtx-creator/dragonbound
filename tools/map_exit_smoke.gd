extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/maps/kindra_town.tscn")
	if packed == null:
		push_error("failed to load Kindra town")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var obstacle_layer: TileMapLayer = scene.get_node_or_null("ObstacleLayer")
	if obstacle_layer == null:
		push_error("Kindra town has no obstacle layer")
		quit(1)
		return
	for tile in [Vector2i(34, 14), Vector2i(35, 14), Vector2i(34, 15), Vector2i(35, 15), Vector2i(34, 16), Vector2i(35, 16)]:
		if obstacle_layer.get_cell_source_id(tile) != -1:
			push_error("east exit blocked at tile " + str(tile))
			quit(1)
			return
	var exit_zone := scene.get_node_or_null("ExitToDustway")
	if exit_zone == null:
		push_error("Kindra town has no ExitToDustway")
		quit(1)
		return
	print("east exit open")
	quit(0)
