extends Node2D

@export_range(1, 500) var num_lines = 10
@export var free_when_finished = false

@export_category("Line Properties")
@export_range(2, 100) var line_points = 3
@export var color = Color.WHITE
@export_range(1.0, 40) var max_width = 40.0
@export_range(1.0, 20) var starting_width =2.0
@export_range(0.0, 10.0) var starting_width_deviation = 0.2

@export_category("Line Behavior")
@export_range(0.0, 2000) var starting_velocity = 400.0
@export_range(0.0, 10.0) var starting_velocity_deviation = 0.7
@export_range(0.0, 100) var deceleration_half_life = 6.0
@export_range(0.0, TAU) var dir_deviation = 0.6

## adjusts the number of line segments based on framerate
@export var dynamic_point_count = true

@export_range(0.0, 20.0) var branch_chance = 1.0
@export_range(0.0, 10.0) var branch_vel_deviation = 0.5
@export_range(0.0, 100.0) var branch_extra_vel = 0.0
@export_range(0.0, 1000.0) var min_vel = 5

@export_category("Direction_bias")
@export var bias_dir = Vector2(1, 0)
@export_range(0, 1) var bias_amount = 0.0
@export var two_way_bias = false



var real_num_points:
	get:
		if !dynamic_point_count:
			return line_points

		var fps = DisplayServer.screen_get_refresh_rate() if Engine.max_fps <= 0 else min(DisplayServer.screen_get_refresh_rate(), Engine.max_fps)
		var mod = fps / 60.0
		

		return max(floor(line_points * mod), 2)

var lines: Array[PackedVector2Array] = []
var vels: Array[float] = []
var widths: Array[float] = []
var rng = BetterRng.new()
var t = 0.0
# Called when the node enters the scene tree for the first time.

func go() -> void:

	lines.clear()
	vels.clear()
	widths.clear()
	t = 0.0
	for i in range(num_lines):
		var arr = PackedVector2Array()
		var dir = rng.random_vec(true).lerp(bias_dir * (1 if !two_way_bias else (1 if i % 2 == 0 else -1)), bias_amount if rng.chance(bias_amount) else 0.0).normalized()
		var vel = starting_velocity * rng.randfn(1.0, starting_velocity_deviation)
		if rng.chance(bias_amount):
			vel = lerp(vel, vel * (abs(dir.dot(bias_dir)) if two_way_bias else dir.dot(bias_dir)), bias_amount)
		
		for j in range(1, real_num_points + 1):
			arr.append((j / float(real_num_points)) * dir)
			

		lines.append(arr)
		vels.append(vel)
		widths.append(starting_width * rng.randfn(1.0, starting_width_deviation))

func _ready() -> void:
	go()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	
	var done = true
	var width
	var vel_ratio
	var vel
	var line
	var dir
	for i in lines.size():
		vel = vels[i]
		if vel > min_vel:
			width = widths[i]
			vel = Math.splerp(vel, 0, delta, deceleration_half_life)
			vel_ratio = inverse_lerp(0, starting_velocity, vel)
			width = starting_width * vel_ratio
			width = clamp(width, 1, max_width)
			done = false
		else:
			continue
		
		
		line = lines[i]
		dir = (line[-1] - line[-2]).normalized()
		#dir = (line[-1] - line[-2]).normalized().lerp(bias_dir * (1 if !two_way_bias else (1 if i % 2 == 0 else -1)), bias_amount * vel_ratio)
		line.append(line[-1] + dir.rotated(rng.randfn(0.0, dir_deviation)) * ((vel * delta)))

		lines[i] = line.slice(1)
		vels[i] = vel
		widths[i] = width
		if rng.chance_delta(branch_chance, delta):
			lines.append(line.duplicate())
			vels.append(vel * rng.randfn(1.0, branch_vel_deviation) + branch_extra_vel)
			widths.append(width)
			pass
	
	t += delta
	#

	if done:
		queue_free()

func _draw():
	for i in lines.size():
		if vels[i] <= min_vel:
			continue
		var line = lines[i]
		draw_polyline(line, color, widths[i], false)
