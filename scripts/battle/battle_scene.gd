## Full battle scene — UI and turn logic built entirely in code.
##
## Flow: intro message → player picks move → enemy acts → repeat → result → return.
## Player always acts before enemy (speed-based initiative is a future addition).

extends Node2D

# ── Layout ────────────────────────────────────────────────────────────────────
const VP_W         := 320
const VP_H         := 180
const FIELD_H      := 120
const PANEL_H      := 60
const BTN_W        := 160
const BTN_H        := 30
const INFO_BOX_W   := 164
const INFO_HP_BAR_W := 134   ## INFO_BOX_W - 30

# ── Palette ───────────────────────────────────────────────────────────────────
const C_SKY        := Color(0.49, 0.75, 0.93)   ## Field sky
const C_GRASS      := Color(0.35, 0.65, 0.22)   ## Field grass
const C_GRASS_DARK := Color(0.28, 0.55, 0.17)   ## Grass texture stripes
const C_PLATFORM   := Color(0.18, 0.36, 0.10)   ## Platform oval shadow
const C_UI_BG      := Color(0.93, 0.93, 0.87)   ## Cream white (panels, HP boxes)
const C_UI_BORDER  := Color(0.06, 0.06, 0.06)   ## Near-black border
const C_TEXT       := Color(0.06, 0.06, 0.06)   ## Dark text
const C_HP_HIGH    := Color(0.22, 0.82, 0.16)   ## Green HP
const C_HP_MED     := Color(0.96, 0.82, 0.06)   ## Yellow HP
const C_HP_LOW     := Color(0.90, 0.16, 0.10)   ## Red HP
const C_HP_BG      := Color(0.28, 0.14, 0.14)   ## HP bar track

## Drake sprite colors by type
const DRAKE_COL := {
	DrakeData.Type.FIRE:   Color(0.92, 0.36, 0.12),
	DrakeData.Type.WATER:  Color(0.16, 0.46, 0.90),
	DrakeData.Type.NATURE: Color(0.22, 0.72, 0.25),
}

## Move button background tints by type
const MOVE_COL := {
	MoveData.Type.FIRE:   Color(1.00, 0.80, 0.65),
	MoveData.Type.WATER:  Color(0.65, 0.85, 1.00),
	MoveData.Type.NATURE: Color(0.72, 1.00, 0.72),
	MoveData.Type.NORMAL: Color(0.88, 0.88, 0.88),
}

# ── State machine ──────────────────────────────────────────────────────────────
enum State { MESSAGE, SELECT, BENCH_SELECT, RESOLVING, DONE }
var _state := State.MESSAGE
var _msg_confirmed := false
var _queued_action := {}

# ── UI node references ─────────────────────────────────────────────────────────
var _msg_label:         Label
var _confirm_arrow:     Label
var _move_btns:         Array = []   ## 4 × Button
var _bench_btns:        Array = []   ## 3 × Button
var _enemy_hp_bar:      ColorRect
var _player_hp_bar:     ColorRect
var _enemy_hp_label:    Label        ## static "HP" text
var _player_hp_label:   Label        ## live "cur/max" numbers
var _player_name_label: Label
var _enemy_sprite:      ColorRect
var _player_sprite:     ColorRect

# ── Battle data ────────────────────────────────────────────────────────────────
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


