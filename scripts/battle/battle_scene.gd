## Full battle scene — UI and turn logic built entirely in code.
##
## Flow: intro message → player picks move → enemy acts → repeat → result → return.
## Player always acts before enemy (speed-based initiative is a future addition).

extends Node2D

# ── Layout ───────────────────────────────────────────────────────────────────
const VP_W    := 320
const VP_H    := 180
const FIELD_H := 120   ## Pixels for the battle field
const PANEL_H := 60    ## Pixels for the bottom UI panel
const BTN_W   := 160
const BTN_H   := 30

# ── Palette ──────────────────────────────────────────────────────────────────
const C_FIELD      := Color(0.55, 0.47, 0.35)
const C_PLATFORM   := Color(0.42, 0.35, 0.25)
const C_PANEL      := Color(0.10, 0.07, 0.03)
const C_BORDER     := Color(0.28, 0.18, 0.08)
const C_TEXT       := Color(1.00, 0.97, 0.90)
const C_HP_HIGH    := Color(0.20, 0.85, 0.20)
const C_HP_MED     := Color(0.90, 0.85, 0.10)
const C_HP_LOW     := Color(0.90, 0.20, 0.10)
const C_HP_BG      := Color(0.12, 0.12, 0.12)
const C_BTN        := Color(0.18, 0.12, 0.05)
const C_BTN_BORDER := Color(0.35, 0.23, 0.10)

## Tint colors for placeholder drake rectangles
const DRAKE_COL := {
	DrakeData.Type.FIRE:   Color(0.90, 0.35, 0.10),
	DrakeData.Type.WATER:  Color(0.15, 0.45, 0.90),
	DrakeData.Type.NATURE: Color(0.20, 0.75, 0.25),
}

## Move button tints by move type
const MOVE_COL := {
	MoveData.Type.FIRE:   Color(1.00, 0.78, 0.62),
	MoveData.Type.WATER:  Color(0.62, 0.85, 1.00),
	MoveData.Type.NATURE: Color(0.72, 1.00, 0.72),
	MoveData.Type.NORMAL: Color(0.85, 0.85, 0.85),
}

# ── State machine ─────────────────────────────────────────────────────────────
enum State { MESSAGE, SELECT, BENCH_SELECT, RESOLVING, DONE }
var _state := State.MESSAGE
var _msg_confirmed := false
var _queued_action := {}

# ── UI node references ────────────────────────────────────────────────────────
var _msg_label:         Label
var _move_btns:         Array = []   ## 4 × Button
var _bench_btns:        Array = []   ## 3 × Button
var _enemy_hp_bar:      ColorRect
var _player_hp_bar:     ColorRect
var _enemy_hp_label:    Label
var _player_hp_label:   Label
var _player_name_label: Label
var _enemy_sprite:      ColorRect
var _player_sprite:     ColorRect

# ── Battle data ───────────────────────────────────────────────────────────────
var _player: DrakeInstance
var _enemy:  DrakeInstance


func _ready() -> void:
	_player = GameState.get_active()
	_enemy  = BattleManager.enemy_party[0]
	_player.reset_battle_state()
	_enemy.reset_battle_state()
	GameState.selected_bench_slot = 0

	_build_ui()
	_run_battle.call_deferred()


