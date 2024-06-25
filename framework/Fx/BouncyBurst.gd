@tool

extends Node2D

class_name BouncyBurst

const WIDTH = 1

@export var num_bodies := 100
@export_flags_2d_physics var collision_mask := 1
@export_flags_2d_physics var collision_layer := 0
@export var autostart := true

@export_category("Line Properties")
@export_range(1, 100, 1, "or_greater") var segment_count := 2
@export var color := Color.WHITE

## adjusts the number of line segments based on framerate
@export var dynamic_point_count := true

@export_range(0.0, 10.0, 0.25, "or_greater") var jitter_amount := 0.0
@export_range(0.0, 50.0, 1, "or_greater") var quantize_amount := 0.0

@export_category("Start Behavior")
@export_range(0.0, 2000, 0.5, "or_greater") var starting_velocity := 500.0
@export_range(0.0, 2000, 0.5, "or_greater") var starting_velocity_deviation := 100.0
@export_range(0.0, 100.0, 0.5, "or_greater") var max_starting_distance := 2.0
@export_range(0.0, 2000, 0.5, "or_greater") var min_speed := 0.0

@export_category("Body Properties")
@export_range(0.0, 1.0, 0.001, "or_greater") var bounce := 0.4
@export_range(0.0, 1.0, 0.001, "or_greater") var friction := 0.05
@export_range(0.0, 10.0, 0.0001, "or_greater") var mass := 0.05
@export_range(-1.0, 100.0, 0.005, "or_greater", "or_less") var damp := 00
@export_range(-10.0, 10.0, 0.1) var gravity_scale := 1.0
@export var continuous_cd := PhysicsServer2D.CCD_MODE_CAST_RAY
@export var freeze_rotation := true
@export var lifetime := 0

@export_category("Bias")
@export_range(0, 1) var direction_bias_amount := 0.0
@export_range(0, 1) var velocity_bias_amount := 0.0
@export_range(0, 10, 0.001, "or_greater") var velocity_bias_multiplier := 1.0
@export_range(0, 50, 0.5, "or_greater") var velocity_bias_power := 2.0
@export_range(0, 1) var ignore_bias_effect_chance := 0.0

var px1_mode: bool = false

var real_num_points: int:
	get:
		if !dynamic_point_count:
			return segment_count * 2

		var fps : float = DisplayServer.screen_get_refresh_rate() if Engine.max_fps <= 0 else min(DisplayServer.screen_get_refresh_rate(), Engine.max_fps)
		var mod := fps / 60.0

		return max(floor(Math.stepify(segment_count * mod * 2, 2)), 2)

var bias_dir: Vector2

var bodies: Array[RID] = []

var canvas_item: RID
var collision_shape: RID

var lines: Array[PackedVector2Array] = []

var physics_mode: PhysicsServer2D.BodyMode

var colors: PackedColorArray = PackedColorArray()

var initialized := false

var bias_active := false

var num_left: int = 0

var bodies_to_remove: Array[RID] = []

var rng := BetterRng.new()

func _ready() -> void:
	set_process(false)
	
	if Engine.is_editor_hint():
		return
	if autostart:
		go()
	
func go() -> void:
	if lifetime > 0:
		get_tree().create_timer(lifetime, false, true, false).timeout.connect(queue_free)
	if initialized:
		return
	
	#assert(!initialized)
	_initialize()
	set_process.call_deferred(true)

func _process(delta: float) -> void:
	_draw_lines()
	
