shader_type canvas_item;

uniform float time_scale = 5.0f;
uniform float squash_scale = 0.25f;
uniform float squash_time_scale = 2.0f;

uniform float ratio : hint_range(0.0, 1.0) = 0.1;
 
uniform float power = 3.0;
 
uniform float min_speed = 10.0;
 
uniform float max_speed = 90.0;

uniform vec4 modulate_color : source_color;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

uniform vec2 global_position;

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void vertex() {
	VERTEX = rotate(VERTEX, vec2(0.5, 0.5), -TIME * time_scale + global_position.x * -1.2 + global_position.y * 1.5) * (1.0 + sin(TIME * squash_time_scale + global_position.x * 0.9 + global_position.y * 1.2) * squash_scale);
}

void fragment() {
    vec2 uv = UV;
    
    uv *= 2.0;
    uv -= vec2(1.0);
    
    float len = length(uv);
 
    float rspeed = mix(max_speed, min_speed, len);
    
    float sinx = sin((1. - ratio) * rspeed);
    float cosx = cos((1. - ratio) * rspeed);
 
    vec2 trs = uv * mat2(vec2(cosx, sinx), vec2(-sinx, cosx));
    trs /= pow(ratio, power);
    
    trs += vec2(1.0);
    trs /= 2.;
    if(trs.x > 1. || trs.x < 0. || trs.y > 1. || trs.y < 0.) {
        // Prevent sprite leaking.
        COLOR = vec4(0.);
    } else {
        vec4 col = texture(TEXTURE, trs);   
    	COLOR = (col + modulate_color);
		COLOR.a *= modulate_color.a;
    }

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
