extends StateInterface2D

class_name ObjectState

var object: BaseObject2D

var body: BaseObjectBody2D

#@export var apply_drag := true
@export var apply_physics := true
@export var apply_gravity := true
@export var apply_friction = true

func init() -> void:
	object = host
	body = object.body

func _update_shared(delta):
	if apply_gravity:
		body.apply_gravity()
	if apply_friction:
		host.apply_friction(delta)
	if apply_physics:
		body.apply_physics(delta)
