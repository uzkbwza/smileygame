extends BaseObject2D

class_name SmileyPlayer

signal jumped_off_ground
signal jumped_off_wall(direction: Vector2)
signal jumped_off_something(direction: Vector2)

signal landed
signal coin_collected
signal death_animation_started
signal death_animation_finished

const RUN_SPEED  = 900
const DUCK_SPEED_MODIFIER = 0.8
const SPLAT_SPEED = 1000
const POSITION_HISTORY_LENGTH = 60

const VISUAL_LEG_LENGTH = 21
const MIN_IDLE_LEG_LENGTH = 20
const STAND_FORCE = 3000
const FOOT_SPRITE_VERT_OFFSET = -4
const CAMERA_VERT_OFFSET = -32
const FALLING_DRAG = 0.35
const FEET_DIST = 25
const WALL_RETAIN_MOMENTUM_LENIENCY = 0.2

const RESPAWN_POSITION_FRAMES = 10

const MAX_GROUNDED_Y_NORMAL = -0.25

const INPUT_PRESS_BOUND = -999999999
const JUMP_WINDOW = 3
const TRICK_WINDOW = 5
const SLIDE_WINDOW = 3

const FOOTSTEP_PARTICLE_MIN_SPEED = 10

const DUCK_FORCE = 500

const GROUNDED_VERT_DRAG = 1.000

const RE_TRICK_TIMEOUT_FRAMES = 6
const RE_JUMP_TIMEOUT_FRAMES = 6


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

#@onready var foot_dangler_1: RigidBody2D = $FootDangler1
#@onready var foot_dangler_2: RigidBody2D = $FootDangler2
#@onready var foot_dangler_joint_1: PinJoint2D = $FootDanglerJoint1
#@onready var foot_dangler_joint_2: PinJoint2D = $FootDanglerJoint2

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
@onready var bumpable_object_detector: Area2D = %BumpableObjectDetector
@onready var trickable_object_detector: Area2D = %TrickableObjectDetector
@onready var jumpable_object_detector: Area2D = %JumpableObjectDetector
@onready var sprite_z_index = sprite.z_index
@onready var damage_invulnerability_timer: FrameTimer = $DamageInvulnerability
@onready var invuln_flash_timer: FrameTimer = $InvulnFlashTimer

@onready var re_trick_timer: FrameTimer = $ReTrickTimer
@onready var re_jump_timer: FrameTimer = $ReJumpTimer

var position_history := PackedVector2Array()
var position_history_grounded := PackedVector2Array()
var position_history_aerial := PackedVector2Array()

var debug_lines: Array[Line2D] = []

var is_grounded: bool = false:
	get:
		return is_grounded and !slope_too_steep()

var ground_object_last_position
var ground_object_velocity
var last_ground_object

var was_grounded := false

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
var last_grounded_position := Vector2()

var input_move_dir: int = 0
var input_move_dir_vec: Vector2i = Vector2i()
var input_move_dir_vec_normalized: Vector2 = Vector2()
var input_move_dir_vec_just_pressed: Vector2i = Vector2i()
var input_move_dir_vec_just_pressed_normalized: Vector2 = Vector2()
var input_duck_held: bool = false
var input_primary_pressed: bool = false
var input_primary_held: bool = false

var input_secondary_pressed: bool = false
var input_secondary_held: bool = false

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

var input_up_hold_time := 0
var input_down_hold_time := 0
var input_left_hold_time := 0
var input_right_hold_time := 0
var input_primary_hold_time := 0
var input_secondary_hold_time := 0

var input_up_last_press_time := INPUT_PRESS_BOUND
var input_down_last_press_time := INPUT_PRESS_BOUND
var input_left_last_press_time := INPUT_PRESS_BOUND
var input_right_last_press_time := INPUT_PRESS_BOUND
var input_primary_last_press_time := INPUT_PRESS_BOUND
var input_secondary_last_press_time := INPUT_PRESS_BOUND

