extends GameScene

const MENU_OPTION_SCENE = preload("res://ui/main_menu/MenuOption.tscn")
@export var MENU_TILT :float = 0.025
@export var MENU_WIDTH :float = 500
@export var MENU_WIDTH_MOD :float = 0.7
@export var MENU_HEIGHT :float = 200
@export var MENU_HEIGHT_MOD :float = 1.0
@export var MENU_OFFSET := Vector2(-50,30)
@export var NUM_SHOWN :int = 5
@export var ARC_LENGTH :float = PI*0.74
@export var CURVE_OFFSET :float = 2.41854

@export var MENU_ITEM_WIGGLE_AMOUNT := 0.25
@export var MENU_ITEM_WIGGLE_SPEED := 3.0

@export var MENU_BREATHE_AMOUNT := 0.02
@export var MENU_BREATHE_SPEED = 0.023

@export var CURVE_WIGGLE_AMOUNT := 0.9
@export var CURVE_WIGGLE_SPEED := 0.035

@export var MENU_WIGGLE_AMOUNT := 0.01
@export var MENU_WIGGLE_SPEED := 0.015

#const START_TO_END_DISTANCE = 100
@export var SELECT_SMOOTHING_HALF_LIFE :float = 2.0
@export var NODE_DISAPPEAR_HALF_LIFE :float = 2.0
@export var NODE_APPEAR_HALF_LIFE :float = 2.0
@export var LOCATION_OFFSET : int = 6
@export var SELECTED_ITEM_OFFSET : int = 1

@export var START_DISTANCE_MULTIPLIER := 5.0
@export var START_CURVE_OFFSET := TAU * 2 

@onready var anchor: Node2D = $MenuStuff/Anchor
@onready var center_element: Node2D = $MenuStuff/CenterElement
@onready var center_element_position: Vector2 = center_element.position
@onready var starparticle: Sprite2D = $MenuStuff/Starparticle
@onready var sounds: Node = $Sounds

var menu_options: Array[String] = [
	"MAIN_MENU_START",
	"MAIN_MENU_LEVEL_SELECT",
	"MAIN_MENU_OPTIONS",
	"MAIN_MENU_QUIT",
]

var commands: Dictionary = {
}

var menu_nodes: Dictionary = {
}

var node_offsets: Dictionary = {
}

var selected_menu_item := 0
var selected_menu_node: MainMenuOption
var selected_menu_key: StringName
var menu_offset := 0
var elapsed_time := 0.0

var input_active := false

var startup_t := 1.0

var button_press_t := 0.0

enum State {
	Scrolling,
	ButtonPressed,
	SubMenu,
}

var state = State.Scrolling

func _ready() -> void:
	input_active = false
	
	anchor.global_position = Global.viewport_size / 2.0
	for i in range(max(ceil(float(NUM_SHOWN) / menu_options.size()), 1) * 2):
		for command in menu_options:
			var menu_option = MENU_OPTION_SCENE.instantiate()
			anchor.add_child(menu_option)
			menu_option.set_text(command)
			menu_nodes[command + ":" + str(i)] = menu_option
			commands[command + ":" + str(i)] = command
			node_offsets[command + ":" + str(i)] = 0.0
		#menu_option.hide()
		#menu_option.reset_physics_interpolation.call_deferred()
	#physics_interpolation_mode = 
	#propagate_call()
	_set_menu_offset(-LOCATION_OFFSET)
	
	update_menu_items(100)
	startup_animation()

func startup_animation():
	button_press_t = 0.0
	state = State.Scrolling
	input_active = false
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	startup_t = 0.2
	tween.tween_property(self, "startup_t", 0.0, 0.75)
	await get_tree().create_timer(0.35).timeout
	input_active = true

func scroll_effect():
	play_sound("Scroll1")
	play_sound("Scroll2")

func _set_menu_offset(offs: int):
	menu_offset = offs
	selected_menu_item = posmod(menu_offset + LOCATION_OFFSET,  menu_nodes.size())
	selected_menu_node = menu_nodes.values()[selected_menu_item]
	selected_menu_key = menu_nodes.keys()[selected_menu_item]

func play_sound(sound_name):
	var sound = sounds.get_node(sound_name)
	if sound is VariableSound2D:
		sound.go()
	elif sound is AudioStreamPlayer2D:
		sound.play()

func _input(event: InputEvent) -> void:
	if !input_active:
		return

	if state == State.Scrolling:

		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			_set_menu_offset(menu_offset - 1)
			scroll_effect()

		if event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			_set_menu_offset(menu_offset + 1)
			scroll_effect()
		
		if event.is_action_pressed("primary"):
			select_item()

	
	Debug.dbg("selected_menu_item", selected_menu_item)

func select_item():
	play_sound("Select1")
	play_sound("Select3")
	state = State.ButtonPressed
	input_active = false
	await select_effect()
	
	var command = commands[selected_menu_key]
	match command:
		"MAIN_MENU_START":
			queue_scene_change("Game")
		"MAIN_MENU_OPTIONS":
			pass
		"MAIN_MENU_QUIT":
			queue_scene_change("Quit")
			#startup_animation()


func select_effect() -> void:
	button_press_t = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	#tween.set_trans(Tween.TRANS_EXPO)r
	tween.tween_property(self, "button_press_t", 1.0, 0.25)

	await tween.finished
	return

