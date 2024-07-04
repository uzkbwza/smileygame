extends BaseObject2D

class_name SmileyPlayer

const RUN_SPEED = 700
const DUCK_SPEED_MODIFIER = 0.8


const VISUAL_LEG_LENGTH = 21
const MIN_IDLE_LEG_LENGTH = 20
const STAND_FORCE = 3000
const FOOT_SPRITE_VERT_OFFSET = -4
const CAMERA_VERT_OFFSET = -32
const FALLING_DRAG = 0.35
const FEET_DIST = 25


const FOOTSTEP_PARTICLE_MIN_SPEED = 10

const BOOST_TILE_SPEED_MODIFIER = 2.5

const DUCK_FORCE = 600

const GROUNDED_VERT_DRAG = 1.000

@export var tutorial_character := false

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
@onready var boost_tile_detector: RayCast2D = %BoostTileDetector

@onready var ceiling_detector: RayCast2D = %CeilingDetector
@onready var hurtbox: Area2D = %Hurtbox


var is_grounded: bool = false

var is_boosting: bool = false

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
var can_coyote_jump := false
var invulnerable := false

var death_height := 0

var camera_offset := Vector2()

var face_offset := Vector2()

var last_aerial_velocity := Vector2()

var nearby_hazards: Array[Node2D] = []

var foot_1_was_touching_ground := false:
	set(value):
		if value and !foot_1_was_touching_ground:
			play_sound("Footstep1", true)
			play_sound("FootstepBass", true)
			if footstep_particles:
				footstep_effect.call_deferred(foot_1)
		#foot_1.modulate.r = 0 if value else 1
		foot_1_was_touching_ground = value
		
var foot_2_was_touching_ground := false:
	set(value):
		if value and !foot_2_was_touching_ground:
			play_sound("Footstep2", true)
			play_sound("FootstepBass", true)
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	remove_child.call_deferred(camera_target)
	get_parent().add_child.call_deferred(camera_target)
	camera_target.set_deferred("global_position", global_position)

	super._ready()
	reset_idle_feet()
	
	feet_ray.target_position.y = FEET_DIST
	
	hurtbox.body_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.area_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.body_exited.connect(on_hurtbox_hazard_exited)
	hurtbox.area_exited.connect(on_hurtbox_hazard_exited)

func on_hurtbox_hazard_entered(hazard: Node2D):
	nearby_hazards.append(hazard)

func on_hurtbox_hazard_exited(hazard: Node2D):
	nearby_hazards.erase(hazard)
	

func get_floor_angle() -> float:
	## normalized to up
	return feet_ray.get_collision_normal().rotated(TAU/4).angle()

func _physics_process(delta: float) -> void:

	
	if body.is_on_floor():
		body.velocity.y *= 0
	
	if not playing_replay:
		process_input()
	else:
		play_replay()
		
	if recording:
		record_replay()
	
	if !tutorial_character:
		modulate.g = 0.0 if recording else 1.0
		modulate.b = 0.0 if recording else 1.0
		
		modulate.r = 0.0 if playing_replay else 1.0
		modulate.b = 0.0 if playing_replay else 1.0
	
	if is_grounded:
		last_grounded_height = feet_ray.get_collision_point().y
	else:
		last_aerial_velocity = body.velocity
	
	bounce_dir = 0 if !is_grounded or abs(body.velocity.y) <= 60 else sign(body.velocity.y)
	
	update_camera_target(delta)
	
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().reload_current_scene()

	floor_overlap_ratio = 0.0
	if feet_ray.is_colliding():
		var feet_collision_point := feet_ray.get_collision_point()
		var diff := (feet_pos - feet_collision_point).length()
		floor_overlap_ratio = diff / (feet_ray.target_position.y + (3 if ducking else 0))
		var normal = feet_ray.get_collision_normal()

	super._physics_process(delta)

	if Debug.enabled:
		debug_process()

	body.set_collision_mask_value.call_deferred(10, !ducking)
	if ducking:
		if feet_ray.is_colliding():
			body.apply_force(Vector2(0, DUCK_FORCE).rotated(feet_ray.get_collision_normal().angle() + TAU/4))
		else:
			body.apply_force(Vector2(0, DUCK_FORCE))
		if !ceiling_detector.is_colliding():
			ducking = false
	
	if !playing_replay:
		if !invulnerable and nearby_hazards.size() > 0:
			die()
		if y > death_height:
			die()

	queue_redraw()

func get_slope_level() -> float:
	return Vector2.RIGHT.dot(feet_ray.get_collision_normal()) * facing

func die():
	#hide()
	set_physics_process(false)
	body.set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func debug_process():
	#Debug.dbg("ducking", ducking)
	#Debug.dbg("duck_blocking", body.get_collision_mask_value(10))
	Debug.dbg("body_vel", body.velocity.round())
	Debug.dbg("aerial_vel", last_aerial_velocity.round())
	Debug.dbg("input_dir", input_move_dir_vec)
	Debug.dbg("slope", get_slope_level())
	

