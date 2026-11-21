shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add, shadows_disabled;

uniform vec4 glint : source_color = vec4(0.76, 0.83, 0.88, 1.0);
uniform float phase = 0.0;
varying float distance_to_eye;

void vertex() {
	distance_to_eye = distance(CAMERA_POSITION_WORLD, MODEL_MATRIX[3].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float center = exp(-dot(p, p) * 17.0);
	float ray = exp(-abs(p.x) * 48.0 - abs(p.y) * 4.8) + exp(-abs(p.y) * 48.0 - abs(p.x) * 4.8);
	float pulse = pow(0.5 + 0.5 * sin(TIME * 2.7 + phase), 4.0);
	ALBEDO = glint.rgb;
	ALPHA = (center * 0.30 + ray * 0.18) * (0.08 + pulse * 0.92) * (1.0 - smoothstep(2.2, 5.0, distance_to_eye));
}
