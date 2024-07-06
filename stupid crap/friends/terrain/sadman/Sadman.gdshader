shader_type canvas_item;

uniform float time_scale = 3.0f;
uniform float squash_scale = 2.0f;

uniform vec4 modulate: source_color;

void vertex() {
	VERTEX.y += (sin(VERTEX.y) + cos(VERTEX.x + TIME * time_scale * SCREEN_MATRIX[3].y)) * squash_scale;
	VERTEX.x += (sin(VERTEX.x) + cos(VERTEX.y + TIME * time_scale * SCREEN_MATRIX[2].x)) * squash_scale;
}

void fragment() {
	COLOR += texture(TEXTURE, UV) * modulate;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
