shader_type canvas_item;

uniform float bearing : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	vec2 on_stone = (UV - vec2(0.368, 0.355)) / vec2(0.162, 0.161);
	float center = 1.0 - smoothstep(0.66, 1.05, length(on_stone));
	float cyan = smoothstep(0.025, 0.27, art.b - art.r) * smoothstep(0.28, 0.72, art.g);
	float beat = 0.5 + 0.5 * sin(TIME * 2.4);
	vec3 flash = vec3(0.31, 0.76, 0.94) * center * (0.16 + 0.84 * cyan) * (0.46 + 0.54 * beat) * bearing;
	COLOR = vec4(art.rgb + flash, art.a) * tint;
}
