extends Node

var enabled = false
var draw = true
var show_object_info = true

var items = {
}

var times = {
}

var dbg_function: Callable

func dbg_enabled(id, value):
#	return
	items[id] = value

func dbg_disabled(_id, _value):
	pass

#func _input(event):
#	if event.is_action_pressed("ui_toggle_debug_draw") and enabled:
#		draw = !draw

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
	if enabled:
		dbg_function = dbg_enabled
	else:
		dbg_function = dbg_disabled

func _process(delta):
#	yield(get_tree(), "idle_frame")
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


func dbg_prop(object: Object, prop: String):
	dbg(prop, object.get(prop))

func dbg(id, v):
	dbg_function.call(id, v)

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
