extends SmileyGrabbedState

func _enter():
	die_effect.call_deferred()

func die_effect():
	var tween = create_tween()
	player.sprite.frame = 0
	var prev_z_index = player.sprite.z_index
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	player.sprite.z_index = 1000
	tween.tween_property(player.sprite, "frame", player.sprite.sprite_frames.get_frame_count(player.sprite.animation) - 1, 0.5)
	#player.spawn_scene(preload("res://object/player/fx/death_shine.tscn"))
	await tween.finished
	player.hide()
	#player.get_camera().bump(Vector2(), 5, 0.8, 60)
	player.spawn_scene(preload("res://object/player/fx/death_burst.tscn"))
	await get_tree().create_timer(0.25).timeout
	body.reset_momentum()
	queue_state_change("Idle")
	player.sprite.frame = 0
	player.show()
	#get_tree().reload_current_scene()
	#queue_free()
	#return
	
	player.global_position = player.start_position
	player.set_physics_process(true)
	player.body.set_physics_process(true)
	player.body.reset_momentum()
	player.dead = false