# ──────────────────────────────────────────────────────────────────────────────
# UI construction
# ──────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	## ── Field background ──────────────────────────────────────────────────
	_add_rect(Vector2(0, 0),  Vector2(VP_W, 70), C_SKY)
	_add_rect(Vector2(0, 70), Vector2(VP_W, 50), C_GRASS)
	## Horizontal texture stripes across the grass section
	for i in 4:
		_add_rect(Vector2(0, 75 + i * 11), Vector2(VP_W, 3), C_GRASS_DARK)

	## ── Platform oval shadows ─────────────────────────────────────────────
	_draw_platform(58.0,  69.0, 78)   ## enemy platform (upper-left area)
	_draw_platform(258.0, 104.0, 78)  ## player platform (lower-right area)

	## ── Drake sprites ─────────────────────────────────────────────────────
	## Enemy: front-facing, upper-left
	_enemy_sprite = _add_rect(Vector2(26, 24), Vector2(40, 40),
			DRAKE_COL.get(_enemy.data.type, Color.WHITE))
	## Player: back-facing (slightly larger), lower-right
	_player_sprite = _add_rect(Vector2(230, 57), Vector2(44, 44),
			DRAKE_COL.get(_player.data.type, Color.WHITE))

	## ── HP info boxes ─────────────────────────────────────────────────────
	_build_info_box(Vector2(148, 5),  _enemy,  true)
	_build_info_box(Vector2(4,   72), _player, false)

	## ── Bottom panel — cream white with thick dark top border ─────────────
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, PANEL_H), C_UI_BG)
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, 3),       C_UI_BORDER)

	## Message label (full panel width, left-aligned with margin)
	_msg_label = _add_label(
			Vector2(8, FIELD_H + 7), Vector2(VP_W - 28, PANEL_H - 14), "")
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	## ▼ confirm indicator shown in bottom-right while waiting for input
	_confirm_arrow = _add_label(
			Vector2(VP_W - 16, VP_H - 13), Vector2(12, 11), "▼")
	_confirm_arrow.visible = false

	## ── Move buttons — 2×2 grid filling the panel ────────────────────────
	for i in 4:
		var btn := _make_button(
				Vector2((i % 2) * BTN_W, FIELD_H + (i / 2) * BTN_H),
				Vector2(BTN_W, BTN_H), "")
		var idx := i
		btn.pressed.connect(func(): _on_move_pressed(idx))
		_move_btns.append(btn)

	## ── Bench buttons — 3 equal columns in lower half of panel ───────────
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
	var W := INFO_BOX_W
	var H := 46
	## Dark outer border, cream inner fill
	_add_rect(pos,                   Vector2(W, H),         C_UI_BORDER)
	_add_rect(pos + Vector2(2, 2),   Vector2(W - 4, H - 4), C_UI_BG)

	## Name + level
	var name_lbl := _add_label(
			pos + Vector2(5, 4), Vector2(W - 10, 11),
			drake.nickname + "  Lv" + str(drake.level))
	if not is_enemy:
		_player_name_label = name_lbl

	## Thin divider under name
	_add_rect(pos + Vector2(2, 17), Vector2(W - 4, 1), C_UI_BORDER)

	## "HP" label left of bar
	var hp_lbl := _add_label(pos + Vector2(5, 20), Vector2(18, 9), "HP")
	if is_enemy:
		_enemy_hp_label = hp_lbl

	## HP bar track + fill
	var bar_x := int(pos.x) + 25
	var bar_y := int(pos.y) + 22
	_add_rect(Vector2(bar_x, bar_y), Vector2(INFO_HP_BAR_W, 5), C_HP_BG)
	var bar := _add_rect(Vector2(bar_x, bar_y), Vector2(INFO_HP_BAR_W, 5), C_HP_HIGH)

	if is_enemy:
		_enemy_hp_bar = bar
	else:
		_player_hp_bar = bar
		## Player only: HP numbers below the bar
		var num_lbl := _add_label(
				pos + Vector2(W - 62, 30), Vector2(57, 10),
				"%d/%d" % [drake.current_hp, drake.get_max_hp()])
		_player_hp_label = num_lbl


# ──────────────────────────────────────────────────────────────────────────────
# UI helpers
# ──────────────────────────────────────────────────────────────────────────────

func _set_ui_mode(mode: String) -> void:
	match mode:
		"message":
			_msg_label.visible     = true
			_confirm_arrow.visible = true
			for b in _move_btns:  b.visible = false
			for b in _bench_btns: b.visible = false
		"moves":
			_msg_label.visible     = false
			_confirm_arrow.visible = false
			for b in _bench_btns: b.visible = false
			_refresh_move_buttons()
			for b in _move_btns: b.visible = true
		"bench":
			_msg_label.text        = "Choose bench drake:"
			_msg_label.visible     = true
			_confirm_arrow.visible = false
			for b in _move_btns: b.visible = false
			_refresh_bench_buttons()
			for b in _bench_btns: b.visible = true


