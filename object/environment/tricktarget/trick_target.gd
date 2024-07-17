extends Area2D

class_name TrickTarget
@onready var timer = $Timer

@export_range(0.1, 10.0,0.05) var rocket_time = 0.25

var active = true
var tricked_player: SmileyPlayer

func _ready():
	timer.timeout.connect(on_timer_timeout)
	activate()

func on_timer_timeout():
	if !active:
		if tricked_player == null:
			activate()
		elif tricked_player.is_grounded:
			activate()

func tricked_by(player: SmileyPlayer):
	tricked_player = player
	trick_effect()
	deactivate()
	timer.start()
	await player.landed
	if active:
		return
	activate()

func activate():
	monitorable = true
	active = true
	show()
	reform_effect()	
	pass

func deactivate():
	active = false
	monitorable = false
	hide()
	pass

func trick_effect():
	pass

func reform_effect():
	
	pass
