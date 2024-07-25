extends CanvasLayer

class_name GameScene 

signal scene_change_triggered(scene_name: String,  transition_type: GameView.ScreenTransitionType, scene_data: Dictionary)

func queue_scene_change(scene_name: String, scene_data: Dictionary = {}, transition_type: GameView.ScreenTransitionType = GameView.ScreenTransitionType.Fade):
	scene_change_triggered.emit(scene_name, transition_type, scene_data)

func get_screen_transition_in():
	return GameView.ScreenTransitionType.Fade

func load_scene_data(scene_data: Dictionary):
	pass
