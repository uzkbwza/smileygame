extends Node

class_name StateInterface

# State interface for StateMachine
@onready var state_name: String = name

#export var animation = "" setget , get_animation
var animation: String = "": 
	get:
		if animation == "":
			return get_name()
		else:
			return animation

var host
var active := false
var data = null

signal queue_change(state, self_)
signal queue_change_with_data(state, data, self_)

func queue_state_change(state, data=null) -> void:
	if !data:
		queue_change.emit(state, self)
		return
	queue_change_with_data.emit(state, data, self)

func _previous_state() -> String:
	return get_parent().states_stack[-2].name if get_parent().states_stack.size() > 1 else name

func init() -> void:
	pass

func _enter_tree() -> void:
	host = get_parent().host

func _exit_tree() -> void:
	if active:
		_exit()

# virtual state logic methods

#######################
# shared methods for a state type. these will be called for every subclass of this state type, 
# before their individual methods
func _enter_shared() -> void:
	pass

func _update_shared(_delta: float) -> void:
	pass

# for fixed_step games
func _tick_shared() -> void:
	pass

func _integrate_shared(_state: PhysicsDirectBodyState2D) -> void:
	# To use with _integrate_forces(state)
	pass

func _exit_shared() -> void:
	#  Cleanup and exit state
	pass
#######################

func _enter() -> void:
	# Initialize state 
	pass

# for fixed_step games
func _tick() -> void:
	pass

func _tick_after() -> void:
	pass

func _update(_delta: float):
	#  To use with _process or _physics_process
	pass
	
func _integrate(_state: PhysicsDirectBodyState2D) -> void:
	# To use with _integrate_forces(state)
	pass

func _exit() -> void:
	#  Cleanup and exit state
	pass

func _animation_finished() -> void:
	pass
