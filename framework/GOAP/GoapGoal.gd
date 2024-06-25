extends RefCounted

class_name GoapGoal

var actor

var priority: float:
	get:
		return _get_priority()

var desired_state: Dictionary:
	get:
		return _get_desired_state()

var preconditions: Dictionary:
	get:
		return _get_preconditions()

func _init(actor):
	self.actor = actor

func is_valid() -> bool:
	return true

func _get_desired_state() -> Dictionary:
	return {}

func _get_priority() -> float:
	return 1.0

func _get_preconditions() -> Dictionary:
	return {}
