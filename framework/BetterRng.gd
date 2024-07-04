extends RandomNumberGenerator

class_name BetterRng

const cardinal_dirs = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const diagonal_dirs = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]

static func ang2vec(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))
	
func random_dir(diagonals:=false, zero:=false) -> Vector2i:
	var dirs : Array[Vector2i] = []
	dirs.append_array(cardinal_dirs)
	if diagonals:
		dirs.append_array(diagonal_dirs)
	if zero:
		dirs.append_array([Vector2i(0, 0)])
	return choose(dirs)

func _init() -> void:
	self.randomize()

func spread_vec(vec: Vector2, spread_degrees: float) -> Vector2:
	return vec.rotated(randf_range(deg_to_rad(-spread_degrees/2), deg_to_rad(spread_degrees/2)))

func random_angle() -> float:
	return randf_range(0, TAU)
	
func random_angle_centered() -> float:
	return randf_range(0, TAU) - TAU/2

func random_cell(start: Vector2i, end: Vector2i) -> Vector2i:
	return Vector2i(self.randi_range(start.x, end.x), self.randi_range(start.y, end.y))

func random_rect2i(start: Vector2i, end: Vector2i, min_width := 1, min_height := 1, max_width :=INF, max_height :=INF) -> Rect2i:
	var rect_size := Vector2i(randi_range(min_width, max_width), randi_range(min_height, max_height))
	var rect_start := random_cell(start, end - rect_size)
	return Rect2i(rect_start, rect_size)

func random_vec(normalized :=true) -> Vector2:
	return ang2vec(random_angle()) * (randf_range(0, 1) if !normalized else 1)

func choose(array: Array) -> Variant:
	if array.size() == 0:
		return null
	return array[randi() % array.size() - 1]

func rand_sign() -> int:
	return -1 if randi() % 2 == 0 else 1

func coin_flip() -> bool:
	return randi() % 2 == 0

func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))

func weighted_randi_range(start: int, end: int, weight_function: Callable) -> int:
	if start == end:
		return start
	var weight_sum := 0.0
	var weights : Array[int] = []
	for i in range(start, end):
		var weight: int = weight_function.call(i)
		weights.append(weight)
		weight_sum += weight
	var rnd := randf_range(0, weight_sum)
	for i in range(start, end):
		var weight := weights[start + i]
		if rnd <= weight:
			return i
		rnd -= weight
	assert(false, "should never get here")
	return 0

func percent(percent: float) -> bool:
	return chance(percent / 100.0)

func percent_delta(percent: float, delta: float, max: float=INF) -> bool:
	return chance_delta(percent / 100.0, delta, max / 100.0)

func chance(n:float) -> bool:
	if n >= 1:
		return true
	if n <= 0:
		return false
	return randf() < n

func chance_delta(chance: float, delta: float, max: float=INF) -> bool:
	# Calculates probability of at least one occurrence happening over `delta` 
	# seconds and returns a random bool based on that probability.
	# if chance is 2.0, it should generally occur around twice per second.
	# Calculates cumulative chance for it happening over time, meaning delta
	# of e.g. 10 seconds and chance of 1.0 per second will likely return true,
	# but if you need to actually have events occur more than once per second,
	# you will probably want to poll this function every game tick.
	var probability_at_least_one := 1 - exp(-chance * delta)

	return self.chance(min(probability_at_least_one, max))

func weighted_choice(array: Array, weight_array: Array) -> Variant:
	return func_weighted_choice(array, func(i: int) -> Variant: return weight_array[i])

func func_weighted_choice(array: Array, weight_function: Callable) -> Variant:
	if array.is_empty():
		return null

	return array[weighted_randi_range(0, array.size(), weight_function)]
