class_name Map2D
# 2d array

extends Array2D

var open_spaces = []
var closed_spaces = []

enum Space {
	Floor = 0,
	Wall = 1,
	Unknown = 2,
}

func _init(w, h):
	super._init(w, h, Space.Wall)

func is_blocking(tile):
	return tile == Space.Wall or tile == Space.Unknown

func is_position_blocking(pos: Vector2i):
	return !contains_v(pos) or is_blocking(get_cell_v(pos))

func set_cell(x, y, value, set_used=true):
	super.set_cell(x, y, value, set_used)
	if value == Space.Floor:
		open_spaces.append(Vector2i(x, y))
	elif value == Space.Wall:
		closed_spaces.append(Vector2i(x, y))

func walls():
	for i in range(length):
		var xy = id_to_xy(i)
		set_cell_v(xy, Space.Wall)
		closed_spaces.append(xy)
	return self

func floors():
	for i in range(length):
		var xy = id_to_xy(i)
		set_cell_v(xy, Space.Floor)
		open_spaces.append(xy)
	return self
	
func unknown():
	for i in range(length):
		var xy = id_to_xy(i)
		set_cell_v(xy, Space.Unknown, false)
		open_spaces.append(xy)
	return self

func print_map():
	for row in height:
		var line = ""
		for col in width:
			line += "# " if get_cell(col, row) == Space.Floor else ". "
		print(line)