var can_coyote_jump := false
var invulnerable : bool:
	get:
		if dead:
			return true
		if damage_invulnerability_timer and !damage_invulnerability_timer.is_stopped():
			return true
		return false
var can_apply_duck_force := true
var dead := false

var start_position: Vector2

var death_height := 0

var camera_offset := Vector2()
var ground_normal := Vector2.UP

var face_offset := Vector2()

var last_aerial_velocity := Vector2()

var nearby_hazards: Array[Node2D] = []

var last_position: Vector2 = Vector2()

var last_movement: Vector2:
	get:
		return (global_position - last_position)


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

var trickable_objects_detected = []
var processed_trickable_objects = []
var last_tricked_object = null

var touching_wall := false
var touching_wall_dir := 0

var slope_level = 0.0

var grinding = false 
var grind_position = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	z_index += 10
	for child in get_children():
		if child is Node2D:
			child.z_index -= 10

	if disable_feet:
		foot_1.hide()
		foot_2.hide()
		
	remove_child.call_deferred(camera_target)
	Global.get_level().add_child.call_deferred(camera_target)
	#remove_child.call_deferred(foot_dangler_1)
	#remove_child.call_deferred(foot_dangler_2)
	#get_parent().add_child.call_deferred(foot_dangler_1)
	#get_parent().add_child.call_deferred(foot_dangler_2)

	re_trick_timer.timeout.connect(set.bind("last_tricked_object", null))

	#if Debug.enabled:
		#debug_line = Line2D.new()
		#debug_line.width = 1.0
		#debug_line.
		#get_parent().add_child.call_deferred(debug_line)

	camera_target.set_deferred("global_position", global_position)

	super._ready()
	reset_idle_feet()
	
	feet_ray.target_position.y = FEET_DIST

	bumpable_object_detector.area_entered.connect(on_bumpable_object_entered)
	#bumpable_object_detector.area_exited.connect(on_bumpable_object_exited)
	bumpable_object_detector.body_entered.connect(on_bumpable_object_entered)
	#bumpable_object_detector.body_exited.connect(on_bumpable_object_exited)
	
	trickable_object_detector.area_entered.connect(on_trickable_object_entered)
	trickable_object_detector.area_exited.connect(on_trickable_object_exited)
	
	trickable_object_detector.body_entered.connect(on_trickable_object_entered)
	trickable_object_detector.body_exited.connect(on_trickable_object_exited)
	
	hurtbox.body_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.area_entered.connect(on_hurtbox_hazard_entered)
	hurtbox.body_exited.connect(on_hurtbox_hazard_exited)
	hurtbox.area_exited.connect(on_hurtbox_hazard_exited)
	
	start_position = global_position

	init_position_history()

func on_bumpable_object_entered(object: Node2D):
	if object.has_method("on_player_touched"):
		object.on_player_touched(self)
	#bumpable_objects_detected.append(object)

#func on_bumpable_object_exited(object: Node2D):
	#bumpable_objects_detected.erase(object)

func on_trickable_object_entered(object: Node2D):
	trickable_objects_detected.append(object)

func on_trickable_object_exited(object: Node2D):
	trickable_objects_detected.erase(object)

func on_hurtbox_hazard_entered(hazard: Node2D) -> void:
	nearby_hazards.append(hazard)

func on_hurtbox_hazard_exited(hazard: Node2D) -> void:
	nearby_hazards.erase(hazard)

func touch_terrain_with_feet(object: Node2D) -> void:
	if object and object != feet_touching_terrain:
		collide_with_terrain(object)
	feet_touching_terrain = object

func init_position_history():
	for i in POSITION_HISTORY_LENGTH:
		update_position_history(true)

func start_damage_invulnerability_timer():
	damage_invulnerability_timer.go()

