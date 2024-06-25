extends Node

class_name Shape

static func line(start: Vector2i, end: Vector2i, order_matters:bool=false) -> Array[Vector2i]:
	# Bresenham's algorithm
	if start.x == end.x or start.y == end.y:
		return straight_line(start, end)
	
	var temp: int
	var x1 :int = (start.x)
	var y1 :int = (start.y)
	var x2 :int = (end.x)
	var y2 :int = (end.y)
	var dx :int = x2 - x1
	var dy :int = y2 - y1
	
	var steep: int = absi(dy) > absi(dx)
	if steep:
		temp = x1
		x1 = y1
		y1 = temp
		temp = x2
		x2 = y2
		y2 = temp

	var swapped := false

	if x1 > x2:
		temp = x1
		x1 = x2
		x2 = temp
		temp = y1
		y1 = y2
		y2 = temp
		swapped = true
		
	dx = x2 - x1
	dy = y2 - y1
	var error: int = int(dx / 2.0)
	var ystep := 1 if y1 < y2 else -1
	var y :int = y1
	var points: Array[Vector2i] = []
	for x in range(x1, x2 + 1):
		points.append(Vector2i(y, x) if steep else Vector2i(x, y))
		error = error - absi(dy)
		if error < 0:
			y += ystep
			error += dx
	if swapped and order_matters:
		points.reverse()

	return points

static func straight_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	assert(start.x == end.x or start.y == end.y)
	if start.y == end.y:
		for x in range(min(start.x, end.x), max(start.x, end.x)):
			points.append(Vector2i(x, start.y))
		return points
	for y in range(min(start.y, end.y), max(start.y, end.y)):
		points.append(Vector2i(start.x, y))
	return points 

static func random_triangle_point(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	return a + sqrt(randf()) * (-a + b + randf() * (c - b))

static func triangle_area(a: Vector2, b: Vector2, c: Vector2):
	var ba: Vector2 = a - b
	var bc: Vector2 = c - b
	return abs(ba.cross(bc)/2)

static func get_polygon_tris(polygon: PackedVector2Array) -> Array[Array]:
	var points := Geometry2D.triangulate_polygon(polygon)
	var size := polygon.size()
	var tris : Array[Array] = []
	for i in range(0, points.size(), 3):
		tris.append([polygon[points[i]], polygon[points[i + 1]], polygon[points[i + 2]]])
	return tris

static func get_polygon_area(polygon: PackedVector2Array):
	var area := 0.0
	for tri in get_polygon_tris(polygon):
		area += triangle_area(tri[0], tri[1], tri[2])
	return area

static func get_polygon_bounding_box(polygon: PackedVector2Array) -> Rect2:
	var top_left := Vector2(INF, INF)
	var bottom_right := Vector2(-INF, -INF)
	for point in polygon:
		if point.x < top_left.x:
			top_left.x = point.x
		if point.y < top_left.y:
			top_left.y = point.y
		if point.x > bottom_right.x:
			bottom_right.x = point.x
		if point.y > bottom_right.y:
			bottom_right.y = point.y
	return Rect2(top_left, bottom_right - top_left)

static func get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var avg := Vector2()
	for point in polygon:
		avg += point
	return (avg / float(polygon.size()))

static func closest_point_on_line_segment(p: Vector2, q: Vector2, point: Vector2) -> Vector2:
	var ls := (point - p).dot(q - p) / (q - p).dot(q - p)
	var s: Vector2
	if ls <= 0:
		s = p
	elif ls >= 1:
		s = q
	else:
		s = p + ls * (q - p)
	return s
	
static func get_random_point_in_polygon(polygon: PackedVector2Array, rng: BetterRng, num_points = 1, min_distance_between_points=0):
	var tris := get_polygon_tris(polygon)
	if tris.size() == 0:
		return Vector2()
	var get_point = (func():
		var tri = rng.func_weighted_choice(tris, func(t): return triangle_area(tris[t][0], tris[t][1], tris[t][2]))
		return random_triangle_point(tri[0], tri[1], tri[2]))
	if num_points == 1:
		return get_point.call()
	else:
		var chosen_points := []
		if min_distance_between_points == 0:
			for i in range(num_points):
				chosen_points.append(get_point.call())
		else:
			var quad_tree = QuadTree.new(get_polygon_bounding_box(polygon), 1)
			var max_try_count := 0
			for i in range(num_points):
				var tries := 0
				var valid_point := false
				var point: Vector2
				var max_tries := 1000
				while tries == 0 or !(valid_point or tries >= max_tries):
					point = get_point.call()
					if chosen_points.is_empty():
						valid_point = true
					else:
						valid_point = true
						for nearby_point in quad_tree.search(point, min_distance_between_points, min_distance_between_points):
							if point.distance_to(nearby_point) < min_distance_between_points:
								valid_point = false
					tries += 1
					if tries >= max_tries:
						max_try_count += 1
#					Debug.dbg_max("tries", tries)
				quad_tree.insert(point)
#					print("didnt insert point into tree")
#				print("acquired point %d" % i)
				chosen_points.append(point)
#				Debug.dbg("max_try_count", max_try_count)
		return chosen_points

static func marching_squares(nw: bool, ne: bool, se: bool, sw: bool, size = 1) -> PackedVector2Array:
	var case = (int(ne) * 8) | (int(nw) * 4) | (int(sw) * 2) | (int(se))
#	print(case)
	var polys = [
		[],
		[Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1), ],
		[Vector2(1, 1), Vector2(1, 0), Vector2(0, 1), ],
		[Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 1), Vector2(0, 1), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 1), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 0), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), ],
		[Vector2(-1, 0), Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(0, 1), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), ],
	]
	var result = polys[case]
	for i in range(result.size()):
		var point = result[i]
		point *= size
		result[i] = point

	return PackedVector2Array(result)
