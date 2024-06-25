extends RigidBody2D

class_name BouncyLineParticle

@onready var last_pos: Vector2 = global_position
@onready var line: Line2D = $Line2D

func _ready() -> void:
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	var arr = PackedVector2Array()
	arr.append(Vector2())
	arr.append(Vector2())
	line.points = arr

func _on_sleeping_state_changed() -> void:
	if sleeping:
		queue_free()

func _physics_process(delta: float) -> void:
	line.points[0] = global_position - last_pos
	last_pos = global_position
