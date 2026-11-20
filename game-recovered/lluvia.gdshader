shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (abs(world_position.x) < 3.70 && world_position.z > -0.54 && world_position.z < 6.13 && world_position.y < 3.05) {
		discard;
	}
	float distance_fade = smoothstep(0.60, 2.9, length(VERTEX));
	ALBEDO = vec3(0.59, 0.68, 0.74);
	ALPHA = intensity * distance_fade * 0.28;
}