# ─────────────────────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	## Field background
	_add_rect(Vector2.ZERO, Vector2(VP_W, FIELD_H), C_FIELD)

	## Platforms
	_add_rect(Vector2(18, 56), Vector2(80, 10), C_PLATFORM)   ## enemy
	_add_rect(Vector2(222, 92), Vector2(80, 10), C_PLATFORM)  ## player

	## Drake sprites (placeholder colored rects)
	_enemy_sprite = _add_rect(Vector2(30, 22), Vector2(32, 32),
			DRAKE_COL.get(_enemy.data.type, Color.WHITE))
	_player_sprite = _add_rect(Vector2(258, 58), Vector2(32, 32),
			DRAKE_COL.get(_player.data.type, Color.WHITE))

	## Info boxes
	_build_info_box(Vector2(148, 6),  _enemy,  true)
	_build_info_box(Vector2(4,   70), _player, false)

	## Bottom panel
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, PANEL_H), C_PANEL)
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, 2), C_BORDER)

	## Message label (full panel area)
	_msg_label = _add_label(Vector2(8, FIELD_H + 6), Vector2(VP_W - 16, PANEL_H - 10), "")
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	## Move buttons — 2×2 grid filling the panel
	for i in 4:
		var btn := _make_button(
				Vector2((i % 2) * BTN_W, FIELD_H + (i / 2) * BTN_H),
				Vector2(BTN_W, BTN_H), "")
		var idx := i
		btn.pressed.connect(func(): _on_move_pressed(idx))
		_move_btns.append(btn)

	## Bench buttons — 3 equal columns in the lower row of the panel
	for i in 3:
		var bw := int(VP_W / 3)
		var btn := _make_button(
				Vector2(i * bw, FIELD_H + BTN_H),
				Vector2(bw, BTN_H), "")
		var idx := i
		btn.pressed.connect(func(): _on_bench_pressed(idx))
		btn.visible = false
		_bench_btns.append(btn)

	_set_ui_mode("message")
	_update_hp_bars()


func _build_info_box(pos: Vector2, drake: DrakeInstance, is_enemy: bool) -> void:
	_add_rect(pos, Vector2(160, 46), Color(0.07, 0.04, 0.01, 0.88))
	_add_rect(pos, Vector2(160, 46), Color(0.28, 0.18, 0.08, 0.5), true)

	var name_lbl := _add_label(pos + Vector2(4, 3), Vector2(152, 12),
			drake.nickname + "  Lv" + str(drake.level))
	if not is_enemy:
		_player_name_label = name_lbl

	var hp_lbl := _add_label(pos + Vector2(4, 16), Vector2(152, 10), "HP")
	if is_enemy:
		_enemy_hp_label = hp_lbl
	else:
		_player_hp_label = hp_lbl

	## HP bar background
	_add_rect(pos + Vector2(4, 28), Vector2(150, 7), C_HP_BG)

	## HP bar fill (tracked by ref)
	var bar := _add_rect(pos + Vector2(4, 28), Vector2(150, 7), C_HP_HIGH)
	if is_enemy:
		_enemy_hp_bar = bar
	else:
		_player_hp_bar = bar


# ─────────────────────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────────────────────

func _set_ui_mode(mode: String) -> void:
	match mode:
		"message":
			_msg_label.visible = true
			for b in _move_btns: b.visible = false
			for b in _bench_btns: b.visible = false
		"moves":
			_msg_label.visible = false
			for b in _bench_btns: b.visible = false
			_refresh_move_buttons()
			for b in _move_btns: b.visible = true
		"bench":
			_msg_label.text = "Choose bench drake:"
			_msg_label.visible = true
			for b in _move_btns: b.visible = false
			_refresh_bench_buttons()
			for b in _bench_btns: b.visible = true


func _refresh_move_buttons() -> void:
	for i in 3:
		var btn: Button = _move_btns[i]
		if i < _player.moves.size():
			var mv: MoveData = _player.moves[i]
			btn.text = mv.move_name
			btn.modulate = MOVE_COL.get(mv.type, Color.WHITE)
			btn.disabled = false
		else:
			btn.text = "—"
			btn.disabled = true

	## Bench combo button
	var bench := GameState.get_bench()
	var combo_btn: Button = _move_btns[3]
	if bench.is_empty() or _player.bench_blocked_turns > 0:
		combo_btn.text = "—" if bench.is_empty() else "BLOCKED"
		combo_btn.disabled = true
		combo_btn.modulate = Color.WHITE
	else:
		var bd: DrakeInstance = bench[GameState.selected_bench_slot]
		var combo := DrakeDatabase.get_combo_move(_player.data.type, bd.data.type)
		combo_btn.text = (combo.move_name if combo else "—") + "\n[" + bd.nickname + "]"
		combo_btn.disabled = combo == null
		combo_btn.modulate = MOVE_COL.get(combo.type if combo else MoveData.Type.NORMAL, Color.WHITE)


func _refresh_bench_buttons() -> void:
	var bench := GameState.get_bench()
	for i in 3:
		var btn: Button = _bench_btns[i]
		if i < bench.size():
			var bd: DrakeInstance = bench[i]
			btn.text = bd.nickname + " Lv" + str(bd.level)
			btn.disabled = false
		else:
			btn.text = "—"
			btn.disabled = true


