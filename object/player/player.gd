extends BaseObject2D

class_name SmileyPlayer

signal coin_collected

const RUN_SPEED  = 800
const DUCK_SPEED_MODIFIER = 0.8

const VISUAL_LEG_LENGTH = 21
const MIN_IDLE_LEG_LENGTH = 20
const STAND_FORCE = 3000
const FOOT_SPRITE_VERT_OFFSET = -4
const CAMERA_VERT_OFFSET = -32
const FALLING_DRAG = 0.35
const FEET_DIST = 25
const WALL_RETAIN_MOMENTUM_LENIENCY = 0.2

const MAX_GROUNDED_Y_NORMAL = -0.25

const JUMP_WINDOW = 3
const KICK_WINDOW = 5

const FOOTSTEP_PARTICLE_MIN_SPEED = 10

const DUCK_FORCE = 900

const GROUNDED_VERT_DRAG = 1.000

@export var tutorial_character := false
@export var disable_feet := false

@onready var feet_ray: RayCast2D = %FeetPos

var feet_pos: Vector2:
	get:
		return Physics.get_raycast_end_point(feet_ray)
		

@onready var foot_1: Sprite2D = %Foot1
@onready var foot_2: Sprite2D = %Foot2
@onready var camera_target: Marker2D = %CameraTarget

var foot_1_pos: Vector2 = Vector2()
var foot_2_pos: Vector2 = Vector2()

@onready var foot_1_rest: RayCast2D = %Foot1Rest
@onready var foot_2_rest: RayCast2D = %Foot2Rest

@onready var foot_1_rest_idle_angle: float = foot_1_rest.global_rotation
@onready var foot_2_rest_idle_angle: float = foot_2_rest.global_rotation
#@onready var boost_tile_detector: RayCast2D = %BoostTileDetector

@onready var ceiling_detector: RayCast2D = %CeilingDetector
@onready var hurtbox: Area2D = %Hurtbox
@onready var camera_target_raycast: RayCast2D = $CameraTargetRaycast
@onready var wall_detector_1: RayCast2D = %WallDetector1
@onready var wall_detector_2: RayCast2D = %WallDetector2
@onready var wall_retain_momentum_timer: Timer = $WallRetainMomentumTimer
@onready var grind_cooldown: Timer = $GrindCooldown
@onready var object_detector: Area2D = %ObjectDetector

var debug_lines: Array[Line2D] = []

var is_grounded: bool = false:
	get:
		return is_grounded and !slope_too_steep()

var last_rail: RailPost

var wall_sliding: bool = false
var wall_can_retain_momentum := true

var footstep_particles := false
var bounce_dir: int = -1:
	set(value):
		if bounce_dir != value:
			if value > 0:
				
				#play_sound("BounceDown", false, 1.0, min(-25 + abs(body.velocity.y * 0.05), -15))
				pass
			elif value < 0:
				#play_sound("BounceUp", false, 1.0, min(-30 + abs(body.velocity.y * 0.02), -15))
				pass
			bounce_dir = value
				

var last_grounded_height: float = 0.0

var input_move_dir: int = 0
var input_move_dir_vec: Vector2i = Vector2i()
var input_move_dir_vec_normalized: Vector2 = Vector2()
var input_move_dir_vec_just_pressed: Vector2i = Vector2i()
var input_move_dir_vec_just_pressed_normalized: Vector2 = Vector2()
var input_duck: bool = false
var input_jump: bool = false
var input_jump_held: bool = false
var input_kick: bool = false
var input_kick_held: bool = false
var input_up_held: bool:
	get:
		return input_move_dir_vec.y < 0
var input_down_held: bool:
	get:
		return input_move_dir_vec.y > 0

var input_left_held: bool:
	get:
		return input_move_dir_vec.x < 0
var input_right_held: bool:
	get:
		return input_move_dir_vec.x > 0
	
var input_up_pressed:
	get:
		return input_move_dir_vec_just_pressed.y < 0
