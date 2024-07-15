shader_type canvas_item;

const float DEFAULT_RADIUS = 20.000000;
uniform vec2 step = vec2(0, 1);
const float radius = 20.0;
//uniform bool make_transparent = false;

float brightness_at(vec2 uv, sampler2D tex) {
	vec4 col = texture(tex, uv);
	return col.r / (radius);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);


	vec2 s = radius / DEFAULT_RADIUS * step / vec2(textureSize(TEXTURE, 0));
	
	//if (make_transparent && col.r > 0.0)
		//col.a *= 0.0;

	
	vec4 color =
		0.011194727 * texture(TEXTURE, UV - 10.000000000 * s) +
		0.039368696 * texture(TEXTURE, UV - 8.415809477 * s) +
		0.071308558 * texture(TEXTURE, UV - 6.435363708 * s) +
		0.110237219 * texture(TEXTURE, UV - 4.455121108 * s) +
		0.145451038 * texture(TEXTURE, UV - 2.475020813 * s) +
		0.163798995 * texture(TEXTURE, UV - 0.495000167 * s) +
		0.157439298 * texture(TEXTURE, UV + 1.485004498 * s) +
		0.129158204 * texture(TEXTURE, UV + 3.465057055 * s) +
		0.090434685 * texture(TEXTURE, UV + 5.445220765 * s) +
		0.054043977 * texture(TEXTURE, UV + 7.425557483 * s) +
		0.027564604 * texture(TEXTURE, UV + 9.406126897 * s);
	//COLOR.a = 1.0 - (color.r * COLOR.a);


	//COLOR.a = 1.0 - darkness * (1.0 - col.r);
	//COLOR.rgb *= 0.0;
	//COLOR.rgb = col.rgb;
	COLOR.a = col.a * color.a;
	COLOR.rgb = color.rgb;
	//COLOR.rgb *= 0.0;
}
