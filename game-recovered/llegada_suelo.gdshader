shader_type spatial;

uniform int fragment_index;
uniform vec4 soil_tint : source_color;
uniform vec4 track_tint : source_color;
varying vec3 ground;

void vertex() {
	ground = VERTEX;
}

void fragment() {
	float distance = -ground.z;
	float pixel_size = max(length(dFdx(ground.xz)), length(dFdy(ground.xz)));
	float grain = sin(ground.x * 5.1 + sin(ground.z * 2.1)) * sin(ground.z * 3.7);
	grain *= 1.0 - smoothstep(0.08, 0.42, pixel_size);
	float x = 4.7 * sin(distance * 0.103) * smoothstep(15.0, 29.0, abs(distance));
	if (fragment_index == 3) { x = 3.6 * sin(distance * 0.13); }
	if (fragment_index == 4) { x = -4.8 * sin(distance * 0.105); }
	if (fragment_index == 6) { x = 5.0 * sin(distance * 0.113); }
	if (fragment_index == 7) { x = -4.4 * sin(distance * 0.14) + 0.11 * distance; }
	float track = 1.0 - smoothstep(0.85, 1.65, abs(ground.x - x) + grain * 0.20);
	vec3 color = mix(soil_tint.rgb, track_tint.rgb, track);
	if (fragment_index == 0) {
		float road_center = -3.0 + 3.1 * sin(ground.x * 0.055) * smoothstep(13.0, 55.0, abs(ground.x));
		float edge = abs(ground.z - road_center);
		float asphalt = 1.0 - smoothstep(2.51, 2.84, edge);
		float verge = 1.0 - smoothstep(2.72, 3.37, edge + grain * 0.09);
		float branch_z = -7.6 - 0.245 * (ground.x - 2.8) + 1.7 * sin((ground.x - 2.8) * 0.15);
		float branch = smoothstep(0.2, 2.5, ground.x) * (1.0 - smoothstep(0.77, 1.63, abs(ground.z - branch_z) + grain * 0.18));
		color = mix(soil_tint.rgb, track_tint.rgb, max(verge, branch));
		color = mix(color, vec3(0.11, 0.122, 0.115), asphalt);
		float center_line = (1.0 - smoothstep(0.033, 0.060, edge)) * step(2.8, mod(ground.x, 9.2));
		color = mix(color, vec3(0.5, 0.46, 0.34), center_line * 0.76);
	}
	float variation = 0.95 + 0.055 * sin(ground.x * 0.37 + cos(ground.z * 0.44)) + 0.022 * grain;
	ALBEDO = color * variation;
	ROUGHNESS = 1.0;
}
