extends Node2D

@export var independent: Array[Node2D]

func _ready() -> void:
	go.call_deferred()


func go():
	var max_time = 0
	for child in get_children():
		if child is CPUParticles2D or child is GPUParticles2D:
			child.one_shot = true
			child.emitting = true
			if child.lifetime > max_time:
				max_time = child.lifetime / child.speed_scale
		if child is BouncyBurst:
			separate.call_deferred(child)
			child.go.call_deferred()
	get_tree().create_timer(max_time, false).timeout.connect(queue_free)
	reset_physics_interpolation()

func separate(child: Node2D):
	var pos = child.global_position
	remove_child(child)
	get_parent().add_child(child)
	child.global_position = pos