func update_position_history(force=false):

	position_history.append(global_position)

	if is_grounded or force:
		position_history_grounded.append(global_position)
	
	if !is_grounded or force:
		position_history_aerial.append(global_position)

	if position_history.size() >= POSITION_HISTORY_LENGTH:
		position_history = position_history.slice(position_history.size() - POSITION_HISTORY_LENGTH)

	if position_history_grounded.size() >= POSITION_HISTORY_LENGTH:
		position_history_grounded = position_history_grounded.slice(position_history_grounded.size() - POSITION_HISTORY_LENGTH)
	
	if position_history_aerial.size() >= POSITION_HISTORY_LENGTH:
		position_history_aerial = position_history_aerial.slice(position_history_aerial.size() - POSITION_HISTORY_LENGTH)


enum PositionHistoryType {
	All,
	Grounded,
	Aerial,
}

func get_position_x_frames_ago(frames: int, type := PositionHistoryType.All):
	frames -= 1
	frames = min(frames, POSITION_HISTORY_LENGTH)
	
	var history: PackedVector2Array
	match type:
		PositionHistoryType.All:
			history = position_history
		PositionHistoryType.Grounded:
			history = position_history_grounded
		PositionHistoryType.Aerial:
			history = position_history_aerial
		
	return history[POSITION_HISTORY_LENGTH - frames]

func collide_with_terrain(object: Node2D):
	if object is DisappearingBlock:
		object.start()

func get_floor_angle() -> float:
	## normalized to up
	return ground_normal.rotated(TAU/4).angle()

func coin_touch_sound():
	play_sound("Coin")
	play_sound("Coin2")
	play_sound("Coin3")
	play_sound("Coin4")

func on_grabbed_coin() -> void:
	play_sound("Coin5")
	coin_collected.emit()

func _physics_process(delta: float) -> void:
	delta = 0.01666666666667

	update_position_history()

	if body.is_on_floor():
		body.velocity.y *= 0
	
	if not playing_replay:
		process_input()
	else:
		play_replay()
	process_input_held_times()
	process_last_button_press_times()
	
	if recording:
		record_replay()
	
	
	#if !tutorial_character:
		#modulate.g = 0.0 if recording else 1.0
		#modulate.b = 0.0 if recording else 1.0
		#
		#modulate.r = 0.0 if playing_replay else 1.0
		#modulate.b = 0.0 if playing_replay else 1.0
	
	#var shape_dist = body.speed * 0.05
	if is_grounded:
		last_grounded_height = feet_ray.get_collision_point().y
		last_grounded_position = global_position
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
	
	if GlobalInput.is_action_just_pressed("debug_restart"):
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
			var collision = body.get_slide_collision(i)
			var object = collision.get_collider()
			if body.velocity.dot(collision.get_normal()) < -SPLAT_SPEED and !is_grounded:
				die()
			if object and not (object in body_touching_terrain_new):
				if not (object in body_touching_terrain):
					collide_with_terrain(object)
				body_touching_terrain_new.append(object)
			
	body_touching_terrain.clear()
	for body in body_touching_terrain_new:
		body_touching_terrain.append(body)

	if is_grounded and !was_grounded:
		landed.emit()

	was_grounded = is_grounded
	
	if !is_grounded and !wall_sliding:
		if ground_object_velocity != null and ground_object_velocity.length_squared() > 0:
			body.apply_impulse.call_deferred(ground_object_velocity)
		ground_object_velocity = null
		ground_object_last_position = null
	else:
		var ground_objects := get_colliding_terrain_objects()
		Utils.sort_node_array_by_distance(ground_objects, global_position)
		if ground_object_velocity:
			ground_object_velocity *= 0
		
		for ground_object in ground_objects:
			if ground_object_velocity == null:
				ground_object_velocity = Vector2()
			if ground_object:
				if ground_object != last_ground_object:
					ground_object_velocity = Vector2()
					ground_object_last_position = null

				if ground_object_last_position == null:
					ground_object_last_position = ground_object.global_position
				
				var ground_object_diff = (ground_object.global_position - ground_object_last_position)
				body.move_and_collide(ground_object_diff)
				Debug.dbg("ground_object_diff", ground_object_diff)
				ground_object_velocity += ground_object_diff / delta
				foot_1.position += ground_object_diff
				foot_2.position += ground_object_diff
				ground_object_last_position = ground_object.global_position
				last_ground_object = ground_object
			break

		Debug.dbg("ground_objects", ground_objects)

	Debug.dbg("ground_object_velocity", ground_object_velocity)

	if damage_invulnerability_timer.is_stopped():
		modulate.a = 1.0
		if !invuln_flash_timer.is_stopped():
			invuln_flash_timer.stop()
	else:
		if invuln_flash_timer.is_stopped():
			invuln_flash_timer.go()

	last_position = global_position

