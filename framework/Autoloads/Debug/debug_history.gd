extends Control

class_name DebugHistory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !Debug.enabled:
		set_process(false)
		hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	if !Debug.draw:
		return
	
	var history_size := Debug.HISTORY_SIZE
	
	for id in Debug.histories:
		var points = PackedVector2Array()
		var data = Debug.history_data[id]
		var arr : PackedFloat64Array = Debug.histories[id]
		var min = data.min
		var max = data.max
		for i in arr.size():
			var f = arr[i]
			points.append(
				Vector2(
					i / float(history_size) * (size.x),
					inverse_lerp(max, min, f) * (size.y )
				)
			)
		#if points.size() % 2 != 0:
			#points.append(points[-1])
		if points:
			draw_polyline(points, Color.BLACK, 4.0)
			draw_polyline(points, data.color, 2.0)