var input_down_pressed:
	get:
		return input_move_dir_vec_just_pressed.y > 0
var input_left_pressed:
	get:
		return input_move_dir_vec_just_pressed.x < 0
var input_right_pressed:
	get:
		return input_move_dir_vec_just_pressed.x > 0

var input_up_hold_time = 0
var input_down_hold_time = 0
var input_left_hold_time = 0
var input_right_hold_time = 0
var input_jump_hold_time = 0
var input_kick_hold_time = 0

var can_coyote_jump := false
var invulnerable := false
var can_apply_duck_force := true

var start_position: Vector2

var death_height := 0

var camera_offset := Vector2()
var ground_normal := Vector2.UP

var face_offset := Vector2()

var last_aerial_velocity := Vector2()

var nearby_hazards: Array[Node2D] = []

var last_position: Vector2 = Vector2()

var foot_1_was_touching_ground := false:
	set(value):
		if  !disable_feet and  value and !foot_1_was_touching_ground:
			play_sound("Footstep1", false)
			play_sound("FootstepBass", false)
			if footstep_particles:
				footstep_effect.call_deferred(foot_1)
		#foot_1.modulate.r = 0 if value else 1
		foot_1_was_touching_ground = value
		
var foot_2_was_touching_ground := false:
	set(value):
		if !disable_feet and value and !foot_2_was_touching_ground:
			play_sound("Footstep2", false)
			play_sound("FootstepBass", false)
			if footstep_particles:
				footstep_effect.call_deferred(foot_2)

		#foot_2.modulate.b = 0 if value else 1
		foot_2_was_touching_ground = value
		
var ducking = false

var facing := 1
var floor_overlap_ratio := 0.0

var replay_playback: GameplayRecording = null
var replay_record: GameplayRecording = null

var recording := false
var playing_replay := false

var feet_touching_terrain = null
var body_touching_terrain = []
var body_touching_terrain_new = []

var touching_wall := false
var touching_wall_dir := 0

var slope_level = 0.0

var grinding = false 
var grind_position = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:


	if disable_feet:
		foot_1.hide()
		foot_2.hide()
		
	remove_child.call_deferred(camera_target)
	get_parent().add_child.call_deferred(camera_target)

	#if Debug.enabled:
		#debug_line = Line2D.new()
		#debug_line.width = 1.0
		#debug_line.
		#get_parent().add_child.call_deferred(debug_line)

	camera_target.set_deferred("global_position", global_position)

	super._ready()
	reset_idle_feet()
	
	feet_ray.target_position.y = FEET_DIST
	object_detector.area_entered.connect(on_object_entered)
	object_detector.area_exited.connect(on_object_exited)
	object_detector.body_entered.connect(on_object_entered)
	object_detector.body_exited.connect(on_object_exited)
	
	hurtbox.body_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.area_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.body_exited.connect(on_hurtbox_hazard_exited)
	hurtbox.area_exited.connect(on_hurtbox_hazard_exited)
	
	start_position = global_position

func on_object_entered(object: Node2D):
	if object.has_method("on_player_touched"):
		object.on_player_touched(self)
	#elif object is ...

func on_object_exited(object: Node2D):
	pass

func on_hurtbox_hazard_entered(hazard: Node2D) -> void:
	nearby_hazards.append(hazard)

func on_hurtbox_hazard_exited(hazard: Node2D) -> void:
	nearby_hazards.erase(hazard)

func touch_terrain_with_feet(object: Node2D) -> void:
	if object and object != feet_touching_terrain:
		collide_with_terrain(object)
	feet_touching_terrain = object

#func follow_body(xy: Vector2) -> void:
	#super.follow_body(xy)
	#feet_ray.force_raycast_update()

func collide_with_terrain(object: Node2D):
	if object is DisappearingBlock:
		object.start()

func get_floor_angle() -> float:
	## normalized to up
	return ground_normal.rotated(TAU/4).angle()

