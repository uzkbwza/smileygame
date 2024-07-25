extends SmileyState

var rail: RailPost

const GRIND_OFFSET = Vector2(0, -15)
const FORCE_STRENGTH = 1000
const GRIND_SPEED = 300
const GRIND_GRAVITY = 300
const GRIND_DRAG = 0.3
const EXTRA_SPEED = 1.35
const MIN_SPEED = 50
const END_DIST = 10
const MAX_BODY_DIST= 10
const GRIND_CONTROL_CHANGE_MIN_SPEED = 100
const MIN_START_SPEED = 160
const FALL_GRIND_COOLDOWN = 0.35
const JUMP_GRIND_COOLDOWN = 0.167

var grind_position: Vector2

var grind_velocity: float = 0.0

var grind_offset: float = 0.0
var grind_accel: float = 0.0

var control_dir = 1
var last_normal_y = 0
var last_normal = Vector2()
var last_input = 0

func _enter():
	player.play_sound("GrindStart1")
	player.play_sound("GrindStart2")
	player.play_sound("GrindStart3")
	player.grinding = true
	
	grind_velocity *= 0
	grind_accel *= 0
	
	player.is_grounded = false
	rail = data.get("rail")
	var offs = rail.get_offset(player.global_position) 
	grind_offset = clamp(offs, 0.0, rail.length)
	var normal = rail.get_normal(offs)
	var direction = normal.rotated(TAU/4)

	player.get_camera().bump(Vector2.DOWN, max(body.speed * 0.05, 0.01), 0.125, 60)
	#player.global_position = player.global_position.lerp(grind_body_position(), 0.5)

	if offs <= 0 or offs >= rail.length:
		player.global_position = grind_body_position()
	
	#var dir = sign(body.velocity.x)
	#grind_velocity = Vector2(body.velocity.x, player.last_aerial_velocity.y).rotated(-player.get_floor_angle())
	grind_velocity = (body.velocity.length() * direction.dot(body.velocity.normalized()))


	#grind_velocity.x = abs(grind_velocity.x) * dir
	#if sign(grind_velocity.x) == sign(player.input_move_dir) or player.input_move_dir == 0:
	grind_velocity += grind_velocity * (EXTRA_SPEED - 1)

	player.can_coyote_jump = true
	control_dir = 1
	last_normal_y = sign(normal.y)
	#grind_velocity.y *= -sign(normal.y)
	#grind_velocity.x *= -sign(normal.y)
	last_input = player.input_move_dir
	last_normal = normal
	#Debug.dbg("started grind velocity", grind_velocity)
	#Debug.dbg("started grind direction", direction)

	if abs(grind_velocity) < MIN_START_SPEED and player.input_move_dir != 0:
		grind_velocity = player.input_move_dir * MIN_START_SPEED

	player.grind_position = player.global_position


## TODO: closed loops

func _update(delta: float):
	var direction = rail.get_direction(grind_offset)
	var rail_angle = direction.angle()
	var normal = direction.rotated(-TAU/4)

	if last_normal_y != (sign(normal.y)):
		if player.input_move_dir != 0:
			control_dir *= -1

	if player.input_move_dir != last_input or player.input_move_dir == 0 or abs(grind_velocity) < GRIND_CONTROL_CHANGE_MIN_SPEED:
	#if player.input_move_dir != last_input or player.input_move_dir == 0:
		control_dir = 1
		
	last_input = player.input_move_dir

	last_normal_y = sign(normal.y)

	var grind_force = player.input_move_dir * GRIND_SPEED * control_dir * -sign(normal.y)
	
	var gravity =  GRIND_GRAVITY * normal.x * abs(normal.y)
	#
	grind_force += gravity
	#

	#var vel = grind_velocity
	#vel.y *= sign(normal.y)
#
	#var speed = vel.length()
	#grind_velocity_1d = speed * sign(grind_velocity.x)
