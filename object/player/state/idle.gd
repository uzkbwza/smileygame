extends SmileyState

func _enter() -> void:
	player.foot_1.z_index = 1
	player.foot_2.z_index = 1
	#player.reset_idle_feet()

func _update(delta: float):

	check_duck()
	
	player.foot_1.z_index = 1 * player.facing
	player.foot_2.z_index = -1 * player.facing
	player.update_feet_position(0.5)
	player.feet_lift_body()
	player.feet_idle()
	player.squish()
	if player.feet_ray.is_colliding():
		var normal = player.ground_normal
		body.apply_gravity(body.gravity * -normal)
	else:
		body.apply_gravity()


	if player.input_move_dir != 0 and (player.touching_wall_dir != player.input_move_dir):
		player.set_flip(player.input_move_dir)
		body.apply_impulse(Vector2(player.input_move_dir * 0.001, 0))
		return "Run"
#
	#if player.input_move_dir_vec.y > 0 and player.input_jump_window():
		#return "FloorSlide"

	if !check_jump():
		if check_fall():
			pass