func process_jumpable_objects(force=false):
	if !force and !input_jump_window(false):
		return false

	var jumpable_objects_detected = jumpable_object_detector.get_overlapping_areas()

	Utils.sort_node_array_by_distance(jumpable_objects_detected, global_position)

	for object in jumpable_objects_detected:
		var jumped_object = process_jumpable_object(object)
		if jumped_object:
			re_trick_timer.go(RE_TRICK_TIMEOUT_FRAMES)
			last_tricked_object = jumped_object
			input_primary_last_press_time = INPUT_PRESS_BOUND
			return true
	return false

func process_trickable_objects():
	if !input_trick_window():
		return

	Utils.sort_node_array_by_distance(trickable_objects_detected, global_position)

	for object in trickable_objects_detected:
		var tricked_object = process_trickable_object(object)
		if tricked_object:
			re_trick_timer.go(RE_TRICK_TIMEOUT_FRAMES)
			last_tricked_object = tricked_object
			return

func process_jumpable_object(obj) -> Node2D:
	while obj != null:
		if obj is SmileySpring:
			var dist_ratio = obj.get_dist_ratio(body)
			dist_ratio = 1.0 - (1.0 - dist_ratio) ** 3
			if dist_ratio < 0.25:
				dist_ratio = 0.25
			var strength = obj.spring_strength * dist_ratio
			change_state("KickOff", {"kick_dir": obj.spring_dir, "force_kick_strength": strength, "retain_momentum": true, "spring_effect": true})
			return obj


		obj = obj.get_parent()
	return obj

func process_trickable_object(obj) -> Node2D:
	while obj != null:
		if obj == last_tricked_object and !re_trick_timer.is_stopped():
			return null
		
		if obj is TrickTarget:

			#var data = {"trick_jump": true, "retain_speed": abs(body.velocity.x) + abs(impulse.x)}
			var data = {
				"rocket_time": obj.rocket_time, 
				"direction": (Vector2((facing), 0) if not input_move_dir_vec_normalized else input_move_dir_vec_normalized)
			}

			#global_position = obj.global_position

			# TODO: rocket effect
			change_state("TrickRocket", data)
			obj.tricked_by(self)
			return obj
		
		elif obj is TrickSpinner:
			if obj.captured == null:
				var data = {
					"captor": obj
				}
				obj.capture_player(self)
				change_state("TrickSpinner", {"captor": obj})
				return obj
			return null

		elif obj is RailPost:
			
			if can_trick_rail(obj):
				change_state("GrindRail", { "rail": obj })
			else:
				return null
			
			return obj # object was processed and will be cleared

		elif obj is SmileySpring:
			var dist_ratio = obj.get_dist_ratio(body)
			dist_ratio = 1.0 - (1.0 - dist_ratio) ** 3
			if dist_ratio < 0.25:
				dist_ratio = 0.25
			var strength = obj.spring_strength * dist_ratio
			change_state("KickOff", {"kick_dir": obj.spring_dir, "force_kick_strength": strength, "retain_momentum": true, "spring_effect": true})
			return obj
		
		elif obj.has_method("tricked_by"):
			obj.tricked_by(self)
			return obj

		obj = obj.get_parent()

	return obj

