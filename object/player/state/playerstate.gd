extends ObjectState

class_name SmileyState

#const JUMP_VELOCITY = 910
const JUMP_VELOCITY := 310.0
const KICK_JUMP_FORCE := 200.0
const GROUND_POUND_SPEED := 350.0
const UPWARD_MOMENTUM_JUMP_MULTIPLIER := 1.0
const PERP_JUMP_MODIFIER := 1.0
const OVERLAP_JUMP_CORRECTION := 16.0
const FALL_OFF_SPEED := 0.0
const MAX_DEBUG_LINES := 5

@export_range(0.0, 1.0) var update_feet_position_lerp_value := 0.5
@export_range(0.0, 1.0)  var update_face_position_lerp_value := 0.5
@export var process_trickable_objects := true
@export var process_jumpable_objects := true
@export var center_camera := false

var debug_color := Color.WHITE

var player: SmileyPlayer

var rng: BetterRng

var elapsed_time := 0.0
var elapsed_ticks := 0


func init():
	super.init()
	player = host
	rng = player.rng
	set_debug_color.call_deferred()

func set_debug_color():
	if Debug.enabled:
		debug_color = Global.rainbow.sample(get_index() / float(get_parent().get_child_count()))
		#print(debug_color)

func _enter_shared() -> void:
	elapsed_time = 0.0
	if Debug.enabled:
		var stack = player.state_machine.states_stack
		if stack.size() >= 5:
			for i in range(min(5, stack.size())):
				Debug.dbg("state:" + str(i), stack[stack.size() - i - 1].state_name)
		if player.debug_lines.size() >= MAX_DEBUG_LINES:
			player.debug_lines.pop_front().queue_free()
		new_debug_line.call_deferred()

	player.foot_2.flip_h = false
	player.foot_1.flip_h = false
	if player.disable_feet:
		player.foot_1.hide()
		player.foot_2.hide()

func new_debug_line():
	var debug_line = Line2D.new()
	debug_line.width = 1
	debug_line.z_index = player.z_index -1

	debug_line.default_color = debug_color
	Global.get_level().add_child.call_deferred(debug_line)
	if player.debug_lines:
		debug_line.add_point(player.debug_lines[-1].points[-1])
	player.debug_lines.append(debug_line)
	debug_line.add_point(debug_line.to_local(global_position))
	debug_line.default_color.a = 0.75

func _exit_shared() -> void:
	host.sprite.scale = Vector2.ONE
	host.sprite.rotation = 0
	host.face_offset = Vector2()
	
	player.foot_2.flip_h = false
	player.foot_1.flip_h = false
	#player.foot_dangler_1.hide()
	#player.foot_dangler_2.hide()
	player.foot_1.show()
	player.foot_2.show()
	
	if Debug.enabled:
		queue_redraw()

func _update_shared(delta: float) -> void:
	super._update_shared(delta)
	if update_face_position_lerp_value > 0:
		player.update_face_position(update_face_position_lerp_value)
	if update_feet_position_lerp_value > 0:
		player.update_feet_position(update_feet_position_lerp_value)

	if process_trickable_objects:
		player.process_trickable_objects()
		
	if process_jumpable_objects:
		player.process_jumpable_objects()
	
	elapsed_time += delta
	elapsed_ticks += 1
	
	if Debug.enabled:
		queue_redraw()


func check_fall(extra_data: Dictionary = {}, reset_y = true) -> bool:
	if !player.is_grounded:
		queue_state_change("Fall", extra_data)
		if reset_y:
			if body.velocity.y + body.impulses.y > -FALL_OFF_SPEED:
				body.velocity.y = -FALL_OFF_SPEED
		return true
	return false

func check_duck() -> void:
	if player.input_duck_held:
		player.duck()
	
#func check_grounded_kick(extra_data = {}) -> bool:
	#if player.input_secondary_pressed:
		#if body.velocity.y > 0:
			#body.velocity.y *=0 
		#if body.impulses.y > 0:
			#body.impulses.y *= 0
		#if body.accel.y > 0:
			#body.accel.y *= 0
		#player.is_grounded = false
		#body.move_and_collide(Vector2(0, -5))
		#body.apply_impulse(Vector2(0, -KICK_JUMP_FORCE))
		#queue_state_change("Kick", extra_data)
		#return true
	#return false

func get_terrain_colliders() -> Array[PhysicsBody2D]:
	return []

