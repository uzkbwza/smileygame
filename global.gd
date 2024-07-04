extends Node

@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

func _ready():
	RenderingServer.set_default_clear_color(Color("26214d"))
