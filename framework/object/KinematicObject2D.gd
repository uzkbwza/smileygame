extends CharacterBody2D

# my fucked up character controller. sorry!
class_name KinematicObject2D

const PUSH_SPEED = 0.1

signal moved(pos)
signal collided(collision)

#@export var gravity = 400
@export_range(0.0, 20.0) var drag = 0.90;

@export var simple_physics = true
#@export_range(0.0, 10.0) var drag_vert = 0.001;
#@export_range(0.0, 2000.0) var ground_friction = 500;
#@export_range(0.0, 2000.0) var wall_friction = 50;

#@export var motion_mode_: MotionMode = MOTION_MODE_FREE
@onready var starting_position = global_position

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

var prev_velocity = Vector2()
var accel = Vector2(0, 0)
var speed = 0
var impulses = Vector2()
var prev_speed = 0
var prev_accel = Vector2()
var is_moving = false
var dir = Vector2()

func apply_drag(delta, drag=self.drag):
	velocity.x = Math.damp(velocity.x, 0, drag, delta)
	velocity.y = Math.damp(velocity.y, 0, drag, delta)

func apply_physics_simple(delta):
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

func apply_physics(delta):

	var prev_position = global_position
	prev_velocity = velocity
	prev_speed = speed

#	print(accel)
	velocity += impulses
	velocity += accel * delta
#
	if velocity.length() < 0.05:
		velocity *= 0

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

func reset_momentum():
	velocity = Vector2()
	accel = Vector2()
	impulses = Vector2()

func push(node: KinematicObject2D):
	node.apply_force(node.global_position - global_position * PUSH_SPEED)

func move_directly(v):
	velocity = v
	speed = v.length()

func rotate_directly(r, delta):
	rotation += r * delta

func apply_force(f: Vector2):
	accel += f 

func apply_impulse(f: Vector2):
	impulses += f

func accel_toward_object(object: Node2D, accel_speed: float):
	apply_force((object.global_position - global_position).normalized() * accel_speed)

func accel_toward(point: Vector2, accel_speed: float):
	apply_force((point - global_position).normalized() * accel_speed)
