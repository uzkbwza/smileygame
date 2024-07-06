extends StateInterface2D

class_name ObjectState

var object: BaseObject2D:
	get:
		return host

var body: BaseObjectBody2D:
	get:
		return object.body

#@export var apply_drag := true
@export var apply_physics := true
@export var apply_gravity := true
@export var apply_friction = true

func _update_shared(delta):
	if apply_gravity:
		body.apply_gravity()
	if apply_friction:
		host.apply_friction(delta)
	if apply_physics:
		body.apply_physics(delta)