#
	grind_accel += grind_force
	grind_velocity += grind_accel * delta
	grind_accel *= 0
	grind_offset += grind_velocity * delta
		#
	apply_drag(delta, GRIND_DRAG)

	grind_position = rail.get_grind_position_from_offset(grind_offset)
	
	var grind_body_position = grind_body_position()

	
	var speed = abs(grind_velocity)
	
	var sound1 = player.get_sound("Grind1")
	if abs(speed) > 30:
		#player.play_sound("Grind1", false)
		var sound2 = player.get_sound("Grind2")
		
		
		if !sound1.is_playing():
			sound1.go()
			sound1.pitch_scale = 0.25 + speed * 0.01
		if rng.chance_delta(speed * 0.5, delta):
			if !sound2.is_playing():
				sound2.pitch_scale = 1.5 + speed * 0.01
				sound2.play()
				
		if rng.chance_delta(speed * 0.75, delta):
			grind_spark.call_deferred(player.foot_2.global_position)
		if rng.chance_delta(speed * 0.15, delta):
			var dust_pos = player.foot_1.global_position.lerp(player.foot_2.global_position, rng.randf()) + 7 * -normal
			player.spawn_scene(preload("res://object/environment/rail/fx/grind_spark2.tscn"), to_local(dust_pos), rail.get_direction(rail.get_offset(dust_pos)) * sign(grind_velocity), false)
				#player.spawn_scene(preload("res://stupid crap/friends/terrain/rail/fx/grind_spark2.tscn"), to_local(pos), rail.get_direction(pos) * grind_velocity.x, false)
		#player.play_sound("Grind2", true)
	else:
		sound1.stop()

	#
	#var min_height = max(player.foot_1.global_position.y,player.foot_2.global_position.y)
	#if player.global_position.y > min_height:
		#player.global_position.y = min_height
		#body.velocity.y *= 0
	#
	var flip_dir = player.input_move_dir * control_dir
	if player.input_move_dir != 0:
		player.set_flip(player.input_move_dir * control_dir * -sign(normal.y))



	#var rail_overlap = 1.0 - (clampf(grind_position.distance_to(player.global_position) / GRIND_OFFSET.length(), 0.0, 1.0))
	#
	var damp = 1
	var displacement_x = clampf((player.global_position.x - grind_body_position.x) / MAX_BODY_DIST, -0.5, 0.5) * 2
	var displacement_y = clampf((player.global_position.y - grind_body_position.y) / MAX_BODY_DIST, -0.5, 0.5) * 2
	var spring_vel_x = body.velocity.x
	var spring_vel_y = body.velocity.y
	var body_force_x = Physics.spring(FORCE_STRENGTH, displacement_x, damp, spring_vel_x)
	var body_force_y = Physics.spring(FORCE_STRENGTH, displacement_y, damp, spring_vel_y)
	body.apply_force(get_accurate_velocity() * delta * 0.5)
	body.apply_force(Vector2(body_force_x, body_force_y))
#
	#
	var local_pos = (body.global_position - grind_body_position).limit_length(MAX_BODY_DIST)
	#body.global_position = grind_position
	player.global_position = Math.splerp_vec(player.global_position, grind_body_position + local_pos, delta, 0.05)
	player.squish(get_accurate_velocity())
	#body.velocity.y = min(body.velocity.y, get_accurate_velocity().y) # FIX THIS
	
	var jump_input = player.input_jump_window(false)

	if jump_input:
		update_body_velocity()
		pass
	var extra_data = {"retain_speed": abs(grind_velocity), "no_buffer_kick": true}
	if !check_jump(extra_data):
		if (grind_offset) < 0.0 or grind_offset >= rail.length:
			queue_state_change("Fall", extra_data)
			return
		elif !player.input_secondary_held:
			player.grind_cooldown.start(FALL_GRIND_COOLDOWN)
			player.last_rail = rail
			queue_state_change("Fall", extra_data)
			return
	else:
		player.grind_cooldown.start(JUMP_GRIND_COOLDOWN)
		player.last_rail = rail
		player.play_sound("GrindEnd1")
		player.play_sound("GrindEnd2")


		