func on_grabbed_coin() -> void:
	play_sound("Coin")
	play_sound("Coin2")
	play_sound("Coin3")
	play_sound("Coin4")
	coin_collected.emit()


func _physics_process(delta: float) -> void:
	delta = 0.01666666666667

	last_position = global_position

	if body.is_on_floor():
		body.velocity.y *= 0
	
	if not playing_replay:
		process_input()
	else:
		play_replay()
	process_input_held_times()
	
	if recording:
		record_replay()
	
	if !tutorial_character:
		modulate.g = 0.0 if recording else 1.0
		modulate.b = 0.0 if recording else 1.0
		
		modulate.r = 0.0 if playing_replay else 1.0
		modulate.b = 0.0 if playing_replay else 1.0
	
	#var shape_dist = body.speed * 0.05
	if is_grounded:
		last_grounded_height = feet_ray.get_collision_point().y
		#body.shape.position = Math.splerp_vec(body.shape.position, feet_ray.get_collision_normal() * shape_dist, delta, 5.0)
	else:
		#body.shape.position = Math.splerp_vec(body.shape.position, Vector2(0, -shape_dist), delta, 2.0)
		last_aerial_velocity = body.velocity
	
	bounce_dir = 0 if !is_grounded or abs(body.velocity.y) <= 60 else sign(body.velocity.y)

	if !wall_retain_momentum_timer.is_stopped() and wall_can_retain_momentum and body.velocity.y < 0:
		if touching_wall and body.prev_velocity.y < 0 and body.prev_speed >= body.speed:
			body.velocity = Vector2(0, sign(body.velocity.y)) * body.prev_speed
			wall_can_retain_momentum = false
	else:
		wall_can_retain_momentum = false
		
	update_camera_target(delta)
	
	if Input.is_action_just_pressed("debug_restart"):
		#get_tree().reload_current_scene()
		die()

	floor_overlap_ratio = 0.0
	if feet_ray.is_colliding():
		var feet_collision_point := feet_ray.get_collision_point()
		var diff := (feet_pos - feet_collision_point).length()
		floor_overlap_ratio = diff / (feet_ray.target_position.y + (3 if ducking else 0))
		var normal = ground_normal

	touching_wall = wall_detector_1.is_colliding() or wall_detector_2.is_colliding()
	touching_wall_dir = Utils.bools_to_axis(wall_detector_2.is_colliding(), wall_detector_1.is_colliding())

	#feet_ray.force_raycast_update()
	update_ground_normal()
	super._physics_process(delta)
	update_ground_normal()
	#feet_ray.force_raycast_update()
	
	if Debug.enabled:
		debug_process()

	body.set_collision_mask_value.call_deferred(10, !ducking)
	if ducking:
		if can_apply_duck_force:
			if feet_ray.is_colliding():
				body.apply_force(Vector2(0, DUCK_FORCE).rotated(ground_normal.angle() + TAU/4))
			else:
				body.apply_force(Vector2(0, DUCK_FORCE))

		if !ceiling_detector.is_colliding():
			ducking = false


	
	if !playing_replay:
		if !invulnerable and nearby_hazards.size() > 0:
			die()
		if y > death_height:
			die()

	var collision_count = body.get_slide_collision_count()
	body_touching_terrain_new.clear()
	if collision_count > 0:
		for i in collision_count:
			var object = body.get_slide_collision(i).get_collider()
			if object and not (object in body_touching_terrain_new):
				if not (object in body_touching_terrain):
					collide_with_terrain(object)
				body_touching_terrain_new.append(object)
	body_touching_terrain.clear()
	for body in body_touching_terrain_new:
		body_touching_terrain.append(body)


func update_ground_normal():
	feet_ray.force_raycast_update()
	#ground_normal = (feet_ray.get_collision_normal())
	ground_normal = (feet_ray.get_collision_normal() if feet_ray.get_collider() else ground_normal)

