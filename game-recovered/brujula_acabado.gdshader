shader_type canvas_item;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float rim_distance = length((pixel - vec2(187.0, 146.0)) / vec2(101.0, 76.0));
	float ivory = smoothstep(0.60, 0.80, paint.b) * smoothstep(0.75, 0.89, paint.g);
	float lip = smoothstep(0.865, 0.954, rim_distance) * (1.0 - smoothstep(1.03, 1.08, rim_distance));
	float paper = ivory * (1.0 - smoothstep(0.84, 1.02, rim_distance));
	paint.rgb *= mix(vec3(1.0), vec3(0.94, 0.88, 0.76), paper);
	vec3 brass = mix(vec3(0.45, 0.31, 0.16), vec3(0.64, 0.46, 0.25), smoothstep(-0.8, 0.8, (pixel.y - 146.0) / 76.0));
	paint.rgb = mix(paint.rgb, brass, ivory * lip * 0.90);
	COLOR = paint * tint;
}
