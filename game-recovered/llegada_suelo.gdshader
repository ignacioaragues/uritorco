shader_type spatial;

uniform int fragment_index;
uniform vec4 soil_tint : source_color;
uniform vec4 track_tint : source_color;
uniform sampler2D brushwork : filter_linear_mipmap, repeat_enable;
varying vec3 ground;

void vertex() {
	ground = VERTEX;
}

void fragment() {
	float distance = -ground.z;
	float pixel_size = max(length(dFdx(ground.xz)), length(dFdy(ground.xz)));
	float grain = sin(ground.x * 5.1 + sin(ground.z * 2.1)) * sin(ground.z * 3.7);
	grain *= 1.0 - smoothstep(0.08, 0.42, pixel_size);
	vec2 p = ground.xz;
	vec3 broad_brush = texture(brushwork, p * 0.085).rgb;
	vec3 fine_brush = texture(brushwork, vec2(p.x + p.y * 0.21, p.y - p.x * 0.18) * 0.47).rgb;
	float strokes = dot(mix(broad_brush, fine_brush, 0.65), vec3(0.30, 0.59, 0.11));
	float edge_wear = (strokes - 0.5) * 0.67;
	float x = 4.7 * sin(distance * 0.103) * smoothstep(15.0, 29.0, abs(distance));
	if (fragment_index == 3) { x = 3.6 * sin(distance * 0.13); }
	if (fragment_index == 4) { x = -4.8 * sin(distance * 0.105); }
	if (fragment_index == 6) { x = 5.0 * sin(distance * 0.113); }
	if (fragment_index == 7) { x = -4.4 * sin(distance * 0.14) + 0.11 * distance; }
	float track = 1.0 - smoothstep(0.76, 1.79, abs(ground.x - x) + grain * 0.16 + edge_wear);
	vec3 color = mix(soil_tint.rgb, track_tint.rgb, track);
	if (fragment_index == 0) {
		float road_center = -3.0 + 3.1 * sin(ground.x * 0.055) * smoothstep(13.0, 55.0, abs(ground.x));
		float edge = abs(ground.z - road_center);
		float asphalt = 1.0 - smoothstep(2.51, 2.84, edge);
		float verge = 1.0 - smoothstep(2.72, 3.37, edge + grain * 0.09);
		float branch_z = -7.6 - 0.245 * (ground.x - 2.8) + 1.7 * sin((ground.x - 2.8) * 0.15);
		float branch = smoothstep(0.2, 2.5, ground.x) * (1.0 - smoothstep(0.70, 1.74, abs(ground.z - branch_z) + edge_wear));
		color = mix(soil_tint.rgb, track_tint.rgb, max(verge, branch));
		vec3 paint = mix(vec3(0.108, 0.12, 0.115), vec3(0.19, 0.19, 0.17), smoothstep(2.10, 2.84, edge) * 0.56);
		color = mix(color, paint, asphalt);
		float center_line = (1.0 - smoothstep(0.033, 0.060, edge)) * step(2.8, mod(ground.x, 9.2)) * smoothstep(0.24, 0.43, strokes);
		color = mix(color, vec3(0.5, 0.46, 0.34), center_line * 0.76);
	}
	float variation = 0.95 + clamp((strokes - 0.50) * 1.25, -0.18, 0.18) + 0.018 * grain;
	ALBEDO = color * variation;
	ROUGHNESS = 1.0;
}
