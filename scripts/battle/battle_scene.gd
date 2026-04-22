## Battle scene — full FireRed-style UI built in code.
##
## Layout (320×180 viewport):
##   Field  0–120 px  — volcanic sky gradient + ash ground + sprites + info boxes
##   Panel  120–180 px — bottom UI strip
##
## Panel modes:
##   MESSAGE — full-width text, buttons hidden
##   SELECT  — "What will X do?" left half + 2×2 move grid right half (FireRed)
##   BENCH   — message + 3 bench buttons across the bottom row

extends Node2D

# ── Layout constants ──────────────────────────────────────────────────────────
const VP_W    := 320
const VP_H    := 180
const FIELD_H := 120
const PANEL_H := 60
const SPLIT_X := 160   ## x where message ends / move grid begins in SELECT mode

# ── State machine ─────────────────────────────────────────────────────────────
enum State { MESSAGE, SELECT, BENCH_SELECT, RESOLVING, DONE }
var _state := State.MESSAGE
var _msg_confirmed := false
var _queued_action := {}

# ── Node refs ─────────────────────────────────────────────────────────────────
var _msg_label:         Label
var _select_prompt:     Label   ## "What will X do?" — visible only in SELECT mode
var _move_btns:         Array = []
var _bench_btns:        Array = []
var _enemy_hp_bar:      ColorRect
var _player_hp_bar:     ColorRect
var _player_xp_bar:     ColorRect
var _enemy_hp_label:    Label
var _player_hp_label:   Label
var _player_name_label: Label
var _enemy_sprite:      Control
var _player_sprite:     Control

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
	## ── Volcanic sky: 4 gradient bands (15 px each) ───────────────────────
	for i in ThemeColors.FIELD_SKY.size():
		_add_rect(Vector2(0, i * 15), Vector2(VP_W, 15), ThemeColors.FIELD_SKY[i])

	## ── Ash ground ────────────────────────────────────────────────────────
	_add_rect(Vector2(0, 60), Vector2(VP_W, 60), ThemeColors.FIELD_GROUND)

	## ── Thin ember-glow horizon strip ────────────────────────────────────
	_add_rect(Vector2(0, 58), Vector2(VP_W, 4), ThemeColors.RED_EMBER.darkened(0.35))

	## ── Oval platforms ───────────────────────────────────────────────────
	_draw_platform(38,  60, 52)   ## enemy
	_draw_platform(262, 96, 52)   ## player

	## ── Drake sprites ─────────────────────────────────────────────────────
	_enemy_sprite  = _create_drake_visual(Vector2(16,  8), Vector2(52, 52), _enemy)
	_player_sprite = _create_drake_visual(Vector2(240, 44), Vector2(52, 52), _player)

	## ── Info boxes ────────────────────────────────────────────────────────
	_build_enemy_info_box(Vector2(148, 4))
	_build_player_info_box(Vector2(4, 68))

	## ── Bottom panel ──────────────────────────────────────────────────────
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, PANEL_H), ThemeColors.UI_PANEL)
	_add_rect(Vector2(0, FIELD_H), Vector2(VP_W, 2), ThemeColors.UI_BORDER)

	## ── Full-width message label (MESSAGE + BENCH modes) ─────────────────
	_msg_label = _add_label(
		Vector2(8, FIELD_H + 7),
		Vector2(VP_W - 16, PANEL_H - 12),
		"")
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	## ── SELECT-mode left prompt ──────────────────────────────────────────
	_select_prompt = _add_label(
		Vector2(6, FIELD_H + 7),
		Vector2(SPLIT_X - 10, PANEL_H - 12),
		"")
	_select_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD
	_select_prompt.visible = false

	## ── Vertical divider (SELECT mode only, drawn but hidden) ────────────
	var divider := _add_rect(
		Vector2(SPLIT_X - 1, FIELD_H),
		Vector2(2, PANEL_H),
		ThemeColors.UI_DIVIDER)
	divider.name = "SelectDivider"
	divider.visible = false
	## Keep ref so we can toggle visibility
	set_meta("_divider", divider)

	## ── Move buttons — 2×2 grid in the RIGHT half of the panel ──────────
	const BTN_W := 79
	const BTN_H := 30
	for i in 4:
		var col := i % 2
		var row := i / 2
		var btn := _make_button(
			Vector2(SPLIT_X + col * BTN_W, FIELD_H + row * BTN_H),
			Vector2(BTN_W, BTN_H), "")
		var idx := i
		btn.pressed.connect(func(): _on_move_pressed(idx))
		_move_btns.append(btn)

	## ── Bench buttons — 3 equal columns, full panel width ────────────────
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