func update_camera_target(delta: float) -> void:

	var min_x = -INF if input_move_dir <= 0 else camera_offset.x
	var max_x = INF if input_move_dir >= 0 else camera_offset.x
	camera_offset = Math.splerp_vec(camera_offset, Vector2((facing) * 20 + 20 * (body.velocity.x / 200), CAMERA_VERT_OFFSET), delta, 10.0)
	camera_offset.x = clamp(camera_offset.x, min_x, max_x)

	camera_target.global_position.x = global_position.x + camera_offset.x
	if is_grounded or position.y > last_grounded_height:
		if is_grounded:
			camera_target.global_position.y = last_grounded_height + camera_offset.y
		else:
			camera_target.global_position.y = last_grounded_height + camera_offset.y + body.velocity.y * 0.25
			var dist = global_position.y - camera_target.global_position.y + 100
			if dist > (Global.viewport_size.y / 2):
				var diff = dist - (Global.viewport_size.y / 2)
				camera_target.global_position.y += diff
	else:
		camera_target.global_position.y = Math.splerp(camera_target.global_position.y, global_position.y, delta, 5.0)
	#camera_target.global_position = global_position + camera_offset

func footstep_effect(foot: SmileyFoot):
	var speed = body.speed
	if speed < FOOTSTEP_PARTICLE_MIN_SPEED:
		return

	var num_bodies = min(round(rng.randfn(speed / 50, 0.2)), 3)
	if num_bodies <= 0:
		return
	var dir = (Vector2(-2 * facing, -1).rotated(feet_ray.get_collision_normal().angle() + TAU/4)).normalized()
	var particle: BouncyBurst = spawn_scene(preload("res://stupid crap/friends/player/fx/step_particle.tscn"), Vector2(), dir) 
	particle.num_bodies = num_bodies
	particle.global_position = feet_ray.get_collision_point()
	particle.starting_velocity = speed / 2.0
	particle.starting_velocity_deviation = speed / 4.0
	particle.damp = 20
	particle.go()
	var particle_offs := to_local(feet_ray.get_collision_point() + Vector2(-facing * 8, 0).rotated(get_floor_angle()))
	var dust = spawn_scene(preload("res://stupid crap/friends/player/fx/skid_dust.tscn"), particle_offs, dir)
	dust.scale *= 0.25

func get_run_speed() -> float:
	var modifier := 1.0
	if ducking:
		modifier *= (DUCK_SPEED_MODIFIER)
	if is_boosting:
		modifier *= BOOST_TILE_SPEED_MODIFIER
	return RUN_SPEED * modifier

func jump_effect():
	#print(body.velocity.normalized())
	play_sound("Jump")
	spawn_scene(preload("res://stupid crap/friends/player/fx/jump_dust.tscn"), to_local(feet_ray.get_collision_point()) if feet_ray.is_colliding() else Vector2(0, 16), (body.velocity + body.impulses))

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

func duck():
	ducking = true
	
func squish():
	var delta = get_physics_process_delta_time()
	var speed = (body.velocity.y) * 0.0025 + ((-1 + floor_overlap_ratio * 2) if ducking else 0)
	sprite.scale.y = Math.splerp(sprite.scale.y, 1 - 0.5 * speed, delta, 0.2)
	sprite.scale.x = Math.splerp(sprite.scale.x, 1 + 0.5 * speed, delta, 0.2)

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
	
	if Input.is_action_just_pressed("start_recording"):
		recording = !recording
		if recording:
			if replay_record:
				replay_record.clear()
		elif replay_record:
			ResourceSaver.save(replay_record, "res://replay/testreplay.tres")

	if Input.is_action_just_pressed("start_playback"):
		if !recording and !playing_replay:
			replay_playback = replay_record
			start_playback()

func start_playback():
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

func get_vert_drag():
	return body.drag_vert if body.velocity.y < 0 else FALLING_DRAG

func apply_friction(delta: float) -> void:
	body.apply_drag(delta, body.ground_drag if is_grounded else body.air_drag, GROUNDED_VERT_DRAG if is_grounded else get_vert_drag())


const RIDE_HEIGHT = 0.25
const SPRING_AMOUNT = 3000
const SPRING_DAMP = 2.0
const DUCK_SPRING_DAMP = 4.0

func feet_lift_body(stand_force:float=STAND_FORCE,power:float=2) -> void:
	is_grounded = false
	#face_offset.y = 0.0
	if feet_ray.is_colliding():
		face_offset.y = body.velocity.y * 0.025
		var normal := feet_ray.get_collision_normal()
		var displacement =  floor_overlap_ratio - RIDE_HEIGHT
		var force = Physics.spring(SPRING_AMOUNT, displacement, SPRING_DAMP if !ducking else DUCK_SPRING_DAMP, body.velocity.y)

		Debug.dbg("spring force", round(force))
		body.apply_force(force * -normal)
		#body.apply_force(pow(floor_overlap_ratio, power) * stand_force * normal)
		is_grounded = true
		can_coyote_jump = true
		

func reset_idle_feet():
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
#
#func _draw() -> void:
	#draw_circle(to_local(camera_target.global_position), 6, Color.PURPLE)
