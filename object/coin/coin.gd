extends Area2D

class_name Coin

signal mover_detach_needed()

const LAUNCH_SPEED = 300
const ACCEL = 1000
const MIN_TIME = 0.2
const MIN_DISTANCE = 32

static var rng = BetterRng.new()

@onready var icon = $Icon

@onready var trail_particles: GPUParticles2D = $GPUParticles2D2
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var impulses := Vector2()
var accel := Vector2()
var velocity := Vector2()

var time_elapsed = 0.0
var player: SmileyPlayer
var splerp_amount = 0

func _ready():
	icon.material.set_shader_parameter("time_offset", randf() * 1000)
	trail_particles.hide()
	trail_particles.emitting = false

	icon.play()
	var level = get_parent()
	set_physics_process(false)
	
	while !(level is SmileyLevel):
		if level == null:
			break
		level = level.get_parent()

	if level is SmileyLevel:
		level.coins_left += 1
		level.num_coins += 1

func _physics_process(delta: float) -> void:
	queue_redraw()
	monitorable = false
	if player:
		var dist = global_position.distance_to(player.global_position)
		if time_elapsed > MIN_TIME:
			if dist < MIN_DISTANCE:
				player.on_grabbed_coin()
				icon.hide()
				gpu_particles_2d.hide()
				set_physics_process(false)
				trail_particles.emitting = false
				player = null
				await get_tree().create_timer(1.0, false, true).timeout
				queue_free()
				return
			#elif dist < 200:
			#velocity = Math.splerp_vec(velocity, Vector2(), delta, 1.0)
			global_position = Math.splerp_vec(global_position, player.global_position, delta, 20.0 - splerp_amount * 100)
			splerp_amount += delta
			
		#accel += global_position.direction_to(player.global_position) * ACCEL
	Math.splerp_vec(velocity, Vector2(), delta, 3.0)

	#trail_particles.rotation = velocity.angle()

	time_elapsed += delta

	velocity += impulses
	velocity += accel * delta
	
	global_position += velocity * delta

	impulses = Vector2()
	accel = Vector2()
	#velocity = Vector2()


func launch():
	impulses += rng.random_vec(true) * LAUNCH_SPEED + player.body.velocity * 0.5
	#if player.is_grounded:
		#impulses *= impulses.normalized().dot(player.ground_normal)
	pass

func on_player_touched(player: SmileyPlayer):
	if self.player:
		return
	mover_detach_needed.emit()
	trail_particles.emitting = true
	trail_particles.show()
	#icon.scale *= 0.85
	self.player = player
	player.coin_touch_sound()
	launch()
	#player.play_sound("Coin5")
	
	_on_player_touched.call_deferred(player)
	set_physics_process(true)

func _on_player_touched(player: SmileyPlayer):
	var particle = preload("res://object/coin/coin_grab_effect.tscn").instantiate()
	Global.get_level().add_child(particle)
	particle.global_position = global_position

func _draw() -> void:
	#if player:
		#var color = Color.WHITE
		#color.a *= 0.35
		#draw_circle(Vector2(), 10 + sin(0.75 * time_elapsed) * 2.0, color, false)
	pass
