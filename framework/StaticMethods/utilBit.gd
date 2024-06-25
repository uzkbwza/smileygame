extends Node

class_name Bit

# Rotates an 8-bit integer `value` to the left by `count` positions
static func rotate_left_8bit(value: int, count: int) -> int:
	# Mask the value to 8 bits
	value &= 0xFF
	# Perform the rotation
	return ((value << count) | (value >> (8 - count))) & 0xFF

# Rotates an 8-bit integer `value` to the right by `count` positions
static func rotate_right_8bit(value: int, count: int) -> int:
	# Mask the value to 8 bits
	value &= 0xFF
	# Perform the rotation
	return ((value >> count) | (value << (8 - count))) & 0xFF

# Rotates a 4-bit integer `value` to the left by `count` positions
static func rotate_left_4bit(value: int, count: int) -> int:
	# Mask the value to 4 bits
	value &= 0xF
	# Perform the rotation
	return ((value << count) | (value >> (4 - count))) & 0xF

# Rotates a 4-bit integer `value` to the right by `count` positions
static func rotate_right_4bit(value: int, count: int) -> int:
	# Mask the value to 4 bits
	value &= 0xF
	# Perform the rotation
	return ((value >> count) | (value << (4 - count))) & 0xF
