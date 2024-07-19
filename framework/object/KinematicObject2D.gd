extends CharacterBody2D

# my fucked up character controller thing. sorry!
class_name KinematicObject2D

const PUSH_SPEED: float = 0.1

signal moved(pos)
signal collided(collision)

@export var gravity := 400
#@export_range(0.0, 20.0) var drag := 0.90;

@export var simple_physics := false
@export_range(0.0, 10.0) var drag_vert := 0.001;
@export_range(0.0, 10.0) var ground_drag := 0.99;
@export_range(0.0, 10.0) var air_drag := 0.30;
@export_range(0.0, 10.0) var wall_drag := 0.90;

@export var motion_mode_: MotionMode = MOTION_MODE_GROUNDED
@onready var starting_position := global_position

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

var prev_velocity := Vector2()
var accel := Vector2(0, 0)
var speed := 0.0
var impulses := Vector2()
var prev_speed := 0.0
var prev_accel := Vector2()
var is_moving := false
var dir := Vector2()


func apply_drag(delta: float, h_drag: float = air_drag, v_drag: float = drag_vert) -> void:
	#velocity.x = Math.damp(velocity.x, 0, drag, delta)
	#velocity.y = Math.damp(velocity.y, 0, drag, delta)
	velocity.x = Math.damp(velocity.x, 0, h_drag, delta)
	velocity.y = Math.damp(velocity.y, 0, v_drag, delta) 
	#Debug.dbg("h_drag", h_drag)
	#Debug.dbg("v_drag", v_drag)

func apply_physics_simple(delta: float) -> void:
	var prev_position = global_position
#	print(accel)
	velocity += impulses
	velocity += accel * delta
#
	if velocity.length_squared() < 0.001:
		velocity *= 0

	move_and_slide()

	accel = Vector2(0, 0)
	impulses = Vector2(0, 0)
	if global_position != prev_position:
		moved.emit(global_position)

func apply_physics(delta: float) -> void:

	var prev_position = global_position
	prev_velocity = velocity
	prev_speed = speed

#	print(accel)
	velocity += impulses
	velocity += accel * delta
#
	if velocity.length() < 0.05:
		velocity *= 0

	dir = Vector2()
	if velocity.length_squared() > 0:
		dir = velocity.normalized()
#	await get_tree().physics_frame
#	print(velocity)
	move_and_slide()

	
	speed = velocity.length()
#	Debug.dbg("speed", speed)
	is_moving = speed > 0
	prev_accel = accel
	accel = Vector2(0, 0)
	impulses = Vector2(0, 0)

	if global_position != prev_position:
		moved.emit(global_position)
	for i in range(get_slide_collision_count() - 1):
		var collision = get_slide_collision(i)
		collided.emit(collision)

func reset_momentum() -> void:
	velocity = Vector2()
	accel = Vector2()
	impulses = Vector2()

func apply_force_toward(point: Vector2, strength: float) -> void:
	apply_force((point - global_position).normalized() * strength)

func push(node: KinematicObject2D) -> void:
	node.apply_force(node.global_position - global_position * PUSH_SPEED)

func move_directly(v: Vector2) -> void:
	global_position += v

func rotate_directly(r: float, delta: float) -> void:
	rotation += r * delta

func apply_force(f: Vector2) -> void:
	accel += f

func apply_impulse(f: Vector2) -> void:
	impulses += f

func apply_gravity(gravity:Vector2 = Vector2(0, self.gravity)) -> void: 
	apply_force(gravity)

func accel_toward_object(object: Node2D, accel_speed: float) -> void:
	apply_force((object.global_position - global_position).normalized() * accel_speed)

func accel_toward(point: Vector2, accel_speed: float) -> void:
	apply_force((point - global_position).normalized() * accel_speed)
