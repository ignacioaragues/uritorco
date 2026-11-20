shader_type canvas_item;
render_mode blend_mul;

uniform bool charcoal = false;

void fragment() {
	vec4 stroke = texture(TEXTURE, UV);
	float light = dot(stroke.rgb, vec3(0.299, 0.587, 0.114));
	float ink = (1.0 - smoothstep(0.15, 0.79, light)) * stroke.a;
	vec3 pigment = mix(vec3(0.18, 0.15, 0.13), stroke.rgb * 0.71, 0.56);
	if (charcoal) pigment = vec3(0.19);
	// White is neutral in multiply, so paper stays visible even inside the sketch.
	COLOR = vec4(mix(vec3(1.0), pigment, ink), 1.0);
}
