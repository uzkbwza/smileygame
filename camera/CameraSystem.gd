extends Node2D

class_name CameraSystem

const CAMERA_TARGET_SPLERP_HALF_LIFE = 0.5

@onready var camera: GoodCamera = %Camera
@onready var camera_zones: Array[CameraZone] = []
@onready var camera_target: Marker2D = %CameraTarget
@onready var player: SmileyPlayer = %Smiley

var death_height := 0
var init = false

#var current_camera_zone: CameraZone
#var prev_camera_zone: CameraZone

var overlapping_zones: Array[CameraZone] = []

func _ready() -> void:
	for zone in %CameraZones.get_children():
		camera_zones.append(zone)
		for neighbor in %CameraZones.get_children():
			if zone != neighbor:
				zone.try_add_neighbor(neighbor)
	camera.global_position = camera_target.global_position
	camera.global_position = player.global_position
	camera_target.reset_physics_interpolation()
	camera.reset_physics_interpolation()

	await get_tree().create_timer(0.4).timeout
	init = true


func _process(delta: float) -> void:
	if not player:
		return
		
	var in_zone = false
	
	var p_pos = player.global_position
	var c_pos = player.camera_target.global_position

	overlapping_zones.clear()
	var closest_zone: CameraZone
	#var closest_dist: float = INF 
	for z in camera_zones:
		if z.point_within_rect(p_pos):
			in_zone = true
			#var dist = p_pos.distance_squared_to(z.center)
			#if dist < closest_dist:
				#closest_dist = dist
				#zone = z
			overlapping_zones.append(z)

	Utils.sort_array_by_distance(overlapping_zones, p_pos)
	#
	#if zone != current_camera_zone:
		#prev_camera_zone = current_camera_zone
		#current_camera_zone = zone
		#camera_target_y = camera_target.global_position.y
	#elif prev_camera_zone == null:
		#camera_target_y = p_pos.y
	#
	#Debug.dbg("last_zone", prev_camera_zone.get_instance_id() if prev_camera_zone else null)
	#Debug.dbg("curr_zone", current_camera_zone.get_instance_id() if current_camera_zone else null)
	
	Debug.dbg("overlapping zones", overlapping_zones.size())
	camera.limit_bottom = 1000000
	camera.limit_top = -1000000
	camera.limit_left = -1000000
	camera.limit_right = 1000000
	if in_zone:
		var new_camera_target_pos: Vector2 = Vector2()
		var zone = overlapping_zones[0]
		var center := Vector2()
		center.x = clamp(c_pos.x, zone.left + Global.viewport_size.x / 2.0, zone.right - Global.viewport_size.x / 2.0)
		center.y = clamp(c_pos.y, zone.top + Global.viewport_size.y / 2.0, zone.bottom - Global.viewport_size.y / 2.0)
		
		var horiz_target = Vector2()
		var vert_target = Vector2()

		if zone.point_within_padding(p_pos):
			new_camera_target_pos = center
			if !init:
				camera.limit_bottom = zone.bottom
				camera.limit_top = zone.top
				camera.limit_left = zone.left
				camera.limit_right = zone.right

		else:
			var y = c_pos.y
			var x = c_pos.x
			
			var neighbors = zone.left_neighbors
			if x > center.x:
				neighbors = zone.right_neighbors
			
			if neighbors.size() > 0:
				var closest_neighbor: CameraZone
				var closest_dist = INF
				for neighbor in neighbors:
					var dist = abs(y - neighbor.center.y)
					if dist < closest_dist:
						closest_dist = dist
						closest_neighbor = neighbor
						
				var closest_center = Vector2()
				closest_center.x = clamp(c_pos.x, closest_neighbor.left + Global.viewport_size.x / 2.0, closest_neighbor.right - Global.viewport_size.x / 2.0)
				closest_center.y = clamp(c_pos.y, closest_neighbor.top + Global.viewport_size.y / 2.0, closest_neighbor.bottom - Global.viewport_size.y / 2.0)
				horiz_target.y = (center.y + closest_center.y) / 2.0
				horiz_target.x = (center.x + closest_center.x) / 2.0

			neighbors = zone.top_neighbors
			if y > center.y:
				neighbors = zone.bottom_neighbors

			if neighbors.size() > 0:
				var closest_neighbor: CameraZone
				var closest_dist = INF
				for neighbor in neighbors:
					var dist = abs(x - neighbor.center.x)
					if dist < closest_dist:
						closest_dist = dist
						closest_neighbor = neighbor
						
				var closest_center = Vector2()
				closest_center.x = clamp(c_pos.x, closest_neighbor.left + Global.viewport_size.x / 2.0, closest_neighbor.right - Global.viewport_size.x / 2.0)
				closest_center.y = clamp(c_pos.y, closest_neighbor.top + Global.viewport_size.y / 2.0, closest_neighbor.bottom - Global.viewport_size.y / 2.0)
				vert_target.x = (center.x + closest_center.x) / 2.0
				vert_target.y = (center.y + closest_center.y) / 2.0
				
			if vert_target and horiz_target:
				x = vert_target.lerp(horiz_target, 0.5).x
				y = vert_target.lerp(horiz_target, 0.5).y
			elif vert_target:
				x = vert_target.x
				y = vert_target.y
			elif horiz_target:
				x = horiz_target.x
				y = horiz_target.y
				
			#Debug.dbg("vertical_overlap",  zone.vertical_padding_overlap_amount(p_pos.y))
			var overlap = minf(zone.horizontal_padding_overlap_amount(p_pos.x), zone.vertical_padding_overlap_amount(p_pos.y))
			new_camera_target_pos.x = lerp(x, center.x, overlap)
			new_camera_target_pos.y = lerp(y, center.y, overlap)
			#new_camera_target_pos.y = lerp(p_pos.y, center.y, zone.vertical_padding_overlap_amount(p_pos.y))
			#camera_target.global_position = p_pos
		camera_target.global_position = Math.splerp_vec(camera_target.global_position, new_camera_target_pos, delta, CAMERA_TARGET_SPLERP_HALF_LIFE if !init else 1.0)
	else:
		camera_target.global_position = c_pos
	
	camera.smoothing_enabled = true
	if !init:
		camera.global_position = camera_target.global_position
		camera.smoothing_enabled = false


	#if !in_zone and player.global_position.y < death_height:
		#camera.limit_top = -10000000
		#camera.limit_bottom = 10000000
		#camera.limit_left = -10000000
		#camera.limit_right = 10000000

	camera.limit_bottom = min(camera.limit_bottom, death_height - 32)

	queue_redraw()

func _draw():
	if Engine.is_editor_hint():
		pass
	else:
		if Debug.draw:
			draw_circle((camera_target.position), 4.0, Color.GREEN_YELLOW, false, 1.0)
			if player:
				var c = Color.GREEN_YELLOW
				c.a *= 0.5
				draw_circle((to_local(player.camera_target.global_position)), 4.0, Color.PURPLE, false)
				draw_line(camera_target.position, to_local(player.camera_target.global_position), c)
				draw_circle((to_local(camera.global_position)), 2.0, Color.BLUE, false, 1.0)
