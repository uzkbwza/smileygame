extends Node

signal draw_toggled

const HISTORY_SIZE = 500

var enabled := true
var profiling := true
var draw := false:
	get:
		return draw and enabled
	set(value):
		var different = draw != value
		draw = value
		if different:
			draw_toggled.emit()

var show_object_info := true

var profiler := GameProfiler.new()

var items = {
}

var times = {
}

var histories = {
	
}

var history_data = {
}

var dbg_function: Callable
var dbg_history_function: Callable

var rng := BetterRng.new()

func dbg_enabled(id: String, value: Variant) -> void:
#	return
	items[id] = value

func dbg_disabled(_id: String, _value: Variant) -> void:
	pass

func dbg_enabled_history(id: String, v: float, color:= Color.WHITE, min: float=-1000.0, max: float=1000.0) -> void:
	dbg_enabled(id, v)
	var arr: PackedFloat64Array
	if histories.has(id):
		arr = histories[id]
	else:
		arr = []
		histories[id] = arr
		history_data[id] = {
			"color": color,
			"min": min,
			"max": max,
		}

	arr.append(v)
	
	if arr.size() >= HISTORY_SIZE:
		arr = arr.slice(arr.size() - HISTORY_SIZE)
		histories[id] = arr
	pass

func dbg_disabled_history(_id: String, _v: Variant, _color:= Color.WHITE, _min: float=-1000.0, _max: float=1000.0) -> void:
	pass

class TimeLength:
	var length
	var name

	func _init(name, length):
		self.name = name
		self.length = length / 1000.0
		pass

func time_function(method: Callable):
	var start = Time.get_ticks_usec()
	method.call()
	var end = Time.get_ticks_usec()
	if times.has(method):
		times[method.get_method()].append(TimeLength.new(method.get_method(), end - start))
	else:
		times[method.get_method()] = [TimeLength.new(method.get_method(), end - start)]

func _enter_tree():
	if !OS.is_debug_build():
		enabled = false

	if profiling:
		EngineDebugger.register_profiler("main", profiler)
		EngineDebugger.profiler_enable("main", true)

	if enabled:
		dbg_function = dbg_enabled
		dbg_history_function = dbg_enabled_history
		set_process(true)
	else:
		dbg_function = dbg_disabled
		dbg_history_function = dbg_disabled_history
		set_process(false)


func _process(delta):

	for time_array in times:
		var total_time = 0
		var counter = 0
		for time in times[time_array]:
			counter += 1
			total_time += time.length
		dbg(time_array, total_time)
		dbg(time_array + " avg", total_time / float(counter))
		dbg_max(time_array + " max", total_time)
#		times.erase(time_array)

	if Input.is_action_just_pressed("debug_show") and Debug.enabled:
		draw = !draw

func dbg_prop(object: Object, prop: String):
	dbg(prop, object.get(prop))

func dbg(id: String, v: Variant):
	dbg_function.call(id, v)

func dbg_history(id: String, v: Variant, color:= Color.WHITE, min: float=-1000.0, max: float=1000.0):
	dbg_history_function.call(id, v, color, min, max) 

func dbg_dict(dict: Dictionary):
	for key in dict:
		dbg(key, dict[key])

func dbg_count(id, value, min_=1):
	if value >= min_:
		dbg(id, value)

func dbg_remove(id):
	items.erase(id)

func dbg_max(id, value):
	if !items.has(id) or items[id] < value:
		dbg(id, value)

func lines() -> Array:
	var lines = []
	for id in items:
		lines.append(str(id) + ": " + str(items[id]))	
	return lines
