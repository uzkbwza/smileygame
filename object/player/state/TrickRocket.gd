extends SmileyState

const SPEED = 500
const MIN_SPEED_MULTIPLIER = 1.2

var rocket_time := 0.0
var direction: Vector2

func _enter():
	var speed = SPEED
	if data.direction.dot(body.dir) >= 0:
		speed = max(SPEED, body.speed * MIN_SPEED_MULTIPLIER)

	var impulse = speed * data.direction
	rocket_time = data.rocket_time
	body.reset_momentum()
	player.set_flip(data.direction.x)
	direction = data.direction
	body.apply_impulse(impulse)

func _update(delta: float): 

	if !check_landing():
		if body.get_slide_collision_count() > 0:
			return "Fall"

	player.is_grounded = false
	if player.feet_ray.is_colliding():
		player.set_deferred("is_grounded", true)
	
	if elapsed_time >= rocket_time:
		queue_state_change("Fall")
		return
	
	player.foot_1_pos = player.global_position - direction * 15 

	player.foot_2_pos = player.global_position - direction * 9

	player.foot_1.rotation = direction.angle() + (TAU/4 if player.facing == 1 else (TAU/4 * 3))
	player.foot_2.rotation = direction.angle() + (TAU/4 if player.facing == 1 else (TAU/4 * 3))
