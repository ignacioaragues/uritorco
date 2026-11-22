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
	float light_mass = smoothstep(-0.47, 0.43, p.y + 0.21 * sin(p.x * 7.4 - p.z * 5.7 + patch_seed));
	float cluster = sin(p.x * 17.0 - p.y * 12.0 + sin(p.z * 18.0 + patch_seed));
	float brush = p.x * 44.0 + sin(p.y * 28.0 + p.z * 38.0) * 2.1 + p.z * 25.0;
	float resolved = 1.0 - smoothstep(0.85, 2.7, fwidth(brush));
	float leaf_marks = smoothstep(0.10, 0.96, sin(brush) * cluster);
	vec3 shade = mix(vec3(0.69, 0.74, 0.71), vec3(1.13, 1.09, 0.96), light_mass);
	ALBEDO = tint.rgb * shade * (0.98 + 0.10 * cluster + 0.15 * leaf_marks * resolved);
	ROUGHNESS = 1.0;
}
