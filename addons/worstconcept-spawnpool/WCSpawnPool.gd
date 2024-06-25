class_name WCSpawnPool extends Node
## A node that pre-initializes scenes and pre-warms them in the SceneTree

## where to attach the node after spawning (if anywhere)
@export var spawn_parent: NodePath

## the scene file to spawn
@export_file("*.tscn","*.scn") var scene_file: String

## how many instances to prepare in-tree
@export_range(1,-1,1,"or_greater","hide_slider") var thres_in_tree: int = 1

## how many instances to prepare in-memory
@export_range(1,-1,1,"or_greater","hide_slider") var thres_in_memory: int = 1

## how many instances are currently prepared in-tree
var in_tree: int:
	set(_val): pass
	get: return _intree.get_child_count()

## how many instances are currently prepared in-memory
var in_memory: int:
	set(_val): pass
	get: return _inmemory.size()

var _inmemory : Array[Node] = []
var _intree : Node

## emitted when [method spawn] finishes
signal spawned(what: Node)

func _init() -> void:
	_intree = Node.new()
	_intree.name = &"_wcspawnpool_intree"
	_intree.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_intree,false,Node.INTERNAL_MODE_FRONT)

func _ready() -> void:
	pass

var _idle: bool = true
func _process(_delta: float) -> void:
	if _idle:
		_idle = false
		await _prewarm()
		await _preinit()
		_idle = true

## spawns an instance, calling [param cb], emitting [signal spawned] and returning the node async when done. [br]
## Note: in-tree "refills" at a rate of 1 per [method _process], so you may benefit from staggering repeated calls by a few frames.
func spawn(cb: Variant = null)->Node:
	@warning_ignore("unsafe_cast")
	assert(
		cb == null or (
			is_instance_valid(cb) and
			cb is Callable and
			(cb as Callable).get_argument_count()==1
		),
	"callback neither null nor valid Callable with 1 argument")
	if _intree.get_child_count() == 0:
		await _prewarm()
	var what := _intree.get_child(-1) as Node
	if "visible" in what and what.has_meta(&"_wcspawnpool_visible"):
		@warning_ignore("unsafe_property_access")
		what.visible = what.get_meta(&"_wcspawnpool_visible")
		what.remove_meta(&"_wcspawnpool_visible")
	if has_node(spawn_parent):
		what.reparent(get_node(spawn_parent))
	spawned.emit(what)
	if cb is Callable:
		(cb as Callable).call(what)
	return what

func _hide(what: Node)->void:
	if "visible" in what:
		@warning_ignore("unsafe_property_access")
		what.set_meta(&"_wcspawnpool_visible",what.visible)
		@warning_ignore("unsafe_property_access")
		what.visible = false

## re-hides and returns an instance back to the in-tree pool
func despawn(what: Node)->void:
	assert(what.scene_file_path==scene_file, "despawned node not instance of our scene_file")
	_hide(what)
	what.reparent(_intree)

func _prewarm()->void:
	var todo := thres_in_tree - _intree.get_child_count()
	if todo <= 0:
		return
	while _inmemory.size() == 0:
		await _preinit()
	var what := _inmemory.pop_back() as Node
	_intree.add_child.call_deferred(what)
	if not what.is_node_ready(): await what.ready
	return

var _busy: bool = false
func _preinit()->void:
	var todo := thres_in_memory - _inmemory.size()
	if todo <= 0:
		return
	if _busy:
		return
	_busy = true
	var task := WorkerThreadPool.add_group_task(_worker,todo)
	while not WorkerThreadPool.is_group_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task)
	_busy = false
	return

func _worker(_id: int)->void:
	var scene := load(scene_file) as PackedScene
	var what := scene.instantiate()
	_hide(what)
	_inmemory.push_back(what)
