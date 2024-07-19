extends Node

var rainbow = Utils.rainbow_gradient()

var level: Node2D


@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

func _ready():
	RenderingServer.set_default_clear_color(Color("000000"))


func get_level() -> Node2D:
	if !is_instance_valid(level):
		level = get_tree().get_first_node_in_group("Level")
	return level
