@tool

extends Line2D

class_name ShapeOutline

enum Shape {
	Ellipse,
	Box,
}

var prev_scale = Vector2(1, 1)

@export var shape: Shape:
	set(s):
		shape = s
		points = build_shape(shape)
		if shape == Shape.Ellipse:
			end_cap_mode = Line2D.LINE_CAP_NONE
		elif shape == Shape.Box:
			end_cap_mode = Line2D.LINE_CAP_BOX
	get:
		return shape

var _shape_width = 10.0
var _shape_height = 10.0

@export_range(1.0, 1000.0, 0.05) var shape_width = 10.0:
	set(x):
		if link_width_and_height:
			var old_width = shape_width
			_shape_width = x
			_shape_height = shape_height * (shape_width / old_width)
		else:		
			_shape_width = x
		points = build_shape(shape)
	get:
		return _shape_width
		
@export_range(1.0, 1000.0, 0.05) var shape_height = 10.0:
	set(x):
		if link_width_and_height:
			var old_height = shape_height 
			_shape_height = x
			_shape_width = shape_width * (shape_height / old_height)
		else:		
			_shape_height = x
		points = build_shape(shape)
	get:
		return _shape_height

@export var automatic_ellipse_resolution = true:
	set(b):
		automatic_ellipse_resolution = b
		points = build_shape(shape)

@export var link_width_and_height = true

@export_range(3, 100) var ellipse_resolution: int = 18:
	set(x):
		ellipse_resolution = x
		if automatic_ellipse_resolution:
			return
		points = build_shape(shape)

func _ready():
	build_shape(shape)

func build_shape(shape):
	if automatic_ellipse_resolution:
		ellipse_resolution = max((shape_width + shape_height) / 5.0, 12)
	var points = PackedVector2Array()
	if shape == Shape.Ellipse:
		for i in range(ellipse_resolution*1.5):
			var p = TAU * (float(i) / ellipse_resolution)
			points.append(Vector2(cos(p) * shape_width/2, sin(p) * shape_height/2))
		pass
	elif shape == Shape.Box:
		for point in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			points.append(shape_width/2.0 * point)
		pass
	return points