func can_trick_rail(rail: RailPost) -> bool:
	if (!grind_cooldown.is_stopped()) and last_rail == rail:
		return false
	var offset = rail.get_offset(global_position)
	if offset <= 0 or offset >= rail.length:
		var point = rail.path_node.to_global(rail.path_node.curve.sample_baked(offset))
		if abs(global_position.x - point.x) < abs(global_position.x + body.velocity.x - point.x):
			return false
	return true

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
	if dead:
		return
	dead = true
	nearby_hazards.clear()
	change_state("Die")
	#set_physics_process.call_deferred(false)
	#body.set_physics_process.call_deferred(false)
	#body.apply_physics(get_physics_process_delta_time())

func respawn():
	global_position = get_position_x_frames_ago(RESPAWN_POSITION_FRAMES, PositionHistoryType.Grounded)
	sprite.frame = 0
	sprite.scale = Vector2.ONE
	sprite.z_index = sprite_z_index
	nearby_hazards.clear()
	sprite.reset_physics_interpolation.call_deferred()
	reset_physics_interpolation.call_deferred()
	foot_1.reset_physics_interpolation.call_deferred()
	foot_2.reset_physics_interpolation.call_deferred()
	body.reset_momentum.call_deferred()
	show()
	await get_tree().physics_frame
	body.reset_momentum.call_deferred()
	init_position_history.call_deferred()

func debug_process() -> void:
	#Debug.dbg("ducking", ducking)
	#Debug.dbg("duck_blocking", body.get_collision_mask_value(10))
	Debug.dbg("input", "%s" % input_to_bitflags())
	Debug.dbg("input_jump", input_jump_window(false))
	Debug.dbg("input_primary_last_press_time", input_primary_last_press_time)
	Debug.dbg("body_vel", body.velocity.round())
	Debug.dbg("facing", facing)
	Debug.dbg("body_accel", body.accel.round())
	Debug.dbg("body_speed", body.speed)
	Debug.dbg("body_impulses", body.impulses.round())
	Debug.dbg("aerial_vel", last_aerial_velocity.round())
	Debug.dbg("input_dir", input_move_dir_vec)
	#Debug.dbg("floor_overlap", floor_overlap_ratio)
	Debug.dbg("slope", get_slope_level())
	Debug.dbg("floor_normal", ground_normal)
	Debug.dbg("touching_wall_dir", touching_wall_dir)
	Debug.dbg("feet_collider", feet_ray.get_collider().name if feet_ray.is_colliding() and feet_ray.get_collider() else "null" if feet_ray.is_colliding() else "not colliding")
	Debug.dbg("vert_drag", get_vert_drag())
	Debug.dbg("jumpable_objects", jumpable_object_detector.get_overlapping_areas())
	#Debug.dbg("position_history_size", position_history.size())
	

func update_camera_target(delta: float) -> void:
	camera_offset = Math.splerp_vec(camera_offset, Vector2((body.velocity.x) * 0.12 + 35 * (body.velocity.x / 100), CAMERA_VERT_OFFSET) + Vector2(facing * 20, 0), delta, 10.0)

	Debug.dbg("camera_offset_x", camera_offset.x)
	
	if dead:
		camera_target.global_position = global_position
		return

	camera_target.global_position.x = global_position.x + camera_offset.x
	if current_state.center_camera:
		camera_target.global_position = global_position
	if wall_sliding:
		camera_target.global_position.y = y + camera_offset.y
	elif grinding:
		camera_target.global_position = Math.splerp_vec(camera_target.global_position, grind_position + camera_offset * 0.5, delta, 2.0)
	#elif is_grounded or position.y >= last_grounded_height:
	elif is_grounded:
		#if is_grounded:
		camera_target.global_position.y = last_grounded_height + camera_offset.y
		#else:
			#camera_target.global_position.y = last_grounded_height + camera_offset.y + body.velocity.y * 0.25
			#var dist = global_position.y - camera_target.global_position.y + (300)
			#if dist > (Global.viewport_size.y / 2):
				#var diff = dist - (Global.viewport_size.y / 2)
				#camera_target.global_position.y += diff
	else:
		var down_amount = 0
		if body.velocity.y > 0 and !is_grounded:
			down_amount = body.velocity.y * 0.35
		var dist = global_position.y - camera_target.global_position.y
		var diff = 0.0
		if dist > (Global.viewport_size.y / 2):
			diff = dist - (Global.viewport_size.y / 2)

		camera_target.global_position.y = Math.splerp(camera_target.global_position.y, global_position.y + down_amount + diff, delta, 2.0)
	#camera_target.global_position = global_position + camera_offset
	camera_target_raycast.position *= 0
	camera_target_raycast.target_position = to_local(camera_target.global_position)
	
	var camera_target_raycast_check_resolution = 20
	var camera_target_raycast_check_height = 200
	camera_target_raycast.force_raycast_update()
	var collision_point = camera_target_raycast.get_collision_point()
	var blocking := true
	var perp := camera_target_raycast.target_position.rotated(TAU/4).normalized()
	#var furthest_dist = 0.0
