@tool

extends Node2D

class_name RingMover

@export_range(16, 128, 16) var radius: int = 32
@export_range(8.0, 1024.0, 8) var speed = 64.0
@export_range(-1, 1, 2) var direction: int = 1

var objects: Array[Node2D] = []

var elapsed_time = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	set_physics_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var finished = true
	var size = objects.size()
	for i in size:
		var object := objects[i]
		if !is_instance_valid(object) or object.get_parent() != self:
			continue
		var offset = (float(i) / size) * TAU

		var angle = (elapsed_time) * (speed / (radius)) * -direction + (offset)
		object.position = Vector2(sin(angle), cos(angle)) * radius
		finished = false
		
	if finished:
		set_physics_process.call_deferred(false)
		set_process.call_deferred(false)

	if Engine.is_editor_hint():
		queue_redraw()

	elapsed_time += delta
	
	

func process_movable_children(children):
	if !Engine.is_editor_hint():
		for child in children:
			objects.append(child)
	else:
		for child in children:
			child.global_position = global_position
			var placeholder = preload("res://object/movers/MoverPlaceholder.tscn").instantiate()
			objects.append(placeholder)
			add_child.call_deferred(placeholder)

	set_process.call_deferred(true)
	set_physics_process.call_deferred(true)

func _draw():
	if Engine.is_editor_hint():
		draw_circle(Vector2(), radius, Color.BLACK, false, 2.0)
