extends SmileyGrabbedState

var captor: TrickSpinner

func _enter():
	captor = data.captor
	captor.apply_torque_impulse(captor.process_2d_impulse(body.velocity))

func _update(delta: float):
	player.global_position = captor.head.global_position
	body.velocity = Vector2()
	body.move_and_slide()
	body.velocity = captor.get_2d_velocity()

	if !check_landing():
		if check_jump():
			return

	if !player.input_secondary_held:
		fall_and_retain_speed()
		return

	player.is_grounded = player.feet_ray.is_colliding()
	if body.get_slide_collision_count() > 0:
		return "Fall"
	
	#Debug.dbg("spinner_vel", captor.velocity)

func _exit():
	player.last_tricked_object = captor
	player.re_trick_timer.go(12)
	captor.release_player()
