shader_type spatial;
render_mode cull_disabled;

varying vec2 flow_position;

void vertex() {
	flow_position = VERTEX.xz;
}

void fragment() {
	vec2 p = flow_position - vec2(TIME * 0.82, 0.0);
	float broad = sin(p.x * 1.35 + sin(p.y * 3.9) * 1.4);
	float ripple = sin(p.y * 21.0 + p.x * 2.2 + broad * 2.4);
	float reflection = smoothstep(0.48, 1.0, ripple * 0.59 + broad * 0.41);
	ALBEDO = mix(vec3(0.23, 0.31, 0.30), vec3(0.53, 0.62, 0.59), reflection * 0.50);
	ROUGHNESS = 0.31 + 0.37 * (1.0 - reflection);
}
