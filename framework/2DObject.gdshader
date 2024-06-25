shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.,1.,1., 1.0);
uniform bool flash = false;

uniform bool outline = false;
uniform vec4 outline_color  : source_color = vec4(0., 0., 0., 1.0);

uniform vec4 color_to_replace : source_color = vec4(1., 0., 1.0, 1.0);
uniform vec4 replacement_color : source_color = vec4(1., 0., 1.0, 1.0);
uniform float replacement_dist = 0.01;

const vec2 OUTLINE_OFFSETS[] = {
	vec2(-1, 0), vec2(0, -1),vec2(1, 0), vec2(0, 1)
};

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	if (distance(color_to_replace.rgb, tex_color.rgb) < replacement_dist) {
		tex_color.rgb = replacement_color.rgb;
	}

	vec4 color = tex_color;

	if (outline) {
		vec2 outline_size = TEXTURE_PIXEL_SIZE;
		float outline_amount = 0.0;
		for (int i=0; i < OUTLINE_OFFSETS.length(); i++) {
			outline_amount += texture(TEXTURE, UV + outline_size * OUTLINE_OFFSETS[i]).a;
		}
		outline_amount = min(outline_amount, 1.0);
		color = mix(tex_color, outline_color, outline_amount - tex_color.a);
	}

	if (flash) {
		color.rgb = flash_color.rgb;
	}
	COLOR = color;

}