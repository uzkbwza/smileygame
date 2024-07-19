@tool 

extends Node2D

class_name SmileyLevel

signal coin_collected

const SHADOW_COLOR = Color("000000A0")
const SHADOW_OFFSET = Vector2(8, 8)
 
const BRICK_TERRAIN_SOURCE = 4

@export var tutorial_replay: GameplayRecording
@onready var background_tile_map: LevelTileMapLayer = %BackgroundTiles
@onready var tile_map: LevelTileMapLayer = %GreyBox
@onready var terrain_shapes: Node2D = %TerrainShapes
@onready var background_shapes: Parallax2D = %BackgroundShapes
@export var level_bg: PackedScene

@export_range(0.0, 3520, 176) var death_height := 0:
	set(value):
		death_height = value
		death_height_update()
		queue_redraw()
		
@onready var tile_map_parent: Node2D = $TileMaps
@onready var player: SmileyPlayer = $Smiley
@onready var camera_system: CameraSystem = $CameraSystem
@onready var camera: GoodCamera = %Camera

@onready var death_animation_layer = %DeathAnimationLayer
@onready var background_color_overlay: ColorRect = %BackgroundColorOverlay
@onready var giant_player_sprite: Sprite2D = %GiantPlayerSprite

var debug_collision_lines = []

var collision_polygons : Array[PackedVector2Array] = []
var background_polygons : Array[PackedVector2Array] = []

#var subviewport_container: SubViewportContainer
#var subviewport: Viewport
#@onready var shadow_polygon_container: Node2D = Node2D.new()

var bg_camera: Camera2D

var rect_px := Rect2()

var rng := BetterRng.new()

var num_coins := 0
var coins_left := 0
var coins_collected: int:
	get:
		return maxi(num_coins - coins_left, 0)

var collision_polygon_hash_grid: SpatialHashGrid
var background_polygon_hash_grid: SpatialHashGrid

func _ready():
	if !Engine.is_editor_hint():
		Debug.draw_toggled.connect(debug_line_toggle)
		init_tilemap_info.call_deferred()
		process_background_tile_map.call_deferred()
		process_tile_map.call_deferred()
		process_terrain_shapes.call_deferred()
		initialize_object_data.call_deferred()
	else:
		set_process(false)
		set_physics_process(false)
	
	death_height_update()
	if tutorial_replay and !Engine.is_editor_hint():
		instantiate_tutorial_character()
	assert(death_height > 0)
	
	player.death_animation_started.connect(on_player_death_animation_started)
	player.death_animation_finished.connect(on_player_death_animation_finished)
	death_animation_layer.hide()

func on_player_death_animation_started():
	var tween = create_tween()
	
	
	giant_player_sprite.modulate.a = 0.0
	background_color_overlay.color.a = 0.0
	background_color_overlay.global_position = player.global_position - background_color_overlay.size / 2.0
	
	death_animation_layer.show()
	
	#tween.set_ease(Tween.EASE_IN_OUT)
	#tween.set_trans(Tween.TRANS_CIRC)
	tween.set_parallel(true)
	tween.tween_property(background_color_overlay, "color:a", 0.5, 0.25)
	tween.tween_property(giant_player_sprite, "modulate", Color.WHITE, 0.25)
	tween.tween_interval(1.0)
	while tween.is_running():
		await RenderingServer.frame_pre_draw
		giant_player_sprite.texture = player.sprite.sprite_frames.get_frame_texture(player.sprite.animation, player.sprite.frame)
		pass
		
func on_player_death_animation_finished():
	death_animation_layer.hide()
	background_color_overlay.color.a = 0.0
	giant_player_sprite.modulate.a = 0.0


func initialize_object_data():
	if coins_left > num_coins:
		num_coins = coins_left
	player.coin_collected.connect(on_coin_collected)

func on_coin_collected():
	coins_left -= 1
	coin_collected.emit()

