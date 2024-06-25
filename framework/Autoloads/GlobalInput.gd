extends Node

## Mapping
## KBM
var kbd_forward := KEY_W
var kbd_backward := KEY_S

var kbd_left := KEY_A
var kbd_right := KEY_D

var kbd_jump := KEY_SPACE

var use_mouse_attack = true
var kbd_attack := KEY_H
var mouse_attack := MOUSE_BUTTON_LEFT

var use_mouse_look = true

## JOY
var joy_attack = JOY_BUTTON_X
var joy_jump = JOY_BUTTON_A

var keyboard = true

func _input(event):
	if event is InputEventJoypadButton or  event is InputEventJoypadMotion:
		keyboard = false
	elif event is InputEventMouse or event is InputEventKey:
		keyboard = true

func toggle_mouse_mode():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