#
	var start :Vector2 = -perp * camera_target_raycast_check_height/2.0
	var end :Vector2 = perp * camera_target_raycast_check_height/2.0
	for i in range(camera_target_raycast_check_resolution):
		camera_target_raycast.position = start.lerp(end, i / float(camera_target_raycast_check_resolution))
		camera_target_raycast.force_raycast_update()
		if !camera_target_raycast.is_colliding():
			blocking = false
			break
		#var dist = camera_target_raycast.to_local(camera_target_raycast.get_collision_point()).length()
		#if dist > furthest_dist:
			#furthest_dist = dist
	if blocking:
		camera_target.global_position = collision_point
		#camera_target.global_position = camera_target.global_position + to_local(collision_point).normalized() * furthest_dist


func footstep_effect(foot: SmileyFoot) -> void:
	var speed = body.speed
	if speed < FOOTSTEP_PARTICLE_MIN_SPEED:
		return

	var num_bodies = min(round(rng.randfn(speed / 50, 0.2)), 3)
	if num_bodies <= 0:
		return
	var dir = (Vector2(-2 * facing, -1).rotated(ground_normal.angle() + TAU/4)).normalized()
	var particle: BouncyBurst = spawn_scene(preload("res://object/player/fx/step_particle.tscn"), Vector2(), dir, false) 
	particle.num_bodies = num_bodies
	particle.global_position = feet_ray.get_collision_point()
	particle.starting_velocity = speed / 2.0
	particle.starting_velocity_deviation = speed / 4.0
	particle.damp = 20
	particle.go.call_deferred()
	particle.z_index = 1000
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
			pass

	queue_redraw()


func process_input() -> void:
	input_move_dir_vec = Utils.bools_to_vector2i(GlobalInput.is_action_pressed("move_left"), GlobalInput.is_action_pressed("move_right"),GlobalInput.is_action_pressed("move_up"), GlobalInput.is_action_pressed("move_down"))
	input_move_dir = input_move_dir_vec.x
	input_move_dir_vec_normalized = Vector2(input_move_dir_vec).normalized()
	input_move_dir_vec_just_pressed = Utils.bools_to_vector2i(GlobalInput.is_action_just_pressed("move_left"), GlobalInput.is_action_just_pressed("move_right"),GlobalInput.is_action_just_pressed("move_up"), GlobalInput.is_action_just_pressed("move_down"))
	input_move_dir_vec_just_pressed_normalized = Vector2(input_move_dir_vec_just_pressed).normalized()
	input_primary_pressed = GlobalInput.is_action_just_pressed("primary")
	input_primary_held = GlobalInput.is_action_pressed("primary")
	input_secondary_pressed = GlobalInput.is_action_just_pressed("secondary")
	input_secondary_held = GlobalInput.is_action_pressed("secondary")
	input_duck_held = GlobalInput.is_action_pressed("move_down")

