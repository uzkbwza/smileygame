class_name CircularBuffer

var arr: Array 
var length = 0
var write_pos = 0 # points to where the next element will be inserted

var _cursor = 0

func _init(length: int, default=null):
	assert(length > 0)
	self.length = length
	arr = []
	arr.resize(length)
	if default != null:
		for i in range(length):
			arr[i] = default

func write(item):
	arr[write_pos] = item
	write_pos = (write_pos + 1) % length

func read(i=-1):
	if i == -1:
		i = write_pos
	return arr[i % length]

func _iter_init(_arg):
	_cursor = 0
	return should_continue()

func _iter_next(_arg):
	_cursor = (_cursor + 1)
	return should_continue()

func _iter_get(_arg):
	return arr[(_cursor + write_pos) % length]

func should_continue():
	return (_cursor) < length

func get_buffer():
	var values = []
	for value in self:
		values.append(value)
	return values
