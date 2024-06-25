@tool

extends Node2D


@onready var ne = $HBoxContainer2/NE
@onready var nw = $HBoxContainer2/NW
@onready var sw = $HBoxContainer/SW
@onready var se = $HBoxContainer/SE
@onready var test_parent = $TestParent

@export var print: bool = false:
	set(x):
		print_polys()

# Called when the node enters the scene tree for the first time.
func print_polys():
	for polygon in get_children():
		if polygon is Polygon2D:
			var text = "["
			for point in polygon.polygon:
				text += "Vector2(" + str(point.x) + ", " + str(point.y) + "), " 
			text += "],"
			print(text)

func _on_button_pressed():
	var poly = Shape.marching_squares(ne.button_pressed, nw.button_pressed, sw.button_pressed, se.button_pressed, 10)

	for child in test_parent.get_children():
		child.queue_free()
	print(poly)
	var poly_node = Polygon2D.new()
	
	poly_node.polygon = poly
	test_parent.add_child(poly_node)


func _on_ne_pressed():
	_on_button_pressed()
	pass # Replace with function body.


func _on_nw_pressed():
	_on_button_pressed()
	pass # Replace with function body.


func _on_sw_pressed():
	_on_button_pressed()
	pass # Replace with function body.


func _on_se_pressed():
	_on_button_pressed()
	pass # Replace with function body.
