extends Label

class_name DebugLabel
var timer: Timer

func _ready() -> void:
	if !Debug.draw:
		hide()
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.0001
	timer.timeout.connect(loop)
	loop()
	
func loop() -> void:
	visible = Debug.draw
	if !visible:
		timer.start()
		return
		
	if Debug.enabled:
		text = ""
		for line in Debug.lines():
			text = text + line + "\n"
		timer.start()
