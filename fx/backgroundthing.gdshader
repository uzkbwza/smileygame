shader_type canvas_item;

uniform float alpha = 1.0;

vec2 rotateUV(vec2 uv, float rotation)
{
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

void fragment() {
	float t = TIME;
	vec2 uv = rotateUV(UV, TAU/0.24 * alpha + (t * 0.040 * alpha));
	vec2 offset = vec2(uv.x + sin(uv.y + t), uv.y + cos(uv.x + t) + t * 50. * 0.025 / pow(alpha, 1.3));
	offset.x *= sin(uv.y - uv.x + 1.0);
	offset /= 100.;
	vec4 col = texture(TEXTURE, uv + offset);
	COLOR = col;
	COLOR.a *= alpha;
}
