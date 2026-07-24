## Global mode stack. Autoloaded as GameMode.
##
## The game is always in exactly one mode. Mode controls which systems accept
## input and which UI layers are visible. Modes stack — opening a menu on top
## of a dialog keeps the dialog's state intact underneath.
##
##   OVERWORLD   Player walks, encounters roll, NPCs are interactable.
##   DIALOG      Textbox shown, player input goes to dialog system.
##   BATTLE      Battle scene active, overworld suspended.
##   MENU        Pause menu / party / bag.
##   TRANSITION  Fade-to-black between scenes, all input blocked.

extends Node

enum Mode { OVERWORLD, DIALOG, BATTLE, MENU, TRANSITION }

var _stack: Array[int] = [Mode.OVERWORLD]

signal mode_changed(new_mode: int, old_mode: int)


func current() -> int:
	return _stack[-1]


func is_overworld() -> bool:
	return current() == Mode.OVERWORLD


func push(m: int) -> void:
	var old := current()
	_stack.append(m)
	if m != old:
		mode_changed.emit(m, old)


func pop() -> void:
	if _stack.size() <= 1:
		return
	var old := current()
	_stack.pop_back()
	var new := current()
	if new != old:
		mode_changed.emit(new, old)


## Replace the top of the stack.
func swap(m: int) -> void:
	if _stack.size() == 0:
		push(m)
		return
	var old := current()
	_stack[-1] = m
	if m != old:
		mode_changed.emit(m, old)


func reset_to_overworld() -> void:
	var old := current()
	_stack = [Mode.OVERWORLD]
	if old != Mode.OVERWORLD:
		mode_changed.emit(Mode.OVERWORLD, old)
