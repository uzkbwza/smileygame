extends DGGenerator

class_name DGDrunkardsWalk

var _walk_length: int
var _num_walks: int = 1
var _starts_from_center = false
var _diagonals = false
var _prefer_digging_new_walls = false
var _new_direction_chance = null
var _random_dir_always_different = false
var map
var pos

func set_walk_length(wl: int) -> void:
	_walk_length = wl

func set_num_walks(nw: int) -> void:
	_num_walks = nw

func new_direction_chance(amount):
	_new_direction_chance = amount

func prefer_digging_new_walls():
	_prefer_digging_new_walls = true

func start_from_center() -> void:
	_starts_from_center = true

func diagonal_walking() -> void:
	_diagonals = true

func generate():
	map = Map2D.new(width,height).walls()
	if _starts_from_center:
		pos = Vector2i(width/2, height/2)
	else:
		pos = Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
	var last_nearby_walls = []
	var positions = [pos]
	var starting_dirs = cardinal_dirs.duplicate()
	if _diagonals:
		starting_dirs.append_array(diagonal_dirs.duplicate())
	var dir = starting_dirs[rng.randi_range(0, starting_dirs.size() - 1)]
	var change_dir_chance
	if _new_direction_chance:
		change_dir_chance = _new_direction_chance
	elif !_diagonals:
		change_dir_chance = 0.75
	else:
		change_dir_chance = 0.825
	for i in range(_walk_length):
		map.set_cell_v(pos, Map2D.Space.Floor)
		if rng.randf_range(0, 1) < change_dir_chance:
			var new_dir = rng.random_dir(_diagonals)
			while new_dir == dir:
				new_dir = rng.random_dir(_diagonals)
			dir = new_dir
		if _prefer_digging_new_walls:
			var nearby_walls = []
			var spaces_to_check = cardinal_dirs.duplicate()
			if _diagonals:
				spaces_to_check.append_array(diagonal_dirs.duplicate())
			if map.get_cell(min((pos + dir).x, width - 1), min((pos + dir).y, height - 1)) == Map2D.Space.Floor:
				for new_dir in spaces_to_check:
					var new_pos = pos + new_dir
					new_pos.x = clampi(new_pos.x, 1, width - 2)
					new_pos.y = clampi(new_pos.y, 1, height - 2)
					if map.get_cell(new_pos.x, new_pos.y) == Map2D.Space.Wall:
						nearby_walls.append(new_dir)
				if nearby_walls:
					dir = nearby_walls[rng.randi_range(0, nearby_walls.size() - 1)]
					for wall in nearby_walls:
						last_nearby_walls.append(wall + pos)
				else:
					last_nearby_walls.shuffle()
					for wall in last_nearby_walls:
						if map.get_cell(min(wall.x, width-1), min(wall.y, height-1)) == Map2D.Space.Wall:
							pos = wall
							pos.x = clampi(pos.x, 1, width - 2)
							pos.y = clampi(pos.y, 1, height - 2)
							map.set_cell_v(pos, Map2D.Space.Floor)
							break
		var new_pos = pos
		new_pos += dir
		new_pos.x = clampi(new_pos.x, 1, width - 2)
		new_pos.y = clampi(new_pos.y, 1, height - 2)
		if new_pos == pos:
			dir = rng.random_dir(_diagonals)
		pos = new_pos
		positions.append(pos)
#		if _debug and _host:
#			await _host.get_tree().process_frame
#			await _host.get_tree().process_frame
#			pass
