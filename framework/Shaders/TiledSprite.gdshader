shader_type canvas_item;
uniform sampler2D tile : filter_nearest;
uniform vec2 sprite_scale;
uniform vec2 offset;

void fragment() {
	COLOR = texture(tile, fract(UV * sprite_scale + offset));
}