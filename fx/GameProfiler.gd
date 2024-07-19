extends EngineProfiler

class_name GameProfiler

func _enter():
	pass

func _toggle(enable: bool, options: Array) -> void:
	pass

func _tick(frame_time: float, process_time: float, physics_time: float, physics_frame_time: float) -> void:
	Debug.dbg_history("fps", 1.0 / frame_time, Color.CYAN, 0, 1000)
	Debug.dbg_history("physics_time", physics_time * 1000, Color.PURPLE, 0.0, 16.6667)
	Debug.dbg_history("physics_frame_time", physics_frame_time * 1000, Color.ORANGE, 0.0, 16.6667)
	Debug.dbg_history("process_time", process_time * 1000, Color.BLUE, 0.0, 16.6667)
	
