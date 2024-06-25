@tool

extends Sprite2D

@export var tile: Texture2D:
	set(value):
		tile = value
		texture = value
		material.set_shader_parameter("tile", value)

@export var offs: Vector2:
	set(value):
		offs = value
		material.set_shader_parameter("offset", value)

@export_range(0.0001, 100) var size = 1.0:
	set(value):
		size = value;
		update_sprite_size()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_sprite_size()
	set_notify_transform.call_deferred(true)
	if !Engine.is_editor_hint():
		set_process.call_deferred(false)
		return

func _process(_delta):
	update_sprite_size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_sprite_size()

func update_sprite_size():
	material.set_shader_parameter("sprite_scale", scale / size)
