extends CanvasLayer

@export var startup_level: PackedScene

@onready var level_bg_viewport: SubViewport = %LevelBgViewport
@onready var game_world_layer: CanvasLayer = %GameWorldLayer
@onready var game_hud_layer: GameHudLayer = $GameHUDLayer
@onready var level_bg_container: SubViewportContainer = %LevelBgContainer

func load_level(level_scene: PackedScene) -> SmileyLevel:
	var level = level_scene.instantiate()
	game_world_layer.add_child(level)
	return level

func _ready() -> void:
	var level = get_level()
	if level:
		setup_level(level)
	elif startup_level:
		setup_level(load_level(startup_level))

func setup_level(level: SmileyLevel) -> void:
	setup_level_background.call_deferred(level)
	game_hud_layer.setup_level(level)

func setup_level_background(level: SmileyLevel):
	var bg = level.level_bg
	if bg:
		level_bg_viewport.add_child(bg.instantiate())

func get_level():
	return game_world_layer.get_child(0)
