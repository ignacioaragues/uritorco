shader_type spatial;

uniform vec4 ground_tint : source_color;
uniform int terrain_style = 1;
uniform bool bedrock = false;
varying vec3 terrain_position;

void vertex() {
	terrain_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grit(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 n = vec4(dot(cell,vec2(41.17,289.2)),dot(cell+vec2(1,0),vec2(41.17,289.2)),
		dot(cell+vec2(0,1),vec2(41.17,289.2)),dot(cell+vec2(1,1),vec2(41.17,289.2)));
	n = fract(sin(n) * 4172.53);
	return mix(mix(n.x,n.y,f.x),mix(n.z,n.w,f.x),f.y);
}

void fragment() {
	vec3 p = terrain_position;
	vec2 xz = p.xz;
	float broad = grit(xz * 0.19) * 0.66 + grit(xz * 0.73) * 0.34;
	float fine = grit(xz * 11.0 + p.y * 7.0);
	float marks = 0.0;
	vec3 vein = vec3(0.31, 0.44, 0.50);
	if (terrain_style == 1) {
		float frost = sin(xz.x * 1.72 + xz.y * 1.19 + broad * 4.1 + p.y * 0.55);
		marks = smoothstep(0.80, 0.99, frost) * smoothstep(0.31, 0.72, broad) * 0.53;
		vein = vec3(0.37, 0.52, 0.66);
	} else if (terrain_style == 2) {
		float band = sin(p.y * 4.3 + xz.x * 0.26 - xz.y * 0.11 + broad * 2.3);
		marks = smoothstep(0.45, 0.95, band) * (0.20 + broad * 0.51);
		vein = vec3(0.47, 0.33, 0.24);
	} else {
		float flow = sin(xz.x * 0.68 + broad * 3.16 - xz.y * 0.53 - p.y * 2.4);
		marks = smoothstep(0.83, 0.98, flow) * (0.24 + broad * 0.43);
		vein = vec3(0.36, 0.28, 0.49);
	}
	vec3 crust = ground_tint.rgb * (0.71 + broad * 0.44 + fine * 0.16);
	ALBEDO = mix(crust, vein * (0.72 + fine * 0.26), marks * (0.80 + float(bedrock)*0.17));
	ROUGHNESS = 0.93 - marks * (terrain_style == 3 ? 0.51 : 0.21);
}
