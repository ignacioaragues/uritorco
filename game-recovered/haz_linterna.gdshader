shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D opaque_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 light_origin;
uniform vec3 light_axis;
uniform float density = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 ndc = SCREEN_UV * 2.0 - 1.0;
	float depth = texture(opaque_depth, SCREEN_UV).r;
	// La profundidad despejada corresponde al cielo.
	if (depth <= 0.00001) {
		discard;
	}
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	depth = depth * 2.0 - 1.0;
#endif
	vec4 scene = INV_PROJECTION_MATRIX * vec4(ndc, depth, 1.0);
	vec3 direction = normalize(scene.xyz);
	float finish = min(length(scene.xyz) / max(abs(scene.w), 0.00001), 18.0);
	float step_size = finish / 16.0;
	float scatter = 0.0;
	if (dot(direction, light_axis) > 0.93) {
		for (int sample = 0; sample < 16; sample++) {
			vec3 offset = direction * ((float(sample) + 0.5) * step_size) - light_origin;
			float travel = dot(offset, light_axis);
			float radius = length(offset - light_axis * travel);
			float width = 0.054 + travel * 0.178;
			float envelope = smoothstep(0.30, 1.25, travel) * (1.0 - smoothstep(9.0, 18.0, travel));
			float core = 1.0 - smoothstep(0.18, 1.0, radius / max(width, 0.054));
			scatter += core * envelope * step_size / (0.92 + 0.25 * travel * travel);
		}
	}
	float glow = 0.13 * (1.0 - exp(-0.38 * density * scatter));
	if (glow < 0.001) {
		discard;
	}
	ALBEDO = vec3(0.87, 0.82, 0.68) * glow;
	ALPHA = 1.0;
}
