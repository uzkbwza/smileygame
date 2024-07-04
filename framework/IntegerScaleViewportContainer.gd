extends SubViewportContainer

class_name GameScreen

@export var pixel_perfect_scaling_enabled = true:
	set(value):
		pixel_perfect_scaling_enabled = value
		update_viewport()

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
	
	var max_width_scale: int = window_size.x / viewport_size.x
	var max_height_scale: int = window_size.y / viewport_size.y
	sub_viewport.size = viewport_size
	sub_viewport.size_2d_override = viewport_size
	var viewport_pixel_scale : int = min(max_width_scale, max_height_scale)
	if pixel_perfect_scaling_enabled:
		size = viewport_size * viewport_pixel_scale
	else:
		size = window_size
	stretch = true
	stretch_shrink = viewport_pixel_scale
	position = window_size / 2 - Vector2i(size) / 2
	DisplayServer.window_set_min_size(viewport_size)