func _refresh_move_buttons() -> void:
	for i in 3:
		var btn: Button = _move_btns[i]
		if i < _player.moves.size():
			var mv: MoveData = _player.moves[i]
			btn.text = mv.move_name
			_set_btn_color(btn, MOVE_COL.get(mv.type, Color(0.88, 0.88, 0.88)))
			btn.disabled = false
		else:
			btn.text = "—"
			_set_btn_color(btn, Color(0.88, 0.88, 0.88))
			btn.disabled = true

	## Bench combo button (slot 3)
	var bench := GameState.get_bench()
	var combo_btn: Button = _move_btns[3]
	if bench.is_empty() or _player.bench_blocked_turns > 0:
		combo_btn.text = "—" if bench.is_empty() else "BLOCKED"
		combo_btn.disabled = true
		_set_btn_color(combo_btn, Color(0.88, 0.88, 0.88))
	else:
		var bd: DrakeInstance = bench[GameState.selected_bench_slot]
		var combo := DrakeDatabase.get_combo_move(_player.data.type, bd.data.type)
		combo_btn.text     = (combo.move_name if combo else "—") + "\n[" + bd.nickname + "]"
		combo_btn.disabled = combo == null
		_set_btn_color(combo_btn,
				MOVE_COL.get(combo.type if combo else MoveData.Type.NORMAL,
				Color(0.88, 0.88, 0.88)))


func _refresh_bench_buttons() -> void:
	var bench := GameState.get_bench()
	for i in 3:
		var btn: Button = _bench_btns[i]
		if i < bench.size():
			var bd: DrakeInstance = bench[i]
			btn.text     = bd.nickname + " Lv" + str(bd.level)
			btn.disabled = false
		else:
			btn.text     = "—"
			btn.disabled = true


func _update_hp_bars() -> void:
	_update_one_bar(_player, _player_hp_bar, _player_hp_label, false)
	_update_one_bar(_enemy,  _enemy_hp_bar,  _enemy_hp_label,  true)


func _update_one_bar(drake: DrakeInstance, bar: ColorRect, lbl: Label, is_enemy: bool) -> void:
	var pct    := float(drake.current_hp) / float(drake.get_max_hp())
	bar.size.x  = float(INFO_HP_BAR_W) * clampf(pct, 0.0, 1.0)
	bar.color   = C_HP_HIGH if pct > 0.5 else (C_HP_MED if pct > 0.25 else C_HP_LOW)
	if not is_enemy:
		lbl.text = "%d/%d" % [drake.current_hp, drake.get_max_hp()]


# ──────────────────────────────────────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _state == State.MESSAGE and event.is_action_pressed("ui_accept"):
		_msg_confirmed = true


func _on_move_pressed(idx: int) -> void:
	if _state != State.SELECT:
		return
	if idx == 3:
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


# ──────────────────────────────────────────────────────────────────────────────
# Battle flow
# ──────────────────────────────────────────────────────────────────────────────

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


func _show_and_wait(text: String) -> void:
	_state                 = State.MESSAGE
	_msg_label.visible     = true
	_confirm_arrow.visible = true
	_msg_label.text        = text
	_msg_confirmed         = false
	while not _msg_confirmed:
		await get_tree().process_frame
	_msg_confirmed = false


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
	if _player.bench_blocked_turns > 0:
		_player.bench_blocked_turns -= 1
	if _enemy.bench_blocked_turns > 0:
		_enemy.bench_blocked_turns -= 1

	for pair in [[_player, "your " + _player.nickname], [_enemy, _enemy.nickname]]:
		var drake: DrakeInstance = pair[0]
		var label: String        = pair[1]
		if drake.is_burned and not drake.is_fainted():
			var dmg := maxi(1, int(drake.get_max_hp() * 0.10))
			drake.take_damage(dmg)
			_update_hp_bars()
			await _show_and_wait(label + " is burning! (-" + str(dmg) + " HP)")


func _execute_move(mv: MoveData, atk: DrakeInstance, def: DrakeInstance, bench: DrakeInstance) -> void:
	if mv == null:
		return

	if atk.is_fortified:
		atk.is_fortified = false
		await _show_and_wait(atk.nickname + " can't move while fortified!")
		return

	await _show_and_wait(atk.nickname + " used " + mv.move_name + "!")

	if mv.accuracy > 0:
		var eff_acc := mv.accuracy * atk.accuracy_mod
		if randf() < def.evasion_chance or randf() * 100.0 > eff_acc:
			await _show_and_wait("But it missed!")
			return

	if mv.power > 0:
		var power := mv.power
		if bench != null:
			power += int((atk.level + bench.level) * 0.5)

		var def_stat := def.get_def()
		if mv.effect == MoveData.Effect.IGNORE_DEF_BUFFS:
			def_stat = def.data.base_def + def.level * 2

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

		if mv.effect == MoveData.Effect.SELF_DAMAGE:
			var recoil := maxi(1, int(atk.get_max_hp() * mv.effect_value))
			atk.take_damage(recoil)
			_update_hp_bars()
			await _show_and_wait(atk.nickname + " took " + str(recoil) + " recoil damage!")

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
			atk.defense_mod  += mv.effect_value
			atk.is_fortified  = true
			await _show_and_wait(atk.nickname + " fortified! It can't move next turn.")

	if def.is_fainted():
		_update_hp_bars()
		await _show_and_wait(def.nickname + " fainted!")


