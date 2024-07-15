extends SmileyState

const KICK_DIST = 30
const KICK_OFF_SPEED = 450
@onready var recovery_timer: Timer = $RecoveryTimer
@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest

func _enter():
	body.velocity *= 0.3
	body.apply_impulse(data.kick_dir * KICK_OFF_SPEED * data.kick_strength)
	recovery_timer.start()
	foot_1_rest.enabled = true
	foot_2_rest.enabled = true
	player.is_grounded = false
	player.can_coyote_jump = false
	#player.play_sound("WallJump")
	player.play_sound("WallJump2")


func _exit():
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false

func _update(delta: float):
	check_landing()
	#player.squish()
	
	player.is_grounded = player.feet_ray.is_colliding() and body.velocity.y >= 0
	
	if data.kick_dir.x != 0:
		player.set_flip(sign(data.kick_dir.x))
	
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
		#return "Fall" if !player.input_kick_held else "Kick"
		#return "Fall" if !player.input_kick_held else "Kick"
