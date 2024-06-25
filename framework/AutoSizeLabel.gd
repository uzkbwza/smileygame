@tool
class_name AutoSizeLabel extends Label


@export var max_font_size = 56


func _ready() -> void:
	clip_text = true
	item_rect_changed.connect(_on_item_rect_changed)


func _set(property: StringName, value: Variant) -> bool:
	match property:
		"text":
			# listen for text changes
			update_font_size()

	return false


func update_font_size() -> void:
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")

	var line = TextLine.new()
	line.direction = text_direction
	line.flags = justification_flags
	line.alignment = horizontal_alignment

	for i in 20:
		line.clear()
		var created = line.add_string(text, font, font_size)
		if created:
			var text_size = line.get_line_width()

			if text_size > floor(size.x):
				font_size -= 1
			elif font_size < max_font_size:
				font_size += 1
			else:
				break
		else:
			push_warning('Could not create a string')
			break

	add_theme_font_size_override("font_size", font_size)


func _on_item_rect_changed() -> void:
	update_font_size()
