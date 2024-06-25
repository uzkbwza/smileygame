extends RefCounted

class_name CurveTween

var curve
var tween
var object

func _init(object: Node, curve: Curve):
	self.tween = object.create_tween()
	self.curve = curve
	self.object = object

