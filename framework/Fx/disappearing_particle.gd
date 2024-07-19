extends Node2D

@export var independent: Array[Node2D]
@export var lifetime = 0.0

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
		elif child is BouncyBurst:
			separate.call_deferred(child)
			child.go.call_deferred()
			if child.lifetime > max_time:
				max_time = child.lifetime
		elif child is VariableSound2D:
			var length = child.stream.get_length() * (1 / child.pitch_scale_) * 2
			if length > max_time:
				max_time = length
			child.go()
		elif child is AudioStreamPlayer2D:
			var length = child.stream.get_length() * (1 / child.pitch_scale) * 2
			if length > max_time:
				max_time = length
			child.play()
		elif child is BurstParticleGroup2D:
			child.update_children()
			if child.lifetime > max_time:
				max_time = child.lifetime
			child.free_when_finished = false
			child.burst()
		elif child is BurstParticles2D:
			if child.lifetime > max_time:
				max_time = child.lifetime
			child.burst()
	get_tree().create_timer(max_time if lifetime == 0 else lifetime, false).timeout.connect(queue_free)
	reset_physics_interpolation()

func separate(child: Node2D):
	var pos = child.global_position
	child.scale = scale
	remove_child(child)
	child.global_position = pos
	child.global_rotation += global_rotation
	get_parent().add_child(child)
