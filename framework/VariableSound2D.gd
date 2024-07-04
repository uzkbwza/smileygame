extends AudioStreamPlayer2D

class_name VariableSound2D

@export var pitch_variation = 0.1
@export var one_shot = false
@export var auto = false
var pitch_scale_
var amplitude

var rng = BetterRng.new()
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func _ready():
	rng.randomize()
	pitch_scale_ = pitch_scale
	amplitude = volume_db
	if one_shot:
		finished.connect(queue_free)
	if auto:
		go()

# Called when the node enters the scene tree for the first time.
func go(p=0.0,pitch=null, amplitude=null):
	volume_db = amplitude if amplitude != null else self.amplitude
	if pitch == null:
		pitch_scale = pitch_scale_ + rng.randf_range(-pitch_variation, pitch_variation)
	else:
		pitch_scale = pitch + rng.randf_range(-pitch_variation, pitch_variation)
		
	
	play(p)
