@tool

extends Line2D

class_name PathMover

@export_range(-1, 1, 2) var direction: int = 1
@export_range(0.0, 1024.0, 16) var speed = 64.0
@export_exp_easing() var easing = 1.0
@export_range(0.0, 2.0, 0.01) var start_offset = 0.0

@export var center: bool:
	set(value):
		if value:
			center = false
			center_points()

@export var center_root: bool:
	set(value):
		if value:
			center_root = false
			move_root_to_center()

@export var reset_root: bool:
	set(value):
		if value:
			reset_root = false
			move_root_to_origin()

@onready var curve := Curve2D.new()

var objects: Array[Node2D] = []
var elapsed := 0.0

func center_points():
		var current_center = Shape.get_polygon_center(points)
		var move = (global_position - to_global(current_center))
		var new_points = Shape.move_polygon(points, move)
		points = new_points

func move_root_to_center():
	var current_center = Shape.get_polygon_center(points)
	global_position = to_global(current_center)
	center_points()
	
func move_root_to_origin():
		var move = (position)
		var new_points = Shape.move_polygon(points, move)
		points = new_points
		position *= 0.0

func _ready():
	if !Engine.is_editor_hint():
		default_color.a = 0.0
	set_process(false)
	set_physics_process(false)
	for point_id in points.size():
		var point = points[point_id]
		curve.add_point(point)
	if closed and points.size() > 0:
		curve.add_point(points[0])

func process_movable_children(children: Array[Node2D]) -> void:
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

func _physics_process(delta: float) -> void:
	var count = objects.size()
	var length = curve.get_baked_length()
	var finished = true
	for i in count:
		var offset = fposmod((float(i) / count) + start_offset, 2.0) * length

		var object = objects[i]
		if !is_instance_valid(object):
			continue
		if object.get_parent() != self:
			continue
		finished = false
	
		var offs: float
		if closed:
			offs = fposmod(elapsed * speed * direction + (offset), length)
		else:
			offs = Math.ping_pong_interpolate(elapsed * speed + (offset), 0.0, length, easing)
		object.global_position = to_global(curve.sample_baked(offs))

	if finished:
		set_physics_process.call_deferred(false)
		set_process.call_deferred(false)
	
	elapsed += delta
