extends Node2D

@onready var cursor_sprite: Sprite2D = $CursorSprite
@onready var icon: Sprite2D = $Icon
@onready var area_2d: Area2D = %Area2D

var blit_image: Image

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var image = icon.texture.get_image()
	image.convert(Image.FORMAT_RGBAH)
	icon.texture = ImageTexture.create_from_image(image)
	blit_image = image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cursor_sprite.global_position = get_global_mouse_position()
	if Physics.area2d_contains_point(area_2d, get_global_mouse_position()):
		blit_sprite(cursor_sprite, icon)
		pass

func blit_sprite(texture: Sprite2D, surface: Sprite2D):
	var texture_size = texture.texture.get_size()
	var surface_size = surface.texture.get_size()
	
	var texture_location = surface.to_local(texture.global_position) + (surface_size / 2) - texture_size / 2
	
	var texture_image = texture.texture.get_image()
	texture_image.convert(Image.FORMAT_RGBAH)
	blit_image.blit_rect_mask(texture_image, texture_image, Rect2(Vector2(), texture_size), texture_location)
	icon.texture = ImageTexture.create_from_image(blit_image)
