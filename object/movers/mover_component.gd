@tool

extends Node2D

class_name MoverComponent

signal movable_children_entered(children: Array[Node2D])

@export_range(1, 1024, 1) var max_children := 1024

var parent: Node2D

func _ready() -> void:
	parent = get_parent()
	parent.set_meta("is_mover", true)
	var children = parent.get_children()
	var movable : Array[Node2D] = []
	for i in mini(children.size(), max_children):
		var child = children[i]
		if child.owner != parent and child is Node2D:
			#print("movable object: " + child.name)
			movable.append(child)
			if !Engine.is_editor_hint():
				if child.has_signal("mover_detach_needed"):
					child.mover_detach_needed.connect(_on_mover_detach_requested.bind(child), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	if movable:
		if parent.has_method("process_movable_children"):
			parent.process_movable_children(movable)
		movable_children_entered.emit(movable)

func _on_mover_detach_requested(object: Node2D) -> void:
	var pos = object.global_position
	if parent.has_method("on_mover_detach_requested"):
		parent.on_mover_detach_requested()
	else:
		parent.remove_child(object)
		Global.get_level().add_child(object)
		object.global_position = pos
		object.reset_physics_interpolation()