func _type_effectiveness(mv_type: MoveData.Type, def_type: DrakeData.Type) -> float:
	if mv_type == MoveData.Type.NORMAL:
		return 1.0
	## FIRE=0, WATER=1, NATURE=2
	match [int(mv_type), int(def_type)]:
		[0, 2]: return 2.0
		[0, 1]: return 0.5
		[1, 0]: return 2.0
		[1, 2]: return 0.5
		[2, 1]: return 2.0
		[2, 0]: return 0.5
	return 1.0


func _is_over() -> bool:
	return _player.is_fainted() or _enemy.is_fainted()


func _show_result() -> void:
	if _player.is_fainted():
		await _show_and_wait(_player.nickname + " fainted...")
		await _show_and_wait("You blacked out!")
		return

	var xp     := maxi(1, int(_enemy.data.base_hp * _enemy.level * 0.3))
	var leveled := _player.gain_xp(xp)
	await _show_and_wait(_enemy.nickname + " was defeated!")
	await _show_and_wait(_player.nickname + " gained " + str(xp) + " XP!")

	if leveled:
		if _player_name_label:
			_player_name_label.text = _player.nickname + "  Lv" + str(_player.level)
		_update_hp_bars()
		await _show_and_wait(_player.nickname + " grew to level " + str(_player.level) + "!")

		if _player.data.evolution_id != "" and _player.level >= _player.data.evolution_level:
			var evo_data: DrakeData = DrakeDatabase.drakes.get(_player.data.evolution_id)
			if evo_data:
				var old_name := _player.nickname
				_player.data       = evo_data
				_player.nickname   = evo_data.drake_name
				_player.current_hp = mini(_player.current_hp, _player.get_max_hp())
				for mv in evo_data.base_moves:
					if _player.moves.size() < 3 and mv not in _player.moves:
						_player.moves.append(mv)
				_update_hp_bars()
				await _show_and_wait(old_name + " is evolving...")
				await _show_and_wait(old_name + " evolved into " + _player.nickname + "!")


func _finish() -> void:
	_state = State.DONE
	GameState.reset_party_battle_state()
	GameState.battle_cooldown_steps = 5
	SceneTransition.change_scene(GameState.return_scene, GameState.return_pos)


# ──────────────────────────────────────────────────────────────────────────────
# Node factory helpers
# ──────────────────────────────────────────────────────────────────────────────

## Approximate oval platform shadow with three stacked rects of different widths.
func _draw_platform(cx: float, y: float, w: int) -> void:
	var hw := w * 0.5
	_add_rect(Vector2(cx - hw + 8, y),     Vector2(w - 16, 8), C_PLATFORM)
	_add_rect(Vector2(cx - hw + 3, y + 1), Vector2(w - 6,  6), C_PLATFORM)
	_add_rect(Vector2(cx - hw,     y + 3), Vector2(w,       4), C_PLATFORM)


func _add_rect(pos: Vector2, sz: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size     = sz
	r.color    = color
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


## Apply a fill color + dark border to a button's normal and hover styles.
func _set_btn_color(btn: Button, fill: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color     = fill
	normal.border_color = C_UI_BORDER
	normal.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color     = fill.lightened(0.15)
	hover.border_color = C_UI_BORDER
	hover.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color     = fill.darkened(0.10)
	pressed_style.border_color = C_UI_BORDER
	pressed_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("pressed", pressed_style)


func _make_button(pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size     = sz
	btn.text     = text
	btn.flat     = false
	btn.add_theme_color_override("font_color",  C_TEXT)
	btn.add_theme_font_size_override("font_size", 8)
	_set_btn_color(btn, Color(0.88, 0.88, 0.88))
	add_child(btn)
	return btn
