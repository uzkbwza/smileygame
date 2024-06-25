class_name RawInputState extends RefCounted

var buttons := {
}

var relative_facing := Vector2(0, 0):
	set(x):
		relative_facing = x
		relative_facing_angle = x.angle()

var relative_facing_angle := 0.0

func get_left_stick_relative_to_agent() -> Vector2:
	return Vector2()

func get_right_stick_relative_to_agent() -> Vector2:
	return Vector2()
