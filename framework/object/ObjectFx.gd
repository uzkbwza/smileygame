extends RefCounted

class_name ObjectFx

var object: BaseObject2D
var rng = BetterRng.new()

func _init(object: BaseObject2D):
	self.object = object
	rng.randomize()

func flash(b: bool):
	
	object.sprite.get_material().set_shader_parameter("flash", b)

func squish(time:float=0.6, amount=0.3, frequency = 70.0):
	var squish_tween = object.create_tween()

	var dir = sign(rng.randf() - 0.5)

	var squish_func = func(time: float, amount: float, frequency: float, duration: float):
		var realtime = time * duration
		var t = sin(realtime * frequency * dir)
#		print(t)
		object.flip.scale.x = 1 - t * amount * time
		object.flip.scale.y = 1 + t * amount * time
	squish_tween.tween_method(squish_func.bind(amount, frequency, time), 1.0, 0.0, time)

func death_effect():
	for i in range(12):
		object.sprite.modulate.a = 1
		await object.get_tree().create_timer(0.032 * Engine.time_scale).timeout
		object.sprite.modulate.a = 0
		await object.get_tree().create_timer(0.032 * Engine.time_scale).timeout
	object.sprite.modulate.a = 1
	
func hit_effect():
	squish()
	flash(true)
	object.hitstopped = true
	await object.get_tree().create_timer(0.1).timeout
	if is_instance_valid(object):
		flash(false)
		object.hitstopped = false