func start_wall_momentum_timer():
	wall_can_retain_momentum = true
	wall_retain_momentum_timer.start(WALL_RETAIN_MOMENTUM_LENIENCY)

func get_slope_level() -> float:
	if !feet_ray.is_colliding():
		return 0.0
	#if floor_ov
	slope_level = Vector2.RIGHT.dot(ground_normal) * facing
	return slope_level

func die():
	#hide()
	nearby_hazards.clear()
	set_physics_process(false)
	body.set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	#get_tree().reload_current_scene()
	global_position = start_position
	set_physics_process(true)
	body.set_physics_process(true)
	body.reset_momentum()
	change_state("Idle")

func debug_process() -> void:
	#Debug.dbg("ducking", ducking)
	#Debug.dbg("duck_blocking", body.get_collision_mask_value(10))
	Debug.dbg("body_vel", body.velocity.round())
	Debug.dbg("facing", facing)
	Debug.dbg("body_accel", body.accel.round())
	Debug.dbg("body_impulses", body.impulses.round())
	Debug.dbg("aerial_vel", last_aerial_velocity.round())
	Debug.dbg("input_dir", input_move_dir_vec)
	Debug.dbg("floor_overlap", floor_overlap_ratio)
	Debug.dbg("slope", get_slope_level())
	Debug.dbg("floor_normal", ground_normal)
	Debug.dbg("touching_wall_dir", touching_wall_dir)
	Debug.dbg("feet_collider", feet_ray.get_collider().name if feet_ray.is_colliding() and feet_ray.get_collider() else "null" if feet_ray.is_colliding() else "not colliding")
	#Debug.dbg("feet_rotation", feet_ray.global_rotation)
	

func update_camera_target(delta: float) -> void:

	var min_x = -INF if input_move_dir <= 0 else camera_offset.x
	var max_x = INF if input_move_dir >= 0 else camera_offset.x
	camera_offset = Math.splerp_vec(camera_offset, Vector2((facing) * 20 + 20 * (body.velocity.x / 200), CAMERA_VERT_OFFSET), delta, 10.0)
	camera_offset.x = clamp(camera_offset.x, min_x, max_x)

	camera_target.global_position.x = global_position.x + camera_offset.x
	if wall_sliding:
		camera_target.global_position.y = y + camera_offset.y
	elif grinding:
		camera_target.global_position = Math.splerp_vec(camera_target.global_position, grind_position + camera_offset * 0.5, delta, 2.0)
	elif is_grounded or position.y >= last_grounded_height:
		if is_grounded:
			camera_target.global_position.y = last_grounded_height + camera_offset.y
		else:
			camera_target.global_position.y = last_grounded_height + camera_offset.y + body.velocity.y * 0.25
			var dist = global_position.y - camera_target.global_position.y + (200)
			if dist > (Global.viewport_size.y / 2):
				var diff = dist - (Global.viewport_size.y / 2)
				camera_target.global_position.y += diff
	else:
		camera_target.global_position.y = Math.splerp(camera_target.global_position.y, global_position.y, delta, 2.0)
	#camera_target.global_position = global_position + camera_offset
	camera_target_raycast.target_position = to_local(camera_target.global_position)
	if camera_target_raycast.is_colliding():
		camera_target.global_position = camera_target_raycast.get_collision_point()

func footstep_effect(foot: SmileyFoot) -> void:
	var speed = body.speed
	if speed < FOOTSTEP_PARTICLE_MIN_SPEED:
		return

	var num_bodies = min(round(rng.randfn(speed / 50, 0.2)), 3)
	if num_bodies <= 0:
		return
	var dir = (Vector2(-2 * facing, -1).rotated(ground_normal.angle() + TAU/4)).normalized()
	var particle: BouncyBurst = spawn_scene(preload("res://object/player/fx/step_particle.tscn"), Vector2(), dir) 
	particle.num_bodies = num_bodies
	particle.global_position = feet_ray.get_collision_point()
	particle.starting_velocity = speed / 2.0
	particle.starting_velocity_deviation = speed / 4.0
	particle.damp = 20
	particle.go.call_deferred()
	var particle_offs := to_local(feet_ray.get_collision_point() + Vector2(-facing * 8, 0).rotated(get_floor_angle()))
	var dust = spawn_scene(preload("res://object/player/fx/skid_dust.tscn"), particle_offs, dir)
	dust.scale *= 0.25

