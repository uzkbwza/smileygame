@tool
extends Node2D

class_name BaseDrawParticle

signal finished()

@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var transition_type: Tween.TransitionType = Tween.TRANS_QUAD
@export var duration: float = 1.0
#@export var gravity: float = 0
#@export var friction: float = 0.0
@export var duration_variance: float = 0.25

@export var color: Color = Color.WHITE
var time: float
static var rng: BetterRng = BetterRng.new()
	
#	func apply_forces(delta):
#		vel += accel * delta
#		vel += impulses
#		position += vel * delta
#		accel = Vector2(0, 0)
#		impulses = Vector2(0, 0)

var tweens: Array[Tween] = []

	
static func ang2vec(angle):
	return Vector2(cos(angle), sin(angle))
	
static func map(value, istart: float, istop: float, ostart: float, ostop: float):
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
	
static func map_pow(value, istart: float, istop: float, ostart: float, ostop: float, power):
	return ostart + (ostop - ostart) * (pow((value - istart) / (istop - istart), power))
	
func _ready():
	rng.randomize()
	if !Engine.is_editor_hint():
		finished.connect(queue_free)
	else:
		finished.connect(start)
	start()

func get_random_duration():
	return duration + rng.randf_range(-duration_variance/2, duration_variance/2)

func get_tween():
	var tween = create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(transition_type)
	if Engine.is_editor_hint():
		tweens.append(tween)
	return tween

func start():
	setup()
	time = 0.0
	var tween = get_tween()
	tween.tween_property(self, "time", 1.0, duration + duration_variance/2)
	tween.tween_callback(emit_signal.bind("finished"))
		
func _process(delta):
	update()

func setup():
	pass

func draw():
	pass

func _draw():
	draw()
