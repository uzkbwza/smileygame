@tool
class_name MonoBuildToggler
extends HBoxContainer

signal on_toggled(new_value)


func _on_ToggleButton_toggled(button_pressed: bool) -> void:
	on_toggled.emit(button_pressed)


func set_enabled(value: bool):
	$ToggleButton.set_pressed_no_signal(value)
