class_name InputBuffer

var buffer: Array
var write_pos = 0
var length = 0
var last:
	get:
		return read_all()[length - 1]
	set(value):
		buffer[((length - 1) + write_pos) % length] = value

func _init(length: int, default = null):
	buffer = []
	self.length = length
	for i in range(length):
		buffer.append(default)

func write(value: Variant) -> void:
	buffer[write_pos] = value
	write_pos = (write_pos + 1) % length

func read_all() -> Array:
	var arr: Array = []
	for i in range(length):
		arr.append(buffer[(i + write_pos) % length])
	return arr
