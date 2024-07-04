extends ObjectState

class_name SmileyState

const JUMP_VELOCITY = 310
const GROUND_POUND_SPEED = 350
const UPWARD_MOMENTUM_JUMP_MULTIPLIER = 1.4

@export_range(0.0, 1.0) var update_feet_position_lerp_value = 0.5
@export_range(0.0, 1.0)  var update_face_position_lerp_value = 0.5

var player: SmileyPlayer:
	get:
		return host

var rng: BetterRng:
	get:
		return player.rng

var elapsed_time := 0.0

func _enter_shared() -> void:
	elapsed_time = 0.0
	if Debug.enabled:
		var stack = player.state_machine.states_stack
		if stack.size() >= 7:
			for i in range(min(7, stack.size())):	
				Debug.dbg("state:" + str(i), stack[stack.size() - i - 1].state_name)

func _exit_shared() -> void:
	host.sprite.scale = Vector2.ONE
	host.sprite.rotation = 0
	host.face_offset = Vector2()

func _update_shared(delta: float) -> void:
	super._update_shared(delta)
	if update_face_position_lerp_value > 0:
		player.update_face_position(update_face_position_lerp_value)
	if update_feet_position_lerp_value > 0:
		player.update_feet_position(update_feet_position_lerp_value)
	elapsed_time += delta

func check_fall() -> bool:
	if !player.is_grounded:
		queue_state_change("Fall")
		if body.velocity.y > 0 and body.impulses.y >= 0:
			body.velocity.y = 0
		return true
	return false

func check_duck() -> void:
	if player.input_duck:
		player.duck()

func check_jump() -> bool:
	if player.input_jump and !(player.ceiling_detector.is_colliding() and player.ducking):
		if body.velocity.y > 0:
			body.velocity.y *= 0
		if body.impulses.y > 0:
			body.impulses.y *= 0
		if body.accel.y > 0:
			body.accel.y *= 0
		if player.is_grounded and body.velocity.y <= 0:
			body.velocity.y *= UPWARD_MOMENTUM_JUMP_MULTIPLIER
		body.move_directly(Vector2(0, -1))
		queue_state_change("Fall", {"jump": true})
		body.apply_impulse.call_deferred(Vector2(0, -JUMP_VELOCITY))
		player.jump_effect.call_deferred()
		return true
	return false

func check_landing() -> bool:
	if player.is_grounded:
		
		var slope = player.get_slope_level()
		if slope != 0:
			body.velocity = Vector2(body.velocity.x, player.last_aerial_velocity.y).rotated(-player.get_floor_angle()) 
			if body.velocity.x != 0:
				player.set_flip(sign(body.velocity.x))
		queue_state_change("Idle" if abs(body.velocity.x) < SmileyRunState.MIN_RUN_SPEED else "Run")
		player.foot_1_was_touching_ground = true
		player.foot_2_was_touching_ground = true
			#print(body.velocity)
		if player.last_aerial_velocity.y > GROUND_POUND_SPEED:

			
			#body.apply_impulse(Vector2.DOWN * body.velocity.y / 1.0)
			player.play_sound("Landing", true)
			player.play_sound("Landing2", true)
			player.get_camera().bump(Vector2.DOWN, abs(player.last_aerial_velocity.y) * 0.03, abs(player.last_aerial_velocity.y) * 0.001, 50)
			player.spawn_scene.call_deferred(preload("res://stupid crap/friends/player/fx/landing_dust.tscn"), player.to_local(player.feet_ray.get_collision_point()), player.feet_ray.get_collision_normal().rotated(TAU/4))
		else:
			#body.velocity.y *= 0.85
			pass
		#body.velocity.y *= 1.25
		return true
	return false

func check_run() -> void:
	if player.input_move_dir != 0:
		queue_state_change("Run")
