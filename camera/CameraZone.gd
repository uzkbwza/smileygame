@tool

extends ReferenceRect

class_name CameraZone

@export var open_left := false
@export var open_right := false
@export var open_top := false
@export var open_bottom := false

#var open_side_padding := 128
#
#var open_left_padding := -1
		#
#var open_right_padding := -1
		#
#var open_top_padding := -1
		#
#var open_bottom_padding := -1

@export_range(0, 4096, 16) var open_side_padding := 64

@export_range(0, 4096, 16) var open_left_padding := 0
		
@export_range(0, 4096, 16) var open_right_padding := 0
		
@export_range(0, 4096, 16) var open_top_padding := 0
		
@export_range(0, 4096, 16) var open_bottom_padding := 0


var top: int:
	get:
		return global_position.y

var left: int:
	get:
		return global_position.x

var bottom: int:
	get:
		return global_position.y + size.y
		
var right: int:
	get:
		return  global_position.x + size.x

var center: Vector2:
	get:
		return global_position + (size / 2.0)

var left_neighbors: Array[CameraZone] = []
var right_neighbors: Array[CameraZone] = []
var top_neighbors: Array[CameraZone] = []
var bottom_neighbors: Array[CameraZone] = []

func get_left_padding() -> float:
	return (open_left_padding if open_left_padding > 0 else open_side_padding) if open_left else 0
func get_right_padding() -> float:
	return (open_right_padding if open_right_padding > 0 else open_side_padding) if open_right else 0
func get_top_padding() -> float:
	return (open_top_padding if open_top_padding > 0 else open_side_padding) if open_top else 0
func get_bottom_padding() -> float:
	return (open_bottom_padding if open_bottom_padding > 0 else open_side_padding) if open_bottom else 0

func try_add_neighbor(zone: CameraZone) -> void:
	if zone.bottom == top and zone.left < right and zone.right > left:
		top_neighbors.append(zone)
	if zone.top == bottom and zone.left < right and zone.right > left:
		bottom_neighbors.append(zone)
	if zone.left == right and zone.top < bottom and zone.bottom > top:
		right_neighbors.append(zone)
	if zone.right == left and zone.top < bottom and zone.bottom > top:
		left_neighbors.append(zone)
	
func horizontal_padding_overlap_amount(x: float)-> float:
	## 0.0 to 1.0
	if !point_within_horizontal_bounds(x):
		return 0.0
	elif point_inside_horizontal_padding(x):
		return 1.0
	else:
		if x <= center.x:
			return inverse_lerp(left, left + get_left_padding(), x)
		else:
			return inverse_lerp(right, right - get_right_padding(), x)

func vertical_padding_overlap_amount(y: float)-> float:
	## 0.0 to 1.0
	if !point_within_vertical_bounds(y):
		return 0.0
	elif point_inside_vertical_padding(y):
		return 1.0
	else:
		if y <= center.y:
			return inverse_lerp(top, top + get_top_padding(), y)
		else:
			return inverse_lerp(bottom, bottom - get_bottom_padding(), y)

func _ready() -> void:
	if !Engine.is_editor_hint():
		if !Debug.enabled:
			set_process(false)
			hide()
		else:
			editor_only = false
		global_position = global_position.round()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		#pass
		size.x = max(size.x, Math.stepify(ProjectSettings.get_setting("display/window/size/viewport_width"), 16))
		size.y = max(size.y, Math.stepify(ProjectSettings.get_setting("display/window/size/viewport_height"), 16))
		if size.x <= 0:
			size.x = 1
		if size.y <= 0:
			size.y = 1
	else:
		visible = Debug.draw
	queue_redraw()

func point_within_rect(point: Vector2) -> bool:
	return point.x >= left and point.x <= right and point.y >= top and point.y <= bottom

func point_within_horizontal_bounds(x: float) -> bool:
	return x >= left and x <= right

func point_within_vertical_bounds(y: float) -> bool:
	return y >= top and y <= bottom

func point_within_padding(point: Vector2) -> bool:
	return point.x >= left + get_left_padding() and point.x <= right - get_right_padding() and \
	 point.y >= top + get_top_padding() and point.y <= bottom - get_bottom_padding()

func point_inside_horizontal_padding(x: float) -> bool:
	return x >= left + get_left_padding() and x <= right - get_right_padding()
	
func point_inside_vertical_padding(y: float) -> bool:
	return y >= top + get_top_padding() and y <= bottom - get_bottom_padding()
	
func point_inside_left_padding(x: float) -> bool:
	return x >= left + get_left_padding() 
	
func point_inside_right_padding(x: float) -> bool:
	return x <= right - get_right_padding()
	
func point_inside_top_padding(y: float) -> bool:
	return y >= top + get_top_padding()
	
func point_inside_bottom_padding(y: float) -> bool:
	return y <= bottom - get_bottom_padding()

func _draw() -> void:
	if (!Engine.is_editor_hint() and !Debug.draw):
		return
	var open_color = Color.YELLOW
	open_color.a *= 0.5
	var l = 0.0
	var r = size.x
	var u = 0.0
	var d = size.y

	var rect_color = open_color
	rect_color.a *= 0.5 if !Engine.is_editor_hint() else 0.15
	draw_rect(Rect2(Vector2(), size), rect_color, true)

	if open_left:
		draw_line(Vector2(l + get_left_padding(), u), Vector2(l + get_left_padding(), d), open_color)
	if open_right:
		draw_line(Vector2(r - get_right_padding(), u), Vector2(r - get_right_padding(), d), open_color)
	if open_top:
		draw_line(Vector2(l, u + get_top_padding()), Vector2(r, u + get_top_padding()), open_color)
	if open_bottom:
		draw_line(Vector2(l, d - get_bottom_padding()), Vector2(r, d - get_bottom_padding()), open_color)
