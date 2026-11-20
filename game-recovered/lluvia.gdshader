shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float rain_hash(vec2 id) {
	return fract(sin(dot(id, vec2(42.3, 97.1))) * 4265.4);
}

float droplets(vec2 uv, vec2 grid, float lean, float drift, float coverage, float width) {
	vec2 cell = vec2(uv.x + uv.y * lean, uv.y) * grid;
	float column = floor(cell.x);
	float seed = rain_hash(vec2(column, drift));
	cell.y += TIME * drift * (0.74 + 0.66 * seed) + seed * 53.0;
	float chance = rain_hash(floor(cell));
	vec2 sub = fract(cell);
	float streak = 1.0 - smoothstep(width * 0.42, width, abs(sub.x - (0.43 + seed * 0.14)));
	float tail = smoothstep(0.12, 0.58, sub.y) * (1.0 - smoothstep(0.63, 0.88, sub.y));
	return streak * tail * step(1.0 - coverage, chance);
}

void fragment() {
	float near_rain = droplets(UV, vec2(112.0, 21.0), 0.22, 13.4, intensity * 0.145, 0.076);
	float far_rain = droplets(UV + vec2(0.15, 0.0), vec2(197.0, 32.0), 0.17, 17.0, intensity * 0.20, 0.098);
	float alpha = (near_rain * 0.32 + far_rain * 0.19) * intensity;
	COLOR = vec4(0.73, 0.78, 0.82, alpha);
}
