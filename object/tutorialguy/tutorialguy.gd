extends SmileyPlayer

const PRESS_COLOR = Color("fd4d4f")
@onready var tut_up: Sprite2D = $TutControls/TutUp
@onready var tut_down: Sprite2D = $TutControls/TutDown
@onready var tut_left: Sprite2D = $TutControls/TutLeft
@onready var tut_right: Sprite2D = $TutControls/TutRight
@onready var tut_jump_controller: Sprite2D = $TutControls/TutJumpController
@onready var tut_kick_controller: Sprite2D = $TutControls/TutKickController
@onready var tut_jump_keyboard: Sprite2D = $TutControls/TutJumpKeyboard
@onready var tut_kick_keyboard: Sprite2D = $TutControls/TutKickKeyboard

func play_sound(sound_name: String, force=true, pitch=null, amplitude=null) -> void:
	pass
	#var sound: VariableSound2D = sounds[sound_name]
	#if force or !sound.playing:
		#sound.go(0.0, pitch, amplitude)

func spawn_scene(scene: PackedScene, offset: Vector2=Vector2(), direction: Vector2=Vector2(1.0, 0.0), particle_flip:=true) -> Node2D:
	var child = super.spawn_scene(scene, offset, direction,particle_flip)
	child.queue_free()
	return child

func _process(delta: float) -> void:
	#super._process(delta)
	color_tutorial_sprite(tut_up, input_move_dir_vec.y == -1)
	color_tutorial_sprite(tut_down, input_move_dir_vec.y == 1)
	color_tutorial_sprite(tut_left, input_move_dir_vec.x == -1)
	color_tutorial_sprite(tut_right, input_move_dir_vec.x == 1)

	color_tutorial_sprite(tut_jump_controller, input_jump_held)
	color_tutorial_sprite(tut_kick_controller, input_kick_held)
	
	color_tutorial_sprite(tut_jump_keyboard, input_jump_held)
	color_tutorial_sprite(tut_kick_keyboard, input_kick_held)
	
	tut_jump_keyboard.visible = GlobalInput.keyboard
	tut_kick_keyboard.visible = GlobalInput.keyboard

	tut_jump_controller.visible = !GlobalInput.keyboard
	tut_kick_controller.visible = !GlobalInput.keyboard
	

func color_tutorial_sprite(sprite: Sprite2D, input: bool):
	sprite.modulate = PRESS_COLOR if input else Color.WHITE
