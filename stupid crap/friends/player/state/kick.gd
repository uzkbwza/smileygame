extends SmileyState

const KICK_DIST = 30

const KICK_FORCE = 5000
const MAX_STRENGTH_LENIENCY = 0.1
const MIN_STRENGTH = 0.2
const KICK_FRICTION = 0.9
const FLOOR_KICK_REDUCTION_AMOUNT = 0.35
const DIAGONAL_STICKY_TIME = 0.0167
@onready var kick_ray: RayCast2D = $KickRay
@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest
@onready var hazard_ray: RayCast2D = $HazardRay

var collision_overlap := 0.0

var diagonal_sticky_time := 0.0

var started_sliding = true

var kick_input := Vector2i():
	set(value):
		if player and active:
			if value != kick_input:
				player.play_sound("Kick", true)
		kick_input = value
			

var slide_time := 0.0
var time := 0.0

func _enter() -> void:
	player.play_sound("Kick")
	if not player.input_move_dir_vec:
		kick_input = Vector2i()
		kick_ray.target_position = KICK_DIST * Vector2.RIGHT * player.facing
	else:
		kick_input = player.input_move_dir_vec
		kick_ray.target_position = player.input_move_dir_vec_normalized * KICK_DIST
	diagonal_sticky_time = 0.0
	foot_1_rest.enabled = true
	foot_2_rest.enabled = true
	player.is_boosting = false
	hazard_ray.enabled = true
	player.wall_sliding = false
	kick_ray.enabled = true
	started_sliding = false
	slide_time = 0.0

func _update(delta: float):
	player.squish()
	body.apply_drag(delta, body.air_drag * 0.25, player.get_vert_drag())

	player.wall_sliding = false
	
	if player.input_move_dir_vec:
		if player.input_move_dir_vec.x != 0 and player.input_move_dir_vec.y != 0:
			diagonal_sticky_time = DIAGONAL_STICKY_TIME
			kick_input = player.input_move_dir_vec
		else:
			if diagonal_sticky_time <= 0.0 or (kick_input.x != player.input_move_dir_vec.x and kick_input.y != player.input_move_dir_vec.y):
				kick_input = player.input_move_dir_vec

		kick_ray.target_position = Math.splerp_vec(kick_ray.target_position, kick_input * KICK_DIST, delta, 2.5 if kick_ray.is_colliding() else 0.0)
		
		if player.input_move_dir:
			player.set_flip(player.input_move_dir)

	hazard_ray.target_position = kick_ray.target_position
	kick_ray.enabled = !hazard_ray.is_colliding()

	if diagonal_sticky_time >= 0:
		diagonal_sticky_time -= delta

	foot_1_rest.target_position = kick_ray.target_position * 0.55 - Vector2(0, 10).rotated(kick_ray.target_position.angle() + (PI if player.facing == 1 else 0))
	player.foot_1_pos = Physics.get_raycast_end_point(foot_1_rest) if !foot_1_rest.is_colliding() else foot_1_rest.get_collision_point()
	player.foot_1.rotation = kick_ray.target_position.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))

	foot_2_rest.target_position = kick_ray.target_position * 0.20 + Vector2(0, 0).rotated(kick_ray.target_position.angle() + (PI if player.facing == 1 else 0))
	player.foot_2_pos = Physics.get_raycast_end_point(foot_2_rest) if !foot_2_rest.is_colliding() else foot_2_rest.get_collision_point()
	player.foot_2.rotation = kick_ray.target_position.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))
	#player.foot_2.flip_v
	player.foot_2_was_touching_ground = foot_2_rest.is_colliding()
	player.foot_1_was_touching_ground = foot_1_rest.is_colliding()
	
	collision_overlap = 0.0
	if kick_ray.is_colliding() and kick_ray.get_collision_normal().y >= 0:
		collision_overlap = min(((kick_ray.target_position - kick_ray.to_local(kick_ray.get_collision_point()))).length() / KICK_DIST, 1)
		if collision_overlap > 0.5:

			player.touch_terrain_with_feet(kick_ray.get_collider())
			if body.velocity.y < 0:
				slide_time += delta * 0.25
			else:
				slide_time += delta
			
			player.wall_sliding = true
			#player.last_grounded_height = player.y
			
			body.apply_gravity(Vector2.DOWN * lerpf(body.gravity, body.gravity * clampf(slide_time, 0, 2), collision_overlap))
			started_sliding = true
		else:
			slide_time = 0.0
			body.apply_gravity()
	else:
		slide_time = 0.0
		body.apply_gravity()
	
	if slide_time == 0.0 and started_sliding:
		queue_state_change("Fall", {"no_buffer_kick": true})
	
	#Debug.dbg("slide gravity",slide_time)
	
	if collision_overlap > 0.5 and rng.chance_delta(3.0 * body.speed / 10.0, delta):
		player.play_sound("WallFall", false)
		player.spawn_scene(preload("res://stupid crap/friends/player/fx/wall_skid_dust.tscn"), to_local(kick_ray.get_collision_point()), Vector2.DOWN)
		if rng.chance_delta(10.0, delta):
			var particle = player.spawn_scene(preload("res://stupid crap/friends/player/fx/wall_skid_particle.tscn"), to_local(kick_ray.get_collision_point()), Vector2.DOWN)
			particle.rotation = body.velocity.angle()
			particle.starting_velocity = max(body.speed * 0.5, 200)
			particle.go()

	
	#body.velocity.x *= (1 - pow(collision_overlap, 10) / 10.0)
	body.velocity.y *= (1 - pow(collision_overlap, 10) / 10.0) if body.velocity.y > 0 else (1 - pow(collision_overlap, 10) / 30.0)

	if player.floor_overlap_ratio > 0.0 and ((collision_overlap <= 0.9 or body.is_on_floor()) and body.velocity.y >= 0 and player.feet_ray.get_collision_normal().dot(Vector2.UP) > 0.5):
		player.is_grounded = true
		check_landing()
	
	#if collision_overlap > 0.8 and body.velocity.normalized().dot(-kick_ray.target_position.normalized()) > 0.5:
		#queue_state_change("KickOff", { "kick_dir": -kick_ray.target_position.normalized() } )

	
	if !player.input_kick_held:
		if collision_overlap <= 0.5:
			return "Fall"
		else:
			var kick_strength = pow(collision_overlap, 2)
			if kick_strength > 1.0 - MAX_STRENGTH_LENIENCY:
				kick_strength = 1.0
			kick_strength = max(kick_strength, MIN_STRENGTH)
			#var floor_kick_reduction = clamp(1.0 + min(kick_ray.get_collision_normal().dot(Vector2.DOWN), player.feet_ray.get_collision_normal().dot(Vector2.DOWN)), 0.0, 1.0)
			#kick_strength *= lerpf(1.0, floor_kick_reduction, FLOOR_KICK_REDUCTION_AMOUNT)
			queue_state_change("KickOff", { "kick_dir": -kick_ray.target_position.normalized(), "kick_strength": kick_strength } )
			player.spawn_scene(preload("res://stupid crap/friends/player/fx/jump_dust.tscn"), to_local(kick_ray.get_collision_point()), (-kick_ray.target_position))
			pass

	#Debug.dbg("kick overlap", collision_overlap)

func _exit():
	player.stop_sound("WallFall")
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false
	kick_ray.enabled = false
	hazard_ray.enabled = false
	player.wall_sliding = false	
