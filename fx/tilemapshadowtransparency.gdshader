shader_type canvas_item;

void fragment() {
	COLOR.a *= (1.0 - pow(COLOR.r, 1.));
	COLOR.a = pow(COLOR.a, 3);
	COLOR.rgb *= 0.0;
}

