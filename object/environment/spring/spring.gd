@tool

extends Node2D

class_name SmileySpring

@export_range(32, 2048, 16) var spring_length = 32

@export_range(500, 20000, 100) var spring_strength := 800.0

var colliding_objects = []

var object_distances = {
}

@onready var point_a_node: Marker2D = $PointA
@onready var point_b_node: Marker2D = $PointB

@onready var base: Sprite2D = $Base
@onready var end: Sprite2D = $End

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spring_start: Marker2D = $SpringStart

var spring_dir: Vector2:
	get:
		return Vector2.RIGHT.rotated(rotation)

var point_a: Vector2
var point_b: Vector2

var springy_tween: Tween

func _ready():
	if !Engine.is_editor_hint():
		set_process(false)
	set_physics_process(false)
	collision_shape.shape = collision_shape.shape.duplicate(true)

	update_spring_length()
	return_to_full_length()

func _on_body_entered(body: Node2D) -> void:
	if springy_tween:
		springy_tween.stop()

	colliding_objects.append(body)
	
	var parent = body.get_parent()
	#
	#if parent is SmileyPlayer and !jump_functions.has(parent):
		#var f = on_player_jumped_off_something.bind(body)
		#jump_functions[parent] = f
		#parent.jumped_off_something.connect(f)
	#
	set_physics_process.call_deferred(true)

	#Debug.dbg("jump_functions", jump_functions)

func _on_body_exited(body: Node2D) -> void:
	colliding_objects.erase(body)

	var parent = body.get_parent()
	#
	#if jump_functions.has(parent):
		#var f = jump_functions[parent]
		#if parent.jumped_off_something.is_connected(f):
			#parent.jumped_off_something.disconnect(f)
		#jump_functions.erase(parent)

	#Debug.dbg("jump_functions", jump_functions)
	
	object_distances.erase(body)
	
	if colliding_objects.size() == 0:
		set_physics_process.call_deferred(false)
		return_to_full_length()

func return_to_full_length():
	if springy_tween:
		springy_tween.stop()

	springy_tween = create_tween()
	springy_tween.set_ease(Tween.EASE_OUT)
	springy_tween.set_trans(Tween.TRANS_ELASTIC)
	springy_tween.tween_property(end, "position:x", spring_length, 0.5)


func on_player_pressed_jump(direction: Vector2, body: BaseObjectBody2D):
	if !(body in colliding_objects):
		return
	var amount = direction.dot(spring_dir)
	if amount < 0:
		return

	body.apply_impulse(spring_dir * spring_strength * amount)

func _process(delta: float) -> void:
	update_spring_length()

func update_spring_length():
	end.position.x = spring_start.position.x + spring_length
	collision_shape.shape.size.x = spring_length + 8
	collision_shape.position.x = spring_length / 2.0 + spring_start.position.x
	pass

func _physics_process(delta: float) -> void:
	point_a = point_a_node.global_position
	point_b = point_b_node.global_position
	
	var shortest_dist = INF
	for body in colliding_objects:
		var parent = body.get_parent()
		var touch_pos = body.global_position
		
		var object_dist = INF
		
		if parent is SmileyPlayer:
			for foot in [parent.foot_1, parent.foot_2]:
				var dist = get_distance(foot.global_position)
				if dist and dist < shortest_dist:
					shortest_dist = dist
				if dist and dist < object_dist:
					object_dist = dist

		var dist = get_distance(touch_pos)
		if dist and dist < shortest_dist:
			shortest_dist = dist
		if dist and dist < object_dist:
			object_dist = dist
		
		object_distances[body] = object_dist

	end.position.x = Math.splerp(end.position.x, clampf(spring_start.position.x + shortest_dist, 0, spring_length), delta, 1.0)

func get_dist_ratio(from: Node2D):
	if !(from in object_distances):
		return 0.0
	return 1.0 - clampf(object_distances[from], 0, spring_length) / float(spring_length)

func get_distance(from: Vector2):
		var dir = Vector2.LEFT.rotated(global_rotation)
		var point_d = Shape.ray_to_line_segment_origin(from, dir, point_a, point_b)
		if point_d:
			var dist = point_d.distance_to(from)
			return dist
