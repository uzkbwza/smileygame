@tool

extends Node2D

class_name SmileyLevel

@export var tutorial_replay: GameplayRecording

@export_range(0.0, 2048, 16) var death_height := 0:
	set(value):
		death_height = value
		death_height_update()
		queue_redraw()

@onready var camera: GoodCamera = %Camera
@onready var tile_map: TileMapLayer = %MainTileMap
@onready var shadow_tile_map: TileMapLayer = %TileMapShadow
@onready var player: SmileyPlayer = $Smiley

func _ready():
	if !Engine.is_editor_hint():
		update_shadow()
	death_height_update()
	if tutorial_replay and !Engine.is_editor_hint():
		instantiate_tutorial_character()
	
func instantiate_tutorial_character():
	var tutorial_character = preload("res://stupid crap/friends/tutorialguy/tutorialguy.tscn").instantiate()
	add_child(tutorial_character)
	tutorial_character.replay_playback = tutorial_replay
	tutorial_character.global_position = player.global_position
	tutorial_character.start_playback()
	tutorial_character.reset_idle_feet()

func death_height_update():
		if camera:
			camera.limit_bottom = death_height - 32
		if player:
			player.death_height = death_height

func update_shadow():
	#shadow_tile_map.tile_map_data = tile_map.tile_map_data
	for cell in tile_map.get_used_cells():
		shadow_tile_map.set_cell(cell, tile_map.get_cell_source_id(cell), tile_map.get_cell_atlas_coords(cell))
	#clear_shadow_children.call_deferred()
	pass

func clear_shadow_children():
	for child in shadow_tile_map.get_children():
		child.queue_free()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(-10000, death_height), Vector2(10000, death_height), Color.RED, 2.0)
