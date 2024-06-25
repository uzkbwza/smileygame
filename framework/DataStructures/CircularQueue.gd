class_name CircularQueue

# efficient fixed-length queue

var arr: Array 
var length = 0
var write_pos = 0 # points to where the next element will be inserted
var read_pos = 0 # points to where the next element will be inserted

var _cursor = 0

func _init(length: int, default=null):
	assert(length > 0)
	length = length + 1
	self.length = length
	arr = []
	arr.resize(length)
	if default != null:
		for i in range(length):
			arr[i] = default

func queue(item) -> bool:
	if (write_pos + 1) % length == read_pos:
		return false
	arr[write_pos] = item
	write_pos = (write_pos + 1) % length
	return true

func peek() -> Variant:
	if read_pos == write_pos:
		return null
	var value = arr[read_pos]
	return value

func dequeue() -> Variant:
	if read_pos == write_pos:
		return null
	var value = arr[read_pos]
	read_pos = (read_pos + 1) % length
	return value

func _iter_init(_arg) -> bool:
	return should_continue()

func _iter_next(_arg) -> bool:
	return should_continue()

func _iter_get(_arg) -> Variant:
	return dequeue()

func should_continue() -> bool:
#	return !((_cursor) % length == write_pos)
	return read_pos != write_pos
