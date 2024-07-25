extends CanvasLayer

class_name GameView

signal scene_instantiated(scene: GameScene)

@onready var game_sub_viewport: SubViewport = %GameSubViewport

var instantiation_thread: Thread

var scenes = {
	"MainMenu": "res://screens/MainMenu.tscn",
	"Game": "res://screens/game.tscn"
}

enum ScreenTransitionType {
	None,
	Fade,
}

func _ready() -> void:
	pass

func load_scene(scene_path: StringName, scene_data: Dictionary={}) -> GameScene:
	if Debug.enabled:
		Debug.clear_items()

	var progress = [0]
	
	var scene: PackedScene = await Utils.load_resource_threaded(scene_path, func() -> Signal: return get_tree().process_frame, update_progress)
	
	if game_sub_viewport.get_child_count() > 0:
		game_sub_viewport.get_child(0).free()

	instantiate_scene_threaded(scene)


	var child: GameScene = await scene_instantiated
	
	instantiation_thread.wait_to_finish()
	
	child.scene_change_triggered.connect(on_scene_change_triggered, CONNECT_DEFERRED)
	
	child.load_scene_data(scene_data)
	
	game_sub_viewport.add_child.call_deferred(child)
	var current_screen = child
	return child

func instantiate_scene_threaded(scene: PackedScene):
	if instantiation_thread and instantiation_thread.is_alive():
		instantiation_thread.wait_to_finish()
	
	instantiation_thread = Thread.new()

	instantiation_thread.start(func():
		var instantiated = scene.instantiate()
		scene_instantiated.emit.call_deferred(instantiated)
	)

func finished_instantiating_scene(scene: GameScene):
	scene_instantiated.emit(scene)

func update_progress(progress):
	if progress:
		var p = progress[0]

func _exit_tree() -> void:
	if instantiation_thread and instantiation_thread.is_alive():
		instantiation_thread.wait_to_finish()

func screen_transition_start(type: ScreenTransitionType):
	match type:
		ScreenTransitionType.None:
			return
		ScreenTransitionType.Fade:
			%ScreenFadeRect.color.a = 0.0
			var tween = create_tween()
			tween.tween_property(%ScreenFadeRect, "color:a", 1.0, 0.25)
			await tween.finished
			return

func screen_transition_end(type: ScreenTransitionType):
	match type:
		ScreenTransitionType.None:
			return
		ScreenTransitionType.Fade:
			%ScreenFadeRect.color.a = 1.0
			var tween = create_tween()
			tween.tween_property(%ScreenFadeRect, "color:a", 0.0, 0.25)
			await tween.finished
			return

func on_scene_change_triggered(new_scene_name: StringName, screen_transition:ScreenTransitionType, scene_data: Dictionary) -> void:
	await screen_transition_start(screen_transition)
	
	
	if new_scene_name == "Quit":
		get_tree().quit()
		return
		
		
	var new_scene: GameScene = await load_scene(scenes[new_scene_name], scene_data)
	
	await get_tree().physics_frame
	
	await screen_transition_end(new_scene.get_screen_transition_in())
	
