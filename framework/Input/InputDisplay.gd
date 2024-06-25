extends Node2D

const LINE_LENGTH = 100
const HISTORY = 20
const STICK_DIST = 64.0

var input: InputState
var stick_positions = []

@onready var sprite_2d = $Sprite2D

@onready var label: Label = $Label

var lines = []

func update(input: InputState):
	self.input = input
	queue_redraw()

func _draw():
	if input == null:
		return
	var dir = Vector2i()
	if input.left > 0:
		dir.x -= 1
	if input.right > 0:
		dir.x += 1
	if input.up > 0:
		dir.y -= 1
	if input.down > 0:
		dir.y += 1
#	var display_dir = Vector2(dir).normalized()
	var display_dir = Vector2(dir)
	
	display_dir = (display_dir.normalized() + display_dir) / 2.0
	
	var p = input.punch > 0
	var k = input.kick > 0

	draw_circle(Vector2(), 16, Color.BLACK)
	
#	print(pow(0.999 / 100000000.0, get_process_delta_time()))
	
	sprite_2d.position = sprite_2d.position.lerp(STICK_DIST * display_dir, pow(0.9 / 1000.0, get_process_delta_time()) * 0.5)
	draw_line(Vector2(), sprite_2d.position, Color.BLACK, 20.0, false)	
	
	draw_circle(Vector2(180, -38), 32, Color.RED if p else Color.DARK_RED)
	draw_circle(Vector2(190, 30), 32, Color.BLUE if k else Color.DARK_BLUE)
	
	stick_positions.append(STICK_DIST * display_dir)
	if stick_positions.size() > LINE_LENGTH:
		stick_positions.pop_front()
		for point in stick_positions:
			draw_circle(point, 8.0, Color.WHITE)
	draw_polyline(PackedVector2Array(stick_positions), Color.WHITE, 8.0, false)
	
	var dir_to_text = {
		Vector2i(0, 0): "",
		Vector2i(0, -1): "↑ ",
		Vector2i(1, -1): "↗ ",
		Vector2i(1, 0): "→ ",
		Vector2i(1, 1): "↘ ",
		Vector2i(0, 1): "↓ ",
		Vector2i(-1, 1): "↙ ",
		Vector2i(-1, 0): "← ",
		Vector2i(-1, -1): "↖ ",
	}
	
	var dir_text = dir_to_text[dir] + ("P" if p else "") + ("K" if k else "") + "\n"
	if lines == [] or lines[0] != dir_text:
		lines.push_front(dir_text)
		if lines.size() > HISTORY:
			lines.pop_back()
	
	label.text = ""
	for line in lines:
		label.text += line
