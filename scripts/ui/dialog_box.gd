## FireRed-style dialog box with letter-by-letter reveal.
##
## Usage:
##   SignalBus.dialog_requested.emit("kindra", "elder_moss")
##
## The dialog runner looks up the node in data/dialog/<file>.json, walks the
## array of lines, and shows each one. Lines can be:
##   - string                        → plain text
##   - {"text": "..."}               → plain text (object form)
##   - {"set_flag": "..."}           → sets a GameState flag, no text shown
##   - {"check_flag": "...", "then": [...], "else": [...]}  (future)
##   - {"start_battle": "..."}       → emits battle_started (future)
##
## Input: Enter / Space / Tap anywhere on the box to advance. Mid-reveal, the
## first press fast-forwards to show the full line; the next press advances.

extends CanvasLayer

const REVEAL_CHARS_PER_SEC := 40.0
const DIALOG_DIR := "res://data/dialog/"

@onready var panel: PanelContainer = $Panel
@onready var label: RichTextLabel = $Panel/Margin/Label
@onready var advance_hint: Label = $Panel/AdvanceHint

var _lines: Array = []
var _line_idx: int = 0
var _full_text: String = ""
var _reveal_pos: float = 0.0
var _revealing: bool = false


func _ready() -> void:
	panel.visible = false
	advance_hint.visible = false
	SignalBus.dialog_requested.connect(_on_dialog_requested)


func _process(delta: float) -> void:
	if not _revealing:
		return
	_reveal_pos += REVEAL_CHARS_PER_SEC * delta
	var visible_chars := int(_reveal_pos)
	if visible_chars >= _full_text.length():
		label.visible_characters = -1
		_revealing = false
		advance_hint.visible = true
	else:
		label.visible_characters = visible_chars


func _unhandled_input(event: InputEvent) -> void:
	if GameMode.current() != GameMode.Mode.DIALOG:
		return
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		_advance()
		get_viewport().set_input_as_handled()


## ── Public entry ─────────────────────────────────────────────────────────────

func _on_dialog_requested(dialog_file: String, node_id: String) -> void:
	var path := DIALOG_DIR + dialog_file + ".json"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("dialog_box: could not open %s" % path)
		return
	var j: Variant = JSON.parse_string(f.get_as_text())
	if typeof(j) != TYPE_DICTIONARY:
		return
	var npcs: Dictionary = j.get("npcs", {})
	var node: Variant = npcs.get(node_id, null)
	if node == null:
		push_warning("dialog_box: no npc '%s' in %s" % [node_id, dialog_file])
		return

	## Support two shapes:
	##   {"name": "...", "intro": [...], "post_starter": [...]}  ← npc w/ variants
	##   {"text": "..."}                                          ← sign-style
	var lines: Array = []
	if node is Dictionary:
		var nd: Dictionary = node
		if nd.has("text"):
			lines = [String(nd["text"])]
		else:
			## Pick first variant whose flag condition matches. For MVP just
			## pick "intro" if starter not given, else "post_starter".
			var starter_given: bool = GameState.has_method("get_flag") and GameState.get_flag("starter_given")
			if starter_given and nd.has("post_starter"):
				lines = nd["post_starter"]
			elif nd.has("intro"):
				lines = nd["intro"]
			elif nd.has("lines"):
				lines = nd["lines"]
	elif node is Array:
		lines = node

	if lines.is_empty():
		return

	_lines = lines
	_line_idx = -1
	GameMode.push(GameMode.Mode.DIALOG)
	panel.visible = true
	_next_line()


## ── Line advance ─────────────────────────────────────────────────────────────

func _advance() -> void:
	if _revealing:
		## Fast-forward current line.
		label.visible_characters = -1
		_revealing = false
		advance_hint.visible = true
		return
	_next_line()


func _next_line() -> void:
	_line_idx += 1
	if _line_idx >= _lines.size():
		_close()
		return
	var line: Variant = _lines[_line_idx]

	## Object-form lines (flag sets, future actions) — handle and skip.
	if line is Dictionary:
		var d: Dictionary = line
		if d.has("set_flag"):
			var flag: String = d["set_flag"]
			if GameState.has_method("set_flag"):
				GameState.set_flag(flag, true)
			SignalBus.flag_set.emit(flag, true)
			_next_line()
			return
		if d.has("start_battle"):
			## Defer to battle system; leave dialog mode open to resume after.
			SignalBus.battle_started.emit(String(d["start_battle"]), 5, String(d["start_battle"]))
			_next_line()
			return
		if d.has("text"):
			_show_line(String(d["text"]))
			return
		_next_line()
		return

	## Plain string.
	_show_line(String(line))


func _show_line(text: String) -> void:
	_full_text = text
	label.text = text
	label.visible_characters = 0
	_reveal_pos = 0.0
	_revealing = true
	advance_hint.visible = false


func _close() -> void:
	panel.visible = false
	advance_hint.visible = false
	_lines = []
	_line_idx = 0
	GameMode.pop()
	SignalBus.dialog_closed.emit()
