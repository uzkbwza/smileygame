extends StaticBody2D

class_name DisappearingBlock

@export var crumble_delay := 0.25
@export var reform_delay := 3.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var sprite = $Sprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var wiggle: VariableSound2D = $Wiggle
@onready var crumble_: VariableSound2D = $Crumble
@onready var crumble_2: VariableSound2D = $Crumble2
@onready var reform_: VariableSound2D = $Reform
@onready var gpu_particles_2d_3: GPUParticles2D = $GPUParticles2D3

static var rng = BetterRng.new()
var crumbling = false

func _ready():
	gpu_particles_2d_3.reset_physics_interpolation()
	get_tree().physics_frame.connect(gpu_particles_2d_3.set.bind("emitting", true), CONNECT_ONE_SHOT)
	
func start():
	if crumbling:
		return
	crumbling = true
	
	var tween = create_tween()
	tween.tween_method(pre_crumble_animation, 0.0, 1.0, crumble_delay)
	wiggle.go()
	sprite.frame = 1
	tween.finished.connect(crumble, CONNECT_ONE_SHOT)

func crumble():
	crumble_.go()
	crumble_2.go()
	animation_player.play("Crumble")
	set_collision_layer_value.call_deferred(1, false)
	player_detector.set_deferred("monitoring", true)
	
	timer.start(reform_delay)
	timer.timeout.connect(reform, CONNECT_ONE_SHOT)

func reform():
	if player_detector.get_overlapping_bodies().size() > 0:
		get_tree().physics_frame.connect(reform, CONNECT_ONE_SHOT)
		return

	reform_.go()
	animation_player.play("Reform")
	
	set_collision_layer_value.call_deferred(1, true)
	player_detector.set_deferred("monitoring", false)
	crumbling = false


func pre_crumble_animation(t: float) -> void:
	sprite.offset.x = (sin(t * 10)) * t * 1
	sprite.offset.y = (sin(t * 16)) * t * 1
	sprite.scale = Vector2.ONE * (1 + (pow(t, 3) * 0.15))
	