func _build_enemy_info_box(pos: Vector2) -> void:
	## Enemy info: name + level + HP bar (no numbers, FireRed style)
	var W := 168; var H := 42
	_add_rect(pos - Vector2(1, 1), Vector2(W + 2, H + 2), ThemeColors.UI_BORDER)
	_add_rect(pos, Vector2(W, H), ThemeColors.UI_PANEL)

	_add_label(pos + Vector2(4, 3), Vector2(W - 8, 10),
			_enemy.nickname + "  Lv" + str(_enemy.level))

	var hp_lbl := _add_label(pos + Vector2(4, 15), Vector2(30, 10), "HP")
	_enemy_hp_label = hp_lbl

	_add_rect(pos + Vector2(36, 16), Vector2(W - 42, 6), ThemeColors.HP_BG)
	_enemy_hp_bar = _add_rect(pos + Vector2(36, 16), Vector2(W - 42, 6), ThemeColors.HP_HIGH)

	## Thin ember-gold accent line under the HP bar
	_add_rect(pos + Vector2(4, 30), Vector2(W - 8, 1), ThemeColors.RED_EMBER.darkened(0.3))


func _build_player_info_box(pos: Vector2) -> void:
	## Player info: name + level + HP bar + HP numbers + XP bar
	var W := 168; var H := 48
	_add_rect(pos - Vector2(1, 1), Vector2(W + 2, H + 2), ThemeColors.UI_BORDER)
	_add_rect(pos, Vector2(W, H), ThemeColors.UI_PANEL)

	_player_name_label = _add_label(pos + Vector2(4, 3), Vector2(W - 8, 10),
			_player.nickname + "  Lv" + str(_player.level))

	var hp_lbl := _add_label(pos + Vector2(4, 15), Vector2(30, 10), "HP")
	_player_hp_label = hp_lbl

	_add_rect(pos + Vector2(36, 16), Vector2(W - 42, 6), ThemeColors.HP_BG)
	_player_hp_bar = _add_rect(pos + Vector2(36, 16), Vector2(W - 42, 6), ThemeColors.HP_HIGH)

	## HP numbers label (right-aligned feel)
	var hp_nums := _add_label(pos + Vector2(4, 26), Vector2(W - 8, 9), "")
	hp_nums.name = "PlayerHPNums"
	hp_nums.add_theme_color_override("font_color", ThemeColors.UI_TEXT_DIM)

	## XP bar (FireRed blue at the very bottom of box)
	_add_rect(pos + Vector2(4, 37), Vector2(W - 8, 4), ThemeColors.XP_BG)
	_player_xp_bar = _add_rect(pos + Vector2(4, 37), Vector2(W - 8, 4), ThemeColors.XP_BAR)
	set_meta("_hp_nums_label", hp_nums)


# ─────────────────────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────────────────────

func _set_ui_mode(mode: String) -> void:
	var divider: ColorRect = get_meta("_divider") as ColorRect
	match mode:
		"message":
			_msg_label.visible    = true
			_select_prompt.visible = false
			divider.visible       = false
			for b in _move_btns:  b.visible = false
			for b in _bench_btns: b.visible = false
		"moves":
			_msg_label.visible    = false
			_select_prompt.text   = "What will\n" + _player.nickname + " do?"
			_select_prompt.visible = true
			divider.visible       = true
			for b in _bench_btns: b.visible = false
			_refresh_move_buttons()
			for b in _move_btns: b.visible = true
		"bench":
			_msg_label.text       = "Choose bench drake:"
			_msg_label.visible    = true
			_select_prompt.visible = false
			divider.visible       = false
			for b in _move_btns: b.visible = false
			_refresh_bench_buttons()
			for b in _bench_btns: b.visible = true


func _refresh_move_buttons() -> void:
	for i in 3:
		var btn: Button = _move_btns[i]
		if i < _player.moves.size():
			var mv: MoveData = _player.moves[i]
			btn.text     = mv.move_name
			btn.disabled = false
			_style_move_button(btn, _type_key(mv.type))
		else:
			btn.text     = "—"
			btn.disabled = true
			_style_move_button(btn, "normal")

	## Slot 3: bench combo
	var bench := GameState.get_bench()
	var combo_btn: Button = _move_btns[3]
	if bench.is_empty() or _player.bench_blocked_turns > 0:
		combo_btn.text     = "—" if bench.is_empty() else "BLOCKED"
		combo_btn.disabled = true
		_style_move_button(combo_btn, "normal")
	else:
		var bd: DrakeInstance = bench[GameState.selected_bench_slot]
		var combo := DrakeDatabase.get_combo_move(_player.data.type, bd.data.type)
		combo_btn.text     = (combo.move_name if combo else "—") + "\n▲" + bd.nickname
		combo_btn.disabled = combo == null
		_style_move_button(combo_btn, _type_key(combo.type) if combo else "normal")