func get_run_speed() -> float:
	var modifier := 1.0
	if ducking:
		modifier *= (DUCK_SPEED_MODIFIER)
	#if is_boosting:
		#modifier *= BOOST_TILE_SPEED_MODIFIER
	return RUN_SPEED * modifier

func jump_effect() -> void:
	#print(body.velocity.normalized())
	play_sound("Jump")
	spawn_scene(preload("res://object/player/fx/jump_dust.tscn"), to_local(feet_ray.get_collision_point()) if feet_ray.is_colliding() else Vector2(0, 16), (body.velocity + body.impulses))

func update_feet_position(t:float = 1) -> void:
	foot_1.global_position = foot_1.global_position.lerp(foot_1_pos + Vector2(0, FOOT_SPRITE_VERT_OFFSET).rotated(foot_1.rotation + TAU/4), t)
	foot_2.global_position = foot_2.global_position.lerp(foot_2_pos + Vector2(0, FOOT_SPRITE_VERT_OFFSET).rotated(foot_2.rotation + TAU/4), t)

func update_face_position(t:float = 1) -> void:
	sprite.offset = sprite.offset.lerp(face_offset * Vector2(facing, 1), 0.25)

func stick_to_ground() -> void:
	#body.move_directly(Vector2(0, -floor_overlap_ratio * FEET_DIST * 10))
	#if ground_detector.is_colliding() and !feet_ray.is_colliding():
		#body.move_directly(Vector2(0, ground_detector.get_collision_point().y - feet_pos.y))
	pass

func duck() -> void:
	ducking = true
	
func squish(vel=null) -> void:
	if vel == null:
		vel = body.velocity
	var delta = get_physics_process_delta_time()
	var speed = (vel.y) * 0.0025 + ((-1 + floor_overlap_ratio * 2) if ducking else 0)
	sprite.scale.y = clamp(Math.splerp(sprite.scale.y, 1 - 0.5 * speed, delta, 0.2), 0.5, 2.0)
	sprite.scale.x = clamp(Math.splerp(sprite.scale.x, 1 + 0.5 * speed, delta, 0.2), 0.5, 2.0)

func _process(delta: float) -> void:
	if Debug.enabled:
		if debug_lines:
			var line = debug_lines[-1]
			line.add_point(line.to_local(global_position))
			if Debug.draw != line.visible:
				for l in debug_lines:
					l.visible = Debug.draw
			if line.points.size() > 10000:
				line.points = line.points.slice(1)

	queue_redraw()

