extends SmileyState

class_name SmileyGrabbedState

@export var hide_feet = true

func _enter_shared():
	super._enter_shared()


	#player.invulnerable = true
	#player.foot_1.rotation = -TAU/4
	#player.foot_2.rotation = -TAU/4
	if hide_feet:
		player.foot_1.hide()
		player.foot_2.hide()
		#player.show_danglers.call_deferred()
		player.foot_1.global_position = player.last_position
		player.foot_2.global_position = player.last_position

func _update_shared(delta: float):
	super._update_shared(delta)
	var last_movement = player.last_movement
	if hide_feet:
		player.foot_1.global_position = player.global_position
		player.foot_2.global_position = player.global_position

	#player.foot_1.rotation = last_movement.angle() - TAU/4 * player.facing
	#player.foot_2.rotation = last_movement.angle() - TAU/4 * player.facing
	body.velocity = last_movement

func _exit_shared():
	if hide_feet:
		player.foot_1.global_position = player.global_position
		player.foot_2.global_position = player.global_position

	super._exit_shared()
	player.invulnerable = false
