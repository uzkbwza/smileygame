shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;
//uniform float scale : hint_range(0.0, 10.0) = 1.0;

uniform float h_osc_speed = 1.0;
uniform bool h_osc = false;
uniform bool h_osc_interleaved = false;
uniform float h_osc_width = 0.2;
uniform float h_osc_freq = 3.0;

uniform float v_osc_speed = 1.0;
uniform bool v_osc = false;
uniform float v_osc_width = 0.1;
uniform float v_osc_freq = 2.0;

uniform bool scroll = false;
uniform float scroll_speed = 0.5;
uniform vec2 scroll_dir = vec2(1.0, 1.0);

uniform bool use_custom_texture = false;
uniform sampler2D tex;


void fragment() {
	float h_osc_time = TIME * h_osc_speed;
	float v_osc_time = TIME * v_osc_speed;
	float scroll_time = TIME * scroll_speed;
	vec2 size = vec2(1.0/TEXTURE_PIXEL_SIZE.x, 1.0/TEXTURE_PIXEL_SIZE.y);
	vec2 coords = vec2(round(UV.x * size.x), round(UV.y * size.y));
	vec2 pos = vec2(coords.x / size.x, coords.y / size.y) + scroll_time * (-scroll_dir * scroll_speed * float(scroll));

//	pos.x = (pos.x / TEXTURE_PIXEL_SIZE.x);

	float h_offset = sin(h_osc_time + (pos.y) * h_osc_freq);
	float h_offset_width = h_offset * (h_osc_width);
	float h_offset_interleaved = h_offset_width;
	if (h_osc_interleaved && int(coords.y) % 2 == 0) {
		h_offset_interleaved = -h_offset_interleaved;
	}
	pos.x += h_offset_interleaved * float(h_osc);

	float v_offset = sin(v_osc_time + (pos.y) * v_osc_freq);
	float v_offset_width = v_offset * (v_osc_width);

	pos.y += v_offset_width * float(v_osc);
	vec4 color;

	if (use_custom_texture) {
		color = texture(tex , pos);
	} else {
		color = texture(TEXTURE, pos);
	}
	color.a = alpha * texture(TEXTURE, UV).a;

	COLOR = color;
}
