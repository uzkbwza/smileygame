extends Label

class_name DebugLabel
var timer

func _ready():
	if !Debug.draw:
		hide()
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.0001
	timer.timeout.connect(loop)
	loop()
	
func loop():
	if Debug.enabled:
		text = ""
		for line in Debug.lines():
			text = text + line + "\n"
		timer.start()
	visible = Debug.draw
