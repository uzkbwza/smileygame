@tool

extends StaticBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !Engine.is_editor_hint():
		set_process.call_deferred(false)


func _process(delta: float) -> void:
	pass
