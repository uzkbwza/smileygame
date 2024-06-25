@tool
extends EditorPlugin

const SNAP = 0.5

var current_rect: Rect2Node

var anchors : Array

var drag_start : Dictionary = {
	'size': Vector2(),
}

var mouse_held = false

func _make_visible(visible: bool) -> void:
	if not current_rect:
		return
	
	if not visible:
		current_rect = null
	
	update_overlays()

# Consumes InputEventMouseMotion and forwards other InputEvent types.
func _forward_canvas_gui_input(event) -> bool:
	if not current_rect or not current_rect.visible:
		return false
	
	# Clicking and releasing the click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not mouse_held and event.is_pressed():
			print(event.position)
			for anchor in anchors:
				if not anchor['rect'].has_point(event.position):
					continue
				mouse_held = true
				print("Drag start: %s" % mouse_held)
				drag_start = { 'size': current_rect.size }
				return true

		elif mouse_held and not event.is_pressed():
			drag_to(event.position)
			mouse_held = false
			var undo := get_undo_redo()
			undo.create_action("Move anchor")
		
			undo.add_do_property(current_rect, "size", current_rect.size)
			undo.add_undo_property(current_rect, "size", drag_start['size'])
		
			undo.commit_action()
			return true
	
	if not mouse_held:
		return false
	
	# Dragging
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		drag_to(event.position)
		update_overlays()
		return true
	# Cancelling with ui_cancel
	if event.is_action_pressed("ui_cancel"):
		mouse_held = null
		return true
	return false


func drag_to(event_position: Vector2) -> void:
	if not mouse_held:
		return
	# Calculate the position of the mouse cursor relative to the RectExtents' center
	var viewport_transform_inv := current_rect.get_viewport().get_global_canvas_transform().affine_inverse()
	var viewport_position: Vector2 = viewport_transform_inv * (event_position)
	viewport_position.x = snappedf(viewport_position.x, SNAP)
	viewport_position.y = snappedf(viewport_position.y, SNAP)
	var transform_inv := current_rect.get_global_transform().affine_inverse()
	var target_position : Vector2 = transform_inv * (viewport_position)
	# Update the rectangle's size. Only resizes uniformly around the center for now
	var target_size = (target_position).abs() * 2.0
	current_rect.size = target_size
	current_rect.recalculate_rect()

func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	if current_rect == null:
		return
	if not current_rect or not current_rect.is_inside_tree():
		return
	
	var pos = current_rect.position
	var half_size : Vector2 = current_rect.size / 2.0
	# Top-Left, Top-Right, Bottom-Right, Bottom-Left
	var edit_anchors : Array = [
		pos - half_size,
		pos + Vector2(half_size.x, half_size.y * -1.0),
		pos + Vector2(half_size.x * -1.0, half_size.y),
		pos + half_size,
	]

	var transform_viewport := current_rect.get_viewport_transform()
	var transform_global := current_rect.get_canvas_transform()
	
	anchors = []
	
	# add all corners anchors
	for coord in edit_anchors:
		var anchor_center : Vector2 = transform_viewport * (transform_global * coord)
		var new_anchor : RectAnchor = RectAnchor.new(anchor_center)
		new_anchor.draw(viewport_control, current_rect.stroke_color)
		anchors.append(new_anchor)


func _edit(object: Object) -> void:
	current_rect = object

func _handles(object: Object) -> bool:
	return (object is Rect2Node)

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
