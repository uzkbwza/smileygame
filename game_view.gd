extends CanvasLayer

@onready var bg_camera: Camera2D = %BGCamera
@onready var tile_map_camera: Camera2D = %TileMapCamera
@onready var game_layer: CanvasLayer = %GameLayer
@onready var tile_map: TileMapLayer = %TileMap

func _ready():
	on_level_updated()

func get_level() -> SmileyLevel:
	return game_layer.get_child(0)

func on_level_updated():
	#var level_tile_map: TileMapLayer = get_level().tile_map
	#level_tile_map.self_modulate.a = 0.0
	#tile_map.tile_map_data = level_tile_map.tile_map_data
	#level_tile_map.changed.connect(on_level_updated, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	#tile_map_clear_children.call_deferred()
	pass