func check_jump(extra_data: Dictionary = {}, force=false) -> bool:

	if force or (player.input_jump_window() and !(player.ceiling_detector.is_colliding() and player.ducking)):
		if player.state_machine.queued_states.size() > 0:
			return false
		
		if body.velocity.y > 0:
			body.velocity.y *= 0
		if body.impulses.y > 0:
			body.impulses.y *= 0
		if body.accel.y > 0:
			body.accel.y *= 0

		#if player.feet_ray.is_colliding():
			#var run_speed = abs(body.velocity.dot(player.feet_ray.get_collision_normal().rotated(TAU/4)))
			#var slope = player.get_slope_level()
			#var impulse = run_speed * min(0, slope) * Vector2.DOWN * 0.25
			#body.apply_impulse(impulse)
			#pass

		body.move_and_collide(Vector2(0, player.floor_overlap_ratio * -OVERLAP_JUMP_CORRECTION))
		extra_data.merge({"jump": true})
		queue_state_change("Fall", extra_data)
		
		player.jumped_off_ground.emit(Vector2.UP)
		player.jumped_off_something.emit(Vector2.UP)
		
		var normal = player.ground_normal
		var perp_jump = sign(player.input_move_dir) == sign(normal.x) and player.input_move_dir != 0 and player.is_grounded and sign(body.velocity.x) != sign(normal.x)
		var lerp_amount = 1.0 if perp_jump else 0.0
		var body_speed = body.prev_speed
		var speed = JUMP_VELOCITY if !perp_jump else max(body_speed + body.impulses.length(), JUMP_VELOCITY) * PERP_JUMP_MODIFIER
		#if perp_jump:
			#body.velocity *= 0
		body.apply_impulse.call_deferred(Vector2(0, -1).lerp(normal, lerp_amount) * speed)
		if player.is_grounded and body.velocity.y <= -50:
			#body.impulses.y *= UPWARD_MOMENTUM_JUMP_MULTIPLIER
			body.velocity.y *= UPWARD_MOMENTUM_JUMP_MULTIPLIER
		player.is_grounded = false
		player.jump_effect.call_deferred()
		return true
	return false

func check_landing(custom_landing_state = "", extra_data=null) -> bool:
	if player.is_grounded:
		
		var slope = player.get_slope_level()
		if slope != 0:

				# retain horizontal momentum on slopes. this makes the character feel more slippery
				var normal = player.ground_normal
				body.velocity = Vector2(body.velocity.x, player.last_aerial_velocity.y).rotated(-player.get_floor_angle()) 
				
				# land smoothly down slopes instead of bouncing off
				if sign(normal.y) < 0:
					body.velocity = body.velocity.lerp(normal.rotated(TAU/4 * sign(body.velocity.x)) * body.velocity.length(), 0.5)
					var snap_force = Vector2(0, 16 * abs(body.velocity.y) / 500.0)
					body.move_and_collide(snap_force)
		
		var run = abs(body.velocity.x) >= SmileyRunState.MIN_RUN_SPEED
		
		if body.velocity.x != 0 and run and custom_landing_state == "":
			player.set_flip(sign(body.velocity.x))
		
		var state = ("Idle" if !run else "Run")
		
		if player.input_slide_window(): 
		#if player.input_jump_window() and player.input_move_dir_vec.y > 0: 
			state = "FloorSlide"

		queue_state_change(state if custom_landing_state == "" else custom_landing_state, extra_data)
		player.foot_1_was_touching_ground = true
		player.foot_2_was_touching_ground = true
	

	
		if player.last_aerial_velocity.y > GROUND_POUND_SPEED:


			player.play_sound("Landing", true)
			player.play_sound("Landing2", true)
			player.get_camera().bump(Vector2.DOWN, abs(player.last_aerial_velocity.y) * 0.03, abs(player.last_aerial_velocity.y) * 0.001, 50)
			player.spawn_scene(preload("res://object/player/fx/landing_dust.tscn"), player.to_local(player.feet_ray.get_collision_point()), player.ground_normal.rotated(TAU/4))
		else:

			pass

		return true
	return false

func fall_and_retain_speed(extra_data = null):
	var data = {"retain_speed": abs(body.velocity.x)}
	if extra_data is Dictionary:
		data.merge(extra_data)
	queue_state_change("Fall", data)

func check_run() -> void:
	if player.input_move_dir != 0:
		queue_state_change("Run")
