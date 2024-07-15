extends Resource

class_name TileSetGeneratorInput

@export var texture: Texture2D
@export var name: String

@export var generate_permutations = false
@export var use_mask_and_border = false
@export var purge_redundant = false

@export var mode = TileSetGenerator.Mode.Normal

@export var enabled = true
