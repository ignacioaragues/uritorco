shader_type spatial;

varying vec2 plate_face;

float grain(vec2 cell) {
	return fract(sin(dot(cell, vec2(157.73, 49.81))) * 32176.17);
}

void vertex() {
	plate_face = VERTEX.xy / vec2(0.64, 0.35) + 0.5;
}

void fragment() {
	vec2 uv = plate_face;
	float flecks = grain(floor(uv * vec2(340.0, 180.0)));
	float grime = grain(floor(uv * vec2(76.0, 95.0)));
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float scraped = 1.0 - smoothstep(0.009, 0.059, edge + (grime - 0.6) * 0.030);
	float water_marks = (0.5 + 0.5 * sin(uv.x * 119.0 + 3.2 * sin(uv.x * 22.0))) * 0.053;
	vec3 enamel = vec3(0.25, 0.285, 0.255) * (0.89 + flecks * 0.19 - water_marks);
	vec3 rust = mix(vec3(0.18, 0.126, 0.104), vec3(0.34, 0.215, 0.136), grime);
	ALBEDO = mix(enamel, rust, clamp(scraped * 0.89 + smoothstep(0.93, 1.0, grime) * 0.19, 0.0, 1.0));
	METALLIC = 0.21 + scraped * 0.12;
	ROUGHNESS = 0.65 + grime * 0.21;
}
