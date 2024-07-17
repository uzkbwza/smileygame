extends SmileyState

class_name SmileyFallState

const ROTATE_SPEED = 8
const MOVE_SPEED = 420
const COYOTE_TIME = 0.08
const PREV_SPEED_DECAY = 0.9999
const BUFFER_KICK_COOLDOWN = 0.15
const MAX_STRENGTH_LENIENCY = 0.1
const MIN_STRENGTH = 0.85
const MIN_SLIDE_DIFFERENCE = 0.25
const STICKY_FORCE = 100

const WALL_SLIDE_RAYCAST_RESOLUTION = 32
const WALL_SLIDE_RAYCAST_LENGTH = 8

const DIAGONAL_STICKY_TIME = 0.0167

const WIDEST_ANGLE = TAU/6

const KICK_OVERLAP_GRAVITY_START = 1.0 - (WALL_SLIDE_RAYCAST_LENGTH / SmileyKickState.KICK_DIST)

@onready var jump_hold_timer: Timer = $JumpHoldTimer
@onready var can_land_timer: Timer = $CanLandTimer

@onready var foot_1_rest: RayCast2D = $Foot1Rest
@onready var foot_2_rest: RayCast2D = $Foot2Rest
@onready var jump_grace_pos: RayCast2D = %JumpGracePos


var can_use_run_speed = true
var rotate_dir := 0.0
var rotate_amount := 0.0
var jump_held := true
var retain_speed := false
var starting_dir = 0
var wall_can_retain_momentum = false
var trick_jump = false

var diagonal_sticky_time := 0.0

var prev_speed := 0.0

var time = 0.00

var wall_raycasts : Array[RayCast2D]= []

var is_near_wall: bool
var nearest_collision_point: Vector2
var nearest_collision_normal: Vector2
var nearest_collision_raycast: RayCast2D
var nearest_collision_distance: float
var nearest_collision_angle: float
var nearest_collision_overlap_ratio: float
var nearest_collider: PhysicsBody2D
var kick_dir: Vector2

var slide_time = 0.0

var slide_dir := Vector2()
var slide_input_force_dir := Vector2()

func _ready():
	for i in WALL_SLIDE_RAYCAST_RESOLUTION:
		var raycast = RayCast2D.new()
		raycast.target_position = Vector2(WALL_SLIDE_RAYCAST_LENGTH, 0).rotated((i / float(WALL_SLIDE_RAYCAST_RESOLUTION)) * TAU)
		raycast.enabled = false
		add_child.call_deferred(raycast)
		wall_raycasts.append(raycast)
		raycast.hide()



func _enter():
	player.wall_sliding = false
	for raycast in wall_raycasts:
		raycast.enabled = true
		raycast.force_raycast_update()
	
	if Debug.enabled:
		for raycast in wall_raycasts:
			raycast.show()
		
	if data and data.get("jump"):
		player.start_wall_momentum_timer()
	player.wall_can_retain_momentum = data and data.get("jump")
	rotate_dir = 0
	player.face_offset.y = 0
	#if player.input_move_dir != 0 and player.facing != sign(body.velocity.x) and data:
		#rotate_dir = player.input_move_dir
	time = 0.00
	rotate_amount = 0
	#player.last_aerial_velocity *= 0
	#kick_ray.enabled = true
	#object_detector_shape.set_deferred("disabled", false)
	foot_1_rest.enabled = true
	jump_grace_pos.enabled = true
	foot_2_rest.enabled = true
	player.is_grounded = false
	starting_dir = signf(body.velocity.x)
	prev_speed = 0.0

	#prev_speed = data.retain_speed if data is Dictionary and data.has("retain_speed") else 0.0
	#retain_speed = prev_speed > 0
	prev_speed = abs(body.velocity.x) if !(data is Dictionary and data.has("retain_speed")) else data.retain_speed
	retain_speed = true
	trick_jump = data and data.get("trick_jump")
	

	if retain_speed:
		if signf(body.velocity.x) != starting_dir or signf(body.velocity.x) == 0 or signf(body.velocity.x) != player.input_move_dir:
			retain_speed = false
			prev_speed = 0.0
		elif absf(body.velocity.x) < prev_speed:
			body.velocity.x = sign(body.velocity.x) * prev_speed

	can_use_run_speed = _previous_state() == "Run" and sign(player.input_move_dir) == sign(player.facing)
	
	
	if data and data.get("jump"):
		can_land_timer.start()
		jump_held = true
		jump_hold_timer.start()

	player.foot_1_was_touching_ground = false
	player.foot_2_was_touching_ground = false
	
	update_closest_collision_data()

	slide_time = 0.0
