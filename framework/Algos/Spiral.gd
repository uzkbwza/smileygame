extends RefCounted

class_name Spiral

static func generate(size: int, flip_x: bool = false, flip_y: bool = false) -> Array[Vector2i]:
	var dx: int = 1
	var dy: int = 0
	var dx_mod = 1 if !flip_x else -1
	var dy_mod = 1 if !flip_y else -1
	var length = 1 # segment length
	var x: int = 0
	var y: int = 0
	var passed: int = 0 # segment passed
	var counter: int = 0
	var end: int = size * size
	var arr: Array[Vector2i] = []
	
	while counter < end:
		arr.append(Vector2(x, y))
		x += dx * dx_mod
		y += dy * dy_mod
		passed += 1
		if passed == length:
			# done with current segment
			passed = 0
			var temp = dx
			dx = -dy
			dy = temp
			# we've made a full rotation, increase length
			if dy == 0:
				length += 1
		counter += 1
	
	return arr
