extends SmileyState

class_name SmileyRunState


const RUN_LEG_TURN_SPEED = 25
const MIN_RUN_SPEED = 30
const MAX_SKID_TIME = 1.5
const RUN_DOWN_FORCE = 800
const MIN_RUN_TIME = 0.1
const SLOPE_FORCE = 100
const PREV_SPEED_DECAY = 0.9999
const PREV_SPEED_DECAY_SLOPE_AMOUNT = 0.008
const EXTRA_JUMP_SPEED = 50

@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest
@onready var foot_can_go_under_timer: Timer = $FootCanGoUnderTimer

@onready var foot_1_rest_start_pos = foot_1_rest.position
@onready var foot_2_rest_start_pos = foot_2_rest.position
@onready var slope_detector: RayCast2D = $SlopeDetector

var skid_time := 0.0
var run_time := 0.0
var back_skid = false
var force := Vector2()

var prev_speed := 0.0
var retain_speed := false

func _enter() -> void:
	prev_speed = 0
	run_time = 0
	foot_1_rest.enabled = true
	foot_2_rest.enabled = true
	back_skid = false
	foot_2_rest.global_rotation = PI/2
	foot_1_rest.global_rotation = -PI/2
	foot_can_go_under_timer.start()
	skid_time = 0
	host.footstep_particles = true
	retain_speed = false
	

