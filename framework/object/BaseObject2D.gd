extends Node2D

class_name BaseObject2D

var x: float:
	get:
		return global_position.x
	set(x):
		global_position.x = x

var y: float:
	get:
		return global_position.y
	set(y):
		global_position.y = y

var xy: Vector2:
	get:
		return global_position
	set(xy):
		global_position = xy

var hitstopped := false
var hit_tween: Tween
var rng := BetterRng.new()
var fx := ObjectFx.new(self)

var sounds: Dictionary = {}

@export var start_flipped = false

@onready var body: BaseObjectBody2D = %Body
@onready var sprite = get_node_or_null("%Sprite")
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine2D = %StateMachine
@onready var flip: Node2D = $"%Flip"

var current_state: StateInterface2D:
	get:
		return state_machine.state

func _ready() -> void:
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

func reset_rotation() -> void:
	flip.rotation = 0
	body.rotation = 0

func spawn_scene(scene: PackedScene, offset: Vector2=Vector2(), direction: Vector2=Vector2(1.0, 0.0), particle_flip=true) -> Node2D:
	var child = scene.instantiate()
	child.global_position = global_position + offset

	_finish_spawn.call_deferred(child, offset, direction, particle_flip)
	return child

func spawn_scene_direct(scene: PackedScene) -> Node2D:
	var child = scene.instantiate()
	get_parent().add_child(child)
	child.reset_physics_interpolation()
	return child

func _finish_spawn(child: Node, offset: Vector2, direction: Vector2, particle_flip=true):
	if direction.x < 0 and particle_flip:
		child.rotation = Vector2(abs(direction.x), direction.y).angle()
		child.scale.x *= -1
	else:
		child.global_rotation = direction.angle()
	get_parent().add_child(child)
	child.reset_physics_interpolation()

	pass

func set_flip(dir: int) -> void:
	if dir < 0:
		flip.scale.x = -1
		state_machine.scale.x = -1
	elif dir > 0:
		flip.scale.x = 1
		state_machine.scale.x = 1

func follow_body(xy: Vector2) -> void:
	self.xy = xy
	body.position *= 0

func apply_friction(delta: float) -> void:
	body.apply_drag(delta)

func get_camera() -> GoodCamera:
	return get_tree().get_first_node_in_group("Camera")

func get_object_dir(object: Node2D) -> Vector2:
	return (object.global_position - global_position).normalized()

func get_position_dir(pos: Vector2) -> Vector2:
	return (pos - global_position).normalized()

func play_sound(sound_name: String, force=true, pitch=null, amplitude=null) -> void:
	#return
	var sound = sounds[sound_name]
	if force or !sound.is_playing():
		if sound is VariableSound2D:
			sound.go(0.0, pitch, amplitude)
		elif sound is AudioStreamPlayer2D:
			sound.pitch = pitch
			sound.volume_db = amplitude
			sound.play()

func get_sound(sound_name: String):
	return sounds[sound_name]
		
func stop_sound(sound_name: String) -> void:
	sounds[sound_name].stop()

func change_state(state_name: String, data = null) -> void:
	state_machine.queue_state(state_name, data, current_state)

func _physics_process(delta: float) -> void:
	delta = 0.01666666666667
	if !hitstopped:
		state_machine.update(delta)
	flip.rotation = body.rotation
	state_machine.rotation = body.rotation
