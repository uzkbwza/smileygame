@tool

extends TileMapLayer

class_name LevelTileMapLayer

@export var generate_tileset := false:
	set(value):
		if Engine.is_editor_hint():
			generate_tileset = false
			do_generate_tileset()

@export var input_tileset_template: TileSet

@export var tileset_textures: Array[CompressedTexture2D] = [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null] 

func _ready():
	#if tileset_textures.size() == 0:
		#tileset_textures.resize(20)
	#if !Engine.is_editor_hint():
		#do_generate_tileset()
	pass

func do_generate_tileset():
	if input_tileset_template == null:
		return
	tile_set = TileSet.new()

	tile_set.tile_size = input_tileset_template.tile_size
	tile_set.add_terrain_set()
	
	for i in tileset_textures.size():
		var image = tileset_textures[i]
		if image:
			generate_tileset_source(image, i)

	pass

func generate_tileset_source(texture: CompressedTexture2D, id: int):
	var source_id = id
	var source = TileSetAtlasSource.new()
	source.texture = texture
	
	var terrain_id = id
	tile_set.add_terrain(0, terrain_id)
	tile_set.set_terrain_name(0, terrain_id, str(terrain_id))
	
	var template_source: TileSetAtlasSource = input_tileset_template.get_source(0)
	var grid_size = template_source.get_atlas_grid_size()
	print(grid_size)
	for y in grid_size.y:
		for x in grid_size.x:
			var template_tile_data = template_source.get_tile_data(Vector2i(x, y), 0)

			if template_tile_data == null:
				continue
			var setcoords = str(x) + ":" + str(y) + "/0/"
			if template_source.get(str(x) + ":" + str(y) + "/0") == null:
				continue
			source.set(setcoords, 0)
			
			#if template_source.get(setcoords + "terrain") == 0:
				#source.set(setcoords + "terrain_set", 0)
				#source.set(setcoords + "terrain", terrain_id)
			pass

			var source_tile_data = source.get_tile_data(Vector2i(x, y), 0)

			if template_tile_data.terrain_set < 0:
				continue
			if template_tile_data.terrain == 0:
				source_tile_data.terrain_set = 0
				source_tile_data.terrain = terrain_id
			else:
				continue

			for bit in [
				TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_CORNER,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
				TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			]:
				if template_tile_data.terrain >= 0 and template_tile_data.is_valid_terrain_peering_bit(bit):
					if template_tile_data.get_terrain_peering_bit(bit) >= 0:
						source_tile_data.set_terrain_peering_bit(bit, terrain_id)
		
		
	tile_set.add_source(source, source_id)

#func build_collision_polygons(physics_layer=0) -> Array[PackedVector2Array]: 
	#var skip = {
	#}
	#var skip_poly = {
		#
	#}
	#var polygons: Array[PackedVector2Array] = []
#
	#for cell in get_used_cells():
		#if cell in skip:
			#continue
		#for poly in get_contiguous_polygons(cell, skip, physics_layer):
			#if poly in skip_poly:
				#continue
			#polygons.append(poly)
			#skip_poly[poly] = true
#
	#return polygons
#
#func get_contiguous_polygons(cell, skip_dict: Dictionary, physics_layer=0) -> Array[PackedVector2Array]:
	#var polys : Array[PackedVector2Array] = []
	#var extras = []
	#var poly = PackedVector2Array()
	#var stack: Array[Vector2i] = [cell]
	#var tile_polys: Array[PackedVector2Array] = []
	#var dirs = Utils.cardinal_dirs
	#
	#var counter = 0
#
	#while !stack.is_empty():
		#var current = stack.pop_back()
		#if get_cell_source_id(current) == -1:
			#continue
		#var data = get_cell_tile_data(current)
		#if data == null:
			#continue
		#var tile_poly_count = data.get_collision_polygons_count(physics_layer)
		#if tile_poly_count == 0:
			#continue
		#if current in skip_dict:
			#continue
#
		#skip_dict[current] = true
#
		#var local_pos = map_to_local(current) - tile_set.tile_size * 0.5
		#for i in tile_poly_count:
			#var tile_poly = data.get_collision_polygon_points(physics_layer, i)
			#tile_poly = Shape.move_polygon(tile_poly, local_pos)
			#tile_polys.append(tile_poly)
			#for dir in dirs:
				#stack.append(current + dir)
		#
		#counter += 1
#
	#for chunk in tile_polys:
		#var merged = Geometry2D.merge_polygons(poly, chunk)
		#poly = merged[0]
		#extras.append_array(merged.slice(1))
#
	#polys.append(poly)
	#
	#_merge_extra_polygons(extras, polys)
#
	#return polys
#
#
#func _merge_extra_polygons(extras: Array, polys: Array[PackedVector2Array]):
	#var counter := 0
	#
	#var extra_hash_grid = SpatialHashGrid.new(Vector2.ONE * 128) 
	#
	#var extras_dict = {}
	#
	#for extra_poly in extras:
		#var bounding_box = Shape.get_polygon_bounding_box(extra_poly)
		#extra_hash_grid.add_object_rect(extra_poly, bounding_box)
		#extras_dict[extra_poly] = bounding_box
	#
	#while !extras_dict.is_empty():
		#
		#var p = extras.pop_back()
		#if !p in extras_dict:
			##extras.push_back(p)
			#continue
#
		#var p_original = p.duplicate()
		#var p_bounds = extras_dict[p]
		#var did_merge = false
		#extras_dict.erase(p)
	#
		#var nearby_polygons = extra_hash_grid.search_region(p_bounds)
		#
		#for i in range(nearby_polygons.size()):
			#var p2 = nearby_polygons.pop_back()
			#if !p2 in extras_dict:
				#continue
			#var p2_bounds = extras_dict[p2]
			#extras_dict.erase(p2)
			#var merged = Geometry2D.merge_polygons(p, p2)
			#if merged.size() > 1:
				#extras_dict[p2] = p2_bounds
			#else:
				#p = merged[0]
				#did_merge = true
#
		#if did_merge or extras.size() <= 0:
			#polys.append(p)
			#extras_dict.erase(p_original)
		#else:
			#extras_dict[p] = p_bounds
#
		#counter += 1
		#if counter >= extras.size():
			#polys.append_array(extras)
			#break
#
#
#
	#if polys.size() > 1:
		#var enclosed = []
		#for poly1 in polys:
			#for poly2 in extra_hash_grid.search_region(Shape.get_polygon_bounding_box(poly1)):
				#if poly1 == poly2:
					#continue
				#if Shape.does_polygon_enclose(poly1, poly2): 
					#enclosed.append(poly2)
		#
		#for delete_me in enclosed:
			#polys.erase(delete_me)
#
#func _ready():
	#Debug.draw_toggled.connect(on_debug_draw_toggled)
	#on_debug_draw_toggled()
#
#func on_debug_draw_toggled():
		#queue_redraw()
		#pass
#
#func _draw():
	#pass