#
	#if player.input_secondary_held:
		#if !(data and data.get("jump") and player.input_duck):
			#return "Kick"

func update_closest_collision_data():
	is_near_wall = false

	nearest_collision_distance = INF
	for raycast in wall_raycasts:
		if !raycast.is_colliding():
			continue
		var normal = raycast.get_collision_normal()
		if normal.y < player.MAX_GROUNDED_Y_NORMAL:
			continue
			
		is_near_wall = true
		var point = raycast.get_collision_point()
		var dist = to_local(point).length_squared()
		if dist < nearest_collision_distance:
			nearest_collision_raycast = raycast
			nearest_collision_distance = dist
			nearest_collision_normal = normal
			nearest_collision_point = point

	if !is_near_wall:
		return
		
	nearest_collider = nearest_collision_raycast.get_collider()
	nearest_collision_distance = to_local(nearest_collision_point).length()
	nearest_collision_overlap_ratio = 1.0 - min(nearest_collision_distance / WALL_SLIDE_RAYCAST_LENGTH, 1.0)
	nearest_collision_angle = nearest_collision_normal.rotated(TAU/4).angle()


func wall_slide(delta: float):

	var input_dir = player.input_move_dir_vec_normalized
	if input_dir:
		kick_dir = input_dir
		if absf(nearest_collision_normal.x) > absf(nearest_collision_normal.y):
			if kick_dir.dot(nearest_collision_normal) < 0:
				kick_dir.x *= -1
			if input_dir.y != 0:
				kick_dir.x *= 0
		else:
			if kick_dir.dot(nearest_collision_normal) < 0:
				kick_dir.y *= -1
			if input_dir.x != 0:
				kick_dir.y *= 0

		var angle = kick_dir.angle_to(nearest_collision_normal)
		if abs(angle) > (WIDEST_ANGLE):
			kick_dir = nearest_collision_normal.rotated((WIDEST_ANGLE) * -sign(angle))
	else:
		kick_dir = nearest_collision_normal
	
	var remapped_overlap = remap(nearest_collision_overlap_ratio, 0.0, 1.0, KICK_OVERLAP_GRAVITY_START, 1.0)
	if player.input_primary:
		var kick_strength = pow(remapped_overlap, 2)
		if kick_strength > 1.0 - MAX_STRENGTH_LENIENCY:
			kick_strength = 1.0
		kick_strength = max(kick_strength, MIN_STRENGTH)
		queue_state_change("KickOff", { "kick_dir": kick_dir, "kick_strength": kick_strength } )

	if body.velocity.y < 0:
		slide_time += delta * 0.25
	else:
		slide_time += delta
	
	var wall_sliding := player.input_move_dir_vec_normalized.dot(nearest_collision_normal) < -MIN_SLIDE_DIFFERENCE

	if wall_sliding:
		player.can_coyote_jump = false
		prev_speed = 0
		#prev_speed = abs(body.prev_speed)
		#if !player.wall_sliding:
			#var normal_dir = nearest_collision_normal
			#var new_vel = body.prev_velocity.slide(normal_dir)
			##new_vel.y = abs(new_vel.y) * sign(body.velocity.y)
			#new_vel.x = abs(new_vel.x) * sign(body.velocity.x)
			#slide_dir = new_vel.normalized()
			#body.move_and_collide(body.velocity.normalized() * nearest_collision_distance * 100)
			#player.global_position = nearest_collision_point
			#body.velocity = new_vel
		#body.apply_force(STICKY_FORCE * -nearest_collision_normal)
	player.wall_sliding = wall_sliding
	#player.last_grounded_height = player.y
	#if nearest_collision_normal.y > 0:
		#slide_input_force_dir = player.input_move_dir * nearest_collision_normal.rotated(-TAU/4)
		#body.apply_force(MOVE_SPEED * slide_input_force_dir)
	#else:
	body.apply_force(Vector2(MOVE_SPEED * player.input_move_dir, 0))

	var kick_ray = nearest_collision_raycast
	
	if wall_sliding and rng.chance_delta(3.0 * body.speed / 10.0, delta):
	#if false:
		player.play_sound("WallFall", false)
		player.spawn_scene(preload("res://object/player/fx/wall_skid_dust.tscn"), to_local(kick_ray.get_collision_point()), Vector2.DOWN)
		if rng.chance_delta(10.0, delta):
			var particle = player.spawn_scene(preload("res://object/player/fx/wall_skid_particle.tscn"), to_local(kick_ray.get_collision_point()), Vector2.DOWN)
			particle.rotation = body.velocity.angle()
			particle.starting_velocity = maxf(body.speed * 0.5, 200)
			particle.go.call_deferred()
	
	if player.feet_ray.is_colliding():
		player.set_deferred("is_grounded", true)

	foot_1_rest.target_position = kick_ray.target_position * 0.55 - Vector2(0, 10).rotated(kick_ray.target_position.angle() + (PI if player.facing == 1 else 0))
	player.foot_1_pos = Physics.get_raycast_end_point(foot_1_rest) if !foot_1_rest.is_colliding() else foot_1_rest.get_collision_point()
	player.foot_1.rotation = kick_ray.target_position.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))

	foot_2_rest.target_position = kick_ray.target_position * 0.20 + Vector2(0, 0).rotated(kick_ray.target_position.angle() + (PI if player.facing == 1 else 0))
	player.foot_2_pos = Physics.get_raycast_end_point(foot_2_rest) if !foot_2_rest.is_colliding() else foot_2_rest.get_collision_point()
	player.foot_2.rotation = kick_ray.target_position.angle() - (TAU/4 if player.facing == 1 else (TAU/4 * 3))
	#player.foot_2.flip_v
	player.foot_2_was_touching_ground = foot_2_rest.is_colliding()
	player.foot_1_was_touching_ground = foot_1_rest.is_colliding()

	if wall_sliding:
		body.apply_gravity(Vector2.DOWN * lerpf(body.gravity, body.gravity * clampf(slide_time, 0, 2), remapped_overlap))
		pass
	else:
		body.apply_gravity()
	#started_sliding = true
	body.apply_drag(delta, body.air_drag * 0.25, player.get_vert_drag())
	#body.apply_gravity()
	body.apply_physics(delta)
	#body.reset_momentum()


