shader_type canvas_item;

uniform bool charcoal = false;

void fragment() {
	vec4 stroke = texture(TEXTURE, UV);
	float light = dot(stroke.rgb, vec3(0.299, 0.587, 0.114));
	float ink = 1.0 - smoothstep(0.12, 0.91, light);
	vec3 pigment = mix(vec3(0.18, 0.15, 0.13), stroke.rgb * 0.71, 0.56);
	if (charcoal) pigment = vec3(0.19);
	COLOR = vec4(pigment, stroke.a * ink);
}
