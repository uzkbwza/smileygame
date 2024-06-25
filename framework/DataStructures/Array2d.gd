class_name Array2D
# 2d array

var arr: Array = []
var width
var height
var length
var default
var used_cells: Dictionary

# iterator cursor
var _cursor = 0

func _init(w, h, default=null):
	self.width = w
	self.height = h
	self.length = w * h
	self.default = default
	clear()

func clear() -> void:
	if default == null:
		for i in range(height):
			var row = []
			row.resize(width)
			arr.append(row)
	else:
		for i in range(height):
			var row = []
			for _j in range(width):
				row.append(default)
			arr.append(row)
	used_cells = {}

func get_cell(x, y):
	if !contains(x, y):
		return self.default
	var value = arr[y][x]
	if value == null:
		used_cells.erase(Vector2i(x, y))
	return value

func get_cell_v(xy: Vector2i):
	return get_cell(xy.x, xy.y)

func get_cell_v_unsafe(xy: Vector2i):
#	if contains(xy.x, xy.y):
	return arr[xy.y][xy.x]

func get_cell_unsafe(x: int, y: int):
#	if contains(xy.x, xy.y):
	return arr[x][y]

func contains(x: int, y: int) -> bool:
	return !(x >= width or x < 0 or y >= height or y < 0)

func contains_v(xy: Vector2i) -> bool:
	return contains(xy.x, xy.y)

func set_cell(x: int, y: int, value, set_used=true) -> void:
	arr[y][x] = value
	if set_used and value != null:
		used_cells[Vector2i(x, y)] = value

func neighbors(cell: Vector2i, diagonal=false) -> Array[Vector2i]:
	var dirs = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	if diagonal:
		dirs.append_array([Vector2i(1, 1),Vector2i(1, -1),Vector2i(-1, -1),Vector2i(-1, 1)])
	var points: Array[Vector2i] = []
	for dir in dirs:
		var x = dir.x
		var y = dir.y
		var neighbor = Vector2i(cell.x + x, cell.y + y)
		if neighbor.x < 0 or neighbor.x >= width or neighbor.y < 0 or neighbor.y >= height:
			continue
		points.append(neighbor)
	return points

func set_cell_v(v, value, set_used=true):
	set_cell(v.x, v.y, value, set_used)

func _iter_init(_arg):
	_cursor = 0
	return _cursor < length

func _iter_next(_arg):
	_cursor += 1
	return _cursor < length

func _iter_get(_arg):
	return arr[_cursor % width][_cursor / height]

func used() -> Array:
	var tiles = []
	for id in used_cells.keys():
		var tile = arr[id.y][id.x]
		if tile != null:
			tiles.append(tile)
	return tiles

func rows() -> Array:
	return arr

func used_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for id in used_cells.keys():
		if arr[id.y][id.x] != null:
			positions.append(id)
	return positions

func positions() -> Array:
	var positions = []
	for x in range(width):
		for y in range(height):
			positions.append(Vector2i(x, y))
	return positions

func id_to_xy(id, width=self.width, height=self.height) -> Vector2i:
	return Vector2i(id % width, (id / width) % height)

func xy_to_id(x: int, y: int) -> int:
	return (y * width) + x

func v_to_id(v: Vector2i) -> int:
	return (v.y * width) + v.x
