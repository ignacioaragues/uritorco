shader_type spatial;
uniform vec4 pigment : source_color = vec4(0.58,0.52,0.43,1.0);
uniform float weather = 0.0;
uniform float wall_base = 0.0;
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
	vec3 painted = pigment.rgb * (0.80 + stains + grit(p * 79.0) * 0.06);
	if (weather > 0.0) {
		float height = stone_p.y - wall_base;
		float chips = grit(p * 10.0 + vec2(2.0, 6.0));
		float substrate = grit(p * 2.0 + vec2(18.0, 7.0)) * 0.55 + chips * 0.45;
		float damp = (1.0 - smoothstep(0.35, 1.07, height + chips * 0.40))
			* smoothstep(0.20, 0.71, grit(p * vec2(6.0, 2.0)));
		float flaked = smoothstep(0.64, 0.82, substrate + 0.16 * damp);
		painted = mix(painted, pigment.rgb * vec3(0.74, 0.65, 0.56), flaked * weather * 0.83);
		painted *= 1.0 - damp * weather * 0.18;
	}
	ALBEDO = painted;
	ROUGHNESS=0.97;
}
