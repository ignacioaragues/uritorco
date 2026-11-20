shader_type spatial;
uniform vec4 tint : source_color = vec4(0.5,0.34,0.22,1.0);
uniform bool across = false;
uniform float grain_strength = 0.31;
uniform float fiber_scale = 145.0;
varying vec3 local_p;
void vertex(){local_p=VERTEX;}
void fragment(){
	vec2 p = vec2(local_p.x,local_p.y+local_p.z);
	if(across){p=p.yx;}
	float warp = sin(p.y*3.6+1.1*sin(p.y*1.3+p.x))*0.021;
	float bands = sin((p.x+warp)*fiber_scale+sin(p.x*47.0))*0.5+0.5;
	float grain = mix(1.06-grain_strength,1.06,smoothstep(0.12,0.8,bands));
	ALBEDO=tint.rgb*grain;
	ROUGHNESS=0.94;
}
