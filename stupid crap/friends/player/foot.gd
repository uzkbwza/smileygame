extends Sprite2D

class_name SmileyFoot

var move_vec := Vector2()
@onready var last_pos := global_position

func _physics_process(delta: float) -> void:
	move_vec = (global_position - last_pos)
	last_pos = global_position
