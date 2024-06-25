extends Node2D

class_name BaseObject2D

var x:
	get:
		return global_position.x
	set(x):
		global_position.x = x

var y:
	get:
		return global_position.y
	set(y):
		global_position.y = y

var xy:
	get:
		return global_position
	set(xy):
		global_position = xy

var hitstopped = false
var hit_tween
var rng = BetterRng.new()
var fx = ObjectFx.new(self)

var sounds = {}

@export var story_variables = {}

@export var start_flipped = false

@onready var body: BaseObjectBody2D = %Body
@onready var sprite = get_node_or_null("%Sprite")
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine2D = %StateMachine
@onready var flip: Node2D = $"%Flip"

var current_state:
	get:
		return state_machine.state

func _ready():
	body.moved.connect(follow_body)
	if start_flipped: set_flip(-1)

	state_machine.init()
	if animation_player and animation_player.has_animation("RESET"):
		animation_player.play("RESET")
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return
	for sound in %Sounds.get_children():
		sounds[sound.name] = sound

func reset_rotation():
	flip.rotation = 0
	body.rotation = 0

func set_flip(dir):
	if dir < 0:
		flip.scale.x = -1
		state_machine.scale.x = -1
	elif dir > 0:
		flip.scale.x = 1
		state_machine.scale.x = 1

func follow_body(xy: Vector2):
	self.xy = xy
	body.position *= 0

func get_object_dir(object: Node2D) -> Vector2:
	return (object.global_position - global_position).normalized()

func get_position_dir(pos: Vector2) -> Vector2:
	return (pos - global_position).normalized()

func play_sound(sound_name: String):
	var sound = sounds[sound_name]
	if sound is VariableSound2D:
		sound.go()
	else:
		sounds[sound_name].play()
func stop_sound(sound_name: String):
	sounds[sound_name].stop()

func change_state(state_name: String):
	state_machine.queue_state(state_name)

func _physics_process(delta):
	if !hitstopped:
		state_machine.update(delta)
	flip.rotation = body.rotation
	state_machine.rotation = body.rotation