func _update_hp_bars() -> void:
	_update_one_bar(_player, _player_hp_bar, _player_hp_label, false)
	_update_one_bar(_enemy,  _enemy_hp_bar,  _enemy_hp_label,  true)


func _update_one_bar(drake: DrakeInstance, bar: ColorRect, lbl: Label, is_enemy: bool) -> void:
	var pct := float(drake.current_hp) / float(drake.get_max_hp())
	bar.size.x = 150.0 * clampf(pct, 0.0, 1.0)
	bar.color   = C_HP_HIGH if pct > 0.5 else (C_HP_MED if pct > 0.25 else C_HP_LOW)
	lbl.text    = "HP %d/%d" % [drake.current_hp, drake.get_max_hp()] if not is_enemy else "HP"


# ─────────────────────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _state == State.MESSAGE and event.is_action_pressed("ui_accept"):
		_msg_confirmed = true


func _on_move_pressed(idx: int) -> void:
	if _state != State.SELECT:
		return
	if idx == 3:
		## Bench combo — show bench picker
		_queued_action = {"type": "combo"}
		_state = State.BENCH_SELECT
		_set_ui_mode("bench")
	elif idx < _player.moves.size():
		_queued_action = {"type": "move", "move": _player.moves[idx]}
		_state = State.RESOLVING
		_set_ui_mode("message")


func _on_bench_pressed(idx: int) -> void:
	if _state != State.BENCH_SELECT:
		return
	var bench := GameState.get_bench()
	if idx >= bench.size():
		return
	GameState.selected_bench_slot = idx
	var bd: DrakeInstance = bench[idx]
	var combo := DrakeDatabase.get_combo_move(_player.data.type, bd.data.type)
	_queued_action = {"type": "combo", "move": combo, "bench": bd}
	_state = State.RESOLVING
	_set_ui_mode("message")


# ─────────────────────────────────────────────────────────────────────────────
# Battle flow
# ─────────────────────────────────────────────────────────────────────────────

func _run_battle() -> void:
	var intro := ""
	if BattleManager.is_trainer_battle:
		intro = BattleManager.trainer_name + " wants to battle!\n" + \
				BattleManager.trainer_name + " sent out " + _enemy.nickname + "!"
	else:
		intro = "A wild " + _enemy.nickname + " appeared!"

	await _show_and_wait(intro)
	await _show_and_wait("Go! " + _player.nickname + "!")

	while not _is_over():
		await _player_turn()
		if _is_over():
			break
		await _enemy_turn()
		await _end_of_turn_effects()

	await _show_result()
	_finish()


## Display text and block until ui_accept is pressed.
func _show_and_wait(text: String) -> void:
	_state = State.MESSAGE
	_msg_label.text = text
	_msg_confirmed = false
	while not _msg_confirmed:
		await get_tree().process_frame
	_msg_confirmed = false


## Block until the player submits an action (move or bench combo).
func _player_turn() -> void:
	_state = State.SELECT
	_set_ui_mode("moves")
	while _state != State.RESOLVING:
		await get_tree().process_frame

	var action := _queued_action
	_queued_action = {}

	if action.get("type") == "combo":
		await _execute_move(action["move"], _player, _enemy, action.get("bench"))
	else:
		await _execute_move(action["move"], _player, _enemy, null)


func _enemy_turn() -> void:
	if _enemy.is_fainted():
		return
	var mv := _enemy_pick_move()
	await _execute_move(mv, _enemy, _player, null)


func _enemy_pick_move() -> MoveData:
	if _enemy.moves.is_empty():
		return null
	return _enemy.moves[randi() % _enemy.moves.size()]


func _end_of_turn_effects() -> void:
	## Tick bench block counters
	if _player.bench_blocked_turns > 0:
		_player.bench_blocked_turns -= 1
	if _enemy.bench_blocked_turns > 0:
		_enemy.bench_blocked_turns -= 1

	for pair in [[_player, "your " + _player.nickname], [_enemy, _enemy.nickname]]:
		var drake: DrakeInstance = pair[0]
		var label: String = pair[1]
		if drake.is_burned and not drake.is_fainted():
			var dmg := maxi(1, int(drake.get_max_hp() * 0.10))
			drake.take_damage(dmg)
			_update_hp_bars()
			await _show_and_wait(label + " is burning! (-" + str(dmg) + " HP)")