func process_input_held_times():
	if input_primary_held:
		input_primary_hold_time += 1
	else:
		input_primary_hold_time = 0
		
	if input_secondary_held:
		input_secondary_hold_time += 1
	else:
		input_secondary_hold_time = 0
		
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

func process_last_button_press_times():
	if input_up_pressed:
		input_up_last_press_time = 0
	else:
		input_up_last_press_time -= 1
		if input_up_last_press_time < INPUT_PRESS_BOUND:
			input_up_last_press_time = INPUT_PRESS_BOUND

	if input_down_pressed:
		input_down_last_press_time = 0
	else:
		input_down_last_press_time -= 1
		if input_down_last_press_time < INPUT_PRESS_BOUND:
			input_down_last_press_time = INPUT_PRESS_BOUND
		
	if input_left_pressed:
		input_left_last_press_time = 0
	else:
		input_left_last_press_time -= 1
		if input_left_last_press_time < INPUT_PRESS_BOUND:
			input_left_last_press_time = INPUT_PRESS_BOUND
		
	if input_right_pressed:
		input_right_last_press_time = 0
	else:
		input_right_last_press_time -= 1
		if input_right_last_press_time < INPUT_PRESS_BOUND:
			input_right_last_press_time = INPUT_PRESS_BOUND
		
	if input_primary_pressed:
		input_primary_last_press_time = 0
	else:
		input_primary_last_press_time -= 1
		if input_primary_last_press_time < INPUT_PRESS_BOUND:
			input_primary_last_press_time = INPUT_PRESS_BOUND
		
	if input_secondary_pressed:
		input_secondary_last_press_time = 0
	else:
		input_secondary_last_press_time -= 1
		if input_secondary_last_press_time < INPUT_PRESS_BOUND:
			input_secondary_last_press_time = INPUT_PRESS_BOUND

func frame_window(pressed_time: Variant, window: int, reset=true):
	if pressed_time is int:
		return pressed_time > -window
	elif pressed_time is String:
		if get(pressed_time) > -window:
			if reset:
				set(pressed_time, INPUT_PRESS_BOUND)
			return true
	return false
		
func hold_window(held_time: int, window: int):
	return held_time > 0 and held_time <= window

func reset_jump_window() -> void:
	input_primary_last_press_time = INPUT_PRESS_BOUND

func input_jump_window(reset=true):
	return frame_window("input_primary_last_press_time", JUMP_WINDOW, reset)

func input_trick_window(reset=true):
	return frame_window("input_secondary_last_press_time", TRICK_WINDOW, reset)

func input_slide_window(reset=true):
	return frame_window("input_down_last_press_time", SLIDE_WINDOW, reset)

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
	input |= FLAG_A     if input_primary_held else 0
	input |= FLAG_B     if input_secondary_held else 0
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
	input_primary_pressed = a and !input_primary_held
	input_primary_held = a
	input_secondary_pressed = b and !input_secondary_held
	input_secondary_held = b
	input_duck_held = input_move_dir_vec.y == 1

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

		#Debug.dbg("spring force", force)
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


func get_colliding_terrain_objects() -> Array[PhysicsBody2D]:
	var arr : Array[PhysicsBody2D] = []
	var current_state_colliders = current_state.get_terrain_colliders()
	if current_state_colliders:
		arr.append_array(current_state_colliders)
	elif feet_ray.is_colliding():
		arr.append(feet_ray.get_collider())
	return arr

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
		draw_circle(buttons_pos + Vector2(-10, 0), lerp(10, 5, hold_time_ratio.call(input_primary_hold_time)), get_color.call(input_primary_hold_time))
		draw_circle(buttons_pos + Vector2(10, 0), lerp(10, 5, hold_time_ratio.call(input_secondary_hold_time)), get_color.call(input_secondary_hold_time))


func _on_invuln_flash_timer_timeout() -> void:
	if modulate.a != 1.0:
		modulate.a = 1.0
	else:
		modulate.a = 0.7
	pass # Replace with function body.
