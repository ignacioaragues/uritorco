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
	float grit = sin(p.x * 37.0 + p.z * 46.2) * sin(p.y * 53.1 - p.x * 14.0);
	float strata = dot(p, vec3(0.67, 3.05, -0.74)) + 0.12 * broad;
	float grain = 1.0 - smoothstep(0.14, 0.50, fwidth(strata));
	float veil = 1.0 - smoothstep(0.015, 0.12, abs(fract(strata) - 0.5));
	float hairline = 1.0 - smoothstep(0.018, 0.060, abs(fract(strata + 0.19) - 0.5));
	float quartz = (0.10 * veil + 0.13 * hairline) * grain * smoothstep(-0.42, 0.55, broad);
	vec3 paint = colored_mesh ? COLOR.rgb : stone_tint.rgb;
	ALBEDO = paint * (0.96 + 0.061 * broad + 0.032 * grit) + quartz * vec3(0.61, 0.51, 0.39);
	ROUGHNESS = 0.94;
}
