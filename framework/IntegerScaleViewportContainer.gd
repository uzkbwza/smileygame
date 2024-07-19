extends SubViewportContainer

class_name GameScreen

var pixel_perfect_scaling_enabled:
	set(value):
		Config.pixel_perfect_mode = value
		#pixel_perfect_scaling_enabled = value
		update_viewport()
	get:
		return Config.pixel_perfect_mode

@onready var sub_viewport = $SubViewport

@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

@export var update_list: Array[Control] = []

func _ready():
	stretch = true
	sub_viewport.size_2d_override_stretch = true
	get_viewport().size_changed.connect(update_viewport)
	Display.window_mode_changed.connect(update_viewport, CONNECT_DEFERRED)
	update_viewport.call_deferred()

func update_viewport():
	await RenderingServer.frame_post_draw

	var window_size: Vector2i = DisplayServer.window_get_size()
	
	var max_width_scale: int = window_size.x / viewport_size.x
	var max_height_scale: int = window_size.y / viewport_size.y
	#sub_viewport.set_deferred("size", viewport_size)
	sub_viewport.size_2d_override = viewport_size
	var viewport_pixel_scale : int = min(max_width_scale, max_height_scale)
	if pixel_perfect_scaling_enabled:
		size = viewport_size * viewport_pixel_scale
	else:
		var size_1 = Vector2(window_size.x, window_size.x * 0.5625)
		var size_2 = Vector2(window_size.y * 1.7777777777777778, window_size.y)
		if size_1.x > window_size.x or size_1.y > window_size.y:
			size = size_2
		else:
			size = size_1
		#size = window_size
	stretch = true
	stretch_shrink = viewport_pixel_scale
	position = window_size / 2 - Vector2i(size) / 2
	for control in update_list:
		control.position = position
		control.size = size
		pass
	DisplayServer.window_set_min_size(viewport_size)
