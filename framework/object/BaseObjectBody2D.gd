@tool

extends KinematicObject2D

class_name BaseObjectBody2D

@export var host: BaseObject2D

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready():
	if host == null:
		host = get_parent()
