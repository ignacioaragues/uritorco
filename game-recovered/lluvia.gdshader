shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 museum_center;
uniform vec3 museum_half_extents;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (abs(world_position.x) < 3.70 && world_position.z > -0.54 && world_position.z < 6.13 && world_position.y < 3.05) {
		discard;
	}
	if (all(lessThan(abs(world_position - museum_center), museum_half_extents))) {
		discard;
	}
	float distance_to_eye = length(VERTEX);
	float distance_fade = smoothstep(0.85, 2.9, distance_to_eye) * (1.0 - smoothstep(23.0, 34.0, distance_to_eye));
	ALBEDO = vec3(0.58, 0.67, 0.74);
	ALPHA = intensity * distance_fade * 0.48;
}
