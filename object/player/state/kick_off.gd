extends SmileyState

const KICK_DIST = 30
const KICK_OFF_SPEED = 450
@onready var recovery_timer: Timer = $RecoveryTimer
@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest

func _enter():
	if !data.has("retain_momentum"):
		body.velocity *= 0.3
	var force = data.has("force_kick_strength")
	var strength : float = ((data.kick_strength * KICK_OFF_SPEED) if !force else data.force_kick_strength)
	if force:
		body.apply_impulse(data.kick_dir * strength)
	else:
		body.apply_impulse(data.kick_dir * strength)
	recovery_timer.start()
	foot_1_rest.enabled = true
	foot_2_rest.enabled = true
	player.is_grounded = false
	player.can_coyote_jump = false
	#player.play_sound("WallJump")
	
	if !data.has("spring_effect"):
		player.play_sound("WallJump2")

	player.jumped_off_wall.emit(data.kick_dir)
	player.jumped_off_something.emit(data.kick_dir)

	#for i in body.get_slide_collision_count():
		#var collider = body.get_slide_collision(i).get_collider()
		#if collider is Spring
			#collider.on_player_kicked_off(player, data.kick_dir)

func _exit():
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false

func _update(delta: float):
	if !check_landing():
		if body.get_slide_collision_count() > 0:
			return "Fall"
	#player.squish()
	
	player.is_grounded = player.feet_ray.is_colliding() and body.velocity.y >= 0
	
	if !is_zero_approx(data.kick_dir.x):
		player.set_flip(sign(data.kick_dir.x))
	
	if !data.has("retain_momentum"):
		if sign(data.kick_dir.x) != sign(body.velocity.x):
			body.velocity.x *= 0
		if sign(data.kick_dir.y) != sign(body.velocity.y):
			body.velocity.y *= 0
	
	var foot_dir = -data.kick_dir
	
	foot_1_rest.target_position = foot_dir * 0.75 * KICK_DIST - Vector2(0, 10).rotated(foot_dir.angle() + (PI if player.facing == 1 else 0))
	player.foot_1_pos = Physics.get_raycast_end_point(foot_1_rest) if !foot_1_rest.is_colliding() else foot_1_rest.get_collision_point()
	player.foot_1.rotation = foot_dir.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))

	foot_2_rest.target_position = foot_dir * 0.40 * KICK_DIST + Vector2(0, 0).rotated(foot_dir.angle() + (PI if player.facing == 1 else 0))
	player.foot_2_pos = Physics.get_raycast_end_point(foot_2_rest) if !foot_2_rest.is_colliding() else foot_2_rest.get_collision_point()
	player.foot_2.rotation = foot_dir.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))

	if recovery_timer.is_stopped():
		queue_state_change("Fall", {"retain_speed": abs(body.velocity.x)})