func init_tilemap_info():
	var start = Vector2(INF, INF)
	var end = Vector2(-INF, -INF)
	for map in tile_map_parent.get_children():
		if map is TileMapLayer:
			var map_start = map.get_used_rect().position * map.tile_set.tile_size
			var map_end = map.get_used_rect().end * map.tile_set.tile_size
			if map_start.x < start.x:
				start.x = map_start.x
			if map_start.y < start.y:
				start.y = map_start.y
			if map_end.x > end.x:
				end.x = map_end.x
			if map_end.y > end.y:
				end.y = map_end.y
	rect_px = Rect2(start, end - start)

	collision_polygon_hash_grid = SpatialHashGrid.new(Vector2.ONE * 128)
	background_polygon_hash_grid = SpatialHashGrid.new(Vector2.ONE * 128)


func process_background_tile_map():
	background_tile_map.collision_enabled = false
	background_tile_map.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_HIDE
	#tile_map_parent.remove_child(background_tile_map)
	#
	#var canvas_layer = CanvasLayer.new()
	#add_child(canvas_layer)
	#canvas_layer.layer -= 1
	##canvas_layer.follow_viewport_enabled = true
	#
	#subviewport_container = SubViewportContainer.new()
	#canvas_layer.add_child(subviewport_container)
#
	#canvas_layer.move_child(subviewport_container, tile_map_parent.get_index() - 1)
	#subviewport_container.z_index = -2
	#subviewport = SubViewport.new()
	#subviewport_container.add_child(subviewport)
	#subviewport_container.add_child(shadow_polygon_container)
	#subviewport.add_child(background_tile_map)
	##background_tile_map.global_position = -Vector2(rect_px.position) + global
	##subviewport_container.global_position = rect_px.position
	##subviewport_container.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	#
	#subviewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	#
	#subviewport.size = Global.viewport_size
	#
	#bg_camera = Camera2D.new()
	#subviewport.add_child(bg_camera)
	#
	#
	##subviewport.size = Vector2(40000, 40000)
	#subviewport.transparent_bg = true
	

func instantiate_tutorial_character():
	var tutorial_character = preload("res://object/tutorialguy/tutorialguy.tscn").instantiate()
	add_child(tutorial_character)
	tutorial_character.replay_playback = tutorial_replay
	tutorial_character.global_position = player.global_position
	tutorial_character.start_playback()
	tutorial_character.reset_idle_feet()

func _physics_process(delta: float) -> void:
	#var raycast = $RayCast2D
	queue_redraw()
	#raycast.global_position = lerp(raycast.global_position, get_global_mouse_position(), 0.2)
	#if raycast.is_colliding() and !raycast.get_collider():
		#print(raycast.get_collision_normal())

#func _process(delta: float) -> void:
	#if bg_camera:
		#bg_camera.global_position = camera.global_position
		#bg_camera.offset = camera.offset
		#bg_camera.reset_physics_interpolation()
		#shadow_polygon_container.global_position = - bg_camera.global_position
		#pass
	
func death_height_update():
		if camera_system and camera_system.get("death_height") != null:
			camera_system.death_height = death_height
		if player:
			player.death_height = death_height

func create_shadow_map(map: TileMapLayer, shadow_group: CanvasGroup):
	var shadow_map = TileMapLayer.new()
	
	shadow_map.collision_enabled = false
	shadow_map.tile_set = map.tile_set
	shadow_group.add_child(shadow_map)
	shadow_map.global_position = map.global_position
	#shadow_map.position += SHADOW_OFFSET
	return shadow_map

