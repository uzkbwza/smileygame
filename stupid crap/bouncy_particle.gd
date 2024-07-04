extends Node2D

@onready var bouncy_burst = $BouncyBurst
@onready var camera_2d: GoodCamera = $Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.key_label == KEY_G and bouncy_burst:
			bouncy_burst.go()
			camera_2d.bump(Vector2(), 10, 0.7)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().reload_current_scene()
