@tool
extends Node2D

const SPEED_MODIFIER = 1.0
const BASE_WIDTH = 64.0
const PARTICLE_AMOUNT = 128.0
const BASE_LENGTH = 320.0
const BASE_SPEED = 3500.0
const MAX_PARTICLES = 1024

@export var strength_gradient: Gradient

@export_range(16, 2048, 8.00000001) var length :int = BASE_LENGTH
@export_range(16, 1024, 8.00000001) var width :int = BASE_WIDTH
@export_range(100, 20000, 100.00000001) var speed :int = BASE_SPEED

@onready var wind_sprite: Sprite2D = $WindSprite
@onready var collision_shape: CollisionShape2D = %CollisionShape
@onready var area_2d: Area2D = $Area2D
@onready var icon: Sprite2D = $Icon
@onready var dust: GPUParticles2D = $Dust

var blowing_objects = []

var point_a # top of the base of the fan
var point_b # bottom of the base of the fan

func _ready() -> void:
	if !Engine.is_editor_hint():
		set_process(false)
	set_physics_process(false)
	point_a = wind_sprite.global_position
	point_b = point_a + Vector2(0, wind_sprite.scale.y).rotated(wind_sprite.global_rotation)
	update_everything()

func strength_formula(distance: float) -> float:
	if distance > length:
		return 0.0
	return strength_gradient.sample(distance / length).v
	#return (1.0 - (distance / length)) ** 2

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_everything()
		queue_redraw()

func update_everything():
	point_a = wind_sprite.global_position
	point_b = point_a + Vector2(0, wind_sprite.scale.y).rotated(wind_sprite.global_rotation)
	var fan_offset = (icon.texture.get_width() / 2.0) * icon.scale.x 
	wind_sprite.scale.x = length - fan_offset
	wind_sprite.scale.y = width
	wind_sprite.position.y = -(width / 2.0)
	wind_sprite.position.x = fan_offset
	wind_sprite.material.set_shader_parameter("texture_length", length / 100.0)
	wind_sprite.material.set_shader_parameter("texture_width", width / 100.0)
	wind_sprite.material.set_shader_parameter("speed", speed / 50000.0)
	wind_sprite.material.set_shader_parameter("rotation", wind_sprite.global_rotation)
	dust.process_material.emission_box_extents.y = width / 2.0
	dust.amount = clampf(PARTICLE_AMOUNT * (width / BASE_WIDTH), 0.0, MAX_PARTICLES)
	dust.scale.x = (speed / BASE_SPEED)
	#dust.scale.x = (length / BASE_LENGTH) * (speed / BASE_SPEED)
	dust.visibility_rect.position.y = -width / 2.0
	dust.visibility_rect.size.y = width
	dust.visibility_rect.size.x = length
	collision_shape.shape.size = Vector2(length - fan_offset, width)
	collision_shape.position = wind_sprite.position + collision_shape.shape.size * 0.5

func _physics_process(delta: float) -> void:
	update_everything()
	point_a = wind_sprite.global_position
	point_b = point_a + Vector2(0, wind_sprite.scale.y).rotated(wind_sprite.global_rotation)
	for body in blowing_objects:
		var dir = Vector2.LEFT.rotated(global_rotation)
		var point_d = Shape.ray_to_line_segment_origin(body.global_position, dir, point_a, point_b)
		if point_d:
			var strength = strength_formula(point_d.distance_to(body.global_position))
			if body is BaseObjectBody2D:
				var parent = body.get_parent()
				if parent is SmileyPlayer:
					if body.dir.dot(dir) > 0:
						if parent.current_state.get("retain_speed") != null:
							parent.current_state.retain_speed = false
							if parent.current_state.get("prev_speed") != null:
								parent.current_state.prev_speed = 0
				body.apply_force(-dir * speed * SPEED_MODIFIER * strength)
				body.velocity = Math.splerp_vec(body.velocity, body.velocity.length() * -dir, delta, 100.0 * ((20000.0 - speed) / 20000.0) + 100.0 * (1.0 - strength))
			Debug.dbg("wind_strength", strength)
		#Debug.dbg("wind_point", point_d)
	queue_redraw()

	

func _on_area_2d_body_entered(body: Node2D) -> void:
	blowing_objects.append(body)
	if !is_physics_processing():
		set_physics_process.call_deferred(true)

func _on_area_2d_body_exited(body: Node2D) -> void:
	blowing_objects.erase(body)
	if blowing_objects.is_empty():
		set_physics_process.call_deferred(false)

func _draw():
	if point_a == null:
		return
	if Engine.is_editor_hint() or Debug.draw:
		#draw_line(to_local(point_a), to_local(point_b), Color.RED, 2.0)
		
		var dir = Vector2.LEFT.rotated(global_rotation)
		for body in blowing_objects:
			if body == null:
				continue
			var point_d = Shape.ray_to_line_segment_origin(body.global_position, dir, point_a, point_b)
			if point_d:
				var color = Color.CYAN
				var strength = strength_formula(point_d.distance_to(body.global_position))
				
				color.a = 0.5 + strength
				color.r += strength * 0.5
				
				draw_circle(to_local(body.global_position), 8.0, color, false, 2.0)
				draw_line(to_local(body.global_position), to_local(point_d), color, 2.0)
				draw_circle(to_local(point_d), 8.0, color, false, 2.0)