func process_terrain_shapes():
	var shadow_polygons = CanvasGroup.new()
	var background_shadow_polygons = CanvasGroup.new()
	
	add_child(shadow_polygons)
	move_child(shadow_polygons, terrain_shapes.get_index() - 1)
	
	shadow_polygons.z_index =  -2
	background_shadow_polygons.z_index = -100
	shadow_polygons.texture_repeat = true
	background_shadow_polygons.texture_repeat = true
	
	for terrain_polygon in terrain_shapes.get_children():
		if terrain_polygon is TerrainShape:
			terrain_polygon.create_physics_body()
			#var shadow = terrain_polygon.get_shadow_polygon() 
			#shadow_polygons.add_child(shadow)
			#var shadow_outline = terrain_polygon.get_shadow_border()
			#if shadow_outline:
				#shadow_polygons.add_child(shadow_outline)
		
	#for background_polygon in background_shapes.get_children():
		#if background_polygon is TerrainShape:
			#var shadow = background_polygon.get_shadow_polygon()
			#background_shadow_polygons.add_child(shadow)
			#var shadow_outline = background_polygon.get_shadow_border()
			#if shadow_outline:
				#background_shadow_polygons.add_child(shadow_outline)

	background_shapes.add_child(background_shadow_polygons)
	background_shapes.move_child(background_shadow_polygons, 0)
	shadow_polygons.self_modulate.a = 0.5
	background_shadow_polygons.self_modulate.a = 0.5
	

func process_tile_map() -> void:
	var shadow_group = CanvasGroup.new()
	background_tile_map.add_child(shadow_group)
	background_tile_map.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	shadow_group.self_modulate = SHADOW_COLOR

	for map in tile_map_parent.get_children():
		var source_ids = []


func process_tile_map_old() -> void:
	var shadow_group = CanvasGroup.new()
	background_tile_map.add_child(shadow_group)
	background_tile_map.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	shadow_group.self_modulate = SHADOW_COLOR
	#shadow_group.z_index = -1000

	var bottom := {
		#Vector2i(0, 0): true,
		Vector2i(3, 1): true,
		Vector2i(4, 1): true,
		Vector2i(5, 1): true,
		Vector2i(6, 1): true,
		Vector2i(3, 3): true,
		Vector2i(4, 3): true,
		Vector2i(5, 4): true,
		Vector2i(6, 4): true,
		Vector2i(5, 5): true,
		Vector2i(6, 5): true,
	}

	background_polygons = background_tile_map.build_collision_polygons(0)
	
	var polygon_array: Array[PackedVector2Array] = tile_map.build_collision_polygons(0)
	
	for polygon in polygon_array:
		
		collision_polygons.append(polygon)
		collision_polygon_hash_grid.add_object_rect(polygon, Shape.get_polygon_bounding_box(polygon))
		
		if polygon.size() == 0:
			continue

		var line = Line2D.new()
		line.points = polygon
		line.closed = true
		line.visible = Debug.draw

		debug_collision_lines.append(line)
		line.width = 1
		add_child(line)

		for child in tile_map.get_children():
			if child is CanvasItem:
				child.z_index += 1
	
	for polygon in background_polygons:
		background_polygon_hash_grid.add_object_rect(polygon, Shape.get_polygon_bounding_box(polygon))

		#build_outline()
	var used_shadow_polygons = {}
	build_outer_shadow(shadow_group, used_shadow_polygons)
		#build_inner_shadow()
	

func build_outer_shadow(shadow_group, used):

	var shadow_dir = SHADOW_OFFSET.normalized()

	var background_polygon_regions = {
		
	}
	
	for polygon: PackedVector2Array in collision_polygons:

		var valid_polygons = []
		var moved_poly = Shape.move_polygon(polygon, SHADOW_OFFSET)
		var search_region = background_polygon_regions.get(polygon)
		if search_region == null:
			search_region = background_polygon_hash_grid.search_region(Shape.get_polygon_bounding_box(polygon))
			background_polygon_regions[polygon] = search_region
		for background_polygon in search_region:
		#for background_polygon in background_polygons:
			#if !Geometry2D
			var intersection = Geometry2D.intersect_polygons(moved_poly, background_polygon)
			if intersection:
				for valid in intersection:
					if !(valid in used):
						valid_polygons.append(valid)
					used[valid] = true


		for valid_polygon in valid_polygons:
			var p2d = Polygon2D.new()

			#for vertex in add_at:
				#var new = add_at[vertex]
				#var index = new_poly.find(vertex) + 1
				#new_poly.insert(index, new)

			p2d.polygon = valid_polygon
			p2d.z_index = -2
			p2d.color = Color.BLACK
			p2d.color.a = 0.5
			#p2d.position 
			add_child(p2d)
			#var line = Line2D.new()
			#line.points = valid_polygon
			##for i in line.points.size():
				##line.points[i] += rng.random_vec(false) * 10
			#line.closed = true
			##line.visible = Debug.draw
