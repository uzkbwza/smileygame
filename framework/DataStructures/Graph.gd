class_name Graph

signal node_added(node)
signal node_removed(node)
signal edge_added(from, to, bidirectional, weight)
signal edge_removed(from, to, bidirectional)

var nodes: Dictionary = {}
var id2n: Dictionary = {}
var n2id: Dictionary = {}
var index = 0
var iter_index = 0
var astar: GAStar = GAStar.new(self)

var use_euclidean_distance = false

class GAStar extends AStar3D:
	var host: Graph
	
	func _init(host):
		self.host = host

	func _compute_cost(from_id, to_id) -> float:
		var from = host.id2n[from_id]
		var to = host.id2n[to_id]
		return host._compute_cost(from, to)

func _init(starting_graph = {}, build_bidirectional=false, use_euclidean_distance=false):
	self.use_euclidean_distance = use_euclidean_distance
	if starting_graph is Dictionary:
		for node in starting_graph:
			add_node(node)
		for node in starting_graph:
			var value = starting_graph[node]
			if value is Dictionary:
				for connection in value:
					var weight = value[connection]
					add_edge(node, connection, build_bidirectional, weight)

			elif value is Array:
				for connection in value:
					add_edge(node, connection, build_bidirectional)

			elif value != null:
				add_edge(node, value, build_bidirectional)

	elif starting_graph is Array:
		for node in starting_graph:
			add_node(node)
	elif !(starting_graph == null):
		add_node(starting_graph)

func _compute_cost(from, to):
		# this should only happen if from and to are the same node.
		if !nodes[from].has(to):
			assert(from == to)
			return 0.0

		var weight = nodes[from][to]
		
		# special cases
		if use_euclidean_distance:
			if from is Node2D and to is Node2D:
				return abs(from.global_position.length() - to.global_position.length()) * weight
			if from is Node3D and to is Node3D:
				return abs(from.global_position.length() - to.global_position.length()) * weight
			if from is Vector2 and to is Vector2:
				return abs(from.length() - to.length()) * weight
			if from is Vector2 and to is Vector2:
				return abs(from.length() - to.length()) * weight
		return float(weight)

func add_node(node, id=null):
	if nodes.has(node):
		return
	nodes[node] = {}
	# a* stuff
	if id == null:
		id = index
	id2n[id] = node
	n2id[node] = id
	astar.add_point(id, Vector3())
	index += 1
	node_added.emit(node)

func replace_node(id, new_node):
	var old_node = id2n[id]
	
	nodes[new_node] = nodes[old_node]
	nodes.erase(old_node)
	for node in nodes:
		for connection in nodes[node]:
			if connection == old_node:
				nodes[node][new_node] = nodes[node][connection]
				nodes[node].erase(connection)
	
	# a* stuff
	n2id.erase(old_node)
	n2id[new_node] = id
	id2n[id] = new_node

func remove_node(node_to_remove):
	# remove it from the nodes dict
	nodes.erase(node_to_remove)
	# remove all edges to it
	for edge_list in nodes.values():
		edge_list.erase(node_to_remove)
	# a* stuff
	var id = n2id[node_to_remove]
	n2id.erase(node_to_remove)
	id2n.erase(id)
	astar.remove_point(id)
	node_removed.emit(node_to_remove)

func add_edge(node1, node2, bidirectional=true, weight=1):
	# make sure the nodes exist
	add_node(node1)
	add_node(node2)
	nodes[node1][node2] = weight
	if bidirectional:
		nodes[node2][node1] = weight
	# a* stuff
	astar.connect_points(n2id[node1], n2id[node2], bidirectional)

	edge_added.emit(node1, node2, bidirectional, weight)

func remove_edge(node1, node2, bidirectional=true):
	nodes[node1].erase(node2)
	if bidirectional:
		nodes[node2].erase(node1)
	# a* stuff
	astar.disconnect_points(n2id[node1], n2id[node2], bidirectional)
	edge_removed.emit(node1, node2, bidirectional)

func is_node_connected(node1, node2):
	return nodes[node1].has(node2)

func dist(node1, node2) -> float:
	var path = path(node1, node2)
	return dist_from_path(path)

func dist_from_path(path):
	if path.size() <= 1:
		return 0
	var total_dist = 0
	for i in range(path.size() - 1):
		var current = path[i]
		var next = path[i + 1]
		total_dist += _compute_cost(current, next)
	return total_dist

func path(node1, node2) -> Array:
	if !nodes.has(node1):
		if nodes.has(node2):
			return [node2]
		return []

	if !nodes.has(node2):
		if nodes.has(node1):
			return [node2]

	var path = astar.get_id_path(n2id[node1], n2id[node2])
	var arr = []
	for id in path:
		arr.append(id2n[id])
	return arr

func print_graph():
	var full_text = ""
	var keys = nodes.keys()
	for node in keys:
		var edge_text = ""
		for edge in nodes[node]:
			edge_text += "%s: %s, " % [edge, nodes[node][edge]]

		full_text += "%s: [color=696969][ [/color]%s[color=696969]][/color] \n" % [node, edge_text]
	print_rich(full_text.strip_edges())

func _iter_init(_arg) -> bool:
	iter_index = 0
	return iter_index < nodes.size()

func _iter_next(_arg) -> bool:
	iter_index += 1
	return iter_index < nodes.size()

func _iter_get(_arg) -> Variant:
	return nodes.keys()[iter_index]

func verify_astar():
	var valid = true
	for node in nodes:
		if !astar.has_point(n2id[node]):
			valid = false
		var edges = nodes[node]
		for edge in edges:
			if !astar.are_points_connected(n2id[node], n2id[edge]):
				valid = false
	assert(valid)
	return valid