func _style_move_button(btn: Button, type_key: String) -> void:
	var bg:    Color = ThemeColors.MOVE_BG.get(type_key,    ThemeColors.UI_BTN)
	var hover: Color = ThemeColors.MOVE_HOVER.get(type_key, ThemeColors.UI_BTN_HOVER)
	var press: Color = ThemeColors.MOVE_PRESS.get(type_key, ThemeColors.UI_BTN_PRESS)

	var n := StyleBoxFlat.new()
	n.bg_color = bg; n.border_color = ThemeColors.UI_BTN_BORDER
	n.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", n)

	var h := StyleBoxFlat.new()
	h.bg_color = hover; h.border_color = ThemeColors.GOLD_FIRE
	h.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", h)

	var p := StyleBoxFlat.new()
	p.bg_color = press; p.border_color = ThemeColors.GOLD_BRIGHT
	p.set_border_width_all(1)
	btn.add_theme_stylebox_override("pressed", p)


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
	_update_one_bar(_enemy,  _enemy_hp_bar,  _enemy_hp_label,  true)
	_update_one_bar(_player, _player_hp_bar, _player_hp_label, false)
	_update_xp_bar()


func _update_one_bar(drake: DrakeInstance, bar: ColorRect, lbl: Label, is_enemy: bool) -> void:
	var pct := float(drake.current_hp) / float(drake.get_max_hp())
	bar.size.x = _bar_width(bar) * clampf(pct, 0.0, 1.0)
	bar.color  = ThemeColors.HP_HIGH if pct > 0.5 else \
				 (ThemeColors.HP_MED if pct > 0.25 else ThemeColors.HP_LOW)
	if not is_enemy:
		lbl.text = "HP %d/%d" % [drake.current_hp, drake.get_max_hp()]
		var nums_lbl: Label = get_meta("_hp_nums_label") as Label
		if nums_lbl:
			nums_lbl.text = "%d / %d" % [drake.current_hp, drake.get_max_hp()]
	else:
		lbl.text = "HP"


func _bar_width(bar: ColorRect) -> float:
	## Returns the track width above the bar (parent bg is 6px taller at same pos)
	## Hard-coded to 126 (W-42) for info boxes.
	return 126.0


func _update_xp_bar() -> void:
	if _player_xp_bar == null:
		return
	var threshold := float(_player.level * _player.level * 4)
	var pct := clampf(float(_player.xp) / threshold, 0.0, 1.0) if threshold > 0 else 0.0
	## XP bar track width = W-8 = 160 from _build_player_info_box
	_player_xp_bar.size.x = 160.0 * pct


## Animated HP bar decrease — tweens to new value, then resolves.
func _animate_hp_decrease(drake: DrakeInstance, bar: ColorRect, lbl: Label, is_enemy: bool) -> void:
	var pct := float(drake.current_hp) / float(drake.get_max_hp())
	var target_w := _bar_width(bar) * clampf(pct, 0.0, 1.0)
	var target_c := ThemeColors.HP_HIGH if pct > 0.5 else \
					(ThemeColors.HP_MED if pct > 0.25 else ThemeColors.HP_LOW)
	var tw := create_tween()
	tw.tween_property(bar, "size:x", target_w, 0.35).set_ease(Tween.EASE_OUT)
	bar.color = target_c
	if not is_enemy:
		lbl.text = "HP %d/%d" % [drake.current_hp, drake.get_max_hp()]
		var nums_lbl: Label = get_meta("_hp_nums_label") as Label
		if nums_lbl:
			nums_lbl.text = "%d / %d" % [drake.current_hp, drake.get_max_hp()]
	else:
		lbl.text = "HP"
	await tw.finished


# ─────────────────────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if _state == State.MESSAGE:
		_msg_confirmed = true
	elif _state == State.SELECT:
		_on_move_pressed(0)


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


