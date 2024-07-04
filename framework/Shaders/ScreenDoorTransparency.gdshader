shader_type canvas_item;

// --- Uniforms --- //
//global uniform vec2 player_position;

uniform float intensity: hint_range(0.0, 1.0, 0.05) = 0.0;

//group_uniforms player;
//uniform float player_influence: hint_range(0.0, 1.0, 0.05) = 0.60;
//uniform float radius: hint_range(0.0, 1.0, 0.05) = 0.05;

// --- Constants --- //
const mat4 THRESHOLD_MATRIX = mat4(
		vec4(1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0),
		vec4(13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0),
		vec4(4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0),
		vec4(16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0));

// --- Functions --- //
void fragment() {
	vec2 uv = SCREEN_UV / SCREEN_PIXEL_SIZE;
	//float player_dist = (clamp(1.0 - distance(SCREEN_UV / SCREEN_PIXEL_SIZE, player_position / SCREEN_PIXEL_SIZE) * SCREEN_PIXEL_SIZE.x / radius, 0.0, 1.0)) * player_influence * step(0.01, intensity);
	//COLOR.a *= step(0.0, THRESHOLD_MATRIX[int(uv.x) % 4][int(uv.y) % 4] - intensity - player_dist);
	COLOR.a *= step(0.0, THRESHOLD_MATRIX[int(uv.x) % 4][int(uv.y) % 4] - intensity);
}