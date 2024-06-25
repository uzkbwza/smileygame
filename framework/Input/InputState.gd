class_name InputState 

const MIN_INPUT_TIME := 1.0

var time: float = 0.0

var forward: float = -INF
var backward: float = -INF
var left: float = -INF
var right: float = -INF

var attack: float = -INF
var jump: float = -INF

var move_dir = Vector2()
var look_dir = Vector2()

var button_names = []

func _init(time:int=0):
	self.time = time
	var properties = get_script().get_script_property_list().slice(2)
	for property in properties:
		if property.type == TYPE_FLOAT:
			button_names.append(property.name)

func set_input_from_bool(input: String, value: bool):
	if value:
		set(input, MIN_INPUT_TIME)

func _to_string():
	var text = ""
	for name in button_names:
		text = text + name + ": %+05d" % get(name) + ", "
	return text

func to_rich_string():
	var text = "t: %-5.1f, " % time
	for name in button_names:
		var color = Color.WHITE
		if get(name) > 0:
			color = Color.GREEN
		if get(name) == 1:
			color = Color.GOLD

		color = color.to_html(false)
		text = text + "[color=%s]" % color + name + ": %+7.1f" % get(name) + "[/color] "
	return text
