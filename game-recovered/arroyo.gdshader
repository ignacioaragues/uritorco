shader_type spatial;
render_mode cull_disabled;

uniform float rain = 0.0;
uniform float sediment = 0.0;
varying vec2 flow_position;

void vertex() {
	flow_position = VERTEX.xz;
}

void fragment() {
	vec2 p = flow_position - vec2(TIME * 0.82, 0.0);
	float broad = sin(p.x * 1.35 + sin(p.y * 3.9) * 1.4);
	float ripple = sin(p.y * 21.0 + p.x * 2.2 + broad * 2.4);
	float reflection = smoothstep(0.48, 1.0, ripple * 0.59 + broad * 0.41);
	vec3 water_color = mix(vec3(0.23, 0.31, 0.30), vec3(0.31, 0.28, 0.22), sediment);
	vec3 sheen = mix(vec3(0.53, 0.62, 0.59), vec3(0.62, 0.60, 0.53), sediment);
	float wake = smoothstep(0.74, 0.98, sin(p.x * 4.2 + cos(p.y * 2.0)) * sin(p.y * 13.0 - broad));
	float splash = 0.0;
	if (rain > 0.01) {
		vec2 grid = flow_position * 7.5;
		float seed = fract(sin(dot(floor(grid), vec2(127.1, 311.7))) * 43758.5453);
		float age = fract(seed * 7.0 + TIME * 2.1);
		float ring = abs(length(fract(grid) - vec2(0.5)) - age * 0.44);
		splash = step(0.60, seed) * rain * (1.0 - age) * (1.0 - smoothstep(0.016, 0.074, ring));
		splash *= 1.0 - smoothstep(9.0, 22.0, length(VERTEX));
	}
	ALBEDO = mix(water_color, sheen, reflection * 0.50 + wake * sediment * 0.19 + splash * 0.52);
	ROUGHNESS = 0.31 + 0.37 * (1.0 - reflection);
}
