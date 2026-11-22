shader_type spatial;

uniform int fragment_index;
uniform bool lane_to_house = false;
uniform vec4 soil_tint : source_color;
uniform vec4 track_tint : source_color;
uniform sampler2D brushwork : filter_linear_mipmap, repeat_enable;
varying vec3 ground;
varying float slope_amount;

void vertex() {
	ground = VERTEX;
	slope_amount = 1.0 - abs(NORMAL.y);
}

float pigment(vec3 sample_color) {
	return dot(sample_color, vec3(0.30, 0.59, 0.11));
}

float stone_grit(vec2 p) {
	vec2 grid = floor(p);
	float seed = fract(sin(dot(grid, vec2(41.7, 289.1))) * 19348.37);
	vec2 chip = fract(p) - (0.28 + vec2(seed, fract(seed * 7.3)) * 0.44);
	float facets = abs(chip.x) + abs(chip.y) * 0.81;
	return step(0.62, seed) * (1.0 - smoothstep(0.098, 0.158, facets));
}

void fragment() {
	float distance = -ground.z;
	float pixel_size = max(length(dFdx(ground.xz)), length(dFdy(ground.xz)));
	vec2 p = ground.xz;
	float earth = pigment(texture(brushwork, p * 0.108).rgb);
	vec2 brush_dir = vec2(p.x + p.y * 0.37, p.y - p.x * 0.34);
	float brush = pigment(texture(brushwork, brush_dir * 0.39 + vec2(0.17, 0.43)).rgb);
	float edge_wear = (earth - 0.5) * 1.3 + (brush - 0.5) * 0.52;
	float x = 4.7 * sin(distance * 0.103) * smoothstep(15.0, 29.0, abs(distance));
	if (fragment_index == 3) { x = 3.6 * sin(distance * 0.13); }
	if (fragment_index == 4) { x = -4.8 * sin(distance * 0.105); }
	if (fragment_index == 6) { x = 5.0 * sin(distance * 0.113); }
	if (fragment_index == 7) { x = -4.4 * sin(distance * 0.14) + 0.11 * distance; }
	if (lane_to_house) { x = 4.3 * sin((ground.z + 4.5) * 0.093) * smoothstep(3.0, 13.0, ground.z + 4.5); }
	float track = 1.0 - smoothstep(0.70, 1.86, abs(ground.x - x) + edge_wear);
	if (lane_to_house) { track *= smoothstep(-5.0, -4.08, ground.z); }
	vec3 meadow = soil_tint.rgb * (0.91 + 0.19 * earth);
	vec3 trail = track_tint.rgb * (0.86 + 0.28 * earth);
	vec3 color = mix(meadow, trail, track);
	if (fragment_index == 1 || fragment_index == 5) {
		float slope = smoothstep(0.16, 0.72, slope_amount);
		float exposure = brush * 0.64 + earth * 0.36;
		vec3 cut = mix(trail, vec3(0.41, 0.35, 0.30), 0.57) * (0.79 + exposure * 0.33);
		color = mix(color, cut, slope * 0.90);
	}
	float detail = 0.0;
	if (pixel_size < 0.075) {
		detail = stone_grit(brush_dir * 14.2) * (1.0 - smoothstep(0.022, 0.075, pixel_size));
	}
	color += vec3(0.061, 0.053, 0.041) * detail * mix(0.28, 0.68, track);
	if (fragment_index == 0) {
		float road_center = -3.0 + 3.1 * sin(ground.x * 0.055) * smoothstep(13.0, 55.0, abs(ground.x));
		float edge = abs(ground.z - road_center);
		float asphalt = 1.0 - smoothstep(2.49, 2.86, edge + edge_wear * 0.34);
		float verge = 1.0 - smoothstep(2.67, 3.56, edge + edge_wear * 0.92);
		float branch_z = -7.6 - 0.245 * (ground.x - 2.8) + 1.7 * sin((ground.x - 2.8) * 0.15);
		float branch = smoothstep(0.2, 2.5, ground.x) * (1.0 - smoothstep(0.70, 1.74, abs(ground.z - branch_z) + edge_wear));
		color = mix(meadow, trail, max(verge, branch));
		color += vec3(0.061, 0.053, 0.041) * detail * mix(0.22, 1.0, verge);
		float dust = smoothstep(1.79, 2.94, edge + edge_wear);
		float patch = smoothstep(0.41, 0.57, brush) * smoothstep(0.36, 0.59, earth);
		vec3 seal = mix(vec3(0.104, 0.111, 0.110), vec3(0.132, 0.136, 0.129), patch);
		seal = mix(seal, vec3(0.22, 0.207, 0.172), dust * 0.55);
		color = mix(color, seal + vec3(0.042, 0.033, 0.023) * detail, asphalt);
		float stripe = 1.0 - smoothstep(0.046, 0.062 + min(0.10, pixel_size), edge);
		float center_line = stripe * step(2.8, mod(ground.x, 9.2)) * smoothstep(0.28, 0.55, brush);
		color = mix(color, vec3(0.51, 0.47, 0.36), center_line * 0.72);
	}
	float variation = 0.95 + clamp((brush - 0.50) * 0.96, -0.11, 0.12);
	ALBEDO = color * variation;
	ROUGHNESS = 1.0;
}