func _update(delta: float):
	kick_dir = Vector2()
	update_closest_collision_data()
	if Debug.enabled:
		Debug.dbg("nearest_collision_normal", nearest_collision_normal)
		Debug.dbg("nearest_collision_overlap", nearest_collision_overlap_ratio)
		Debug.dbg("prev_speed", prev_speed)
	
	if (!jump_held and can_land_timer.is_stopped()) or (body.velocity.y > 0):
		check_landing()
	
	#object_detector.monitoring = player.input_trick_window()
	
	#player.feet_lift_body()
	#player.feet_idle()
	if rotate_dir == 0:
		player.squish()
	
	if body.velocity.y > 0:
		jump_hold_timer.stop()
	
	if !player.input_primary_held:
		jump_held = false
	
	if jump_hold_timer.is_stopped():
		jump_held = false
	else:
		if !jump_held:
			body.velocity.y *= 0.9
		
	var angle = Vector2(lerp_angle(player.facing, -player.facing, body.velocity.y * 0.005), -1).angle()
	var jumped = false
	
	if player.can_coyote_jump and (time < COYOTE_TIME or jump_grace_pos.is_colliding()) and !(data and data.get("jump")):
		var data = {}
		if retain_speed:
			data = {"retain_speed": abs(body.velocity.x)}
		if check_jump(data):
			jumped = true

	
	#if foot_1_rest.is_colliding():
		#player.foot_1_pos = foot_1_rest.get_collision_point()
	#if foot_2_rest.is_colliding():
		#player.foot_2_pos = foot_2_rest.get_collision_point()

	#var applied_drag = false

	if retain_speed:
		prev_speed *= PREV_SPEED_DECAY
		var air_speed = absf(body.velocity.x)
		if time > 0.032:
			prev_speed = air_speed if air_speed > prev_speed else prev_speed
		else:
			body.velocity.x = prev_speed * sign(body.velocity.x)
		if signf(body.velocity.x) != starting_dir or signf(body.velocity.x) == 0 or signf(body.velocity.x) != player.input_move_dir:
			retain_speed = false

		body.velocity.x = sign(body.velocity.x) * prev_speed
		#body.apply_force(Vector2(player.get_run_speed() * player.input_move_dir, 0))
		#applied_drag = true
		#body.apply_drag(delta, body.ground_drag, player.get_vert_drag())

		Debug.dbg("prev_speed", prev_speed)

	#process_trickable_objects.call_deferred()

	if is_near_wall and !jumped:
		return wall_slide(delta)
	elif player.input_move_dir == player.facing and can_use_run_speed:
		body.apply_force(Vector2(player.get_run_speed() * player.input_move_dir, 0))
		body.apply_drag(delta, body.ground_drag, player.get_vert_drag())
	else:
		can_use_run_speed = false
		body.apply_force(Vector2(MOVE_SPEED * player.input_move_dir, 0))
		if player.input_move_dir != 0:
			player.apply_friction(delta)
		else:
			body.apply_drag(delta, body.air_drag * 0.25, player.get_vert_drag())

	player.wall_sliding = false

	slide_time = 0.0
	
	rotate_amount += rotate_dir * ROTATE_SPEED * delta
	
	player.sprite.rotation = rotate_amount
	player.foot_1.rotation = angle + rotate_amount
	player.foot_2.rotation = angle + rotate_amount
	player.foot_1.z_index = -1
	player.foot_2.z_index = 1
	var horiz_offset = Vector2((lerp(-1, 1, body.velocity.y * 0.05) + 10) * player.facing, 0) * (player.facing * body.velocity.x * 0.0025)
	horiz_offset = horiz_offset.limit_length(20)
	if sign(body.velocity.x) != player.facing:
		horiz_offset *= 0.0
	player.foot_1_pos = player.global_position + (Vector2(5 * player.facing, 15) + horiz_offset).rotated(rotate_amount)
	player.foot_2_pos = player.global_position + (Vector2(-5 * player.facing, 15) + horiz_offset).rotated(rotate_amount)
	var vertical_offset = body.velocity.y * -0.02
	player.foot_1_pos += Vector2(0, vertical_offset).rotated(rotate_amount).limit_length(5)
	player.foot_2_pos += Vector2(0, vertical_offset).rotated(rotate_amount).limit_length(5)

	if data and data.get("jump"):
		player.can_coyote_jump = false

	body.apply_gravity()
	body.apply_physics(delta)
	
	player.is_grounded = false
	if player.feet_ray.is_colliding():
		player.set_deferred("is_grounded", true)
	
	time += delta

