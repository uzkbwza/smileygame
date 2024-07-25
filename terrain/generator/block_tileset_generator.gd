@tool

extends Node

class_name TileSetGenerator

const FOLDER = "res://terrain/generator/"
const OUTPUT_FOLDER = "res://terrain/genoutput/"
const PERMUTATIONS_FOLDER = "res://terrain/genoutput/permutations/"
const INPUT_BLOCKS_FOLDER = "res://terrain/generator/input/"
const INPUT_PALETTE_TEXTURE: Texture2D = preload("res://terrain/generator/palettes.png")
#const INPUT_TILESET_TEXTURE = preload("res://terrain/generator/pattern_only.png")
@export var INPUTS: Array[TileSetGeneratorInput]



@export var generate_: bool:
	set(value):
		go()
		generate_ = false

@export var test_resource: GeneratedPatternTexture2D = GeneratedPatternTexture2D.new()

@export var template_tileset: TileSet

enum Mode {
	Normal,
	BorderPattern,
}


@export var force_enable_all = false

const PALETTE_OFFSETS = [
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7,
]

const TILE_TEMPLATE_COLORS = [
	Color("ffffff"),
	Color("888888"),
	Color("000000"),
	Color("ff0000"),
]

const TILE_TEMPLATE_PATTERN_REPLACE_COLOR = TILE_TEMPLATE_COLORS[3]

const PALETTE_INPUT_COLORS = [
	Color("ffffff"),
	Color("dddddd"),
	Color("bbbbbb"),
	Color("999999"),
	Color("666666"),
	Color("444444"),
	Color("222222"),
	Color("000000"),
]

@export var update_tileset = false

static var image_data = {
	
}

static var palettes: Array[PackedColorArray] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	else:
		go()


func go():
	palettes.clear()

	# generate palettes
	# generate images
	for input in INPUTS:
		if force_enable_all or input.enabled:
			generate_all(input)
		
	#EditorInterface.get_resource_filesystem().scan()


static func params_to_filename(name: String, image_index: int, palette_index_2: int, palette_index_1: int, palette_offset: int, absolute:=false) -> String:
	var filename = "%s%02x-%02x-%02x_%02x" % [name, image_index, palette_index_2, palette_index_1, palette_offset]
	if !absolute:
		return filename  
	else:
		return (OUTPUT_FOLDER).path_join(name).path_join(filename) + ".png"

static func generate_palettes():
	#if palettes.size() == 0:
	var INPUT_PALETTE_SET: Image = INPUT_PALETTE_TEXTURE.get_image()
	for y in INPUT_PALETTE_SET.get_height():
		var palette = PackedColorArray()
		for x in INPUT_PALETTE_SET.get_width():
			var pixel = INPUT_PALETTE_SET.get_pixel(x, y)
			if pixel.a == 0:
				break
			palette.append(pixel)

		if palette.size() == 0:
			break
		
		palettes.append(palette)

static func generate_one(input: TileSetGeneratorInput, image_index: int, palette_index_2: int, palette_index_1: int, palette_offset: int) -> Image:
	var image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	return image

