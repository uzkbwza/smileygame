extends Node3D

class_name Component

var host: Node = null

func _name() -> StringName:
	return &"Component"

func _enter_tree() -> void:
	host = get_parent()
	host.set_meta(_name(), self)

func _exit_tree() -> void:
	host.set_meta(_name(), null)
	host = null
	
# get was taken
static func getc(node: Node, component: StringName) -> Component:
	var c = node.get_meta(component, false)
	# generates error if i dont do this
	if not c:
		return null
	return c
