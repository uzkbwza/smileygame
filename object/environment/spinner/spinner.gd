@tool

extends Node2D

class_name TrickSpinner

const GRAVITY = 0.075
const DRAG = 2.0
const CAPTURED_DRAG = 0.25
const RETURN_SPEED = 0.3
const BASE_MASS = 20
const SPEED_MULTIPLIER = 3
const MIN_SPEED = 6.8
const MAX_SPIN_AMOUNT = 15.02
const MIN_IMPULSE_SPEED_AMOUNT = 0.75
const BASE_LENGTH = 80

@export_range(16, 512, 16.1) var length :int = BASE_LENGTH:
	set(value):
		length = value
		on_updated()

@export_range(-180, 180, 22.5, "suffix:°") var starting_direction_degrees :float  = 90:
	set(value):
		starting_direction_degrees = value
		on_updated()

@onready var pivot: Node2D = %Pivot
@onready var line: Line2D = %Line2D
#@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var head: Area2D = %Head

var velocity: float = 0.0
var accel: float = 0.0
var impulses: float = 0.0
var current_angle: float:
	get:
		return pivot.global_rotation
	set(value):
		pivot.global_rotation = value
		
var starting_direction: float:
	get:
		return deg_to_rad(starting_direction_degrees)

var captured: SmileyPlayer

func _ready() -> void:
	global_rotation *= 0
	on_updated()
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	accel += sign(Vector2.UP.angle_to(Math.ang2vec(current_angle))) * GRAVITY
	velocity += impulses
	velocity += accel * delta
	velocity = Math.damp(velocity, 0.0, DRAG if captured == null else CAPTURED_DRAG, delta)
	current_angle += (velocity if abs(velocity) < (MAX_SPIN_AMOUNT * delta) else (MAX_SPIN_AMOUNT * delta * sign(velocity))) * ((BASE_LENGTH) / float(length))
	impulses *= 0
	accel *= 0
		
	if captured == null:
		var diff = angle_difference(current_angle, starting_direction)
		accel += sign(diff) * RETURN_SPEED 
		#print(diff)
		if abs(diff) < 0.01 and abs(velocity) <= 0.01:
			current_angle = starting_direction
			set_physics_process.call_deferred(false)
	else:
		if abs(velocity) < MIN_SPEED * delta:
			velocity = sign(velocity) * MIN_SPEED * delta
		pass

func apply_torque_impulse(impulse: float) -> void:
	impulses += impulse
	set_physics_process(true)
	pass

func process_2d_impulse(impulse: Vector2) -> float:
	var head_pos = head.global_position - pivot.global_position
	var total = head_pos + impulse
	var current_dir = Math.ang2vec(current_angle)
	var cw =  current_dir.rotated( 0.000001)
	var ccw = current_dir.rotated(-0.000001)
	var next = cw if cw.distance_squared_to(total) < ccw.distance_squared_to(total) else ccw
	var torque_impulse = -(impulse.cross(next))
	if abs(torque_impulse) < impulse.length() * MIN_IMPULSE_SPEED_AMOUNT:
		torque_impulse = sign(torque_impulse) * impulse.length() * MIN_IMPULSE_SPEED_AMOUNT
	
	#Debug.dbg("torque impulse", torque_impulse)

	return (torque_impulse / (length)) / BASE_MASS

func get_2d_velocity() -> Vector2:
	var current_dir = Math.ang2vec(current_angle)
	var speed = abs(velocity) * length
	var diff = (current_dir.rotated(sign(velocity) * 0.01) - current_dir).normalized()
	return (diff * speed) * BASE_MASS * SPEED_MULTIPLIER * (BASE_LENGTH / float(length))

func capture_player(player: SmileyPlayer) -> void:
	velocity *= 0
	accel *= 0
	impulses *= 0
	captured = player

func release_player() -> void:
	captured = null

func on_updated() -> void:
	var pos = Vector2(length, 0)
	if head:
		head.position = pos
	if pivot:
		pivot.rotation = starting_direction
	if line:
		line.set_point_position(1, pos)
