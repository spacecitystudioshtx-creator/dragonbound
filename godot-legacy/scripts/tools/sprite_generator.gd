## Sprite Generator Tool — generates all drake battle sprites via the
## HuggingFace Inference API (free tier, model: nerijs/pixel-art-xl).
##
## TARGET STYLE: GBA Pokémon FireRed/LeafGreen battle sprites.
##   Bold black outlines, flat cell shading (no gradients), limited GBA palette,
##   chunky readable pixels, 3/4 front-facing bipedal dragon stance, black BG.
##   Reference: the official Gen-3 Pokémon battle sprite aesthetic.
##
## Usage:
##   1. Get a free token at https://huggingface.co/settings/tokens (read scope)
##   2. Run this scene (set as main or F6)
##   3. Paste token, click Generate All
##   4. Sprites save to res://art/drakes/ — existing files are SKIPPED.
##      Delete a file first if you want to re-generate it.
##   5. Restart Godot after generation so the import system picks up the PNGs.
##
## The battle scene auto-detects the PNGs; falls back to colored rects if missing.
##
## Style notes for future drakes:
##   - Lead with body color(s): "dark navy blue scales, cream underbelly"
##   - Name the wing type explicitly: "large red membranous bat wings"
##   - Include eye color: "glowing red eyes" / "amber eyes"
##   - Describe silhouette features: spikes, horns, fins, tail shape
##   - Keep the build human-readable: "stocky bipedal hatchling", "apex predator stance"
##   - Avoid vague adjectives ("cool", "awesome") — describe shapes and colors only

extends Node2D

## nerijs/pixel-art-xl is fine-tuned specifically for pixel art.
## Its trigger word "pixel_art" is prepended to every prompt automatically.
const API_URL    := "https://router.huggingface.co/hf-inference/models/nerijs/pixel-art-xl"
const TARGET_SIZE := Vector2i(80, 80)   ## stored at 80×80; battle scene displays at 52×52

## Style prefix injected into every prompt — defines the FireRed aesthetic.
const STYLE_PREFIX := (
	"pixel_art, GBA Game Boy Advance pokemon FireRed official battle sprite, "
	+ "bold black outline, flat cell shading no gradients, limited 32 color GBA palette, "
	+ "front 3/4 view facing viewer, single bipedal dragon creature centered, "
	+ "pure black background, chunky readable pixels, gen 3 pokemon creature design, "
)

## What to actively exclude — keeps results clean and on-style.
const NEG_PROMPT := (
	"blurry, realistic, photograph, 3d render, smooth gradients, airbrushed, "
	+ "anime style, chibi, too cute, multiple creatures, text, watermark, "
	+ "washed out, pastel, white background, sketch, pencil, painterly, modern digital art, "
	+ "overdetailed, noisy, jpeg artifacts, low quality, deformed"
)

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
	## ── Fire starter line ────────────────────────────────────────────────────
	## Eye color rule:
	##   Starters evos 1-2 + fodder → white sclera with colored pupils (FireRed style)
	##   Final evolutions (Ashvane, Tidewrath, Ironbark) → solid black eyes (rarer/darker)

	_add("ember",
		"small juvenile fire dragon hatchling, bright orange-red scales, "
		+ "pale orange segmented underbelly, tiny crimson membranous bat wings, "
		+ "flame-tipped tail, small ivory fangs and stubby horns, "
		+ "white eyes with red pupils, stocky compact bipedal body, fierce starter pose")

	_add("scornn",
		"medium fire dragon, deep blood-red and dark charcoal scales, "
		+ "row of ivory spikes along spine and shoulders, swept-back curved horns, "
		+ "dark ember-orange segmented underbelly, broad crimson bat wings, "
		+ "heavy muscular clawed arms, white eyes with red pupils, aggressive stance")

	_add("ashvane",
		"large volcanic fire dragon, dark charcoal slate-gray scales, "
		+ "ashen cream segmented underbelly plates, massive dark crimson membranous bat wings, "
		+ "crown of ivory spikes along head and spine, heavy muscular bipedal body, "
		+ "solid black eyes, apex dragon predator stance")

	## ── Water starter line ───────────────────────────────────────────────────
	_add("ripple",
		"small aquatic dragon hatchling, bright sky-blue scales, "
		+ "pale white segmented underbelly, fin-shaped ear crests, "
		+ "white eyes with blue pupils, slim serpentine tail, tiny webbed claws, "
		+ "sleek cute water starter body, gentle alert pose")

	_add("undertow",
		"medium sea dragon, deep ocean blue scales with teal highlights, "
		+ "silver-white segmented underbelly, tall swept dorsal fin crest on head, "
		+ "powerful flipper-clawed arms, sinuous muscular body, "
		+ "white eyes with blue pupils, flowing ribbon tail fins, confident swimmer stance")

	_add("tidewrath",
		"large water leviathan dragon, dark midnight blue and deep teal armored scales, "
		+ "massive armored lower jaw full of sharp fangs, crimson segmented underbelly, "
		+ "enormous sweeping ocean fin wings, solid black eyes, "
		+ "thick serpentine neck, heavy apex sea predator, imposing front stance")

	## ── Nature starter line ──────────────────────────────────────────────────
	_add("sprig",
		"small forest spirit dragon hatchling, bright leaf-green scales, "
		+ "cream woody segmented underbelly, two branching twig antlers, "
		+ "white eyes with amber pupils, small leaf-frond wings, vine-wrapped tail, "
		+ "round compact cute plant hatchling body, curious upright pose")

	_add("thicket",
		"medium bark-armored forest dragon, dark mahogany brown bark plating, "
		+ "forest-green moss patches between armor segments, white eyes with amber pupils, "
		+ "vine whip forearms with thorn hooks, leaf-edged wings, "
		+ "sturdy powerful guardian bipedal stance, nature protector")

	_add("ironbark",
		"large ancient tree golem dragon, very dark bark and stone-gray cracked body, "
		+ "gnarled root-like legs and sweeping root tail, massive trunk torso, "
		+ "solid black eyes under heavy stone brow ridge, "
		+ "rough cracked bark scales with ivy and lichen patches, "
		+ "towering ancient titan bipedal stance, awe-inspiring size")

	## ── Common wild fodder ───────────────────────────────────────────────────
	_add("flick",
		"small quick common lizard drake, muddy grey-green scales, "
		+ "pale beige underbelly, wide alert white eyes with yellow pupils, slender swift body, "
		+ "long thin whip tail, tiny sharp claws, unassuming wild creature pose")

	_add("tuft",
		"small round fluffy common drake, cream and soft white fur, "
		+ "round large white eyes with black pupils, stubby tiny limbs barely visible, "
		+ "plump round balloon-like body, small folded pointed ears, "
		+ "harmless endearing common critter pose")

	_add("gulp",
		"small squat toad drake, bumpy warty dark olive-green skin, "
		+ "wide pale cream belly, enormous gaping tooth-lined mouth, "
		+ "bulging round white eyes with yellow pupils on top of flat head, "
		+ "short stubby powerful legs, hunched common swamp critter pose")


func _add(id: String, desc: String) -> void:
	_sprites.append({
		"id":     id,
		"file":   "res://art/drakes/" + id + "_front.png",
		"prompt": STYLE_PREFIX + desc,
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