func _execute_move(mv: MoveData, atk: DrakeInstance, def: DrakeInstance, bench: DrakeInstance) -> void:
	if mv == null:
		return

	## Fortify skip
	if atk.is_fortified:
		atk.is_fortified = false
		await _show_and_wait(atk.nickname + " can't move while fortified!")
		return

	await _show_and_wait(atk.nickname + " used " + mv.move_name + "!")

	## Accuracy check
	if mv.accuracy > 0:
		var eff_acc := mv.accuracy * atk.accuracy_mod
		if randf() < def.evasion_chance or randf() * 100.0 > eff_acc:
			await _show_and_wait("But it missed!")
			return

	## Damage calculation
	if mv.power > 0:
		var power := mv.power
		if bench != null:
			power += int((atk.level + bench.level) * 0.5)  ## combo scaling

		var def_stat := def.get_def()
		if mv.effect == MoveData.Effect.IGNORE_DEF_BUFFS:
			def_stat = def.data.base_def + def.level * 2  ## ignore modifier

		var type_mult := _type_effectiveness(mv.type, def.data.type)
		var stab      := 1.5 if int(mv.type) == int(atk.data.type) else 1.0
		var rng       := randf_range(0.85, 1.0)
		var dmg       := int(float(power) * float(atk.get_atk()) / float(maxi(1, def_stat))
							 * type_mult * stab * rng)

		def.take_damage(dmg)
		_update_hp_bars()

		var eff_txt := ""
		if   type_mult >= 2.0: eff_txt = "\nSuper effective!"
		elif type_mult <= 0.5: eff_txt = "\nNot very effective..."
		await _show_and_wait(def.nickname + " took " + str(dmg) + " damage!" + eff_txt)

		## Recoil
		if mv.effect == MoveData.Effect.SELF_DAMAGE:
			var recoil := maxi(1, int(atk.get_max_hp() * mv.effect_value))
			atk.take_damage(recoil)
			_update_hp_bars()
			await _show_and_wait(atk.nickname + " took " + str(recoil) + " recoil damage!")

	## Secondary effects
	match mv.effect:
		MoveData.Effect.LOWER_ACCURACY:
			def.accuracy_mod = maxf(0.3, def.accuracy_mod - mv.effect_value)
			await _show_and_wait(def.nickname + "'s accuracy fell!")
		MoveData.Effect.RAISE_DEFENSE:
			atk.defense_mod += mv.effect_value
			await _show_and_wait(atk.nickname + "'s defense rose!")
		MoveData.Effect.REFLECT_DAMAGE:
			atk.defense_mod += 0.3
			await _show_and_wait(atk.nickname + "'s defenses hardened!")
		MoveData.Effect.RAISE_EVASION:
			atk.evasion_chance = minf(0.75, atk.evasion_chance + mv.effect_value)
			await _show_and_wait(atk.nickname + "'s evasion rose!")
		MoveData.Effect.BURN_DOT:
			if not def.is_burned:
				def.is_burned = true
				await _show_and_wait(def.nickname + " caught fire!")
		MoveData.Effect.TRAP:
			def.is_trapped = true
			await _show_and_wait(def.nickname + " is trapped!")
		MoveData.Effect.BLOCK_BENCH:
			def.bench_blocked_turns = int(mv.effect_value)
			await _show_and_wait(def.nickname + "'s bench combo is blocked for "
					+ str(int(mv.effect_value)) + " turns!")
		MoveData.Effect.HEAL_SELF:
			var amt := int(atk.get_max_hp() * mv.effect_value)
			atk.heal(amt)
			_update_hp_bars()
			await _show_and_wait(atk.nickname + " restored " + str(amt) + " HP!")
		MoveData.Effect.HEAL_TEAM:
			for drake in GameState.party:
				drake.heal(int(drake.get_max_hp() * mv.effect_value))
			_update_hp_bars()
			await _show_and_wait("The whole team was healed a little!")
		MoveData.Effect.FLOOD:
			def.defense_mod  = 1.0
			def.accuracy_mod = 1.0
			await _show_and_wait(def.nickname + "'s stat buffs were washed away!")
		MoveData.Effect.FORTIFY:
			atk.defense_mod   += mv.effect_value
			atk.is_fortified   = true
			await _show_and_wait(atk.nickname + " fortified! It can't move next turn.")

	if def.is_fainted():
		_update_hp_bars()
		await _show_and_wait(def.nickname + " fainted!")


