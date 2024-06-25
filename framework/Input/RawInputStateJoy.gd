class_name RawInputStateJoy extends RawInputState


var left_stick := Vector2()
var right_stick := Vector2()

func _init(device:=0, relative_facing:=Vector2(0, -1)):
	buttons = {
		attack = Input.is_joy_button_pressed(device, GlobalInput.joy_attack),
		jump = Input.is_joy_button_pressed(device, GlobalInput.joy_jump),
	}
	
	left_stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
	right_stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))


func get_left_stick_relative_to_agent() -> Vector2:
	return left_stick.rotated(relative_facing_angle)

func get_right_stick_relative_to_agent() -> Vector2:
	return right_stick.rotated(relative_facing_angle)
