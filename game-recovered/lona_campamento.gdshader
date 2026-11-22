shader_type spatial;
render_mode cull_disabled;

varying vec3 woven_position;

void vertex() {
	woven_position = VERTEX;
	float inset = sin(PI * UV.x) * sin(PI * UV.y);
	VERTEX.y += inset * 0.012 * sin(TIME * 1.7 + UV.x * 8.0 + UV.y * 4.0);
}

void fragment() {
	vec2 uv = UV;
	vec3 p = woven_position;
	float seam = max(
		1.0 - smoothstep(0.002, 0.006, abs(uv.x - 0.48)),
		1.0 - smoothstep(0.002, 0.006, abs(uv.x - 0.53)));
	float border = 1.0 - smoothstep(0.017, 0.032, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	float fiber = sin(uv.x * 830.0) * sin(uv.y * 689.0);
	float resolved = 1.0 - smoothstep(0.35, 2.8, max(fwidth(uv.x * 830.0), fwidth(uv.y * 689.0)));
	float rub = sin(p.x * 17.9 + sin(p.z * 20.0)) * sin(p.z * 10.7 + p.y * 3.2);
	float weather = sin(p.x * 6.3 - p.z * 9.1) * sin(p.z * 6.4 + p.y * 8.0);
	float stain = smoothstep(0.33, 0.79, weather * 0.42 + rub * 0.19 + 0.20 * (1.0 - uv.y) + 0.18);
	vec3 cloth = mix(vec3(0.272, 0.247, 0.153), vec3(0.382, 0.338, 0.227), smoothstep(-0.45, 0.8, weather));
	cloth *= 0.98 + 0.045 * fiber * resolved + 0.035 * rub - 0.19 * stain - 0.21 * border;
	float stitches = smoothstep(0.30, 0.74, sin(uv.y * 351.0));
	ALBEDO = cloth + vec3(0.093, 0.072, 0.045) * seam * stitches;
	ROUGHNESS = 0.92;
}
