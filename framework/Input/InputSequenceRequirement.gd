extends Resource

class_name InputSequenceRequirement
const DEFAULT_CHARGE_TIME = 30
const DEFAULT_DELAY_TIME = 30

enum RequirementState {
	Pressed,
	Released,
	Held,
	ChargedFor,
	ReleasedFor,
}

@export var input = "right"
@export var requirement: RequirementState

## Which part of the sequence we are in (for multiple simultaneous requirements)
@export var step = 0

## This requirement will be satisfied if its conditions are *not* met.
@export var not_ = false

@export_group("Charge")
@export var charge_time = DEFAULT_CHARGE_TIME

@export_group("Delay")
@export var delay_time = DEFAULT_DELAY_TIME
@export var delay_window = 10
@export var endless_delay = true

var positive_inputs = []
var negative_inputs = []

func init():
	for word in input.split(","):
		word = word.strip_edges()
		if "!" in word:
			negative_inputs.append(word.lstrip("!"))
			continue
		positive_inputs.append(word)

func requirements_met(state: InputState):
		for i in range(positive_inputs.size()):
			var word = positive_inputs[i];
			if !requirement_met(word, state, not_): 
				return false
		
		for i in range(negative_inputs.size()):
			var word = negative_inputs[i];
			if state.get(word) > 0: 
				return not_;

		return true;

func requirement_met(required_input, state: InputState, not_=false):
	var met = false
	var button_state = state.get(required_input)
	
	match requirement:
		RequirementState.Pressed:
			met = button_state == 1
		RequirementState.Released:
			met = button_state == -1
		RequirementState.Held:
			met = button_state > 0
		RequirementState.ChargedFor:
			met = button_state > charge_time
		RequirementState.ReleasedFor:
			if !endless_delay:
				met = button_state > -(delay_time) - delay_window and button_state <= -(delay_time)
			else:
				met = button_state < -(delay_time)
	
	return not_ != met
