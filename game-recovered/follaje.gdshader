shader_type spatial;

uniform vec4 tint : source_color;
uniform float pattern = 0.0;
varying vec3 brush_position;
varying float patch_seed;

void vertex() {
	brush_position = VERTEX;
	patch_seed = pattern + dot(MODEL_MATRIX[3].xz, vec2(0.83, 1.39));
	float edge = sin(VERTEX.x * 19.0 + patch_seed) * sin(VERTEX.z * 16.0 - VERTEX.y * 14.0);
	VERTEX += NORMAL * edge * 0.036;
}

void fragment() {
	vec3 p = brush_position;
	float light_mass = smoothstep(-0.48, 0.38, p.y + 0.19 * sin(p.x * 7.4 - p.z * 5.7 + patch_seed));
	float cluster = sin(p.x * 23.0 - p.y * 13.0 + sin(p.z * 21.0 + patch_seed));
	float brush = p.x * 49.0 + sin(p.y * 28.0 + p.z * 41.0) * 1.8 + p.z * 27.0;
	float resolved = 1.0 - smoothstep(0.85, 2.7, fwidth(brush));
	float leaf_marks = smoothstep(0.10, 0.96, sin(brush) * cluster);
	vec3 shade = mix(vec3(0.77, 0.81, 0.79), vec3(1.13, 1.10, 0.97), light_mass);
	ALBEDO = tint.rgb * shade * (0.97 + 0.12 * cluster + 0.15 * leaf_marks * resolved);
	ROUGHNESS = 1.0;
}
