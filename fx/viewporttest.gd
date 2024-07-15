extends SubViewportContainer

@onready var sub_viewport: SubViewport = %SubViewport

@onready var sub_viewport_2: SubViewport = %SubViewport2
@onready var camera_2d: Camera2D = $SubViewport/SubViewportContainer/SubViewport2/Camera2D

func add_sprite(sprite: Sprite2D) -> void:
	sub_viewport_2.add_child(sprite)
	sub_viewport.size = sprite.texture.get_size() * 2.0
	sub_viewport_2.size = sub_viewport.size
	size = sub_viewport.size
