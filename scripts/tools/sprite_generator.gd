## Sprite Generator Tool — generates all drake battle sprites via the
## HuggingFace Inference API (free tier, model: nerijs/pixel-art-xl).
##
## Usage:
##   1. Get a free token at https://huggingface.co/settings/tokens (read scope)
##   2. Run this scene (set as main or F6)
##   3. Paste token, click Generate
##   4. Sprites save to res://art/drakes/ — existing files are skipped
##
## After generation, restart Godot so the import system picks up the PNGs.
## The battle scene auto-detects and uses them (falls back to colored rects).

extends Node2D

const API_URL := "https://api-inference.huggingface.co/models/nerijs/pixel-art-xl"
const TARGET_SIZE := Vector2i(64, 64)
const NEG_PROMPT := "blurry, realistic, 3d render, photograph, multiple creatures, text, watermark, low quality, deformed"

var _token := ""
var _sprites: Array = []
var _index := 0
var _status: Label
var _input: LineEdit
var _btn: Button
var _progress: Label


func _ready() -> void:
	_build_sprite_list()
	_build_ui()


# ──────────────────────────────────────────────────────────────────────────────
# Sprite definitions
# ──────────────────────────────────────────────────────────────────────────────

func _build_sprite_list() -> void:
	## Fire line
	_add("ember",
		"small fire dragon hatchling, orange red scales, small flame on tail tip, cute fierce look")
	_add("scornn",
		"medium fire dragon, armored dark red scales, curved horns, small ember wings")
	_add("ashvane",
		"large fire dragon, ashen gray and deep red scales, massive wings, volcanic energy")

	## Water line
	_add("ripple",
		"small water serpent, light blue scales, fin ears, cute aquatic creature")
	_add("undertow",
		"medium sea serpent, deep blue scales, flowing fin crest, sleek aquatic body")
	_add("tidewrath",
		"large water leviathan dragon, dark blue and teal, massive jaws, tidal energy aura")

	## Nature line
	_add("sprig",
		"small plant creature, green leafy body, twig antlers, cute forest spirit")
	_add("thicket",
		"medium plant beast, bark armor plating, vine whips, forest guardian")
	_add("ironbark",
		"large tree golem, massive bark body, root legs, glowing amber eyes, ancient titan")

	## Fodder
	_add("flick",
		"tiny quick lizard, gray green scales, alert darting eyes, small common creature")
	_add("tuft",
		"small fluffy round creature, soft light fur, big curious eyes, common critter")
	_add("gulp",
		"small toad creature, wide grinning mouth, green spotted bumpy skin, common critter")


func _add(id: String, desc: String) -> void:
	_sprites.append({
		"id": id,
		"file": "res://art/drakes/" + id + "_front.png",
		"prompt": "pixel art game sprite, " + desc + ", front facing, single creature, centered on canvas, clean black outline, fantasy RPG monster, solid color background",
	})


# ──────────────────────────────────────────────────────────────────────────────
# UI
# ──────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.08, 0.08, 0.10)
	add_child(bg)

	_add_lbl(Vector2(10, 6), "Dragonbound — Sprite Generator", 10, Color.WHITE)
	_add_lbl(Vector2(10, 24), "HuggingFace Token (hf_...):", 8, Color.GRAY)

	_input = LineEdit.new()
	_input.position = Vector2(10, 38)
	_input.size = Vector2(200, 18)
	_input.placeholder_text = "hf_..."
	_input.secret = true
	_input.add_theme_font_size_override("font_size", 8)
	add_child(_input)

	_btn = Button.new()
	_btn.position = Vector2(218, 38)
	_btn.size = Vector2(92, 18)
	_btn.text = "Generate All"
	_btn.add_theme_font_size_override("font_size", 8)
	_btn.pressed.connect(_on_generate)
	add_child(_btn)

	_progress = _add_lbl(Vector2(10, 62), "", 8, Color.YELLOW)
	_status = _add_lbl(Vector2(10, 78), "", 8, Color(0.6, 0.8, 1.0))
	_status.size = Vector2(300, 90)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD

	_update_progress()


