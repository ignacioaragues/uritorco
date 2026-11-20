shader_type canvas_item;

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float thumb = smoothstep(0.133, 0.23, paint.r - paint.g) * smoothstep(0.10, 0.20, paint.g - paint.b);
	float crop = step(149.0, px.x) * step(px.x, 212.0) * step(132.0, px.y) * step(px.y, 320.0);
	COLOR = vec4(paint.rgb, paint.a * thumb * crop);
}
