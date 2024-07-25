extends SmileyState

class_name SmileyFloorSlideState

const DOWN_DRAG = -0.4
const DRAG = 0.99
const MIN_DRAG = 0.01
const MAX_DRAG = 0.3
const KICKOFF_DIST = 7
const SLOPE_SPEED_BOOST = 200
const BASE_SLOPE_BOOST = 100
const MIN_TIME = 0.4
const MIN_JUMP_TIME = 0.16

const MIN_SPEED = 100

var starting_dir = 0
@onready var wall_detector: RayCast2D = $WallDetector
@onready var foot_1_ray: RayCast2D = $Foot1Ray
@onready var foot_2_ray: RayCast2D = $Foot2Ray

var last_slope = 0
var buffer_jump = false
var floor_angle = 0.0

func _enter():
	floor_angle = player.get_floor_angle()
	last_slope = player.get_slope_level()
	if player.input_move_dir != 0:
		player.set_flip(player.input_move_dir)
	player.play_sound("FloorSlide")
	foot_1_ray.enabled = true
	foot_2_ray.enabled = true
	wall_detector.enabled = true
	#body.apply_impulse(Vector2(0, 200))
	body.move_and_collide(Vector2(0, 10))
	if sign(body.velocity.x) != player.facing:
		body.velocity.x *= 0
	if body.speed < MIN_SPEED:
		body.velocity = body.velocity.normalized() * MIN_SPEED
	player.can_apply_duck_force = false
	#if data and data.get("speed_boost"):
	buffer_jump = false
	body.apply_impulse(player.ground_normal.rotated(TAU/4 * player.facing) * lerpf(BASE_SLOPE_BOOST, SLOPE_SPEED_BOOST, max(player.slope_level, 0)))
	#body.velocity = player.ground_normal.rotated(TAU/4 * player.facing) * body.velocity.length()

func _update(delta):
	
	body.velocity = Math.splerp_vec(body.velocity, player.ground_normal.rotated(TAU/4 * player.facing) * body.velocity.length(), delta, 2.25)
	
	var jump = player.input_jump_window(false)
	
	if !player.input_primary_held and elapsed_time > MIN_TIME:
		return "Run"

	player.duck()
	player.squish()
	player.feet_lift_body(1000, 2, 10)
	#player.is_grounded = player.feet_ray.is_colliding()

	var extra_data = {"retain_speed": abs(body.velocity.x)}
	#var extra_data = {"retain_speed": abs(body.velocity.x), "no_buffer_kick": true}
	if jump:
		buffer_jump = true

	var jumped = false
	
	var jump_tricked = buffer_jump and player.process_jumpable_objects(true)
	
	
	if !(buffer_jump and elapsed_time > MIN_JUMP_TIME and jump and (jump_tricked or check_jump(extra_data, true))):
		if buffer_jump and elapsed_time > MIN_JUMP_TIME :
			if !player.is_grounded:
				if body.velocity.y > 0:
					body.velocity.y = 0
			check_jump(extra_data, true)
			jumped = true
		else:
			if check_fall(extra_data, false):
				body.velocity = body.velocity.length() * Vector2(player.facing, 0).rotated(floor_angle)
				return
	else:
		jumped = true

	if !jumped and buffer_jump and player.input_primary_held and player.get_slope_level() > last_slope and !jump_tricked:
			if body.velocity.y > 0:
				body.velocity.y = 0
			#if !player.process_jumpable_objects(true):
			check_jump(extra_data, true)
			jumped = true
			#check_jump(extra_data, true)
			return

	last_slope = player.get_slope_level()


	var drag = lerpf(DOWN_DRAG, DRAG, remap(-(player.slope_level), -1.0, 1.0, 0.0, 1.0))
	drag = clamp(drag, MIN_DRAG, MAX_DRAG)
	Debug.dbg("floor_slide_drag", drag)
	body.apply_drag(delta, drag, drag)
	if rng.chance_delta(20.0, delta):
		player.play_sound("FloorSlide2", false)
	#if rng.chance_delta(20.0, delta):
	
	#player.play_sound("FloorSlide3", false)
	
	var sustained_sound: AudioStreamPlayer2D = player.get_sound("FloorSlide3")
	if !sustained_sound.is_playing():
		sustained_sound.play()
	sustained_sound.volume_db = min(-20 - (20 - body.speed * 0.05), -20)

	player.foot_1.rotation = ((TAU/5 * 2 + PI) if player.facing <= 0 else -TAU/5 * 2)
	player.foot_2.rotation = -TAU/4 * 2 if player.facing == 1 else (TAU/4 * 2 + PI)
	
	floor_angle = player.get_floor_angle()
	
	var foot_1_pos = Vector2(7* player.facing, 5).rotated(floor_angle) + player.global_position
	var foot_2_pos = Vector2(17 * player.facing, 0).rotated(floor_angle) + player.global_position
	
	player.foot_1.z_index = 1
	player.foot_2.z_index = -1
	
	foot_1_ray.target_position = to_local(foot_1_pos)
	#player.foot_1.flip_h = true
	foot_2_ray.target_position = to_local(foot_2_pos)
	player.foot_1_pos = foot_1_pos if !foot_1_ray.is_colliding() else foot_1_ray.get_collision_point()
	player.foot_2_pos = foot_2_pos if !foot_2_ray.is_colliding() else foot_2_ray.get_collision_point()
	
	player.face_offset = Vector2(-10, 0).rotated(floor_angle * player.facing)
	
	wall_detector.target_position = KICKOFF_DIST * player.ground_normal.rotated(TAU/4) * Vector2(player.facing, 1)
	player.update_ground_normal()
	
	body.apply_force(player.ground_normal * -200)

	
	wall_detector.force_raycast_update()
	if wall_detector.is_colliding() and wall_detector.get_collision_normal().y > player.MAX_GROUNDED_Y_NORMAL:
		#var normal = wall_detector.get_collision_normal()
		#var speed = body.velocity.length()
		#body.velocity *= 0
		#body.move_and_collide(normal.rotated(TAU/4 * player.facing) * 5)
		#if speed < 200:
			#body.apply_impulse(normal.rotated(TAU/4 * player.facing) * 200)
		#else:
			#body.apply_impulse(speed * normal.rotated(TAU/4 * player.facing))

		#print(body.velocity)
		#queue_state_change("Fall")
		check_jump({}, true)
	#elif player.input_secondary_pressed:
		#queue_state_change("KickOff", { "kick_dir": , "kick_strength": 1.0 } )
		#if check_grounded_kick({"retain_speed": abs(body.velocity.x)}):
			#pass
	else:
		if body.speed < MIN_SPEED and elapsed_time > MIN_TIME:
			return "Run"

	var particle_offs := player.to_local(player.feet_ray.get_collision_point() + Vector2(player.facing * player.rng.randf_range(15, -5), 0).rotated(player.get_floor_angle()))
	var particle1 = player.spawn_scene(preload("res://object/player/fx/skid_dust.tscn"), particle_offs, player.ground_normal.rotated(TAU/4 * player.facing))
	var particle2 = player.spawn_scene(preload("res://object/player/fx/skid_dust.tscn"), particle_offs, -player.ground_normal.rotated(TAU/4 * player.facing))
	particle1.scale *= body.speed * 0.001
	particle2.scale *= body.speed * 0.001
	particle1.z_index -= 5
	particle2.z_index -= 5
	


func _exit():
	player.stop_sound("FloorSlide3")
	foot_1_ray.enabled = false
	foot_2_ray.enabled = false
	wall_detector.enabled = false
	player.can_apply_duck_force = true
