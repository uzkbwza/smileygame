extends RefCounted

class_name GoapAgent

var planner: GoapPlanner

var actor = null

var current_action: GoapAction = null
var current_goal: GoapGoal = null
var current_plan: Array = []
var world_state
var waiting_for_signal: Signal

func _init(actor, goals: Array, actions: Array):
	self.actor = actor
	planner = GoapPlanner.new(actor, goals, actions)

func step():
	world_state = _get_current_worldstate()
	_update_goal()
	_follow_action()

func _update_goal():
	var goal = planner.choose_goal()
	if current_goal == null or current_goal != goal:
		current_goal = goal
		current_plan = planner.get_plan(goal, world_state)
		current_plan.reverse()
		assert(current_plan.size() > 0)
		start_new_action(current_plan[-1])

func start_new_action(action):
	current_action = action
	if waiting_for_signal:
		waiting_for_signal.disconnect(on_waited_for_signal)
	current_action.perform()
	waiting_for_signal = current_action.end_signal
	waiting_for_signal.connect(on_waited_for_signal, CONNECT_ONE_SHOT)

func _follow_action():
	if !planner.is_action_valid(current_action, world_state):
		_update_goal()

func on_waited_for_signal():
	
	current_plan.pop_back()
	current_action = current_plan[-1]

func _get_current_worldstate() -> Dictionary:
	return actor.get_current_worldstate()
