extends SubViewportContainer

class_name GameScreen

@onready var sub_viewport = $SubViewport

@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

func _ready():
	stretch = true
	sub_viewport.size_2d_override_stretch = true
	get_viewport().size_changed.connect(update_viewport)
	update_viewport()

func update_viewport():
	var window_size: Vector2i = DisplayServer.window_get_size()
	var viewport_pixel_scale : int = 1
	var max_width_scale: int = window_size.x / viewport_size.x
	var max_height_scale: int = window_size.y / viewport_size.y
	sub_viewport.size = viewport_size
	sub_viewport.size_2d_override = viewport_size
	size = viewport_size * min(max_width_scale, max_height_scale)
	position = window_size / 2 - Vector2i(size) / 2
	DisplayServer.window_set_min_size(viewport_size)