func _exit():
	jump_grace_pos.enabled = false
	foot_1_rest.enabled = false
	foot_2_rest.enabled = false
	#kick_ray.enabled = false
	#object_detector.monitoring = false
	#object_detector_shape.set_deferred("disabled", true)
	
	for raycast in wall_raycasts:
		raycast.enabled = false
	if Debug.enabled:
		for raycast in wall_raycasts:
			raycast.hide()
	queue_redraw()
	
func _draw():
	if !active:
		return
	if Debug.draw:
		for raycast in wall_raycasts:
			var colliding = raycast.is_colliding()
			var color = Color.WHITE if !colliding else Color.PURPLE
			color.a *= 0.0 if !colliding else 1.0
			draw_line(Vector2(), raycast.target_position, color)
			if colliding:
				draw_circle(to_local(raycast.get_collision_point()), 3, Color.PURPLE, true)
		if is_near_wall:
			draw_line(Vector2(), nearest_collision_normal * 25, Color.CYAN)
		if kick_dir:
			draw_line(Vector2(), kick_dir * 20, Color.RED)
		if slide_dir:
			draw_line(Vector2(), slide_dir * 25, Color.YELLOW)
		if slide_input_force_dir:
			draw_line(Vector2(), slide_dir * 25, Color.WHITE)
