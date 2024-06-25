extends Node

class_name GoapPlanner

var actor = null
var goals: Array[GoapGoal] = []
var actions: Array[GoapAction] = []

class ActionGraphNode:
	var action: GoapAction
	var before_state = {}
	var after_state = {}
	func _init(action, before, after):
		self.action = action
		self.before_state = before
		self.after_state = after


func _init(actor, goals: Array, actions: Array):
	self.actor = actor
	for goal in goals:
		self.goals.append(goal.new(actor))
	for action in actions:
		self.actions.append(action.new(actor))

func get_plan(goal: GoapGoal, current_state: Dictionary):
	var graph = Graph.new()
	build_plan_graph(graph, current_state, goal.desired_state.duplicate(true))

func build_plan_graph(graph: Graph, starting_state: Dictionary, desired_state: Dictionary, current_action=null):
	for action in actions:
		if action.is_valid():
			pass
	return

func is_goal_valid(goal: GoapGoal, world_state: Dictionary):
	if !goal.is_valid():
		return false
	for precondition in goal.preconditions:
		if world_state[precondition] != goal.preconditions:
			return false
	return true

func choose_goal(world_state):
	var valid_goals = goals.filter(func(goal): is_goal_valid(goal, world_state))
	valid_goals.sort_custom(func(a: GoapGoal, b: GoapGoal): return a.priority > b.priority)
	assert(valid_goals.size() > 0)
	return valid_goals[0]