func _draw_lines() -> void:
	_canvas_item_clear()
	
	var jitter := jitter_amount > 0
	var quantize :bool = quantize_amount > 0
	var finished := true
	for id in num_left:
		var body := bodies[id]
		
		
		if PhysicsServer2D.body_get_state(body, PhysicsServer2D.BODY_STATE_SLEEPING):
			bodies_to_remove.append(body)
			num_left -= 1
			continue
		finished = false
		
		var line := lines[id]
		#var bodypos: Vector2 = Vector2()

		var tform: Transform2D = PhysicsServer2D.body_get_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM) 
		var bodypos := tform.origin - global_position
		var vel : Vector2 = PhysicsServer2D.body_get_state(body, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
#
		if jitter:
			if abs(vel.x) > 10 or abs(vel.y) > 10:
				bodypos += Vector2(rng.randf_range(-jitter_amount, jitter_amount), rng.randf_range(-jitter_amount, jitter_amount))
				#bodypos += rng.random_vec(false) * jitter_amount
		if quantize:
			bodypos.x = Math.stepify(bodypos.x, quantize_amount)
			bodypos.y = Math.stepify(bodypos.y, quantize_amount)
		
		line.append(line[-1])
		line.append(bodypos)

		line = line.slice(2)
		lines[id] = line

		RenderingServer.canvas_item_add_multiline(canvas_item, line, colors, WIDTH, false)

		#else:
			#RenderingServer.canvas_item_add_circle(canvas_item, line[-1], circle_radius, colors[-1])

	_cleanup_bodies()

	if finished and !is_queued_for_deletion():
		queue_free()
	
func _cleanup_bodies() -> void:
	for body in bodies_to_remove:
		var index := bodies.find(body)
		PhysicsServer2D.free_rid(body)
		bodies.remove_at(index)
		lines.remove_at(index)
	bodies_to_remove.clear()

func _canvas_item_clear() -> void:
	RenderingServer.canvas_item_clear(canvas_item)
	RenderingServer.canvas_item_set_parent(canvas_item, get_canvas_item())
	RenderingServer.canvas_item_set_transform(canvas_item, Transform2D())

func _initialize() -> void:
	bias_active = direction_bias_amount > 0 or velocity_bias_amount > 0
	bias_dir = Vector2.RIGHT.rotated(global_rotation)
	global_rotation *= 0
	
	

	if freeze_rotation:
		physics_mode = PhysicsServer2D.BODY_MODE_RIGID_LINEAR 
	else:
		physics_mode = PhysicsServer2D.BODY_MODE_RIGID
	
	_create_canvas_item()

	collision_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(collision_shape, WIDTH / 2.0)

	var num_segments = real_num_points

	for i in num_segments:
		colors.append(color)

	var world_space :RID = get_world_2d().space

	for id in num_bodies:
		var body := _create_body(world_space)
		var line := PackedVector2Array()
		for point_id in num_segments:
			line.append(Vector2())
			line.append(Vector2())

		lines.append(line)
		bodies.append(body)

	num_left = num_bodies

	set_physics_process(true)
	initialized = true

func _create_body(space:RID) -> RID:
	var body := PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(body, physics_mode)
	
	PhysicsServer2D.body_add_shape(body, collision_shape)
	PhysicsServer2D.body_set_param(body, PhysicsServer2D.BODY_PARAM_MASS, mass)
	
	PhysicsServer2D.body_set_space(body, space)
	PhysicsServer2D.body_set_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM, transform.translated(rng.random_vec(false) * max_starting_distance))
	PhysicsServer2D.body_set_param(body, PhysicsServer2D.BODY_PARAM_BOUNCE, bounce)
	PhysicsServer2D.body_set_param(body, PhysicsServer2D.BODY_PARAM_FRICTION, friction)
	PhysicsServer2D.body_set_param(body, PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, gravity_scale)
	PhysicsServer2D.body_set_param(body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, damp)
	PhysicsServer2D.body_set_continuous_collision_detection_mode(body, continuous_cd)
	PhysicsServer2D.body_set_state(body, PhysicsServer2D.BODY_STATE_SLEEPING, false)
	
	var ignore_bias := !bias_active or rng.chance(ignore_bias_effect_chance)
	var speed := starting_velocity + rng.randfn(0, starting_velocity_deviation)
	var impulse := rng.random_vec()

	if !ignore_bias:
		if rng.chance(direction_bias_amount):
			impulse = impulse.lerp(bias_dir, direction_bias_amount)
		var new_speed := speed * (pow(Math.map(impulse.dot(bias_dir), -1, 1, 0, 1), velocity_bias_power) * velocity_bias_multiplier)
		speed = lerpf(speed, new_speed, velocity_bias_amount)

	speed = max(speed, min_speed)

	PhysicsServer2D.body_apply_impulse(body, impulse * speed * scale.x)
	PhysicsServer2D.body_set_collision_mask(body, collision_mask)
	PhysicsServer2D.body_set_collision_layer(body, collision_layer)
	return body
	
func _create_canvas_item() -> void:
	canvas_item = RenderingServer.canvas_item_create()
	_canvas_item_clear()

func kill() -> void:
	for i in len(bodies):
		PhysicsServer2D.free_rid(bodies[i])
	if canvas_item:
		RenderingServer.free_rid(canvas_item)
	if collision_shape:
		PhysicsServer2D.free_rid(collision_shape)
	bodies.clear()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(-10, 0), Vector2(20, 0), Color.RED, 1.0)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color.BLUE, 1.0)

func _exit_tree() -> void:
	kill()
