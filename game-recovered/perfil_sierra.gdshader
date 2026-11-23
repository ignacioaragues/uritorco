shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 stone : source_color;
uniform float distance_layer = 0.0;
uniform float dusk = 0.0;
uniform float nightfall = 0.0;
uniform float storm_amount = 0.0;
uniform float valley_mist = 0.0;
uniform bool storm_deck = false;
uniform vec4 storm_air : source_color = vec4(0.32, 0.38, 0.43, 1.0);
uniform vec4 storm_overhead : source_color = vec4(0.21, 0.27, 0.31, 1.0);
uniform vec2 storm_shift = vec2(0.0);
varying vec3 rock_position;

#include "res://nubes.gdshaderinc"

void vertex() {
	rock_position = VERTEX;
}

void fragment() {
	float hatch = sin(rock_position.x * 0.193 + rock_position.y * 0.45) * sin(rock_position.z * 0.120 + rock_position.y * 0.24);
	float relief = (UV.x - 0.65) * (0.36 - 0.23 * distance_layer) + hatch * (0.018 - 0.012 * distance_layer);
	float shoulder = sin(rock_position.x * 0.045 + rock_position.z * 0.034 + UV.y * 2.7)
		* cos(rock_position.z * 0.039 - UV.y * 2.0);
	float cleft = 1.0 - smoothstep(0.02, 0.25, abs(sin(rock_position.x * 0.137 + rock_position.z * 0.079 - UV.y * 4.2 + shoulder * 1.9)));
	float visible_slope = smoothstep(0.14, 0.65, UV.y) * (1.0 - 0.76 * distance_layer);
	relief += (shoulder * 0.034 - cleft * 0.032) * visible_slope * (1.0 - nightfall * 0.85);
	vec3 morning = stone.rgb * (0.92 + relief);
	morning = mix(morning, vec3(0.69, 0.72, 0.71), (1.0 - UV.y) * 0.16 + distance_layer * 0.11);
	vec3 rain_haze = mix(vec3(0.45, 0.52, 0.54), vec3(0.61, 0.66, 0.67), distance_layer);
	morning = mix(morning, rain_haze, storm_amount * (0.31 + 0.49 * distance_layer));
	float low_veil = valley_mist * (1.0 - UV.y * 0.58) * (0.34 + 0.45 * distance_layer);
	morning = mix(morning, vec3(0.66, 0.71, 0.71), low_veil);
	if (storm_deck) {
		vec3 slopes = stone.rgb * (0.57 - storm_amount * 0.13 + relief * 0.64);
		float rain_density = 0.0031 + storm_amount * 0.0049;
		float transmittance = exp(-length(VERTEX) * (rain_density + low_veil * 0.003));
		vec3 sight = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
		vec3 haze = storm_cloud_color(sight, storm_overhead.rgb, storm_air.rgb, storm_amount, valley_mist, storm_shift);
		morning = mix(haze, slopes, transmittance);
	}
	vec3 evening = mix(morning, vec3(0.57, 0.50, 0.59), 0.30 * dusk);
	vec3 night = mix(vec3(0.085, 0.105, 0.156), vec3(0.18, 0.201, 0.264), distance_layer + (1.0 - distance_layer) * (1.0 - UV.y) * 0.16);
	ALBEDO = mix(evening, night * (0.94 + relief), nightfall);
}