func _update(delta: float):
	#body.apply_gravity()
	#host.apply_friction(delta)
	#body.apply_physics(delta)

	slope_detector.enabled = player.get_slope_level() < 0
	player.is_grounded = player.is_grounded or slope_detector.is_colliding()
	var fell = false
	if !check_jump({"retain_speed": abs(body.velocity.x)}):
		if check_fall():
			pass
	#else:
		#if body.velocity.y <= 0:
			#body.impulses.y *= 1.2

	check_duck()


	foot_1_rest.position = foot_1_rest_start_pos * (1 - player.floor_overlap_ratio)
	foot_2_rest.position = foot_2_rest_start_pos * (1 - player.floor_overlap_ratio)
	
	#foot_1_rest.hit_from_inside = !foot_can_go_under_timer.is_stopped()
	#foot_2_rest.hit_from_inside = !foot_can_go_under_timer.is_stopped()
			
	var slope = player.get_slope_level()
	#var slope = player.get_slope_level()
	player.squish()

	if abs(body.velocity.x) < MIN_RUN_SPEED and player.input_move_dir == 0 and run_time >= MIN_RUN_TIME:
		if back_skid:
			player.set_flip(-player.facing)
		return "Idle"
	else:
		if player.input_move_dir != 0 and player.input_move_dir == sign(body.velocity.x):
			#if foot_can_go_under_timer.is_stopped():
				player.set_flip(player.input_move_dir)

	if (player.touching_wall_dir != player.input_move_dir):
		var force := Vector2(player.get_run_speed() * player.input_move_dir, 0).rotated(player.get_floor_angle())
		body.apply_force(force)
	elif player.touching_wall:
		return "Idle"

	slope_detector.target_position.x = abs(slope_detector.target_position.x) * player.facing
	
	if player.boost_tile_detector.is_colliding():
	#if player.boost_tile_detector.is_colliding() or abs(body.velocity.x) > 300:
		player.is_boosting = true
	if player.input_move_dir != player.facing:
		player.is_boosting = false
	
	player.foot_1.z_index = -1 * player.facing
	player.foot_2.z_index = 1 * player.facing
	player.foot_1.rotation = -PI/2
	player.foot_2.rotation = -PI/2
	
	run_time += delta

	#Debug.dbg("back_skid", back_skid)

	
	var run_speed = abs(body.velocity.dot(player.feet_ray.get_collision_normal().rotated(TAU/4)))
	
	#Debug.dbg("run_speed", run_speed)

	if (sign(body.velocity.x) != player.input_move_dir and player.input_move_dir != 0 and body.velocity.x != 0) or player.input_move_dir == 0:

		if !back_skid:
			back_skid = player.input_move_dir and (sign(body.velocity.x)) != player.input_move_dir and run_time > MIN_RUN_TIME
		
		
		#foot_1_rest.rotation = Vector2(1, 1 * player.facing).angle()
		#foot_2_rest.rotation = Vector2(1, 1 * player.facing).angle()
		#player.foot_1.rotation = Vector2(1 * player.facing, -2).angle()
		#player.foot_2.rotation = Vector2(1 * player.facing, -2).angle()
		#player.update_feet_position(0.5)
		#var run_leg_turn_speed_multiplier = abs(body.velocity.x) * 0.0045
		#foot_1_rest.rotation += delta * RUN_LEG_TURN_SPEED * player.facing * run_leg_turn_speed_multiplier * 3
		#foot_2_rest.rotation = foot_1_rest.rotation + -PI
		#player.update_feet_position(0.5)
	#elif player.input_move_dir == 0:

		foot_1_rest.rotation = Vector2(2, -8 * player.facing).angle()
		foot_2_rest.rotation = Vector2(2, -8 * player.facing).angle()
		player.foot_1.rotation = Vector2(-1 * player.facing, -2).angle()
		player.foot_2.rotation = Vector2(-1 * player.facing, -2).angle()
		player.foot_2_was_touching_ground = true
		player.foot_1_was_touching_ground = true
		var t = 1
		#player.foot_1.rotation = lerp_angle(-PI/2, player.foot_1.rotation, t)
		#player.foot_2.rotation = lerp_angle(-PI/2, player.foot_2.rotation, t)
		#foot_1_rest.rotation = lerp_angle(Vector2(1, 0).angle(), foot_1_rest.rotation, t)
		#foot_2_rest.rotation = lerp_angle(Vector2(1, 0).angle(), foot_2_rest.rotation, t)
		player.update_feet_position(0.5)
		player.face_offset = Vector2(-5, 0)
		skid_time += delta
		if skid_time < 0.75 and abs(body.velocity.x) > 70:

			var dir := Vector2(body.velocity.x, 0).rotated(player.get_floor_angle())
			player.play_sound("Skid", false)
			player.play_sound("Skid2", false)
			var particle_offs := player.to_local(player.feet_ray.get_collision_point() + Vector2(player.facing * player.rng.randf_range(8, -5), 0).rotated(player.get_floor_angle()))
			player.spawn_scene(preload("res://stupid crap/friends/player/fx/skid_dust.tscn"), particle_offs, dir)
			#player.spawn_scene(preload("res://stupid crap/friends/player/fx/skid_dust.tscn"), player.to_local(player.foot_2_pos), dir)
		body.velocity.x *= 0.999
		prev_speed = 0
		retain_speed = false
		player.feet_lift_body()

	else:
		retain_speed = true
		body.apply_force(Vector2.DOWN * RUN_DOWN_FORCE * (1 - player.floor_overlap_ratio) * (max(slope, 0)))
		#body.apply_force(player.get_slope_level())

				
				
		back_skid = false
		player.face_offset = Vector2(0, 0)
		skid_time = 0
		var run_leg_turn_speed_multiplier = abs(body.velocity.x) * 0.0065
		foot_1_rest.rotation += delta * RUN_LEG_TURN_SPEED * player.input_move_dir * run_leg_turn_speed_multiplier
		foot_2_rest.rotation = foot_1_rest.rotation + -PI
		player.update_feet_position(0.95)
		
		player.foot_2_was_touching_ground = foot_2_rest.is_colliding()
		player.foot_1_was_touching_ground = foot_1_rest.is_colliding()

		if foot_1_rest.is_colliding():
			player.foot_1.rotation = foot_1_rest.get_collision_normal().angle()
		
		if foot_2_rest.is_colliding():
			player.foot_2.rotation = foot_2_rest.get_collision_normal().angle()
		
		if sign(body.velocity.x) != player.facing:
			body.velocity.x *= 0

		if player.floor_overlap_ratio > 0.8:
			var amount = Math.map(player.floor_overlap_ratio, 0.8, 1.0, 0.0, 1.0) * -(min(slope, 0))
			body.move_directly(player.feet_ray.get_collision_normal() * body.speed * 0.02 * amount)
			body.move_directly(player.feet_ray.get_collision_normal().rotated(-TAU/8 * player.facing) * body.speed * 0.02 * amount)

		player.feet_lift_body(SmileyPlayer.SPRING_AMOUNT, 2, SmileyPlayer.SPRING_DAMP + (4 * (max(slope, 0))))  

		#if slope > 0:
			#player.feet_lift_body(3000 * (1 - abs(slope / 2.0)), 1) 
		#elif slope < 0:
			#player.feet_lift_body(3000 * (1 - abs(slope / 1.0)), 1) 
		#else:
			#player.feet_lift_body()
		
		prev_speed = run_speed if run_speed > prev_speed else prev_speed
		prev_speed *= PREV_SPEED_DECAY
		prev_speed *= (1 - (PREV_SPEED_DECAY_SLOPE_AMOUNT * -(min(0, slope))))
		#prev_speed = clamp(prev_speed, 0, 300)
	
	#body.apply_gravity()
	
	player.foot_1_pos = foot_1_rest.get_collision_point() if foot_1_rest.is_colliding() else Physics.get_raycast_end_point(foot_1_rest)
	player.foot_2_pos = foot_2_rest.get_collision_point() if foot_2_rest.is_colliding() else Physics.get_raycast_end_point(foot_2_rest)

	#if skid_time > 0:
		#player.foot_1_pos += Vector2(sign(body.velocity.x) * 6, 0)
		#player.foot_2_pos += Vector2(sign(body.velocity.x) * 6, 0)
	
	if retain_speed:
		var norm = player.feet_ray.get_collision_normal()
		if run_speed < prev_speed:
			#Debug.dbg("force", norm * (prev_speed - body.speed))
			body.velocity += (norm.rotated(TAU/4 * player.facing) * (prev_speed - body.speed))
			#body.velocity += (norm * (prev_speed - body.speed) * 0.5)
	#Debug.dbg("prev_speed", prev_speed)


	if skid_time >= MAX_SKID_TIME:
		return "Idle"
	
func _exit():
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false
	host.footstep_particles = false
	slope_detector.enabled = false
