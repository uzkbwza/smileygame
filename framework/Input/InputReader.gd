class_name InputReader

const BUF_SIZE = 100
const WINDOW_SIZE = 20
const ASSUMED_FPS = 60
const STICK_DEADZONE = 0.25

var _buf = InputBuffer.new(BUF_SIZE, InputState.new())

var time = 0

var buffer: Array:
	get:
		return _buf.read_all()

func same_input(state1: InputState, state2: InputState):
	for button in state1.button_names:
		if sign(state1.get(button)) != sign(state2.get(button)):
			return false
		var amt1 = abs(state1.get(button))
		var amt2 = abs(state2.get(button))
		
		# pressing/releasing is special
		if amt1 == 1 and amt1 != amt2:
			return false
			
		if amt2 == 1 and amt2 != amt1:
			return false

	return true

func get_last_input():
	return _buf.last

func add_input(input: InputState):
	input.time = time
	var last = _buf.last
	var diff: float = input.time - last.time
	for button in input.button_names:
		var amount = diff if sign(input.get(button)) == sign(last.get(button)) else 1
		if input.get(button) <= 0:
			input.set(button, clamp(last.get(button) - amount, -99999999, -InputState.MIN_INPUT_TIME))
			continue
		input.set(button, clamp(last.get(button) + amount, InputState.MIN_INPUT_TIME, 99999999))
	if !same_input(input, last):
		_buf.write(input)
	else:
		_buf.last = input

func read_input_from_raw(raw: RawInputState, delta: float):
	time += delta * ASSUMED_FPS
	add_input(generate_input_from_raw(raw))

func generate_input_from_raw(raw: RawInputState) -> InputState:
	var input_state = InputState.new()
	for key in raw.buttons:
		input_state.set_input_from_bool(key, raw.buttons[key])

	process_move_dir(raw, input_state)

	return input_state

func process_move_dir(raw: RawInputState, input_state: InputState):
	var move_dir = raw.get_left_stick_relative_to_agent()
	var look_dir = raw.get_right_stick_relative_to_agent()
	
	input_state.forward = move_dir.y < -STICK_DEADZONE
	input_state.backward = move_dir.y > STICK_DEADZONE
	input_state.left = move_dir.x < -STICK_DEADZONE
	input_state.right = move_dir.x > STICK_DEADZONE

	if move_dir.length() < STICK_DEADZONE:
		move_dir *= 0

	if look_dir.length() < STICK_DEADZONE:
		look_dir *= 0

	input_state.move_dir = move_dir
	input_state.look_dir = look_dir

func get_last_action(sequences, delta):
	var valid_sequences = []
	var buf = buffer
	for sequence in sequences:
		if sequence.fulfilled(buf, time, WINDOW_SIZE):
			valid_sequences.append(sequence)
	valid_sequences.sort_custom(func(a, b): return a.priority < b.priority)
	if valid_sequences:
		return valid_sequences[0].action_name
	return ""
