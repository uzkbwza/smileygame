extends RefCounted

class_name SpatialHashGrid

var cell_size: Vector2
var grid: Dictionary

func _init(cell_size: Vector2) -> void:
	self.cell_size = cell_size
	grid = {}

func _world_to_grid(pos: Vector2) -> Vector2:
	return Vector2(floor(pos.x / cell_size.x), floor(pos.y / cell_size.y))

func add_object(obj: Variant, pos: Vector2) -> void:
	var grid_pos = _world_to_grid(pos)
	if not grid.has(grid_pos):
		grid[grid_pos] = []
	grid[grid_pos].append(obj)

func add_object_rect(obj: Variant, rect: Rect2) -> void:
	var start_pos = _world_to_grid(rect.position)
	var end_pos = _world_to_grid(rect.position + rect.size)
	
	for x in range(start_pos.x, end_pos.x + 1):
		for y in range(start_pos.y, end_pos.y + 1):
			var grid_pos = Vector2(x, y)
			if not grid.has(grid_pos):
				grid[grid_pos] = []
			grid[grid_pos].append(obj)

func search_region(area: Rect2) -> Array:
	var start_pos = _world_to_grid(area.position)
	var end_pos = _world_to_grid(area.position + area.size)
	var objects_in_area = []

	for x in range(start_pos.x, end_pos.x + 1):
		for y in range(start_pos.y, end_pos.y + 1):
			var grid_pos = Vector2(x, y)
			if grid.has(grid_pos):
				objects_in_area.append_array(grid[grid_pos])
				
	return objects_in_area
