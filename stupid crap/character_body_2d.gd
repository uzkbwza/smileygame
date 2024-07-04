extends CharacterBody2D


const ACCEL = 20.0
const AIR_ACCEL = 5.0
const GRAVITY = 6
const JUMP_VELOCITY = -300.0
const FRICTION = 0.92
const AIR_FRICTION = 0.95

const DOWN_SHAPE_DISTANCE = 8


var accel := Vector2()

@onready var ground_detector: RayCast2D = %GroundDetector
@onready var down_left: CollisionShape2D = $DownLeft
@onready var down_right: CollisionShape2D = $DownRight


func _ready():
	ground_detector.target_position.y = (floor_snap_length * 2) + 1

func _physics_process(delta: float) -> void:
	
	accel += Vector2(0, GRAVITY)
	
	
	#if ground_detector.is_colliding() or is_on_floor():
		#var slope_amount = (1 - ground_detector.get_collision_normal().dot(Vector2.UP))
		#var down_shape_distance = max(DOWN_SHAPE_DISTANCE - (slope_amount * 20), 1)
		#down_left.position.x = -down_shape_distance
		#down_right.position.x = down_shape_distance
	#else:
		#down_left.position.x = -1
		#down_right.position.x = 1
	#
	#if velocity.length_squared() > 0:
		#down_right.disabled = velocity.x > 0
		#down_left.disabled = velocity.x < 0


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		accel += Vector2(direction * (ACCEL if is_on_floor() else AIR_ACCEL), 0)

	velocity += accel
	accel *= 0
	

	velocity.x *= FRICTION if is_on_floor() else AIR_FRICTION

	move_and_slide()
