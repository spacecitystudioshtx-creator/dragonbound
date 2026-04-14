## Save / load system. Autoloaded as SaveSystem.
##
## Serializes GameState to user://save.json — a JSON doc the user and AI
## tooling can read/edit. Party is serialized by drake id + level + current
## HP + move ids; rebuilt via DrakeDatabase.make_drake on load.
##
## Auto-save on major events (battle won, flag set) is wired by listening to
## SignalBus. Manual save via `SaveSystem.save()`.

extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func _ready() -> void:
	## Auto-save hooks.
	SignalBus.battle_ended.connect(_on_battle_ended)
	SignalBus.flag_set.connect(_on_flag_set)


## ── Save ─────────────────────────────────────────────────────────────────────

func save() -> bool:
	var data := {
		"_schema_version": SAVE_VERSION,
		"_saved_at": Time.get_datetime_string_from_system(),
		"has_starter": GameState.has_starter,
		"flags": _get_flags(),
		"party": _serialize_party(),
		"scene": _current_scene_path(),
		"position": _player_position_dict(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: could not open %s for write" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	SignalBus.game_saved.emit()
	return true


func _serialize_party() -> Array:
	var out: Array = []
	if not "party" in GameState:
		return out
	var party: Array = GameState.party
	for d in party:
		if d == null:
			continue
		var entry := {
			"id": d.data.drake_name.to_lower() if d.data else "unknown",
			"species_id": _find_species_id(d),
			"level": d.level,
			"current_hp": d.current_hp,
			"max_hp": d.max_hp,
			"moves": _move_ids_for(d),
		}
		out.append(entry)
	return out


func _find_species_id(drake_instance) -> String:
	if drake_instance == null or drake_instance.data == null:
		return ""
	var dname: String = drake_instance.data.drake_name
	for id in DrakeDatabase.drakes.keys():
		var species = DrakeDatabase.drakes[id]
		if species.drake_name == dname:
			return id
	return dname.to_lower()


func _move_ids_for(drake_instance) -> Array:
	var out: Array = []
	if drake_instance == null:
		return out
	var known_moves = drake_instance.get("moves") if "moves" in drake_instance else []
	if known_moves == null:
		return out
	for mv in known_moves:
		if mv == null:
			continue
		for mid in DrakeDatabase.moves.keys():
			if DrakeDatabase.moves[mid].move_name == mv.move_name:
				out.append(mid)
				break
	return out


func _get_flags() -> Dictionary:
	if GameState.has_method("get_all_flags"):
		return GameState.get_all_flags()
	if "flags" in GameState:
		return GameState.flags
	return {}


func _current_scene_path() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		return tree.current_scene.scene_file_path
	return ""


func _player_position_dict() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return {}
	return {"x": player.position.x, "y": player.position.y}


## ── Load ─────────────────────────────────────────────────────────────────────

func exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> bool:
	if not exists():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed

	GameState.has_starter = bool(data.get("has_starter", false))

	## Restore flags.
	var flags: Dictionary = data.get("flags", {})
	for k in flags.keys():
		if GameState.has_method("set_flag"):
			GameState.set_flag(k, flags[k])

	## Rebuild party.
	var party_data: Array = data.get("party", [])
	var new_party: Array = []
	for entry in party_data:
		var species_id: String = entry.get("species_id", "")
		if species_id == "" or not DrakeDatabase.drakes.has(species_id):
			continue
		var inst = DrakeDatabase.make_drake(species_id, int(entry.get("level", 5)))
		if inst and "current_hp" in inst:
			inst.current_hp = int(entry.get("current_hp", inst.max_hp))
		new_party.append(inst)
	if "party" in GameState:
		GameState.party = new_party

	## Load scene if present.
	var scene_path: String = data.get("scene", "")
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.change_scene_to_file(scene_path)
			var pos: Dictionary = data.get("position", {})
			if not pos.is_empty():
				await tree.process_frame
				var player := tree.get_first_node_in_group("player")
				if player:
					player.position = Vector2(pos.get("x", 0), pos.get("y", 0))

	SignalBus.game_loaded.emit()
	return true


## ── Auto-save hooks ──────────────────────────────────────────────────────────

func _on_battle_ended(_result: String) -> void:
	save()


func _on_flag_set(_flag: String, _value: Variant) -> void:
	save()
