class_name RectAnchor

const CIRCLE_OUTER_RADIUS : float = 10.0
const CIRCLE_INNER_RADIUS : float = 8.0

const ANCHOR_SIZE : Vector2 = Vector2.ONE * CIRCLE_OUTER_RADIUS * 2.0

const COLOR_DEFAULT : Color = Color("#36a1ff")
const COLOR_WHITE : Color = Color("#ffffff")

var position : Vector2
var rect : Rect2


func _init(position : Vector2, size: Vector2 = ANCHOR_SIZE) -> void:
	self.position = position
	self.rect = Rect2(position - size / 2.0, size)

func draw(overlay: Control, color: Color = COLOR_DEFAULT) ->  void:
	overlay.draw_circle(position, CIRCLE_OUTER_RADIUS, color)
	overlay.draw_circle(position, CIRCLE_INNER_RADIUS, COLOR_WHITE)
