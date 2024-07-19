extends Node

class_name Math

static func map(value: float, istart: float, istop: float, ostart: float, ostop: float) -> float:
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

static func map_pow(value: float, istart: float, istop: float, ostart: float, ostop: float, power: float) -> float:
	return ostart + (ostop - ostart) * (pow((value - istart) / (istop - istart), power))

static func ang2vec(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))

static func dtlerp(power: float, delta: float) -> float:
	return 1 - pow(pow(0.1, power), delta)

static func ease_out(num: float, pow: float) -> float:
	assert(num <= 1 and num >= 0)
	return 1.0 - pow(1.0 - num, pow)

static func lerp_clamp(a: Variant, b: Variant, t: float) -> Variant:
	return lerp(a, b, clamp(t, 0.0, 1.0))

static func inverse_lerp_clamp(a: Variant, b: Variant, v: float) -> Variant:
	return clamp(inverse_lerp(a, b, v), 0.0, 1.0)

static func angle_diff(from: float, to: float) -> float:
	return fposmod(to-from + PI, PI*2) - PI

## exponential decay function stolen from freya holmer 
## i call it spring lerp or splerp for short because it's funny
static func splerp(a: float, b: float, delta: float, half_life: float) -> float:
	return b + (a - b) * pow(2, -delta / (half_life / 60))
	
static func splerp_vec(a: Vector2, b: Vector2, delta: float, half_life: float) -> Vector2:
	return b + (a - b) * pow(2, -delta / (half_life / 60))

static func ping_pong_interpolate(value: float, a: float, b: float, ease:=1.0) -> float:
	var start = min(a, b)
	var end = max(a, b)
	var t = inverse_lerp(start, end, value)
	
	var f = fposmod(t, 1.0)
	if floori(t) % 2 != 0:
		f = 1.0 - f
	return start + ease(f, ease) * (end - start)

static func damp(source: float, target: float, smoothing: float, dt: float) -> float:
	return lerp(source, target, dtlerp(smoothing, dt))

static func damp_angle(source: float, target: float, smoothing: float, dt: float) -> float:
	return lerp_angle(source, target, 1 - pow(smoothing, dt))

static func damp_vec2(source: Vector2, target: Vector2, smoothing: float, dt: float) -> Vector2:
	return source.lerp(target, 1 - pow(smoothing, dt))

static func damp_vec3(source: Vector3, target: Vector3, smoothing: float, dt: float) -> Vector3:
	return source.lerp(target, 1 - pow(smoothing, dt))

static func vec_dir(vec_1: Vector2, vec_2: Vector2) -> Vector2:
	return (vec_2 - vec_1).normalized()

static func sin_0_1(value: float) -> float:
	return (sin(value) / 2.0) + 0.5

static func clamp_cell(cell: Vector2i, map: Array2D) -> Vector2i:
	return Vector2i(clamp(cell.x, 0, map.width - 1), clamp(cell.y, 0, map.height - 1))

static func stepify(s: float, step: float) -> float:
	return round(s / step) * step

static func stepify_floor(s: float, step: float) -> float:
	return floor(s / step) * step
	
static func wave(from: float, to: float, duration: float, offset: float =0) -> float:
	var t := Time.get_ticks_msec() / 1000.0
	var a := (to - from) * 0.5
	return from + a + sin((((t) + duration * offset) / duration) * TAU) * a

static func pulse(duration:float=1.0, width:float=0.5) -> bool:
	return wave(0.0, 1.0, duration) < width

static func snap(value: float, step: float) -> float:
	return round(value / step) * step

static func approach(a: float, b: float, amount: float) -> float:
	if a < b:
		a += amount
		if a > b:
			return b
	else:
		a -= amount
		if a < b:
			return b
	return a
