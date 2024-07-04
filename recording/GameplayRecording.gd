extends Resource

class_name GameplayRecording

const PHYSICS_DATA_UPDATE_FREQUENCY = 20 

@export var positions: Dictionary
@export var velocities: Dictionary
@export var inputs: Dictionary
@export var length = 0

var tick_data := {}
var current_tick := -1
var current_

func clear() -> void:
	tick_data.clear()
	positions.clear()
	velocities.clear()
	inputs.clear()
	current_tick = -1
	length = 0

func restart() -> void:
	current_tick = -1

func record(character: SmileyPlayer) -> void:
	current_tick += 1
	if current_tick % PHYSICS_DATA_UPDATE_FREQUENCY == 0:
		positions[current_tick]  = character.global_position
		velocities[current_tick] = character.body.velocity

	var last_key = Utils.get_first_dict_key_below_number(inputs, current_tick)
	var last_input = inputs[last_key] if current_tick > 0 else 0
	var input = character.input_to_bitflags()
	if current_tick == 0 or input != inputs[last_key]:
		inputs[current_tick] = input
	length = current_tick + 1

func advance():
	current_tick += 1
	if length > current_tick:
		tick_data.clear()
		if current_tick in positions:
			tick_data.position = positions[current_tick]
		if current_tick in velocities:
			tick_data.velocity = velocities[current_tick]
		var last_key = Utils.get_first_dict_key_below_number(inputs, current_tick)
		if last_key in inputs:
			tick_data.input = inputs[last_key]
		return tick_data
	return null
