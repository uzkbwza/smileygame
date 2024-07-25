@tool

extends Polygon2D

class_name TerrainShape

const SHADOW_OFFSET = Vector2(16, 16)

@export var copy_to: TerrainShape:
	set(value):
		if !Engine.is_editor_hint():
			return
		for child in value.get_children():
			child.queue_free()
		value.border = border
		value.border_z = border_z if border_z != null else 0
		value.offset_border = offset_border
		value.border_offset = border_offset
		value.texture = texture
		if value.border:
			value.create_border()
		copy_to = null

@export var copy_from: TerrainShape:
	set(value):
		if !Engine.is_editor_hint():
			return
		if value:
			value.copy_to = self

@export var center: bool:
	set(value):
		if value:
			center = false
			center_points()

@export var center_root: bool:
	set(value):
		if value:
			center_root = false
			move_root_to_center()

@export var reset_transform: bool:
	set(value):
		if value:
			reset_transform = false
			do_reset_transform()

@export var reset_root: bool:
	set(value):
		if value:
			reset_root = false
			move_root_to_origin()

#@export var invert: bool:
	#set(value):
		#if value:
			#invert = false
			#invert_border_()

@export var border: Texture2D
	#set(value):
		#border = valueK
@export var border_z = 0

@export var offset_border = true
@export_range(-16.0, 16.0, 0.5) var border_offset: float = 2.0

@export_flags_2d_physics var collision_layer = 1

@export var force_create_physics_body := false
@export var create_shadow := true


var border_node = null
var child_poly = null
var body: PhysicsBody2D

#var line_in_front := true

var previous

func invert_border_():
	var new_poly = polygon
	new_poly.reverse()
	polygon = new_poly

func center_points():
		var current_center = Shape.get_polygon_center(polygon)
		var move = (global_position - to_global(current_center))
		var new_points = Shape.move_polygon(polygon, move)
		polygon = new_points

func do_reset_transform():
	polygon = Transform2D(rotation, scale, 0.0, position) * polygon
	rotation *= 0
	position *= 0
	scale = Vector2.ONE
	pass

func move_root_to_center():
	var current_center = Shape.get_polygon_center(polygon)
	global_position = to_global(current_center)
	center_points()
	
func move_root_to_origin():
		var move = (position)
		var new_points = Shape.move_polygon(polygon, move)
		polygon = new_points
		position *= 0.0

func _ready():
	if Engine.is_editor_hint():
		for child in get_children():
			child.queue_free()
		do_reset_transform()
	else:
		set_process(false)
		if force_create_physics_body:
			create_physics_body.call_deferred()
	if create_shadow or Engine.is_editor_hint():
		var shadow = get_shadow_polygon()
		add_child.call_deferred(shadow)
		shadow.color.a = SmileyLevel.SHADOW_COLOR.a
		shadow.position = SHADOW_OFFSET
	elif get_parent().get_meta("is_mover", false):
		push_warning("moving terrain object has no shadow at %s" % get_path())
	#TODO: inner infill polygon
	self_modulate.a = 1.0
	if border:
		create_border.call_deferred()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if border_node:
			if border_node.points != previous:
				update_border()
			else:
				previous = border_node.points if border_node else null
			if border == null:
				border_node.queue_free()
		elif border:
			create_border()

func update_border():
	if Engine.is_editor_hint():
		if polygon:	
			for i in polygon.size():
				var p = to_global(polygon[i])
				polygon[i] = to_local(Vector2(Math.stepify(p.x, 16), Math.stepify(p.y, 16)))
		if Geometry2D.is_polygon_clockwise(polygon):
			invert_border_()
	
	if border == null:
		border_node.queue_free()
		if child_poly:
			child_poly.queue_free()
			self_modulate.a = 1.0
	border_node.width = border.get_height()
	border_node.points = Geometry2D.offset_polygon(polygon, -(border_offset))[0]
	border_node.joint_mode = Line2D.LINE_JOINT_SHARP
	border_node.sharp_limit = 10000
	#border_node.points = polygon
	border_node.texture_mode = Line2D.LINE_TEXTURE_TILE
	border_node.z_index = border_z if border_z != null else 0
	#if border_z == null:
		#border_z = 0
	border_node.texture_repeat = false
	border_node.closed = true
	border_node.z_as_relative = true
	border_node.texture = border
	if child_poly:
		child_poly.z_as_relative = true
		child_poly.polygon = Geometry2D.offset_polygon(border_node.points, (border_offset))[0]
		child_poly.texture = texture

func create_border():
	var line = Line2D.new()
	border_node = line
	child_poly = Polygon2D.new()
	child_poly.texture = texture
	child_poly.color = color
	self_modulate.a = 0.0
	add_child(child_poly)
	add_child(line)
	update_border()

func create_physics_body():
	body = KinematicObject2D.new()
	body.z_index += 1
	body.collision_layer = collision_layer
	var collision_polygon_2d = CollisionPolygon2D.new()
	#collision_polygon_2d.polygon = polygon if child_poly == null else child_poly.polygon
	collision_polygon_2d.polygon = polygon
	add_child(body)
	body.add_child(collision_polygon_2d)

func get_shadow_polygon():
	var shape = Polygon2D.new()
	shape.polygon = polygon if border_node == null else border_node.points if offset_border else polygon
	shape.texture_repeat = true
	shape.texture = texture
	shape.color = Color.BLACK
	shape.global_position = global_position + SHADOW_OFFSET
	shape.z_as_relative = true
	shape.z_index = -10
	return shape

func get_shadow_border():
	if border_node == null:
		return null
	var line = Line2D.new()
	line.width = border_node.width
	line.points = border_node.points
	line.joint_mode = border_node.joint_mode
	line.sharp_limit = border_node.sharp_limit
	#border_node.points = polygon
	line.texture_mode = border_node.texture_mode
	line.z_index = border_node.z_index
	line.texture_repeat = border_node.texture_repeat
	line.closed = border_node.closed
	line.z_as_relative = border_node.z_as_relative
	line.texture = border_node.texture
	#line.default_color = Color.BLACK
	line.global_position = global_position + SHADOW_OFFSET
	return line
