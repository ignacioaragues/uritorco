shader_type spatial;
uniform vec4 tint : source_color = vec4(0.5,0.34,0.22,1.0);
uniform bool across = false;
uniform float grain_strength = 0.31;
uniform float fiber_scale = 145.0;
uniform bool irregular = false;
varying vec3 local_p;
varying float offset;
void vertex(){
	local_p = VERTEX;
	offset = dot(MODEL_MATRIX[3].xz, vec2(0.73, 1.91));
}
void fragment(){
	vec2 p = vec2(local_p.x,local_p.y+local_p.z);
	if(across){p=p.yx;}
	float warp = sin(p.y*3.6+1.1*sin(p.y*1.3+p.x))*0.021;
	float bands = sin((p.x+warp)*fiber_scale+sin(p.x*47.0))*0.5+0.5;
	float grain = mix(1.06-grain_strength,1.06,smoothstep(0.12,0.8,bands));
	if (irregular) {
		float wave = sin(p.y * 5.3 + offset + sin(p.x * 13.0)) * 0.016;
		wave += sin(p.y * 12.1 + p.x * 21.6 - offset) * 0.007;
		float run = p.x + wave;
		float ring = sin(run * 61.0 + 1.5 * sin(p.x * 18.0 + offset));
		float surface = sin(p.x * 17.5 + sin(p.y * 3.5 + offset)) * sin(p.y * 8.0 + offset);
		float resolved = 1.0 - smoothstep(0.014, 0.054, fwidth(run));
		float fibers = smoothstep(0.62, 0.98, ring) * (0.61 + surface * 0.31) * resolved;
		grain = 1.0 + grain_strength * (surface * 0.36 - fibers);
	}
	ALBEDO=tint.rgb*grain;
	ROUGHNESS=0.94;
}