static func generate_all(input: TileSetGeneratorInput):
	generate_palettes()

	var input_tileset = input.texture.get_image()
	var input_name = input.name
	
	var time = Time.get_ticks_msec()

	input_tileset.decompress()

	var input_tileset_size = input_tileset.get_size()
	var input_tileset_width = input_tileset_size.x
	var input_tileset_height = input_tileset_size.y
	var input_blocks_dir := DirAccess.open(INPUT_BLOCKS_FOLDER.path_join(input_name))
	var input_block_images : Array[Image] = []
	var use_mask_and_border = input.use_mask_and_border

	var mask_image = tileset_sized_image(input_tileset_width, input_tileset_height)
	image_data.clear()
	var border_image = tileset_sized_image(input_tileset_width, input_tileset_height)

	var TILE_WIDTH = 0
	var TILE_HEIGHT = 0
	for file in Utils.walk_path(INPUT_BLOCKS_FOLDER.path_join(input_name), true, "png"):
		var image = ResourceLoader.load(file).get_image()
		input_block_images.append(image)
		TILE_WIDTH = image.get_width()
		TILE_HEIGHT = image.get_height()

	DirAccess.make_dir_absolute(OUTPUT_FOLDER.path_join(input_name))
	
	for file in Utils.walk_path(OUTPUT_FOLDER.path_join(input_name), true):
		DirAccess.remove_absolute(file)

	for y in input_tileset_height:
		for x in input_tileset_width:
			var color = input_tileset.get_pixel(x, y)
			if color == TILE_TEMPLATE_PATTERN_REPLACE_COLOR:
				mask_image.set_pixel(x, y, Color.WHITE)
			else:
				mask_image.set_pixel(x, y, Color.TRANSPARENT)
				border_image.set_pixel(x, y, tileset_template_to_palette_color(color))
			if color == TILE_TEMPLATE_COLORS[1] and input.mode == Mode.BorderPattern:
				mask_image.set_pixel(x, y, Color.WHITE)

	mask_image.save_png(FOLDER.path_join("mask.png"))
	border_image.save_png(FOLDER.path_join("border.png"))

	var create_tileset = func(original_input_image, image_index, palette_index_1, palette_index_2, palette_offset_index) -> Array:
		var palette_1 = palettes[palette_index_1].duplicate()
		var palette_2 = palettes[palette_index_2].duplicate()
		var palette_offset:int = PALETTE_OFFSETS[palette_offset_index]
		if palette_offset > 0:
			palette_1 = palette_1.slice(palette_offset)
			palette_2 = palette_2.slice(palette_offset)
			for i in palette_offset:
				palette_1.append(palette_1[-1])
				palette_2.append(palette_2[-1])

		var new_tileset = tileset_sized_image(input_tileset_width, input_tileset_height)
		var recolored_border = replace_colors_in_image(border_image, palette_1) if use_mask_and_border else null
		var input_image = replace_colors_in_image(original_input_image, palette_2)
		var tiled_input_image = tileset_sized_image(input_tileset_width, input_tileset_height)
		var filename = params_to_filename(input_name, image_index, palette_index_2, palette_index_1, palette_offset, false)
		
		for start_y in max(input_tileset_height / TILE_HEIGHT, 1):
			for start_x in max(input_tileset_width / TILE_WIDTH, 1):
				var src_rect = Rect2i(0, 0, TILE_WIDTH, TILE_HEIGHT)
				var dst = Vector2i(start_x * TILE_WIDTH, start_y * TILE_HEIGHT)
				tiled_input_image.blit_rect(input_image, src_rect, dst)

		if use_mask_and_border:
			new_tileset.blit_rect(recolored_border, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
			new_tileset.blit_rect_mask(tiled_input_image, mask_image, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
		else:
			new_tileset.blit_rect(tiled_input_image, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
		var data = hash(new_tileset.get_data())
		if !(input.purge_redundant and data in image_data):
			#print("skipping")
			image_data[data] = true
			new_tileset.save_png(((OUTPUT_FOLDER).path_join(input_name)).path_join(filename + ".png"))
		return [new_tileset, filename]

	for image_index in input_block_images.size():
		var original_input_image = input_block_images[image_index]
		original_input_image.convert(Image.FORMAT_RGBA8)

		for palette_offset_index in PALETTE_OFFSETS.size():
			for palette_index_1 in range(1, palettes.size()):
				create_tileset.call(original_input_image, image_index, palette_index_1, palette_index_1, palette_offset_index)

		if input.generate_permutations:
			for palette_offset_index in PALETTE_OFFSETS.size():
				for palette_index_1 in range(1, palettes.size()):
					for palette_index_2 in range(1, palettes.size()):
						if palette_index_1 == palette_index_2:
							continue
						create_tileset.call(original_input_image, image_index, palette_index_1, palette_index_2, palette_offset_index)

static func create_one_tileset(input: TileSetGeneratorInput, image_index, palette_index_1, palette_index_2, palette_offset_index) -> Image:
	generate_palettes()
	print("generating " + params_to_filename(input.name, image_index, palette_index_1, palette_index_2, palette_offset_index))
	var input_tileset = input.texture.get_image() 
	#input_tileset.convert(Image.FORMAT_RGBA8)
	var input_name = input.name
	
	var time = Time.get_ticks_msec()

	input_tileset.decompress()

	var input_tileset_size = input_tileset.get_size()
	var input_tileset_width = input_tileset_size.x
	var input_tileset_height = input_tileset_size.y
	var input_blocks_dir := DirAccess.open(INPUT_BLOCKS_FOLDER.path_join(input_name))
	var input_block_images : Array[Image] = []
	var use_mask_and_border = input.use_mask_and_border

	var mask_image = tileset_sized_image(input_tileset_width, input_tileset_height)
	image_data.clear()
	var border_image = tileset_sized_image(input_tileset_width, input_tileset_height)

	var TILE_WIDTH = 0
	var TILE_HEIGHT = 0
	
	for file in Utils.walk_path(INPUT_BLOCKS_FOLDER.path_join(input_name), true, "png"):
		var image = ResourceLoader.load(file).get_image()
		image.convert(Image.FORMAT_RGBA8)
		input_block_images.append(image)
		TILE_WIDTH = image.get_width()
		TILE_HEIGHT = image.get_height()
		
	var original_input_image = input_block_images[image_index]

	for y in input_tileset_height:
		for x in input_tileset_width:
			var color = input_tileset.get_pixel(x, y)
			if color == TILE_TEMPLATE_PATTERN_REPLACE_COLOR:
				mask_image.set_pixel(x, y, Color.WHITE)
			else:
				mask_image.set_pixel(x, y, Color.TRANSPARENT)
				border_image.set_pixel(x, y, tileset_template_to_palette_color(color))
			if color == TILE_TEMPLATE_COLORS[1] and input.mode == Mode.BorderPattern:
				mask_image.set_pixel(x, y, Color.WHITE)

	var palette_1 = palettes[palette_index_1].duplicate()
	var palette_2 = palettes[palette_index_2].duplicate()
	var palette_offset:int = PALETTE_OFFSETS[palette_offset_index]
	if palette_offset > 0:
		palette_1 = palette_1.slice(palette_offset)
		palette_2 = palette_2.slice(palette_offset)
		for i in palette_offset:
			palette_1.append(palette_1[-1])
			palette_2.append(palette_2[-1])

	var new_tileset = tileset_sized_image(input_tileset_width, input_tileset_height)
	var recolored_border = replace_colors_in_image(border_image, palette_1) if use_mask_and_border else null
	var input_image = replace_colors_in_image(original_input_image, palette_2)
	var tiled_input_image = tileset_sized_image(input_tileset_width, input_tileset_height)
	var filename = params_to_filename(input_name, image_index, palette_index_2, palette_index_1, palette_offset, false)
	
	for start_y in max(input_tileset_height / TILE_HEIGHT, 1):
		for start_x in max(input_tileset_width / TILE_WIDTH, 1):
			var src_rect = Rect2i(0, 0, TILE_WIDTH, TILE_HEIGHT)
			var dst = Vector2i(start_x * TILE_WIDTH, start_y * TILE_HEIGHT)
			tiled_input_image.blit_rect(input_image, src_rect, dst)

	if use_mask_and_border:
		new_tileset.blit_rect(recolored_border, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
		new_tileset.blit_rect_mask(tiled_input_image, mask_image, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
	else:
		new_tileset.blit_rect(tiled_input_image, Rect2i(0, 0, input_tileset_width, input_tileset_height), Vector2(0,0))
	var data = hash(new_tileset.get_data())

	return new_tileset

static func tileset_template_to_palette_color(color: Color) -> Color:
	var opaque = color
	opaque.a = 1.0
	if opaque in TILE_TEMPLATE_COLORS:
		var result = PALETTE_INPUT_COLORS[TILE_TEMPLATE_COLORS.find(opaque)]
		result.a = color.a
		return result
	return color

static func replace_colors_in_image(src: Image, palette: PackedColorArray) -> Image:
	var image : Image = src.duplicate()
	for y in src.get_height():
		for x in src.get_width():
			var color = src.get_pixel(x, y)
			var opaque = color
			opaque.a = 1.0
			var index = PALETTE_INPUT_COLORS.find(opaque)
			if index >= 0:
				var result = palette[index]
				result.a = color.a
				image.set_pixel(x, y, result)
	return image

static func tileset_sized_image(input_tileset_width, input_tileset_height) -> Image:
	return Image.create_empty(input_tileset_width, input_tileset_height, false, Image.FORMAT_RGBA8)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().reload_current_scene()
