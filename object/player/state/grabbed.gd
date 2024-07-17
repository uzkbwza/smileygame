extends SmileyState

class_name SmileyGrabbedState

func _enter_shared():
	super._enter_shared()
	player.invulnerable = true
	player.foot_1.rotation = -TAU/4
	player.foot_2.rotation = -TAU/4

func _update_shared(delta: float):
	super._update_shared(delta)
	var last_movement = player.last_movement
	player.foot_1_pos = player.last_position
	player.foot_2_pos = player.last_position
	player.foot_1.rotation = last_movement.angle() - TAU/4 * player.facing
	player.foot_2.rotation = last_movement.angle() - TAU/4 * player.facing
	body.velocity = last_movement

func _exit_shared():
	super._exit_shared()
	player.invulnerable = false
