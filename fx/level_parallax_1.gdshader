shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform sampler2D noise2 : repeat_enable;
uniform float speed = 1.0;
uniform vec4 smoke_color : source_color;

void fragment(){
	vec2 uv1 = vec2(UV.x + TIME*speed, UV.y);
	vec2 uv2 = vec2(UV.x - TIME*speed, UV.y);
	vec2 uv3 = vec2(UV.x, UV.y + TIME*speed);


	float noise_r = texture( noise, uv1 ).r;
	float noise_g = texture( noise, uv2 ).g;
	float noise_b = texture( noise, uv3 ).b;

	float noise_r_2 = texture( noise2, uv1 ).r;
	float noise_g_2 = texture( noise2, uv2 ).g;
	float noise_b_2 = texture( noise2, uv3 ).b;

	vec3 new_color = vec3(noise_r, noise_g, noise_b);
	vec3 new_color2 = vec3(noise_r_2, noise_g_2, noise_b_2);

	float new_alpha = noise_r * noise_g * noise_b;
	float new_alpha_2 = noise_r_2 * noise_g_2 * noise_b_2;

	COLOR.rgb = smoke_color.rgb;//texture(TEXTURE, UV).rgb;
	COLOR.a = clamp(new_alpha * new_alpha_2 * 1.0 * texture(TEXTURE, UV).a, 0.0, 1.0) > 0.1 ? smoke_color.a : 0.0;
}
