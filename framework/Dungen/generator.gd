class_name DGGenerator

var width: int
var height: int
var _host: Node
var _debug: bool = false
var rng
signal took_step()
signal updated_map(map)
var cardinal_dirs = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
var diagonal_dirs = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]

func _init(width: int, height: int, rng: BetterRng):
	self.width = width
	self.height = height
	self.rng = rng
	pass

func step():
	if _debug:
		took_step.emit()

func set_debug(debug: bool = true) -> void:
	_debug = debug

func set_host(host: Node) -> void:
	_host = host

func generate() -> void:
	return Map2D.new(width, height).floors()
