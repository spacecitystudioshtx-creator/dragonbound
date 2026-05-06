extends SceneTree


func _initialize() -> void:
	for path in [
		"res://scenes/maps/kindra_home_interior.tscn",
		"res://scenes/maps/kindra_shop_interior.tscn",
		"res://scenes/maps/kindra_house_interior.tscn",
		"res://scenes/maps/kindra_pyre_interior.tscn",
		"res://scenes/maps/kindra_elder_interior.tscn",
		"res://scenes/maps/kindra_town.tscn",
		"res://scenes/maps/dustway_route.tscn",
		"res://scenes/maps/zone_2.tscn",
	]:
		var packed := load(path)
		if packed == null:
			push_error("failed to load " + path)
			quit(1)
			return
		print("loaded ", path)
	quit(0)
