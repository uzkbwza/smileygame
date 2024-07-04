extends SmileyState

const ROTATE_SPEED = 8
const MOVE_SPEED = 420
const COYOTE_TIME = 0.08

@onready var jump_hold_timer: Timer = $JumpHoldTimer
@onready var can_land_timer: Timer = $CanLandTimer

@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest
@onready var jump_grace_pos: RayCast2D = %JumpGracePos

var can_use_run_speed = true
var rotate_dir := 0
var rotate_amount = 0.0
var jump_held = true

var time = 0.00

func _enter():
	rotate_dir = 0 
	player.face_offset.y = 0
	#if player.input_move_dir != 0 and player.facing != sign(body.velocity.x) and data:
		#rotate_dir = player.input_move_dir
	time = 0.00
	rotate_amount = 0
	player.last_aerial_velocity *= 0
	
	foot_1_rest.enabled = true
	jump_grace_pos.enabled = true
	foot_2_rest.enabled = true
	player.is_grounded = false
	
	can_use_run_speed = _previous_state() == "Run" and sign(player.input_move_dir) == sign(player.facing)
	
	
	if data and data.get("jump") and player.input_jump_held:
		can_land_timer.start()
		jump_held = true
		jump_hold_timer.start()
		

	player.foot_1_was_touching_ground = false
	player.foot_2_was_touching_ground = false
#
	#if player.input_kick_held:
		#if !(data and data.get("jump") and player.input_duck):
			#return "Kick"

func _update(delta: float):
	if (!jump_held and can_land_timer.is_stopped()) or (body.velocity.y > 0):
		check_landing()
	
	player.is_grounded = false
	if player.feet_ray.is_colliding():
		player.is_grounded = true
	
	#player.feet_lift_body()
	#player.feet_idle()
	if rotate_dir == 0:
		player.squish()
	#player.update_feet_position(0.5)
	
	if body.velocity.y > 0:
		jump_hold_timer.stop()
	
	if !player.input_jump_held:
		jump_held = false
	
	if jump_hold_timer.is_stopped():
		jump_held = false
	else:
		if !jump_held:
			body.velocity.y *= 0.9
		
	var angle = Vector2(lerp_angle(player.facing, -player.facing, body.velocity.y * 0.005), -1).angle()
	
	if player.can_coyote_jump and (time < COYOTE_TIME or jump_grace_pos.is_colliding()) and !(data and data.get("jump")):
		check_jump()
	
	rotate_amount += rotate_dir * ROTATE_SPEED * delta
	
	player.sprite.rotation = rotate_amount
	player.foot_1.rotation = angle + rotate_amount
	player.foot_2.rotation = angle + rotate_amount
	player.foot_1.z_index = -1
	player.foot_2.z_index = 1
	var horiz_offset = Vector2((lerp(-1, 1, body.velocity.y * 0.05) + 10) * player.facing, 0) * (player.facing * body.velocity.x * 0.0025)
	if sign(body.velocity.x) != player.facing:
		horiz_offset *= 0.0
	player.foot_1_pos = player.global_position + (Vector2(5 * player.facing, 15) + horiz_offset).rotated(rotate_amount)
	player.foot_2_pos = player.global_position + (Vector2(-5 * player.facing, 15) + horiz_offset).rotated(rotate_amount)
	var vertical_offset = body.velocity.y * -0.02
	player.foot_1_pos += Vector2(0, vertical_offset).rotated(rotate_amount)
	player.foot_2_pos += Vector2(0, vertical_offset).rotated(rotate_amount)
	
	#if foot_1_rest.is_colliding():
		#player.foot_1_pos = foot_1_rest.get_collision_point()
	#if foot_2_rest.is_colliding():
		#player.foot_2_pos = foot_2_rest.get_collision_point()
	
	if player.input_move_dir == player.facing and can_use_run_speed:
		body.apply_force(Vector2(player.get_run_speed() * player.input_move_dir, 0))
		body.apply_drag(delta, body.ground_drag, player.get_vert_drag())
	else:
		player.is_boosting = false
		can_use_run_speed = false
		body.apply_force(Vector2(MOVE_SPEED * player.input_move_dir, 0))
		if player.input_move_dir != 0:
			player.apply_friction(delta)
		else:
			body.apply_drag(delta, body.air_drag * 0.25, player.get_vert_drag())

	if data and data.get("jump"):
		player.can_coyote_jump = false

	var input_kick = player.input_kick_held if not (data and data.get("no_buffer_kick")) else player.input_kick
	if input_kick:
		if !(data and data.get("jump") and player.input_duck and time < 0.03):
			return "Kick"
	time += delta

	
func _exit():
	jump_grace_pos.enabled = false
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false
