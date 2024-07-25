@tool

extends ImageTexture

class_name GeneratedPatternTexture2D

@export_group("Direct")

@export var pattern_index: int = 0:
	set(value):
		value = int(value)
		if value == pattern_index:
			pattern_index = value
			return
		pattern_index = value
		update_params()
		if pattern_index >= num_patterns:
			pattern_index = 0
		elif pattern_index < 0:
			pattern_index = num_patterns - 1
		#else:

		if !Engine.is_editor_hint():
			return
		update_texture()
		
@export var palette_index: int = 1:
	set(value):

		value = int(value)
		if value == palette_index:
			palette_index = value
			return
		palette_index = value
		update_params()
		#if palette_index >= num_palettes - 1:
			#palette_index = 1
		#elif palette_index < 1:
			#palette_index = num_palettes - 2
		if !Engine.is_editor_hint():
			return
		update_texture()

@export var palette_offset: int = 0:
	set(value):
		#if !Engine.is_editor_hint():
			#return
		value = int(value)
		if value == palette_offset:
			palette_offset = value
			return
		palette_offset = value
		if palette_offset < TileSetGenerator.PALETTE_OFFSETS[0]:
			palette_offset = TileSetGenerator.PALETTE_OFFSETS[-1]
		elif palette_offset > TileSetGenerator.PALETTE_OFFSETS[-1]:
			palette_offset = TileSetGenerator.PALETTE_OFFSETS[0]
		update_params()
		if !Engine.is_editor_hint():
			return
		update_texture()

@export var filename_string: String = ""

enum ImageType {
	Pattern,
	PatternBig,
	Border
}

const IMAGE_TEMPLATES = {
	ImageType.Pattern : preload("res://terrain/generator/pattern_only.png"),
	ImageType.PatternBig : preload("res://terrain/generator/pattern_only_big.png"),
	ImageType.Border : preload("res://terrain/generator/border_pattern.png"),
}

@export var image_type: ImageType:
	set(value):
		image_type = value
		update_params()
		if !Engine.is_editor_hint():
			return
		update_texture()

static var num_palettes = -1
static var num_patterns = -1

func update_texture() -> void:
	#if !Engine.is_editor_hint():
		#return
	#update_params()
	load_file()

func load_file() -> void:
	if !Engine.is_editor_hint():
		return

	#var input_name = get_input_name()
	#var filename = TileSetGenerator.params_to_filename(input_name, pattern_index, palette_index, palette_index, palette_offset, true)
#
	##if filename == filename_string:
		##return
#
	#filename_string = filename
	#
	#var image = ResourceLoader.load(filename)
	#
	#if Engine.is_editor_hint():
		#print("loading " + filename)
	var input = TileSetGeneratorInput.new()
	input.texture = IMAGE_TEMPLATES[image_type]
	input.name = get_input_name()
	
	var image = TileSetGenerator.create_one_tileset(input, pattern_index, palette_index, palette_index, palette_offset)
	
	image.convert(Image.FORMAT_RGBA8)
	
	if image:
		self.set_image(image) 

func get_input_name() -> String:
	match image_type:
		ImageType.Pattern:
			return "pattern"
		ImageType.PatternBig:
			return "pattern_big"
		ImageType.Border:
			return "border"
	return "unknown"

func update_params():
	if !Engine.is_editor_hint():
		return
	#if num_palettes != -1 and num_patterns != -1:
		#return

	var palette_set = TileSetGenerator.INPUT_PALETTE_TEXTURE.get_image()
	num_patterns = Utils.walk_path(TileSetGenerator.INPUT_BLOCKS_FOLDER.path_join(get_input_name()), false, "png").size()
	
	num_palettes = 0
	for y in palette_set.get_height():
		var palette = PackedColorArray()
		var done = false
		for x in palette_set.get_width():
			var pixel = palette_set.get_pixel(x, y)
			if pixel.a == 0:
				done = true
				break
		if done:
			break
		num_palettes += 1

		if palette.size() == 0:
			break
	#if pattern_index >= num_patterns:
		#pattern_index = 0
	#elif pattern_index < 0:
		#pattern_index = num_patterns - 1
	#if palette_index >= num_palettes - 1:
		#palette_index = 1
	#elif palette_index < 1:
		#palette_index = num_palettes - 2
