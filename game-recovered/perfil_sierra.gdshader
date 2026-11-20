shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 stone : source_color;
uniform float distance_layer = 0.0;
uniform float dusk = 0.0;
uniform float nightfall = 0.0;
varying vec3 rock_position;

void vertex() {
	rock_position = VERTEX;
}

void fragment() {
	float hatch = sin(rock_position.x * 0.193 + rock_position.y * 0.45) * sin(rock_position.z * 0.120 + rock_position.y * 0.24);
	float relief = (UV.x - 0.65) * (0.36 - 0.23 * distance_layer) + hatch * (0.018 - 0.012 * distance_layer);
	vec3 morning = stone.rgb * (0.92 + relief);
	morning = mix(morning, vec3(0.69, 0.72, 0.71), (1.0 - UV.y) * 0.16 + distance_layer * 0.11);
	vec3 evening = mix(morning, vec3(0.57, 0.50, 0.59), 0.30 * dusk);
	vec3 night = mix(vec3(0.085, 0.105, 0.156), vec3(0.18, 0.201, 0.264), distance_layer + (1.0 - distance_layer) * (1.0 - UV.y) * 0.16);
	ALBEDO = mix(evening, night * (0.94 + relief), nightfall);
}
