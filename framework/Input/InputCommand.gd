@tool

extends Resource

class_name InputCommand

const LENIENCE_FRAMES: float = 2

enum Type {
	Pressed,
	Released,
	DoubleTap,
}


@export var action_name = "InputName"

## This will take precedence over other InputSequences. Lower number means higher priority.
@export var priority = 0 

@export var button: String = ""
@export var type: Type = Type.Pressed

@export var window = -1

var sequence = []

var steps = null

func setup_steps():
	if steps != null:
		return
	steps = {}
	sequence = get_sequence()
	for value in sequence:
		if not value.step in steps:
			steps[value.step] = []
		steps[value.step].append(value) 
		value.init()

func get_sequence():
	var seq = []
	match type:
		Type.Pressed:
			var requirement = InputSequenceRequirement.new()
			requirement.input = button
			seq.append(requirement)
		Type.Released:
			var requirement = InputSequenceRequirement.new()
			requirement.input = button
			requirement.requirement = InputSequenceRequirement.RequirementState.Released
			seq.append(requirement)
		Type.DoubleTap:
			var requirement = InputSequenceRequirement.new()
			requirement.input = button
			requirement.requirement = InputSequenceRequirement.RequirementState.Pressed
			seq.append(requirement)
			var requirement2 = InputSequenceRequirement.new()
			requirement.input = button
			requirement.step = 1
			requirement.requirement = InputSequenceRequirement.RequirementState.Released
			seq.append(requirement)
			var requirement3 = InputSequenceRequirement.new()
			requirement.input = button
			requirement.step = 2
			requirement.requirement = InputSequenceRequirement.RequirementState.Pressed
			seq.append(requirement)
	return seq

func fulfilled(buffer: Array, time:int, max_window:int):
	setup_steps()
	var sequence_step = 0
	var window = self.window if self.window != -1 else max_window
	var window_left = window
	var start = clamp(buffer.size() - window, 0, buffer.size()) if window > 0 else 0
	var end = buffer.size()
#	inputs_to_consume = {}
	var buffer_index = start
	while buffer_index < end:
		var all_requirements_met = true
		if !sequence_step in steps:
			buffer_index += 1
			continue
		var state = buffer[buffer_index]
		if state.time < time - window:
			buffer_index += 1
			continue
		var requirements = steps[sequence_step]
		
		for requirement in requirements:
			if !requirement.requirements_met(state):
				all_requirements_met = false
				break

		if all_requirements_met:
			sequence_step += 1
			buffer_index -= LENIENCE_FRAMES
			if buffer_index < 0:
				buffer_index = 0
		if sequence_step == sequence.size():
			return true
		buffer_index += 1

	return false
