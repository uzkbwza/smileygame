extends Camera2D
@export var game_view: Node

func _process(delta: float) -> void:
	var level = game_view.get_level()
	if level == null:
		return
	var camera = game_view.get_level().camera
	global_position = camera.global_position
	offset = camera.offset
	global_rotation = camera.global_rotation
	reset_physics_interpolation()
