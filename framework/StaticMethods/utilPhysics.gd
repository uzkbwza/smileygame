extends Node

class_name Physics

static func spring(x:float,  v:float, xt:float, zeta:float, omega:float, h:float) -> Array[float]:
	# thanks chaoclypse
	var f := 1.0 + 2.0 * h * zeta * omega
	var oo := omega * omega
	var hoo := h * oo
	var hhoo := h * hoo
	var detInv := 1.0 / (f + hhoo)
	var detX := f * x + h * v + hhoo * xt
	var detV := v + hoo * (xt - x)
	x = detX * detInv
	v = detV * detInv
	return [x,v]

static func vector_spring(vec:Vector2, vel:Vector2, target:Vector2, zeta:float,  omega:float,  h:float) -> Array[Vector2]:
	var x := vec.x;
	var y := vec.y;
	var t1 := spring(x, vel.x, target.x, zeta, omega, h);
	x = t1[0]
	vel.x = t1[1]
	var t2 := spring(y, vel.y, target.y, zeta, omega, h);
	y = t2[0]
	vel.y = t2[1]
	vec = Vector2(x, y);
	return [vec,vel];

static func area2d_contains_point(area2d: Area2D, point: Vector2) -> bool:
	var space_state = area2d.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = area2d.collision_layer
	var colliders = space_state.intersect_point(params, 32)
	for data in colliders:
		if data.collider == area2d:
			return true
	return false

static func get_colliders_at_point(point: Vector2, world: World2D, collision_mask = 0xFFFFFFFF) -> Array[Dictionary]:
	var space_state = world.direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = collision_mask
	return space_state.intersect_point(params, 32)

static func get_area2ds_at_point(point: Vector2, world: World2D, collision_mask = 0xFFFFFFFF) -> Array[Area2D]:
	var space_state = world.direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = collision_mask
	var areas: Array[Area2D] = []
	for datum in space_state.intersect_point(params, 32):
		areas.append(datum.collider)
	return areas
	
static func get_body2ds_at_point(point: Vector2, world: World2D, collision_mask = 0xFFFFFFFF) -> Array[PhysicsBody2D]:
	var space_state = world.direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = collision_mask
	var bodies: Array[PhysicsBody2D] = []
	for datum in space_state.intersect_point(params, 32):
		bodies.append(datum.collider)
	return bodies

static func body2d_contains_point(body2d: PhysicsBody2D, point: Vector2) -> bool:
	var space_state = body2d.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = body2d.collision_layer
	var collider_data = space_state.intersect_point(params, 32)
	for datum in collider_data:
		if datum.collider == body2d:
			return true
	return false
