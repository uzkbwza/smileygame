shader_type canvas_item;

uniform float normal_offset : hint_range(0, 2, .1) = 1.5;
uniform float time_influence : hint_range(0, 50) = 3;
uniform float time_offset = 0.0;
uniform float y_div : hint_range(0, 10, .1) = 2.87;

void vertex() {
	VERTEX.x += sin(VERTEX.y * y_div + ((time_offset + TIME) * time_influence)) * normal_offset;
	VERTEX.y += sin(VERTEX.x * y_div + ((time_offset + TIME) * time_influence)) * normal_offset;
}

void fragment() {
	vec2 uv = UV;

	COLOR = texture(TEXTURE, uv);
}