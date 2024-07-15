extends CanvasLayer

@export var level: SmileyLevel
@onready var coin_label: Label = %CoinLabel

var elapsed_time = 0.0

func setup_level(level: SmileyLevel):
	self.level = level
	level.coin_collected.connect(on_coin_collected)
	on_coin_collected.call_deferred()

func _ready() -> void:
	setup_level(level)

func on_coin_collected():
	# TODO: better effect
	coin_label.text = str(level.coins_collected) + " / " + str(level.num_coins)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	coin_label.material.set_shader_parameter("angle", sin(elapsed_time * 5.25) * PI / 5.0)
	coin_label.material.set_shader_parameter("thickness", (sin(elapsed_time * 5.25) + 2) * 10.5)
	coin_label.material.set_shader_parameter("shear", Vector2(sin(elapsed_time * 3.0) * 0.2, sin(elapsed_time * 8.0) * 0.6))
