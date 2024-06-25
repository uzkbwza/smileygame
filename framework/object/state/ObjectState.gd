extends StateInterface2D

class_name ObjectState

var object: BaseObject2D:
	get:
		return host

var body: BaseObjectBody2D:
	get:
		return object.body

@export var apply_drag = true
@export var apply_physics = true

func _update_shared(delta):
	if apply_physics:
#		if apply_gravity:
#			host.apply_gravity()
#		if apply_friction:
#			host.apply_ground_friction()
#			host.apply_wall_friction()
		if apply_drag:
			body.apply_drag(delta)
		body.apply_physics(delta)
