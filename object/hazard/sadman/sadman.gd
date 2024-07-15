@tool

extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Spiral.get_material().set_shader_parameter("global_position", global_position)
	$Spiral2.get_material().set_shader_parameter("global_position", global_position)
	$Sprite.get_material().set_shader_parameter("global_position", global_position)