func update_menu_items(delta: float) -> void:
	var keys := menu_nodes.keys()
	var amount := keys.size()
	var anchor_pos := anchor.global_position
	
	
	var visible_range = []
	var inner_edge_range = []
	#var outer_edge_range = []
	
	for i in range(-2, NUM_SHOWN + 2):
		var start = menu_offset - NUM_SHOWN / 2 + LOCATION_OFFSET + SELECTED_ITEM_OFFSET
		var id = posmod(start + i, amount)
		
		if i > -1 and i < NUM_SHOWN:
			visible_range.append(id)
		if i > -2 and i < NUM_SHOWN + 1:
			inner_edge_range.append(id)
		#outer_edge_range.append(id)

	# loop from the edges including nodes we're animating in and out
	# i is the position in space
	# node_index is the absolute index of the node regardless of position
	var selected_node: Node2D
	
	for i: int in amount:

		# this starts at selected_menu_item and wraps around amount
		#var node_index: int = 0
		var node_index: int = posmod((menu_offset + i), amount)

		var key: String = keys[node_index]
		var node: MainMenuOption = menu_nodes[key]
		var selected := node == selected_menu_node
		
		var edge = node_index in inner_edge_range and !(node_index in visible_range)
		var hidden = (!node_index in inner_edge_range)
		
		# get the actual offset of the node on the menu from 0 to 1, allows for smoothing
		var node_pos:float = node_offsets[key]
		

		# this is where the node wishes to go
		var target_node_pos: float = (i) / float(amount)

		# where the node will actually end up on the curve
		var calculated_offset:float = target_node_pos
		
		if !is_equal_approx(node_pos, target_node_pos):
			calculated_offset = Math.splerp(node_pos, target_node_pos, delta, SELECT_SMOOTHING_HALF_LIFE) 
		
		node_offsets[key] = calculated_offset
		
		var amount_shown_ratio := (amount / float(NUM_SHOWN))
		
		var offset_from_selected = (Math.wrap_diff(node_index, selected_menu_item, amount * 2))
		
		
		var distance_from_selected = abs((offset_from_selected / (NUM_SHOWN * 2.0)))
		
		
		# get the actual positions on screen to interpolate between
		var arc_length :float = ARC_LENGTH + (startup_t * 20)

		var rot :float = calculated_offset * arc_length * amount_shown_ratio + (sin(CURVE_WIGGLE_SPEED * elapsed_time) * CURVE_WIGGLE_AMOUNT) + (startup_t * START_CURVE_OFFSET)

		#if !selected:
		rot -= pow(button_press_t, 1) * 2
		
		var width = (MENU_WIDTH / 2.0)
		var height = (MENU_HEIGHT / 2.0)

		var real_position := Vector2(sin(CURVE_OFFSET + rot) * width, cos(CURVE_OFFSET + rot) * height)
		#var real_position := Vector2(-200, -100).lerp(Vector2(200, 100), calculated_offset)
		real_position = real_position.rotated(MENU_TILT + sin(MENU_WIGGLE_SPEED * elapsed_time) * MENU_WIGGLE_AMOUNT) * Vector2(MENU_WIDTH_MOD, MENU_HEIGHT_MOD + (startup_t * 0.5))
		real_position *= 1 + (startup_t * START_DISTANCE_MULTIPLIER)
		
		#if !selected:
		real_position *= 1 + (pow(button_press_t, 1) * START_DISTANCE_MULTIPLIER * 1.5)

		real_position += MENU_OFFSET
		real_position *= 1 + (sin(MENU_BREATHE_SPEED * elapsed_time) * MENU_BREATHE_AMOUNT)

		
		if !hidden:
			var dist_amount = (1 - distance_from_selected)
			
			var node_scale: float
			if node_index == selected_menu_item and input_active:
				node_scale = Math.splerp(node.size, 1, delta, 2.0)
				node.set_active(true)
				selected_node = node
				node.z_index = 5
			else:
				node.set_active(false)
				node_scale = Math.splerp(node.size, dist_amount ** 4 * 0.9, delta, 2.0)
				#if !selected:
				node_scale = lerp(node_scale, 0.5, button_press_t)
				node_scale = lerpf(0.1, node_scale, 1 - startup_t)
				node.z_index = 100 * (dist_amount - 0.5) - 20.0 - (startup_t * 100)
				if edge:
					node.z_index -= 5
			node.set_startup(startup_t > 0.1)

			node.set_size(node_scale)

		if node.is_hidden != hidden:
			node.set_hidden(hidden)
		
		node.position = real_position
		
		if !(edge or hidden):
			node.modulate.a = Math.splerp(node.modulate.a, 1.0, delta, NODE_APPEAR_HALF_LIFE)
		elif hidden:
			node.modulate.a = Math.splerp(node.modulate.a, 0.00, delta, NODE_DISAPPEAR_HALF_LIFE / 2.0)
		else:
			node.modulate.a = Math.splerp(node.modulate.a, 0.40, delta, NODE_DISAPPEAR_HALF_LIFE)
	
		node.modulate.a *= 1 - startup_t / 10.0


	center_element.position = center_element_position + Vector2(cos(elapsed_time * 1.2) * 10, sin(elapsed_time * 1.3) * 10)


func _process(delta: float) -> void:
	#match state:
		#State.Scrolling:
	update_menu_items(delta)
	
	
	#print(selected_menu_item)
	elapsed_time += delta
