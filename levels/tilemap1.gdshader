shader_type canvas_item;

uniform float time_scale = 10.0;
uniform  float stretch_scale = 1.0;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	//VERTEX += vec2(sin(TIME + world_position.x * time_scale), cos(TIME + world_position.y * time_scale)) * stretch_scale;
}

void fragment() {
	//COLOR.rgb = vec3(1.0);
	vec2 UV_in_world_space = world_position.xy;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
