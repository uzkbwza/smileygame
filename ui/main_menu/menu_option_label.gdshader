shader_type canvas_item;

uniform sampler2D glyph_texture;

varying vec2 vertex_base;
varying flat vec2 glyph_position;
varying vec2 padding;
varying vec4 my_modulate;

void vertex() {
	// Magic :)
	vertex_base = vec2(float(VERTEX_ID>>1), float(6>>VERTEX_ID&1));
	glyph_position = UV;

	// Extend bounds
	//padding = (vertex_base*2.0-1.0);
	//padding += (vertex_base*2.0-1.0) * outline_width;
	//VERTEX.xy += padding;
	//padding *= TEXTURE_PIXEL_SIZE;

	// Give me access to MODULATE
	my_modulate = COLOR;
}
float box(vec2 p, vec2 d){
	p = abs(p) - d;
	return max(p.x, p.y);
}
void fragment() {
	vec2 glyph_size = (UV - glyph_position)/vertex_base;
	vec2 glyph_center = glyph_position + glyph_size/2.0;

	vec3 p = vec3(UV + padding, 0); // A point in the font atlas, with padded bounds
	

	vec4 samp = texture(TEXTURE, p.xy);
	samp.a *= float(box(p.xy - glyph_center, glyph_size/2.0) < 0.0); // Clipping


	samp.rgb = texture(glyph_texture, vertex_base).rgb;


	samp *= my_modulate;
	samp.rgb *= samp.a; // premultiply alpha
	COLOR = samp + COLOR * (1.0 - samp.a); // premultiplied alpha over operator


	//vec4 color = texture(glyph_texture, UV);
	//color.a = COLOR.a;
	//COLOR.rgb = color.rgb * COLOR.r;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