func process_input() -> void:
	input_move_dir_vec = Utils.bools_to_vector2i(Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right"),Input.is_action_pressed("move_up"), Input.is_action_pressed("move_down"))
	input_move_dir = input_move_dir_vec.x
	input_move_dir_vec_normalized = Vector2(input_move_dir_vec).normalized()
	input_move_dir_vec_just_pressed = Utils.bools_to_vector2i(Input.is_action_just_pressed("move_left"), Input.is_action_just_pressed("move_right"),Input.is_action_just_pressed("move_up"), Input.is_action_just_pressed("move_down"))
	input_move_dir_vec_just_pressed_normalized = Vector2(input_move_dir_vec_just_pressed).normalized()
	input_jump = Input.is_action_just_pressed("jump")
	input_jump_held = Input.is_action_pressed("jump")
	input_kick = Input.is_action_just_pressed("kick")
	input_kick_held = Input.is_action_pressed("kick")
	input_duck = Input.is_action_pressed("move_down")
	#
	#if Input.is_action_just_pressed("start_recording"):
		#recording = !recording
		#if recording:
			#if replay_record:
				#replay_record.clear()
		#elif replay_record:
			#ResourceSaver.save(replay_record, "res://replay/testreplay.tres")
#
	#if Input.is_action_just_pressed("start_playback"):
		#if !recording and !playing_replay:
			#replay_playback = replay_record
			#start_playback()

func process_input_held_times():

	if input_jump_held:
		input_jump_hold_time += 1
	else:
		input_jump_hold_time = 0
		
	if input_kick_held:
		input_kick_hold_time += 1
	else:
		input_kick_hold_time = 0
		
	if input_up_held:
		input_up_hold_time += 1
	else:
		input_up_hold_time = 0
		
	if input_down_held:
		input_down_hold_time += 1
	else:
		input_down_hold_time = 0
		
	if input_left_held:
		input_left_hold_time += 1
	else:
		input_left_hold_time = 0
		
	if input_right_held:
		input_right_hold_time += 1
	else:
		input_right_hold_time = 0


func frame_window(held_time: int, window: int):
	return held_time > 0 and held_time <= window

func input_jump_window():
	return frame_window(input_jump_hold_time, JUMP_WINDOW)

func input_kick_window():
	return frame_window(input_kick_hold_time, KICK_WINDOW)


func start_playback() -> void:
	playing_replay = true
	if replay_playback:
		replay_playback.restart()
	else:
		replay_playback = ResourceLoader.load("res://replay/testreplay.tres")
	body.reset_momentum.call_deferred()
	feet_idle.call_deferred()
	global_position = replay_playback.positions[0]
	foot_1.reset_physics_interpolation.call_deferred()
	foot_2.reset_physics_interpolation.call_deferred()
	reset_physics_interpolation.call_deferred()
	reset_idle_feet.call_deferred()
	update_feet_position.call_deferred(1.0)
	foot_1_pos = global_position
	foot_2_pos = global_position

func play_replay() -> void:
	if replay_playback.current_tick == -1:
		body.velocity *= 0
	var tick_data = replay_playback.advance()
	if tick_data == null:
		playing_replay = false
		if tutorial_character:
			start_playback()
		return
	if tick_data.has("position"):
		global_position = tick_data.position
	if tick_data.has("velocity"):
		body.velocity = tick_data.velocity
	if tick_data.has("input"):
		bitflags_to_input(tick_data.input)
	reset_physics_interpolation()

func record_replay() -> void:
	if replay_record == null:
		replay_record = GameplayRecording.new()
	replay_record.record(self)

const FLAG_LEFT = 0b000001
const FLAG_RIGHT = 0b000010
const FLAG_UP = 0b000100
const FLAG_DOWN = 0b001000
const FLAG_A = 0b010000
const FLAG_B = 0b100000

func input_to_bitflags() -> int:
	var input = 0
	input |= FLAG_LEFT  if input_move_dir_vec.x < 0 else 0
	input |= FLAG_RIGHT if input_move_dir_vec.x > 0 else 0
	input |= FLAG_UP    if input_move_dir_vec.y < 0 else 0
	input |= FLAG_DOWN  if input_move_dir_vec.y > 0 else 0
	input |= FLAG_A     if input_jump_held else 0
	input |= FLAG_B     if input_kick_held else 0
	return input

func bitflags_to_input(input: int) -> void:
	var l = input & FLAG_LEFT != 0
	var r = input & FLAG_RIGHT != 0
	var u = input & FLAG_UP != 0
	var d = input & FLAG_DOWN != 0
	var a = input & FLAG_A != 0
	var b = input & FLAG_B != 0
	input_move_dir_vec_just_pressed.x -= 1 if l and input_move_dir_vec.x != -1 else 0
	input_move_dir_vec_just_pressed.x += 1 if r and input_move_dir_vec.x != 1 else 0
	input_move_dir_vec_just_pressed.y -= 1 if u and input_move_dir_vec.y != -1 else 0
	input_move_dir_vec_just_pressed.y += 1 if d and input_move_dir_vec.y != 1 else 0
	input_move_dir_vec = Utils.bools_to_vector2i(l, r, u, d)
	input_move_dir = input_move_dir_vec.x
	input_move_dir_vec_normalized = Vector2(input_move_dir_vec).normalized()
	input_move_dir_vec_just_pressed_normalized = Vector2(input_move_dir_vec_just_pressed).normalized()
	input_jump = a and !input_jump_held
	input_jump_held = a
	input_kick = b and !input_kick_held
	input_kick_held = b
	input_duck = input_move_dir_vec.y == 1

func set_flip(dir: int) -> void:
	dir = signi(dir)
	if dir == 0:
		dir = 1
	foot_1.flip_v = dir == -1
	foot_2.flip_v = foot_1.flip_v
	facing = dir

func get_vert_drag() -> float:
	return body.drag_vert if body.velocity.y < 0 else FALLING_DRAG

func apply_friction(delta: float) -> void:
	body.apply_drag(delta, body.ground_drag if is_grounded else body.air_drag, GROUNDED_VERT_DRAG if is_grounded else get_vert_drag())

const RIDE_HEIGHT = 0.25
const SPRING_AMOUNT = 3000
const SPRING_DAMP = 0.2
const DUCK_SPRING_DAMP = 4.0

func feet_lift_body(stand_force:float=SPRING_AMOUNT, power:float=2, damp:float=SPRING_DAMP, ride_height:float=RIDE_HEIGHT) -> void:
	is_grounded = false
	#face_offset.y = 0.0
	if feet_ray.is_colliding() and !slope_too_steep():
		face_offset.y = body.velocity.y * 0.025
		var normal := ground_normal

		#var normal := Vector2.UP
		var displacement =  floor_overlap_ratio - RIDE_HEIGHT
		var force = Physics.spring(stand_force, displacement, damp if !ducking else DUCK_SPRING_DAMP, body.velocity.y)

		Debug.dbg("spring force", force)
		body.apply_force(force * -normal)
		#body.apply_force(pow(floor_overlap_ratio, power) * stand_force * normal)
		is_grounded = true
		can_coyote_jump = true
		touch_terrain_with_feet(feet_ray.get_collider())

func slope_too_steep():
	if ground_normal.y > MAX_GROUNDED_Y_NORMAL:
		return true
	return false

func custom_stand(normal: Vector2,floor_overlap_ratio: float, stand_force:float=SPRING_AMOUNT, power:float=2, damp:float=SPRING_DAMP, ride_height:float=RIDE_HEIGHT) -> void:
	#var normal := Vector2.UP
	var displacement = floor_overlap_ratio - ride_height
	var force = Physics.spring(stand_force, displacement, damp, body.velocity.y)

	Debug.dbg("spring force", force)
	body.apply_force(force * -normal)

func reset_idle_feet() -> void:
	foot_1_pos = feet_pos
	foot_2_pos = feet_pos
	foot_1_rest.global_rotation = foot_1_rest_idle_angle
	foot_2_rest.global_rotation = foot_2_rest_idle_angle

func feet_idle() -> void:
	#foot_1_rest.global_rotation = foot_1_rest_idle_angle
	#foot_2_rest.global_rotation = foot_2_rest_idle_angle
	#var foot_1_dist = foot_1_pos.distance_to(global_position)
	#var foot_2_dist = foot_2_pos.distance_to(global_position)
	
	#if facing == 1:
		#if foot_1_dist > VISUAL_LEG_LENGTH:
	foot_1_was_touching_ground = foot_1_rest.is_colliding()
	foot_1_pos = foot_idle(foot_1, foot_1_rest) - Vector2(-2, 0).rotated(foot_1.rotation - TAU/4)
		#foot_2_pos = foot_2_rest.get_collision_point() + Vector2(10, 0)
	#else:
		#foot_1_pos = Vector2(foot_1_pos.x, foot_idle(foot_1, foot_1_rest).y)
	
	#if facing == -1: 
		#if foot_2_dist > VISUAL_LEG_LENGTH:
	foot_2_was_touching_ground = foot_2_rest.is_colliding()
	foot_2_pos = foot_idle(foot_2, foot_2_rest) + Vector2(-2, 0).rotated(foot_2.rotation - TAU/4)
		#foot_1_pos = foot_1_rest.get_collision_point() - Vector2(10, 0)
	#else:
		#foot_2_pos = Vector2(foot_2_pos.x, foot_idle(foot_2, foot_2_rest).y)

func foot_idle(foot: Node2D, foot_rest: RayCast2D) -> Vector2:
	var foot_pos: Vector2
	var foot_normal: Vector2
	if foot_rest.is_colliding():
		foot_pos = foot_rest.get_collision_point()
		foot_normal = foot_rest.get_collision_normal()
	else:
		var end = foot_rest.target_position.rotated(feet_ray.global_rotation).normalized()
		foot_pos = foot_rest.global_position + end * VISUAL_LEG_LENGTH
		foot_normal = -end
	foot.global_rotation = foot_normal.angle()
	return foot_pos

func _draw():
	if Debug.draw:
		#print((global_position - last_position))
		var normal_color = Color.CYAN
		var normal_color2 = Color.GREEN
		if !feet_ray.is_colliding():
			normal_color.a *= 0.5
			normal_color2.a *= 0.5

		draw_line(Vector2(), feet_ray.get_collision_normal() * 32, normal_color)
		draw_line(Vector2(), ground_normal * 32, normal_color2)
		draw_line(Vector2(), body.velocity * 0.1, Color.ORANGE)
		draw_line(Vector2(), feet_ray.target_position, Color.WHITE if !feet_ray.is_colliding() else Color.RED)
		#draw_line(Vector2()Vector2(), feet_ray.target_position, Color.WHITE if !feet_ray.is_colliding() else Color.RED)
		if feet_ray.is_colliding():
			draw_circle(to_local(feet_ray.get_collision_point()), 3.0, Color.RED, false)
		#draw_circle(body.velocity * Vector2(1, 0) * 0.1, 2.0, Color.GREEN)
		var dpad_pos = Vector2(-32, -16)
		var buttons_pos = Vector2(32, -16)
		var w = 6
		var h = 4
		var dist = 3
	
		var hold_time_ratio = func(hold_time, time:float=5.0,power:float=2.0):
			if hold_time == 0:
				return 1.0
			return (min(hold_time, time) / time) ** (1.0 / power)
		var get_color = func(hold_time):
			if hold_time > 0:
				return Color.YELLOW.lerp(Color.RED, hold_time_ratio.call(hold_time, 5, 1))
			return Color.WHITE

		draw_circle(dpad_pos, 1, Color.WHITE)
		draw_rect(Rect2(dpad_pos + Vector2(-h/2, -w - dist), Vector2(h, w)), get_color.call(input_up_hold_time))
		draw_rect(Rect2(dpad_pos + Vector2(-h/2, dist), Vector2(h, w)), get_color.call(input_down_hold_time))
		draw_rect(Rect2(dpad_pos + Vector2(-w - dist, -h/2), Vector2(w, h)), get_color.call(input_left_hold_time))
		draw_rect(Rect2(dpad_pos + Vector2(dist, -h/2), Vector2(w, h)), get_color.call(input_right_hold_time))
		draw_circle(buttons_pos + Vector2(-10, 0), lerp(10, 5, hold_time_ratio.call(input_jump_hold_time)), get_color.call(input_jump_hold_time))
		draw_circle(buttons_pos + Vector2(10, 0), lerp(10, 5, hold_time_ratio.call(input_kick_hold_time)), get_color.call(input_kick_hold_time))
