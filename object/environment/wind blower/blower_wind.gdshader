shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform sampler2D gradient_texture;
uniform sampler2D gradient_texture2;
uniform sampler2D side_gradient_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap, repeat_enable;

uniform float speed = 0.01;
uniform float threshold = 0.3;
uniform float threshold2 = 0.5;
uniform float alpha = 0.5;
uniform float alpha2 = 0.8;
uniform float step_ = 0.2;
uniform float step2 = 0.2;
uniform float alpha_step = 0.025;
uniform float screen_warp_amount = 0.02;
uniform float rotation = 0.0;

uniform float texture_length = 1.0;
uniform float texture_width = 1.0;

float stepify(float value, float snap) {
    return (floor(value/snap))*snap;
}
vec2 rotateVector(vec2 vec, float rot) {

    return vec2(cos(rot) * vec.x - sin(rot) * vec.y, sin(rot) * vec.x + cos(rot) * vec.y);
}

void fragment() {
	vec2 noise_uv = vec2((UV.x * 0.01) * texture_length + (-TIME * speed), (UV.y * 0.5) * texture_width);
	//// Called for every pixel the material is visible on.
	float noise_value = (texture(noise, noise_uv).r);
	
	float amount = texture(gradient_texture, UV).r;
	float amount2 = texture(gradient_texture2, UV).r;
	//float a = noise_value > threshold ? 1.0 : 0.0;
	//float b = noise_value > threshold2 ? 1.0 : 0.0;
//
	float a = smoothstep(threshold, threshold + step_, noise_value);
	float b = smoothstep(threshold2, threshold2 + step2, noise_value);


	a *= amount2 * texture(side_gradient_texture, UV).r;
	b *= amount2 * texture(side_gradient_texture, UV).r;
	a *= alpha;
	b *= alpha2;
	float warp_amount = (pow(noise_value, 1.5)) * screen_warp_amount * amount * texture(side_gradient_texture, UV).r;
	warp_amount = (noise_value * 10000. * screen_warp_amount) * warp_amount;
	//
	vec4 color = vec4(1.0);
	vec4 color2 = vec4(1.0);
	//vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	vec2 warp_vec = rotateVector(vec2(1.0, 0.0), rotation) * warp_amount;
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV - warp_vec * SCREEN_PIXEL_SIZE);
	
	//float final_alpha = stepify(a + b, alpha_step);
	float final_alpha = a + b;
	COLOR = screen_color + color * final_alpha;

}