#
			##debug_collision_lines.append(line)
			#line.width = 1
			#add_child(line)

func build_inner_shadow():
	var alpha = 1.0
	var shadow_offset = 1
	var shadow_radius = 12
	var shadow_band_distance = 2
	for polygon in collision_polygons:
		for i in range(shadow_radius / shadow_band_distance):

			var offset = Geometry2D.offset_polygon(polygon, -shadow_offset - (i / 2.0) * shadow_band_distance, Geometry2D.JOIN_SQUARE)
			#print(offset)
			if offset:
				for shadow_poly in offset:
					var p2d = Polygon2D.new()
					p2d.polygon = shadow_poly
					p2d.color = Color(0.0, 0.0, 0.0, float(i * shadow_band_distance) / shadow_radius)
					if i + 1 >= shadow_radius / shadow_band_distance:
						p2d.color.a = 1.0
					p2d.color.a *= alpha
					add_child(p2d)

func build_outline():

	
	var texture = preload("res://terrain/outline1.png")
	var group = CanvasGroup.new()
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var alpha = 0.8
	add_child(group)
	
	group.self_modulate.a = alpha
	
	for polygon in collision_polygons:
		var line_offset = 0
		var line_radius = 1
		var line_band_distance = 1
		var line_height_multiplier = 1.0

		for i in range(line_radius / line_band_distance):

			var offset = Geometry2D.offset_polygon(polygon, -line_offset - (i / 2.0) * line_band_distance, Geometry2D.JOIN_MITER)
			if offset:
				for line_poly in offset:
					var line = Line2D.new()
					line.points = Shape.move_polygon(line_poly, Vector2(0.01, 0.01))
					#for j in line.points.size():
						#line.points[j] = line.points[j].floor()
#					
					line.texture = texture
					line.width = texture.get_height() * line_height_multiplier
					line.texture_mode = Line2D.LINE_TEXTURE_TILE
					line.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR

					#line.material = mat

					line.closed = true
					line.joint_mode = Line2D.LINE_JOINT_SHARP
					line.default_color = Color(1.0, 1.0, 1.0, 1.0 - float(i * line_band_distance) / line_radius)
					#line.default_color.a *= alpha

					group.add_child(line)


func debug_line_toggle():
	for line in debug_collision_lines:
		line.visible = Debug.draw

func build_shadow(map: LevelTileMapLayer) -> void:
	var tilemap_mask_sprite = await map.build_mask()
	tilemap_mask_sprite.centered = false
	tilemap_mask_sprite.z_index = 0
	tilemap_mask_sprite.material = ShaderMaterial.new()
	tilemap_mask_sprite.material.shader = preload("res://fx/tile_darkness_2.gdshader")
	tilemap_mask_sprite.material.set_shader_parameter("radius", 8.0)
	tilemap_mask_sprite.material.set_shader_parameter("steps", 40.0)
	tilemap_mask_sprite.material.set_shader_parameter("alpha", 0.80)

	var shadow_viewport = preload("res://fx/TileMapShadowViewport.tscn").instantiate()
	add_child(shadow_viewport)
	shadow_viewport.add_sprite(tilemap_mask_sprite)
	shadow_viewport.global_position = map.sprite_pos - shadow_viewport.size / 2.0

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(-10000, death_height), Vector2(10000, death_height), Color.RED, 2.0)
