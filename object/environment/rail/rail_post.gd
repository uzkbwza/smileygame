@tool

extends Line2D

class_name RailPost

## TODO: closed loops

const RAIL_WIDTH = 32.0

@onready var area_2d: Area2D = $Area2D

var path_node: Path2D

var segments := {
	
}

var segment_offsets = []

var length = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !(Engine.is_editor_hint()):
		set_process(false)

	width = texture.get_height()

	if Engine.is_editor_hint():
		return

	#texture = preload("res://stupid crap/friends/terrain/rail/rail.png")
	#texture_mode = Line2D.LINE_TEXTURE_STRETCH 
	path_node = Path2D.new()
	path_node.curve = Curve2D.new()
	add_child.call_deferred(path_node)
	#add_child.call_deferred(line_node)

	var last_offset: float = 0.0

	var last = null

	for point_id in points.size():
		var point = points[point_id]

		path_node.curve.add_point(point)

		if last != null and point != last:
			var collision_shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size.y = RAIL_WIDTH
			box.size.x = point.distance_to(last) + (RAIL_WIDTH)
			collision_shape.shape = box
			collision_shape.rotation = (point - last).angle()
			collision_shape.position = (point + last) / 2.0
			area_2d.add_child.call_deferred(collision_shape)
			var offset := path_node.curve.get_closest_offset(point)
			segments[last_offset] = { 
				"start": to_global(last), 
				"end": to_global(point), 
				"centered": point - last, 
				"direction": (point - last).normalized() 
			}
			last_offset = offset
			

		
		path_node.curve.bake_interval = 5.0
		length = path_node.curve.get_baked_length()

		last = point

	segment_offsets = segments.keys()

func get_grind_position(to: Vector2) -> Vector2:
	return path_node.to_global(path_node.curve.get_closest_point(path_node.to_local(to)))

func get_grind_position_from_offset(offs: float) -> Vector2:
	return path_node.to_global(path_node.curve.sample_baked(offs))

func get_segment(check: Vector2):
	return get_segment_from_offset(get_offset(check))

func get_segment_from_offset(check: float):
	var size = segment_offsets.size()
	var index :int
	var offset = 0.0
	var min :int = 0
	var max :int = size - 1
	
	if size == 1:
		return segments[0.0]
	
	if check <= 0:
		return segments[0.0]
	
	if check >= length:
		return segments[segment_offsets[-1]]

	while min <= max:
		
		index = (min + max) / 2
		offset = segment_offsets[index]
		if offset == check:
			return segments[offset]
		elif offset > check:
			max = index - 1
		elif offset < check:
			min = index + 1
	
	if max < 0:
		return segments[segment_offsets[0]]

	return segments[segment_offsets[max]]

func get_normal(offset: float) -> Vector2:
	return get_direction(offset).rotated(-TAU/4)
	
func get_direction(offset: float) -> Vector2:
	var segment = get_segment_from_offset(offset)
	return segment.direction

func get_offset(to: Vector2) -> float:
	return path_node.curve.get_closest_offset(path_node.to_local(to))

func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	if !(Engine.is_editor_hint() or Debug.draw):
		return
	var col = Color.CYAN
	var col2 = Color.RED
	var col3 = Color.LIME_GREEN
	col.a *= 0.7
	col2.a *= 0.7
	#if start:

	for point in points:
		#draw_polyline(points, to_local(next.global_position), col, 1.0)
		draw_circle(point, 4.0, col, false, 1.0, false)

	draw_circle(points[0], 4.0, col3, true)