func _add_lbl(pos: Vector2, text: String, sz: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = Vector2(300, 14)
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", col)
	add_child(lbl)
	return lbl


func _update_progress() -> void:
	var done := 0
	for s in _sprites:
		if FileAccess.file_exists(s["file"]):
			done += 1
	_progress.text = "Sprites: " + str(done) + " / " + str(_sprites.size()) + " generated"


# ──────────────────────────────────────────────────────────────────────────────
# Generation pipeline
# ──────────────────────────────────────────────────────────────────────────────

func _on_generate() -> void:
	_token = _input.text.strip_edges()
	if _token.is_empty():
		_status.text = "Paste your HuggingFace token first.\nGet one free at huggingface.co/settings/tokens"
		return

	## Create output directory
	DirAccess.make_dir_recursive_absolute("res://art/drakes")

	_btn.disabled = true
	_btn.text = "Working..."
	_index = 0
	_generate_next()


func _generate_next() -> void:
	## Skip files that already exist
	while _index < _sprites.size():
		if FileAccess.file_exists(_sprites[_index]["file"]):
			_index += 1
		else:
			break

	if _index >= _sprites.size():
		_status.text = "All done! Restart Godot to import the new sprites."
		_btn.text = "Done"
		_update_progress()
		return

	var s: Dictionary = _sprites[_index]
	_status.text = "Generating " + s["id"] + "...  (" + str(_index + 1) + "/" + str(_sprites.size()) + ")\nThis may take 15-60s on the first call (model loading)."
	_call_api(s["prompt"], s["file"], s["id"])


func _call_api(prompt: String, save_path: String, id: String, retry := 0) -> void:
	var http := HTTPRequest.new()
	http.timeout = 120.0
	add_child(http)

	var headers := [
		"Authorization: Bearer " + _token,
		"Content-Type: application/json",
	]
	var body := JSON.stringify({
		"inputs": prompt,
		"parameters": {
			"negative_prompt": NEG_PROMPT,
			"width": 512,
			"height": 512,
		},
		"options": {"wait_for_model": true},
	})

	http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	var response: Array = await http.request_completed
	http.queue_free()

	var code: int       = response[1]
	var resp: PackedByteArray = response[3]

	if code == 200:
		_handle_success(resp, save_path, id)
	elif code == 503 and retry < 3:
		_handle_retry(prompt, save_path, id, retry, resp)
	else:
		_handle_error(code, resp, id)


func _handle_success(body: PackedByteArray, save_path: String, id: String) -> void:
	var img := Image.new()
	var err := img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		_status.text = "Could not decode image for " + id + ". Skipping."
		_index += 1
		_generate_next()
		return

	img.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
	img.save_png(save_path)
	_status.text = "Saved " + id + " -> " + save_path
	_update_progress()
	_index += 1
	_generate_next()


func _handle_retry(prompt: String, save_path: String, id: String, retry: int, body: PackedByteArray) -> void:
	var wait := 15.0
	var err_json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if err_json is Dictionary and err_json.has("estimated_time"):
		wait = float(err_json["estimated_time"]) + 2.0
	_status.text = "Model loading... retrying " + id + " in " + str(int(wait)) + "s (attempt " + str(retry + 2) + "/4)"
	await get_tree().create_timer(wait).timeout
	_call_api(prompt, save_path, id, retry + 1)


func _handle_error(code: int, body: PackedByteArray, id: String) -> void:
	var msg := body.get_string_from_utf8().left(200)
	_status.text = "Error " + str(code) + " on " + id + ":\n" + msg
	_index += 1
	## Keep going with the next sprite
	await get_tree().create_timer(2.0).timeout
	_generate_next()
