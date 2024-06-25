extends Node

class_name Utils

static func clear_children(node: Node, deferred=true) -> void:
	if deferred:
		for child in node.get_children():
				child.queue_free()
		return
	for child in node.get_children():
		child.free()

static func enum_string(value: int, enum_) -> String:
	return enum_.keys()[value].capitalize().to_lower()

static func get_first_dict_value_above_number(dict: Dictionary, num: int) -> int:
	var value = dict[0]
	for key in dict:
		if key > num:
			return value
		value = dict[key]
	return value

static func tree_set_all_process(p_node: Node, p_active: bool, p_self_too: bool = false) -> void:
	if not p_node:
		push_error("p_node is empty")
		return
	var p = p_node.is_processing()
	var pp = p_node.is_physics_processing()
	p_node.propagate_call("set_process", [p_active])
	p_node.propagate_call("set_physics_process", [p_active])
	if not p_self_too:
		p_node.set_process(p)
		p_node.set_physics_process(pp)

static func get_angle_to_target(node: Node2D, target_position: Vector2) -> float:
	var target = node.get_angle_to(target_position)
	target = target if abs(target) < PI else target + TAU * -sign(target)
	return target
	
static func comma_sep(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

static func bools_to_axis(negative: bool, positive: bool) -> float:
	return (-1.0 if negative else 0) + (1.0 if positive else 0)

static func bools_to_vector2(left: bool, right: bool, up: bool, down: bool) -> Vector2:
	return Vector2(bools_to_axis(left, right), bools_to_axis(up, down))

static func remove_duplicates(array: Array) -> Array:
	var seen = []
	var new = []
	for i in array.size():
		var value = array[i]
		if value in seen:
			continue
		seen.append(value)
		new.append(value)
	return new

static func queue_free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
		
static func free_children(node: Node) -> void:
	for child in node.get_children():
		child.free()

static func walk_path(path, absolute=false, filter_file_type=""):
	var files: = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file if !absolute else dir.get_current_dir().path_join(file))
	return files.filter(func(f: String): return f.ends_with(filter_file_type))
