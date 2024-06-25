shader_type canvas_item;

render_mode blend_premul_alpha;

uniform float angle = -0.2;
uniform float thickness : hint_range(0.0, 64.0) = 10.0;
uniform float scale = 1.0;
uniform vec2 shear = vec2(0.0, -0.4);
uniform int slices = 16;
uniform bool outline = true;
uniform float outline_width : hint_range(0.0, 5.0) = 2.0;

uniform sampler2D front_tex : hint_default_white, repeat_disable;
uniform sampler2D back_tex : hint_default_white, repeat_disable;
uniform sampler2D side_tex : hint_default_black, repeat_disable;
uniform sampler2D outline_tex : hint_default_black, repeat_disable;

group_uniforms debug;
uniform bool show_bound = false;

float box(vec2 p, vec2 d){
	p = abs(p) - d;
	return max(p.x, p.y);
}

varying vec2 vertex_base;
varying flat vec2 glyph_position;
varying vec2 padding;
varying vec4 my_modulate;
void vertex() {
	// Magic :)
	vertex_base = vec2(float(VERTEX_ID>>1), float(6>>VERTEX_ID&1));
	glyph_position = UV;

	// Extend bounds
	padding = (vertex_base*2.0-1.0) * abs(shear) * thickness * 0.5;
	padding += (vertex_base*2.0-1.0) * outline_width;
	VERTEX.xy += padding;
	padding *= TEXTURE_PIXEL_SIZE;

	// Give me access to MODULATE
	my_modulate = COLOR;
}

void transformRay(inout vec3 p, inout vec3 rd, float _angle, float _scale, vec2 _shear){
	// Apply scale
	p.xy /= _scale;

	// Apply shear
	p.xy += p.z * _shear;
	rd.xy += rd.z * _shear;

	// Apply rotation
	mat2 R = mat2(vec2(cos(_angle),sin(_angle)),vec2(-sin(_angle),cos(_angle)));
	p.xz *= R;
	rd.xz *= R;
}

// complex number math
vec2 cmul(vec2 a, vec2 b) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }
float getOutline(sampler2D tex, vec2 p, vec2 offset_px, vec2 clip_center, vec2 clip_size){
	float opacity = 0.0;

	for(int i = 0; i < 8; i++){
		float samp = texture(tex, p + offset_px).a;
		samp *= float(box(p + offset_px - clip_center, clip_size) < 0.0); // Clipping

		opacity = max(opacity, samp);

		offset_px = cmul(vec2(1.0/sqrt(2.0)), offset_px);
	}

	return opacity;
}

void fragment(){
	vec2 glyph_size = (UV - glyph_position)/vertex_base;
	vec2 glyph_center = glyph_position + glyph_size/2.0;

	vec3 p = vec3(UV + padding, 0); // A point in the font atlas, with padded bounds
	vec3 rd = vec3(0, 0, -1); // Ray points back to front

	// Inversly transform the ray
	p.xy -= glyph_center;
	transformRay(p, rd, angle, scale, shear);
	p.xy += glyph_center;


	// Intersect xy plane
	rd /= abs(rd.z);
	p -= rd * rd.z * p.z;

	// Thickness is measured in pixels. Hopefully the texture is predictable
	rd *= thickness * TEXTURE_PIXEL_SIZE.x;

	// Find back slice
	p -= rd * 0.5;

	// Prepare for ray march
	rd /= float(slices - 1);

	COLOR = vec4(0,0,0,0);

	// Add back outline
	if(outline){
		float opacity = getOutline(TEXTURE, p.xy, sign(shear) * TEXTURE_PIXEL_SIZE * outline_width, glyph_center, glyph_size/2.0);
		vec4 col = vec4(texture(outline_tex, vertex_base).rgb * opacity, opacity);
		col *= my_modulate;
		COLOR = COLOR + col * (1.0 - COLOR.a); // premultiplied alpha under operator*/
	}

	for(int i = 0; i<slices; i++){
		vec4 samp = texture(TEXTURE, p.xy);
		samp.a *= float(box(p.xy - glyph_center, glyph_size/2.0) < 0.0); // Clipping

		if(i < slices-1) {
			samp.rgb = texture(side_tex, vertex_base).rgb;
		}
		else if(rd.z < 0.0) {
			samp.rgb = texture(front_tex, vertex_base).rgb;
		}
		else {
			samp.rgb = texture(back_tex, vertex_base).rgb;
		}

		samp *= my_modulate;
		samp.rgb *= samp.a; // premultiply alpha
		COLOR = samp + COLOR * (1.0 - samp.a); // premultiplied alpha over operator

		// March to the next slice
		p += rd;
	}

	// Unmarch it back. Kinda lazy
	p -= rd;

	// Add front outline
	if(outline){
		float opacity = getOutline(TEXTURE, p.xy, sign(shear) * TEXTURE_PIXEL_SIZE * outline_width, glyph_center, glyph_size/2.0);
		vec4 col = vec4(texture(outline_tex, vertex_base).rgb * opacity, opacity);
		col *= my_modulate;
		COLOR = COLOR + col * (1.0 - COLOR.a); // premultiplied alpha under operator*/
	}

	if(show_bound){
		COLOR.a = COLOR.a * 0.8 + 0.2;

		float b = box(vertex_base-0.5, vec2(0.5));
		COLOR.g += (1.0 - clamp(abs(b/fwidth(b) + 0.5), 0.0, 1.0));
	}
}