func _type_effectiveness(mv_type: MoveData.Type, def_type: DrakeData.Type) -> float:
	if mv_type == MoveData.Type.NORMAL:
		return 1.0
	## FIRE=0, WATER=1, NATURE=2
	match [int(mv_type), int(def_type)]:
		[0, 2]: return 2.0   ## Fire → Nature
		[0, 1]: return 0.5   ## Fire → Water
		[1, 0]: return 2.0   ## Water → Fire
		[1, 2]: return 0.5   ## Water → Nature
		[2, 1]: return 2.0   ## Nature → Water
		[2, 0]: return 0.5   ## Nature → Fire
	return 1.0


func _is_over() -> bool:
	return _player.is_fainted() or _enemy.is_fainted()


func _show_result() -> void:
	if _player.is_fainted():
		await _show_and_wait(_player.nickname + " fainted...")
		await _show_and_wait("You blacked out!")
		return

	var xp := maxi(1, int(_enemy.data.base_hp * _enemy.level * 0.3))
	var leveled := _player.gain_xp(xp)
	await _show_and_wait(_enemy.nickname + " was defeated!")
	await _show_and_wait(_player.nickname + " gained " + str(xp) + " XP!")

	if leveled:
		if _player_name_label:
			_player_name_label.text = _player.nickname + "  Lv" + str(_player.level)
		_update_hp_bars()
		await _show_and_wait(_player.nickname + " grew to level " + str(_player.level) + "!")

		## Check for evolution
		if _player.data.evolution_id != "" and _player.level >= _player.data.evolution_level:
			var evo_data: DrakeData = DrakeDatabase.drakes.get(_player.data.evolution_id)
			if evo_data:
				var old_name := _player.nickname
				_player.data    = evo_data
				_player.nickname = evo_data.drake_name
				_player.current_hp = mini(_player.current_hp, _player.get_max_hp())
				## Add new moves not already known
				for mv in evo_data.base_moves:
					if _player.moves.size() < 3 and mv not in _player.moves:
						_player.moves.append(mv)
				_update_hp_bars()
				await _show_and_wait(old_name + " is evolving...")
				await _show_and_wait(old_name + " evolved into " + _player.nickname + "!")


func _finish() -> void:
	_state = State.DONE
	GameState.reset_party_battle_state()
	GameState.battle_cooldown_steps = 5  ## prevent instant re-encounter on return
	SceneTransition.change_scene(GameState.return_scene, GameState.return_pos)


# ─────────────────────────────────────────────────────────────────────────────
# Node factory helpers
# ─────────────────────────────────────────────────────────────────────────────

func _add_rect(pos: Vector2, sz: Vector2, color: Color, border_only: bool = false) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size     = sz
	r.color    = color
	if border_only:
		## Simulate a 1px border by using a slightly smaller transparent inner rect
		var inner := ColorRect.new()
		inner.position = Vector2(1, 1)
		inner.size     = sz - Vector2(2, 2)
		inner.color    = Color.TRANSPARENT
		r.add_child(inner)
	add_child(r)
	return r


func _add_label(pos: Vector2, sz: Vector2, text: String) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size     = sz
	lbl.text     = text
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.add_theme_font_size_override("font_size", 8)
	add_child(lbl)
	return lbl


func _make_button(pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size     = sz
	btn.text     = text
	btn.flat     = false
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_font_size_override("font_size", 8)

	## Style the button to match the pixel-art palette
	var normal := StyleBoxFlat.new()
	normal.bg_color     = C_BTN
	normal.border_color = C_BTN_BORDER
	normal.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color     = C_BTN_BORDER
	hover.border_color = C_TEXT
	hover.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", hover)

	add_child(btn)
	return btn
