shader_type spatial;

uniform vec4 tint : source_color = vec4(0.32, 0.40, 0.42, 1.0);
varying vec3 glass_point;

void vertex() {
	glass_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 direction = reflect(-VIEW, NORMAL);
	vec3 reflected = (INV_VIEW_MATRIX * vec4(direction, 0.0)).xyz;
	float sky = smoothstep(-0.22, 0.47, reflected.y);
	float cloud = smoothstep(0.08, 0.84, sin(reflected.x * 8.3 + reflected.y * 6.8)
		* cos(reflected.z * 6.0 + reflected.y * 14.0));
	float at_edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float dust = 0.5 + 0.5 * sin(glass_point.x * 55.0 + glass_point.z * 45.0)
		* sin(glass_point.y * 49.0 - glass_point.z * 31.0);
	vec3 horizon = mix(vec3(0.27, 0.26, 0.18), vec3(0.44, 0.54, 0.57), sky);
	horizon = mix(horizon, vec3(0.66, 0.67, 0.61), cloud * sky * 0.18);
	ALBEDO = mix(tint.rgb * (0.68 + dust * 0.07), horizon, 0.19 + at_edge * 0.49);
	ROUGHNESS = 0.24 + dust * 0.08;
	SPECULAR = 0.35;
}
