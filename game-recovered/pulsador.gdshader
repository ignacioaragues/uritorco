shader_type canvas_item;
uniform float squeeze : hint_range(0.0, 1.0) = 0.0;

varying vec4 tint;
void vertex() { tint = COLOR; }

void fragment() {
	// Flex the thumb pad into the side of the case. Leave the aerial and LCD rigid.
	vec2 p = (UV - vec2(0.46, 0.425)) / vec2(0.155, 0.16);
	float thumb = 1.0 - smoothstep(0.12, 1.0, length(p));
	vec2 uv = UV + vec2(0.022, 0.010) * thumb * squeeze;
	COLOR = texture(TEXTURE, uv) * tint;
}
