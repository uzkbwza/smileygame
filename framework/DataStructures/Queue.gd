class_name Queue

# simple dynamic length queue made with a linked list

class QueueNode:
	var value
	var next

var start: QueueNode = null
var end: QueueNode = null

func queue(value) -> void:
	var next = QueueNode.new()
	next.value = value
	if start == null:
		start = next
		end = start
		return
	end.next = next
	end = next

func dequeue() -> Variant:
	if start == null:
		return null
	var value = start.value
	if start.next:
		start = start.next
		return value
	start = null
	return value

func _iter_init(_arg) -> bool:
	return should_continue()

func _iter_next(_arg) -> bool:
	return should_continue()

func _iter_get(_arg) -> Variant:
	return dequeue()

func should_continue() -> bool:
#	return !((_cursor) % length == write_pos)
	return start != null
