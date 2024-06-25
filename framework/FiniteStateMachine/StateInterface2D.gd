extends Node2D

class_name StateInterface2D

@export var custom_animation: String
@export var has_animation = true
@export_range(0.0, 10.0, 0.001) var animation_player_blend_time = 0.00
@export var next_state: String

@export var update = true
# State interface for StateMachine
@onready var state_name = name

#export var animation = "" setget , get_animation
var animation = "":
	get:
		if animation == "":
			if custom_animation == "":
				return get_name()
			return custom_animation
		else:
			return animation

var host
var active = false
var data = null

signal queue_change(state, self_)
signal queue_change_with_data(state, data, self_)

func queue_state_change(state, data=null):
	if !active:
		return
	if !data:
		queue_change.emit(state, self)
		return
	queue_change_with_data.emit(state, data, self)

func _previous_state():
	return get_parent().states_stack[-2].name if get_parent().states_stack.size() > 1 else name

func init():
	pass

func _enter_tree():
	host = get_parent().host

func _exit_tree():
	if active:
		_exit()

# virtual state logic methods

#######################
# shared methods for a state type. these will be called for every subclass of this state type, 
# before their individual methods
func _enter_shared():
	pass

func _update_shared(_delta):
	pass

# for fixed_step games
func _tick_shared():
	pass

func _integrate_shared(_state):
	# To use with _integrate_forces(state)
	pass

func _exit_shared():
	#  Cleanup and exit state
	pass
#######################

func _enter():
	# Initialize state 
	pass

# for fixed_step games
func _tick():
	pass

func _tick_after():
	pass

func _update(_delta):
	#  To use with _process or _physics_process
	pass
	
func _integrate(_state):
	# To use with _integrate_forces(state)
	pass

func _exit():
	#  Cleanup and exit state
	pass

func _animation_finished():
	pass
