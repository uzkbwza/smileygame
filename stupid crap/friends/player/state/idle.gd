extends SmileyState

func _enter() -> void:
	player.foot_1.z_index = 1
	player.foot_2.z_index = 1
	player.is_boosting = false
	#player.reset_idle_feet()

func _update(delta: float):
	if !check_jump():
		if check_fall():
			pass
	check_duck()
	
	player.foot_1.z_index = 1 * player.facing
	player.foot_2.z_index = -1 * player.facing
	player.update_feet_position(0.5)
	player.feet_lift_body()
	player.feet_idle()
	player.squish()
	if player.feet_ray.is_colliding():
		var normal = player.feet_ray.get_collision_normal()
		#var counter_slope_force = normal - Vector2.UP * -body.gravity
		#print(counter_slope_force)
		#body.apply_force(counter_slope_force)
		body.apply_gravity(body.gravity * -normal)
	else:
		body.apply_gravity()
#
	#if (player.touching_wall_dir != player.input_move_dir):
		#var force := Vector2(player.get_run_speed() * player.input_move_dir, 0).rotated(player.get_floor_angle())
		#body.apply_force(force)

	if player.input_move_dir != 0 and (player.touching_wall_dir != player.input_move_dir):
		player.set_flip(player.input_move_dir)
		body.apply_impulse(Vector2(player.input_move_dir * 0.001, 0))
		return "Run"
