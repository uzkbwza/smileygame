extends Node

class_name Utils

const cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const diagonal_dirs: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]
const all_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]

static func clear_children(node: Node, deferred=true) -> void:
	if deferred:
		for child in node.get_children():
				child.queue_free()
		return
	for child in node.get_children():
		child.free()

static func enum_string(value: int, enum_) -> String:
	return enum_.keys()[value].capitalize().to_lower()

static func sort_node_array_by_distance(arr: Array, from:Vector2):
	arr.sort_custom(func(a, b): return \
		from.distance_squared_to(a.global_position) < \
		from.distance_squared_to(b.global_position))
		
static func sort_array_by_distance(arr: Array[Vector2], from: Vector2):
	arr.sort_custom(func(a, b): return \
		from.distance_squared_to(a) < \
		from.distance_squared_to(b))

static func get_first_dict_key_below_number(dict: Dictionary, num: int):
	var highest = -INF
	for key in dict:
		if key > num:
			return highest
		if key > highest:
			highest = key
	return highest

static func load_resource_threaded(resource_path: StringName, await_callback: Callable, progress_callback:Callable = func(progress: Array) -> void: return) -> Resource:
	#print(resource_path) 

	var progress: Array[int] = [0]
	var resource: Resource

	ResourceLoader.load_threaded_request(resource_path)
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(resource_path, progress)
		var signal_ = await_callback.call()
		if signal_ == null:
			break
		await signal_
		if is_instance_valid(progress_callback):
			progress_callback.call(progress)
		match status:
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				resource = ResourceLoader.load_threaded_get(resource_path)
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				continue
	return resource

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
	
static func bools_to_vector2i(left: bool, right: bool, up: bool, down: bool) -> Vector2i: 
	return Vector2i(bools_to_axis(left, right), bools_to_axis(up, down))
	
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

static func rainbow_gradient(resolution=256) -> Gradient:
	resolution = min(resolution, 256)
	var grad = Gradient.new()
	for i in range(resolution):
		var color = hsv_to_rgb(i / float(resolution), 1.0, 1.0)
		if i < 2:
			grad.set_color(i, color)
		else:
			grad.add_point(i / float(resolution), color)
	return grad

static func hsv_to_rgb(h: float, s: float, v: float, a: float = 1) -> Color:
	#based on code at
	#http://stackoverflow.com/questions/51203917/math-behind-hsv-to-rgb-conversion-of-colors
	var r: float
	var g: float
	var b: float

	var i: float = floor(h * 6)
	var f: float = h * 6 - i
	var p: float = v * (1 - s)
	var q: float = v * (1 - f * s)
	var t: float = v * (1 - (1 - f) * s)

	match (int(i) % 6):
		0:
			r = v
			g = t
			b = p
		1:
			r = q
			g = v
			b = p
		2:
			r = p
			g = v
			b = t
		3:
			r = p
			g = q
			b = v
		4:
			r = t
			g = p
			b = v
		5:
			r = v
			g = p
			b = q
	return Color(r, g, b, a)
