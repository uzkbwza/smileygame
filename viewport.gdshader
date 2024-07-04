// version: 1.0
// repository: https://github.com/TABmk/godot-2d-shadow-shader

shader_type canvas_item;

uniform float borderScale = 2.0;
uniform vec2 offset = vec2(-10.0, -10.0);
uniform vec4 color : source_color;
// turn this on to see where the shadow will be clipped
uniform bool debug = false;

// fragment() function works properly only within the area of an element.
// We can scale this area by scaling the entire element within vertex(), and then scaling it down in fragment().

// fragment works properly only iside element's area. But we can scale this area
// by scaling whole element inside vertex() and then downscale it in fragment()

// scaling element
void vertex() {
	VERTEX.xy *= vec2(borderScale);
}

// fragment downscaling "trail" fix
// while downscaling an element in fragment(), it makes a "trail" of the last pixel in X and Y
vec4 hideExtra(vec2 uv, sampler2D txtr, bool isMain) {
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec4 texColor = texture(txtr, uv);
		return isMain ? texColor : vec4(color.rgb, texColor.a);
	}
	return vec4(0.0);
}

void fragment() {
	// size of a single pixel
	vec2 singlePX = TEXTURE_PIXEL_SIZE;

	// main downscaled and centered element
	vec2 uv = UV * borderScale - (0.5 * (borderScale - 1.0));
	vec4 uv_texture = hideExtra(uv, TEXTURE, true);

	// same element, but with offset
	vec2 shadow_uv = uv + offset * singlePX;
	vec4 shadow = hideExtra(shadow_uv, TEXTURE, false);
	shadow.a *= color.a;

	// show main element on top of shadow
	vec4 res = mix(shadow, uv_texture, uv_texture.a);
	// debug layer. Turn on if you need a big offset
	vec4 debug_layer = vec4(1.0, 0.0, 0.0, 0.3);
	COLOR = mix(debug ? debug_layer : res, res, res.a);
}