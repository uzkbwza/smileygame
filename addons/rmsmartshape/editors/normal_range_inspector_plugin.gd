extends EditorInspectorPlugin

var control: Control = null


func _can_handle(object: Object) -> bool:
	#if object is SS2D_NormalRange:
	#	return true
	if object is SS2D_NormalRange:
		#Connect
		var parms = [object]
		if not object.is_connected("changed", self._changed):
			object.connect("changed", self._changed.bind(parms))
		return true
	else:
		#Disconnect
		if control != null:
			control = null

		if object.has_signal("changed"):
			if object.is_connected("changed", self._changed):
				object.disconnect("changed", self._changed)
		pass

	return false


func _changed(_object) -> void:
	control._value_changed()


func _parse_property(
	_object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags,
	_wide: bool
) -> bool:
	if name == "edgeRendering":
		control = SS2D_NormalRangeEditorProperty.new()
		add_property_editor(" ", control)
		return true
	return false

