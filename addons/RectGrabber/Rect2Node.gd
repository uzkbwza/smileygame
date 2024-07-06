@tool

extends Node2D

class_name Rect2Node

const UNSELECTED_ALPHA_MUL = 0.2

var size: Vector2:
	set(v):
		size_x = v.x
		size_y = v.y
	get:
		return Vector2(size_x, size_y)

@export_range(0, 1000, 0.002, "or_greater", "or_less") var size_x = 32.0:
	set(x):
		x = abs(Math.stepify(x, pixel_snap))
		size_x = x
		recalculate_rect()
	
@export_range(0, 1000, 0.002, "or_greater", "or_less") var size_y = 32.0:
	set(y):
		y = abs(Math.stepify(y, pixel_snap))
		size_y = y
		recalculate_rect()

@export_range(1, 128, 1.0) var pixel_snap = 1

var rect: Rect2
var stroke_color = Color()
var fill_color = Color()

func recalculate_rect():
	var start = Vector2(-size_x / 2, -size_y / 2)
	rect = Rect2(start, Vector2(size_x, size_y))

func get_global_rect() -> Rect2:
	var new_rect = rect
	new_rect.size *= scale
	new_rect.position += global_position
	return new_rect

func overlaps(rect: Rect2Node):
	return get_global_rect().intersects(rect.get_global_rect(), true)

func overlaps_rect2(rect: Rect2):
	return get_global_rect().intersects(rect, true)
	
func contains_point(point: Vector2):
	return get_global_rect().has_point(point)

func _ready():
	size_x = size_x
	size_y = size_y
	update_color()
	if !Engine.is_editor_hint():
		set_process(false)

func _process(delta: float) -> void:
	queue_redraw()

func get_color() -> Color:
	return Color.DARK_GRAY

func get_fill_alpha() -> float:
	return 0.1

func get_unselected_alpha_mul() -> float:
	return UNSELECTED_ALPHA_MUL

func update_color():
	stroke_color = get_color()
	fill_color = stroke_color
	fill_color.a = get_fill_alpha()

func can_draw() -> bool:
	return Engine.is_editor_hint() or true

func _draw():
	if can_draw():
		var fill = fill_color
		var stroke = stroke_color
		if Engine.is_editor_hint():
			if !self in EditorInterface.get_selection().get_selected_nodes():
				stroke.a *= get_unselected_alpha_mul()
				fill.a *= get_unselected_alpha_mul()
		draw_rect(rect, fill, true)
		draw_rect(rect, stroke, false, 1.0 / get_viewport_transform().get_scale().x)
