extends Node

### Mapping
### KBM
#var kbd_forward := KEY_W
#var kbd_backward := KEY_S
#
#var kbd_left := KEY_A
#var kbd_right := KEY_D
#
#var kbd_jump := KEY_SPACE
#
#var use_mouse_attack = true
#var kbd_attack := KEY_H
#var mouse_attack := MOUSE_BUTTON_LEFT
#
#var use_mouse_look = true
#
### JOY
#var joy_attack = JOY_BUTTON_X
#var joy_jump = JOY_BUTTON_A

var keyboard = true

func _input(event):
	if event is InputEventJoypadButton or  event is InputEventJoypadMotion:
		keyboard = false
	elif event is InputEventKey:
	#elif event is InputEventMouse or event is InputEventKey:
		keyboard = true
		if event.pressed and event.keycode == KEY_F11:
			Display.toggle_fullscreen()

func can_process_input(node: Node) -> bool:
	return node.get_meta("input_enabled", true)

func is_action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)

func toggle_mouse_mode():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
