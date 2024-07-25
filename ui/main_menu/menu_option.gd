extends Node2D

class_name MainMenuOption

@onready var label: Label = %Label
@onready var color_rect: Control = $Node2D/ColorRect
@onready var color_rect_2: Panel = $Node2D/ColorRect2
@onready var font_size = label.get("theme_override_font_sizes/font_size")
@onready var color_rect_active: Panel = $Node2D/ColorRectActive
@onready var color_rect_y = color_rect.size.y

var active := false
@onready var size : float = 1.0
var rect_size := 1.0

var startup := false

var is_hidden := false

func set_startup(startup: bool):
	self.startup = startup

func _ready():
	set_active(false)
	set_size(0.0)
	update_stuff(10.0)

func set_text(text: String) -> void:
	label.text = text

func set_active(active: bool):
	#if active == self.active:
		#return
	self.active = active

func _process(delta: float) -> void:
	if is_hidden:
		return
	update_stuff(delta)
	color_rect_2.size = color_rect.size
	color_rect_2.modulate.a = color_rect.modulate.a
	color_rect_2.position = color_rect.position + Vector2(2, 2)
	color_rect_active.size = color_rect.size
	color_rect_active.position = color_rect.position

func set_hidden(is_hidden: bool):
	self.is_hidden = is_hidden

func set_size(size: float):
	if is_hidden:
		return
	self.size = size
	label.set("theme_override_font_sizes/font_size", font_size * size ** 1.1)

func update_stuff(delta: float) -> void:
	if is_hidden:
		return
	if active:
		var label_color = Color("e8fd4d") 
		#var rect_color = Color("fd4d4f")
		label.modulate = Math.splerp_color(label.modulate, label_color, delta, 1.0)
		#color_rect.modulate.a = Math.splerp(color_rect.modulate.a, 1.0, delta, 2.0)
		#color_rect.modulate = Math.splerp_color(color_rect.modulate, rect_color, delta, 1.0)
		#color_rect_2.modulate = Math.splerp_color(color_rect.modulate, rect_color, delta, 1.0)
		color_rect_active.modulate.a = Math.splerp(color_rect_active.modulate.a, 1.0, delta, 2.0)
		color_rect.size.x = Math.splerp(color_rect.size.x, 450.0 * size * (0 if startup else 1.0), delta, 2.0)
		#color_rect.size.y = Math.splerp(color_rect.size.y, color_rect_y, delta, 2.0)
	else:
		var label_color = Color("ceeaea") 
		#var rect_color = Color("fd4d4f")
		#label_color.a = 0.6
		#rect_color.a = 0.0
		label.modulate = Math.splerp_color(label.modulate, label_color, delta, 5.0)
		#color_rect.modulate.a = Math.splerp(color_rect.modulate.a, 0.0, delta, 4.0)
		#color_rect_2.modulate = Math.splerp_color(color_rect.modulate, rect_color, delta, 1.0)
		color_rect.size.x = Math.splerp(color_rect.size.x, 200.0 * size ** 1.25 * (0 if startup else 1.0), delta, 1.0)
		#color_rect.size.y = Math.splerp(color_rect.size.y, color_rect_y * size ** 1.5, delta, 1.0)
		color_rect_active.modulate.a = Math.splerp(color_rect_active.modulate.a, 0.4, delta, 5.0)
