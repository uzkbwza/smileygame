@tool

class_name FrameTimer

extends Timer

@export_range(1, 3600, 0.5) var frames: int = 1.0:
	set(value):
		wait_time = maxf(frames, 0) / 60.0
		frames = value

@export var force_physics = true

func _ready() -> void:
	if !Engine.is_editor_hint():
		set_process(false)

func go(frames: int=-1):
	if frames == -1:
		frames = self.frames
	start(frames_to_time(frames))

func _process(delta: float) -> void:
	wait_time = frames_to_time(frames)
	if force_physics:	
		process_callback = Timer.TimerProcessCallback.TIMER_PROCESS_PHYSICS

static func frames_to_time(frames:int) -> float:
	return maxf(frames, 0) / 60.0

static func time_to_frames(time:float) -> int:
	return int(floor(time * 60))
