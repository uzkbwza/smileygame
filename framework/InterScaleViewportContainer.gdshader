shader_type canvas_item;

uniform vec2 screen_resolution = vec2(512, 512);

void fragment() {
	vec2 px = vec2(round(UV.x * screen_resolution.x) / screen_resolution.x, round(UV.y * screen_resolution.y) / screen_resolution.y);
	COLOR = texture(TEXTURE, px);
}