#
	#if Debug.enabled:
		##Debug.dbg("rail segment", rail.get_segment(grind_position))
		#Debug.dbg("rail overlap", rail_overlap)
		#Debug.dbg("grind_offset", grind_offset)
		#Debug.dbg("grind_velocity", grind_velocity)
		#Debug.dbg("grind_force", grind_force)
		#Debug.dbg("grind_velocity_1d", grind_velocity_1d)
		#Debug.dbg("accurate_velocity", get_accurate_velocity().round())
		#Debug.dbg("grind_position", grind_position.round())
		#Debug.dbg("grind_body_position", grind_body_position.round())
		#Debug.dbg("grind_normal", normal)
		#Debug.dbg("grind_control_dir", control_dir)
		#Debug.dbg("last_normal_y", last_normal_y)
		
#

	#
	#if speed < MIN_SPEED and elapsed_time > 0.5:
		#player.grind_cooldown.start()
		#player.last_rail = rail
		#queue_state_change("Fall", {"no_buffer_kick": true})
	
	#if normal.y > 0:
		#normal *= -1
	#rail_angle = normal.rotated(TAU/4).angle()
	#
	#player.custom_stand(normal, rail_overlap,  2000, 2, 1.0)
	
	player.foot_1_pos = rail.get_grind_position_from_offset(grind_offset + (15 * player.facing + clamp(grind_velocity * 0.03, -5, 5))) - Vector2(0, 5).rotated(rail_angle)
	player.foot_2_pos = rail.get_grind_position_from_offset(grind_offset - (10 * -player.facing + clamp(grind_velocity * 0.05, -10, 10))) - Vector2(0, 2).rotated(rail_angle)
	player.face_offset = Vector2(-4, 2).rotated(rail_angle)

	
	player.foot_1.rotation = (-TAU/8 if player.facing <= 0 else TAU/8 + PI) + rail_angle
	player.foot_2.rotation = ((TAU/4 + PI) if player.facing <= 0 else -TAU/4) + rail_angle
	#if normal.y > 0:
		#player.foot_1.rotation += PI
		#player.foot_2.rotation += PI
	player.grind_position = grind_position
	
	queue_redraw()

func apply_drag(delta: float, drag) -> void:
	#velocity.x = Math.damp(velocity.x, 0, drag, delta)
	#velocity.y = Math.damp(velocity.y, 0, drag, delta)
	grind_velocity = Math.damp(grind_velocity, 0, drag, delta)
	#grind_velocity.y = Math.damp(grind_velocity.y, 0, drag, delta)

func grind_body_position():
	return grind_position + (GRIND_OFFSET * Vector2(sign(grind_velocity) if grind_velocity != 0 else player.facing, 1)).rotated(rail.get_direction(grind_offset).angle())

func get_accurate_velocity() -> Vector2:
	return grind_velocity * rail.get_direction(grind_offset)

func update_body_velocity():
	body.velocity = get_accurate_velocity()

func grind_spark(pos: Vector2) -> void:
	var num_bodies =  rng.randi_range(0, 3)
	if num_bodies == 0:
		return
	var particle: BouncyBurst = player.spawn_scene_direct(preload("res://object/environment/rail/fx/grind_spark.tscn"))
	particle.global_position = pos
	var normal = rail.get_normal(rail.get_offset(pos))
	var dir = normal.rotated(-TAU/6 * sign(grind_velocity))
	particle.starting_velocity = abs(grind_velocity) * 2.25
	particle.starting_velocity_deviation = abs(grind_velocity) * 0.35
	particle.global_rotation = dir.angle()
	particle.global_position += -normal * 5
	particle.color = Color("fdd14d").lerp(Color("eaf74d"), rng.randf())
	particle.color.a = 0.95
	particle.num_bodies =num_bodies
	particle.reset_physics_interpolation()
	particle.go()


func _exit():
	player.stop_sound("Grind1")
	update_body_velocity()
	queue_redraw()
	player.grinding = false

func _draw() -> void:
	if Debug.draw and active:
		draw_circle(to_local(grind_position), 5.0, Color.YELLOW, false)
		draw_circle(to_local(grind_body_position()), 5.0, Color.BLUE, false)
		draw_circle(to_local(player.foot_1.global_position), 2.0, Color.RED, false)
		draw_circle(to_local(player.foot_2.global_position), 2.0, Color.GREEN, false)
