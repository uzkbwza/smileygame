extends DGGenerator

class_name DGSimpleRooms

var _min_num_rooms
var _max_num_rooms

func set_num_rooms(min: int, max: int):
	_min_num_rooms = min
	_max_num_rooms = max

func generate() -> void:
	pass