func _show_and_wait(text: String) -> void:
	_state = State.MESSAGE
	_msg_label.text = text
	_msg_confirmed  = false
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
		var label: String = pair[1]
		if drake.is_burned and not drake.is_fainted():
			var dmg := maxi(1, int(drake.get_max_hp() * 0.10))
			drake.take_damage(dmg)
			await _animate_damage(drake)
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
		await _animate_damage(def)

		var eff_txt := ""
		if   type_mult >= 2.0: eff_txt = "\nSuper effective!"
		elif type_mult <= 0.5: eff_txt = "\nNot very effective..."
		await _show_and_wait(def.nickname + " took " + str(dmg) + " damage!" + eff_txt)

		if mv.effect == MoveData.Effect.SELF_DAMAGE:
			var recoil := maxi(1, int(atk.get_max_hp() * mv.effect_value))
			atk.take_damage(recoil)
			await _animate_damage(atk)
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
			await _animate_damage(atk)
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
		await _show_and_wait(def.nickname + " fainted!")


## Animate HP bar for the given drake, then update XP if it's the player.
func _animate_damage(drake: DrakeInstance) -> void:
	if drake == _enemy:
		await _animate_hp_decrease(_enemy, _enemy_hp_bar, _enemy_hp_label, true)
	else:
		await _animate_hp_decrease(_player, _player_hp_bar, _player_hp_label, false)
		_update_xp_bar()


func _type_effectiveness(mv_type: MoveData.Type, def_type: DrakeData.Type) -> float:
	if mv_type == MoveData.Type.NORMAL:
		return 1.0
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

	var xp := maxi(1, int(_enemy.data.base_hp * _enemy.level * 0.3))
	var leveled := _player.gain_xp(xp)
	await _show_and_wait(_enemy.nickname + " was defeated!")
	await _show_and_wait(_player.nickname + " gained " + str(xp) + " XP!")
	_update_xp_bar()

	if leveled:
		if _player_name_label:
			_player_name_label.text = _player.nickname + "  Lv" + str(_player.level)
		_update_hp_bars()
		await _show_and_wait(_player.nickname + " grew to level " + str(_player.level) + "!")

		if _player.data.evolution_id != "" and _player.level >= _player.data.evolution_level:
			var evo_data: DrakeData = DrakeDatabase.drakes.get(_player.data.evolution_id)
			if evo_data:
				var old_name := _player.nickname
				_player.data     = evo_data
				_player.nickname = evo_data.drake_name
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
	if _player.is_fainted():
		GameState.heal_party()
		SceneTransition.change_scene("res://scenes/maps/kindra_town.tscn", Vector2(168, 360))
	else:
		SceneTransition.change_scene(GameState.return_scene, GameState.return_pos)


# ─────────────────────────────────────────────────────────────────────────────
# Node factory helpers
# ─────────────────────────────────────────────────────────────────────────────

func _draw_platform(cx: int, cy: int, rx: int) -> void:
	var ry := 5
	for dy in range(-ry, ry + 1):
		var half_w := int(float(rx) * sqrt(1.0 - float(dy * dy) / float(ry * ry)))
		var shade := ThemeColors.FIELD_PLATFORM.darkened(0.05 + 0.18 * (float(dy) / float(ry)))
		_add_rect(Vector2(cx - half_w, cy + dy), Vector2(half_w * 2, 1), shade)


func _create_drake_visual(pos: Vector2, sz: Vector2, drake: DrakeInstance) -> Control:
	var name_lower := drake.data.drake_name.to_lower()
	var tex: Texture2D = DrakeSprites.get_sprite(name_lower)
	if tex == null:
		var tex_path := "res://art/drakes/" + name_lower + "_front.png"
		if ResourceLoader.exists(tex_path):
			tex = load(tex_path)
	if tex:
		var tr := TextureRect.new()
		tr.texture      = tex
		tr.position     = pos
		tr.size         = sz
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(tr)
		return tr

	var tint: Color
	match drake.data.type:
		DrakeData.Type.FIRE:   tint = ThemeColors.DRAKE_FIRE
		DrakeData.Type.WATER:  tint = ThemeColors.DRAKE_WATER
		DrakeData.Type.NATURE: tint = ThemeColors.DRAKE_NATURE
		_:                     tint = ThemeColors.EARTH_AMBER
	return _add_rect(pos, sz, tint)


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
	lbl.add_theme_color_override("font_color", ThemeColors.UI_TEXT)
	lbl.add_theme_font_size_override("font_size", 8)
	add_child(lbl)
	return lbl


func _make_button(pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size     = sz
	btn.text     = text
	btn.flat     = false
	btn.add_theme_color_override("font_color", ThemeColors.UI_TEXT)
	btn.add_theme_font_size_override("font_size", 8)
	_style_move_button(btn, "normal")
	add_child(btn)
	return btn


func _type_key(t: int) -> String:
	match t:
		0: return "fire"
		1: return "water"
		2: return "nature"
	return "normal"
