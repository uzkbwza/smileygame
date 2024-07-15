extends Area2D

class_name Coin

@onready var icon = $Icon

func _ready():
	icon.material.set_shader_parameter("time_offset", randf() * 1000)
	#icon.frame = randi_range(0, icon.sprite_frames.get_frame_count(icon.animation) - 1)
	#icon.rotation = randf_range(-0.6, 0.6)
	icon.play()
	var level = get_parent()
	
	while !(level is SmileyLevel):
		if level == null:
			break
		level = level.get_parent()

	if level is SmileyLevel:
		level.coins_left += 1
		level.num_coins += 1

func on_player_touched(player: SmileyPlayer):
	queue_free()
	_on_player_touched.call_deferred(player)

func _on_player_touched(player: SmileyPlayer):
	var particle = preload("res://object/coin/coin_grab_effect.tscn").instantiate()
	get_parent().add_child(particle)
	particle.global_position = global_position
	player.on_grabbed_coin()
