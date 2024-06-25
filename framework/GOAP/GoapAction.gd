extends RefCounted

class_name GoapAction

var actor
var end_signal: Signal:
	get:
		return _get_end_signal()
		
var cost: float:
	get:
		return _get_cost()

var preconditions: Dictionary:
	get:
		return _get_preconditions()

var effects: Dictionary:
	get:
		return _get_effects()

func _init(actor):
	self.actor = actor

func _get_cost() -> float:
	return 1000

func _get_preconditions() -> Dictionary:
	return {}

func _get_effects() -> Dictionary:
	return {}

func _get_end_signal() -> Signal:
	return Signal()

func is_valid() -> bool:
	return true

func perform():
	pass
