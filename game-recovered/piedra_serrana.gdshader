shader_type spatial;

uniform vec4 stone_tint : source_color = vec4(0.54, 0.49, 0.43, 1.0);
uniform bool colored_mesh = true;
varying vec3 rock_position;

void vertex() {
	rock_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 p = rock_position;
	float broad = sin(p.x * 4.1 + p.z * 1.8) * cos(p.y * 6.4 - p.z * 2.8);
	float stain = sin(p.x * 2.8 + p.y * 1.2 + sin(p.z * 3.83)) * cos(p.z * 3.7 - p.y * 3.38);
	float grit_x = p.x * 37.0 + p.z * 46.2;
	float grit_y = p.y * 53.1 - p.x * 14.0;
	float resolved = 1.0 - smoothstep(0.9, 2.8, max(fwidth(grit_x), fwidth(grit_y)));
	float grit = sin(grit_x) * sin(grit_y) * resolved;
	float shift = 0.38 * sin(p.z * 1.47 + p.y * 2.2 + sin(p.x * 2.7));
	float strata = dot(p, vec3(0.59, 1.72, -0.68)) + shift + 0.12 * broad;
	float grain = 1.0 - smoothstep(0.14, 0.50, fwidth(strata));
	float veil = 1.0 - smoothstep(0.015, 0.12, abs(fract(strata) - 0.5));
	float hairline = 1.0 - smoothstep(0.018, 0.060, abs(fract(strata + 0.19) - 0.5));
	float quartz = (0.10 * veil + 0.12 * hairline) * grain * smoothstep(-0.48, 0.54, broad + stain * 0.29);
	vec3 paint = colored_mesh ? COLOR.rgb : stone_tint.rgb;
	vec3 stone = paint * (0.96 + 0.085 * broad + 0.037 * grit);
	stone *= mix(vec3(0.74, 0.78, 0.77), vec3(1.08, 1.02, 0.95), smoothstep(-0.68, 0.72, stain));
	ALBEDO = stone + quartz * vec3(0.61, 0.51, 0.39);
	ROUGHNESS = 0.94;
}
