shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float rain = 0.0;
uniform float moisture = 0.0;

float glass_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 lanes = UV * vec2(94.0, 5.0);
	float lane = floor(lanes.x);
	float drift = glass_hash(vec2(lane, 7.0));
	lanes.y += drift * 4.2 - TIME * mix(0.12, 0.55, drift) * smoothstep(0.0, 0.45, rain);
	float seed = glass_hash(floor(lanes));
	vec2 inside = fract(lanes);
	float sideways = abs(inside.x - mix(0.21, 0.79, seed));
	float down = inside.y - 0.73;
	float bead = 1.0 - smoothstep(0.18, 1.0, length(vec2(sideways / 0.095, down / 0.020)));
	float trail = (1.0 - smoothstep(0.027, 0.102, sideways)) * smoothstep(-0.28, 0.0, down) * (1.0 - step(0.0, down));
	float drop = step(0.90 - 0.23 * moisture, seed) * (bead * 0.36 + trail * rain * 0.24);
	ALBEDO = mix(vec3(0.46, 0.58, 0.64), vec3(0.76, 0.85, 0.89), bead);
	ALPHA = moisture * (0.032 + drop);
}
