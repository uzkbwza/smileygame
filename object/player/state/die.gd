extends SmileyGrabbedState

func _enter():
	
	die_effect.call_deferred()

func die_effect():
	player.death_animation_started.emit()
	var tween = create_tween()
	player.sprite.frame = 0
	var prev_z_index = player.sprite.z_index
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	player.sprite.z_index = 1000
	player.play_sound("Die1")
	player.play_sound("Die2")
	#player.play_sound("Die7")
	player.play_sound("Die8")
	tween.tween_property(player.sprite, "frame", player.sprite.sprite_frames.get_frame_count(player.sprite.animation) - 1, 0.5)
	player.spawn_scene(preload("res://object/player/fx/death_shine.tscn"))
	player.invulnerable = true
	await tween.finished
	player.hide()
	player.play_sound("Die3")
	player.play_sound("Die4")
	player.play_sound("Die5")
	player.play_sound("Die6")
	player.get_camera().bump(Vector2(), 100, 0.5)
	player.spawn_scene(preload("res://object/player/fx/death_burst.tscn"))
	player.death_animation_finished.emit()
	await get_tree().create_timer(1.00).timeout
	body.reset_momentum()
	queue_state_change("Idle")
	player.sprite.frame = 0
	player.show()
	#get_tree().reload_current_scene()
	#queue_free()
	#return
	
	player.global_position = player.start_position
	player.invulnerable = false
	#player.set_physics_process(true)
	#player.body.set_physics_process(true)
	player.body.reset_momentum()
	player.dead = false
