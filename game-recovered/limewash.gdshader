shader_type spatial;
uniform vec4 pigment : source_color = vec4(0.58,0.52,0.43,1.0);
varying vec3 stone_p;
float grit(vec2 p){
	vec2 cell=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	vec4 h=fract(sin(dot(cell,vec2(71.7,19.3))+vec4(0.0,71.7,19.3,91.0))*4375.63);
	return mix(mix(h.x,h.y,f.x),mix(h.z,h.w,f.x),f.y);
}
void vertex(){stone_p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=vec2(stone_p.x+stone_p.z,stone_p.y);
	float stains=grit(p*2.7)*0.18+grit(p*15.0)*0.09;
	ALBEDO=pigment.rgb*(0.80+stains+grit(p*79.0)*0.06);
	ROUGHNESS=0.97;
}
