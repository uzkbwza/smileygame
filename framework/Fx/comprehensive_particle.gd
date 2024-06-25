@tool
extends BaseDrawParticle

class_name ComprehensiveCPUParticle

enum CircleLocation {
	BEGIN,
	END,
	BOTH,
}

@export var use_lines = true
@export var use_circles = false
@export var circle_location : CircleLocation = CircleLocation.BOTH
@export var num_lines: int = 20
@export var max_radius = 12.0
@export var min_radius = 6.0
@export var min_length = 0.5
@export var max_length = 4.0
@export var min_distance = 2.0
@export var max_distance = 10.0
@export var min_width = 1.0
@export var max_width = 4.0
@export var start_spread = 0.0
@export var angle_spread = 10.0
@export var start_distance = 3.0
@export var vertical_offset = 0.0
@export var vertical_offset_pow = 2.0
@export var dir = Vector2(1, 0)
@export var modifier = 1.0
@export var symmetrical = true
@export var straight_spread = rad2deg(TAU/20)
@export var wide_spread = rad2deg(TAU/4)
@export var straight_size_modifier = 2.0
@export var wide_size_modifier = 1.0
@export var full_circle_size_modifier = 0.5
@export var straight_weight = 45.0
@export var wide_weight = 45.0
@export var full_circle_weight = 10.0
@export var dist_from_center = 0.0
@export var width_animation_delay = 0.0
@export var width_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var animate_width = false
@export var end_jump = true
@export var match_radius_to_width = true

@export var use_curve_for_tween = false
@export var curve: Curve = Curve.new()

var lines = []
var _dir = dir
#var threads: Array[Thread] = []

class LineParticle:
	var length: float
	var distance: float
	var width: float
	var color: Color
	var start_distance: float 
	var dir: Vector2
	var position: Vector2
	var starting_position: Vector2
	var time = 0.0
	var width_anim_time = 0.0
	var radius = 1.0
	var vertical_offset = 0.0


#func _ready():
#	super._ready()
#	if curve == null:
#		curve = Curve.new()
#		curve.add_point(Vector2(0, 0), 0)
#		curve.add_point(Vector2(1, 1), 0)

func setup():
	
	lines = []
#	threads = []
	_dir = dir.normalized()
	rng.randomize()
	for i in range(num_lines):
#		if !Engine.is_editor_hint():
#			var thread = Thread.new()
#			threads.append(thread)
#			thread.start(setup_line)
#		else:	
		setup_line()

func setup_line(_data=null):
	var straight_cone = func():
		return _get_cone(straight_spread, straight_size_modifier)

	var wide_cone = func():
		return _get_cone(wide_spread, wide_size_modifier)
		
	var full_circle = func():
		return _get_cone(360, full_circle_size_modifier)
		
	var functions = [straight_cone, wide_cone, full_circle]
	var func_weights = [straight_weight, wide_weight, full_circle_weight]
	var line = rng.weighted_choice(functions, func_weights).call()
	var tween = get_tween()
	var d = get_random_duration()
	tween.tween_method(set_particle_time.bind(line), 0.0, 1.0, d)
#	tween.tween_property(line, "time", 1.0, d)
#		if width_animation_delay > 0:
	var tween2 = get_tween()
	tween2.set_parallel(false)
	tween2.set_ease(width_ease_type)
	var delay = d * width_animation_delay
	tween2.tween_interval(delay)
	tween2.tween_property(line, "width_anim_time", 1.0, d - min(delay, d))
	if symmetrical and rng.coin_flip():
		line.dir.x *= -1
	lines.append(line)

func set_particle_time(time, particle):
	if use_curve_for_tween:
		particle.time = curve.interpolate(time)
	else:
		particle.time = time
	particle.time = min(particle.time, 1)
	
func _get_cone(spread, size_modifier) -> LineParticle:
	var particle = LineParticle.new()
	spread = deg_to_rad(spread)
	particle.length = rng.randf_range(min_length, max_length) * size_modifier
	particle.distance = rng.randf_range(min_distance, max_distance) * size_modifier
	particle.width = rng.randf_range(min_width, max_width)
	particle.dir = _dir.rotated(rng.randf_range(-spread, spread))
	particle.position = rng.random_vec() * start_spread + particle.dir * dist_from_center
	particle.starting_position = position
	particle.vertical_offset = rng.randf_range(0, vertical_offset)
	if match_radius_to_width:
		particle.radius = particle.width/2.0
	else:
		particle.radius = rng.randf_range(min_radius, max_radius)
	return particle

func draw():
	for line in lines:
		var t = line.time
		var w = line.width_anim_time
		var e = pow(t, vertical_offset_pow)
		if end_jump:
			var mod = (0.80 if line.time < 0.90 else lerp(0.80, 1.0, 1 - ((1 - line.time) * 10)))
			t = line.time * mod
			w = line.width_anim_time * mod
		
		var start = (line.distance + start_distance) * line.dir
		var end = (start + line.dir) * (max_distance - start_distance)
		var line_end = (start + line.dir * line.length).lerp(end + line.dir * line.length, line.time)
		line_end = line_end.lerp(line_end + Vector2.DOWN * line.vertical_offset, e)
		var line_start = start.lerp(line_end, t)
		if use_lines:
			draw_line(line.position + line_start * modifier, line.position + line_end * modifier, color, line.width * modifier * ((1.0 - w) if animate_width else 1.0))
		if use_circles:
			line.radius = max(line.radius, 2)
			var r = line.radius * (((1.0 - w) if animate_width else 1.0) if match_radius_to_width else (1.0 - w))
			if circle_location == CircleLocation.BOTH or circle_location == CircleLocation.END:
				draw_circle(line.position + line_end * modifier, r, color)
			if circle_location == CircleLocation.BOTH or circle_location == CircleLocation.BEGIN:
				draw_circle(line.position + line_start * modifier, r, color)
