extends StateInterface

class_name ObjectBodyState

var object: BaseObject2D:
	get:
		return body.host

var body: BaseObjectBody2D:
	get:
		return host

#@export var apply_gravity = false
#@export var apply_friction = false
@export var apply_drag = false
@export var apply_physics = false

func _update_shared(delta):
	if apply_physics:
#		if apply_gravity:
#			host.apply_gravity()
#		if apply_friction:
#			host.apply_ground_friction()
#			host.apply_wall_friction()
		if apply_drag:
			host.apply_drag(delta)
		host.apply_physics(delta)
