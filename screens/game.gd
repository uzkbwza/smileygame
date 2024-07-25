extends GameScene

@export_file() var start: String

@onready var level_bg_viewport: SubViewport = %LevelBgViewport
@onready var game_world_layer: CanvasLayer = %GameWorldLayer
@onready var game_hud_layer: GameHudLayer = $GameHUDLayer
@onready var level_bg_container: SubViewportContainer = %LevelBgContainer

func load_level(level_path: StringName) -> SmileyLevel:
	print(level_path)
	var progress = [0]
	var level: SmileyLevel
	ResourceLoader.load_threaded_request(level_path)
	while true:
		var status = ResourceLoader.load_threaded_get_status(level_path, progress)
		match status:
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				level = ResourceLoader.load_threaded_get(level_path).instantiate()
				add_level.call_deferred(level)
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				continue
		await get_tree().process_frame
	return level

func add_level(level: SmileyLevel):
	game_world_layer.add_child(level)

func _ready() -> void:
	var startup_level = await load_level(start)
	setup_level(startup_level)

func setup_level(level: SmileyLevel) -> void:
	setup_level_background.call_deferred(level)
	game_hud_layer.setup_level(level)

func setup_level_background(level: SmileyLevel):
	var bg = level.level_bg
	if bg:
		level_bg_viewport.add_child(bg.instantiate())

func get_level():
	return game_world_layer.get_child(0)
