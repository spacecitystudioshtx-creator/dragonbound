## Back-compat shim for older scene-transition code.
##
## Player art now lives in art/player/kindra_trainer_sheet.png and is applied
## by player.gd itself. This autoload only asks the active player to refresh,
## so it cannot overwrite the real sheet with the old procedural placeholder.

extends Node


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("reapply")


func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		call_deferred("reapply")


func reapply() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_trainer_sheet"):
		player.refresh_trainer_sheet()
