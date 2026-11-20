shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 position = UV + vec2(UV.y * 0.35, 0.0);
	vec2 cells = position * vec2(170.0, 18.0);
	float id = floor(cells.x);
	cells.y += TIME * (7.0 + fract(sin(id * 13.14) * 643.7) * 6.0);
	float random = fract(sin(dot(floor(cells), vec2(42.3, 97.1))) * 4265.4);
	float drop = (1.0 - smoothstep(0.035, 0.15, abs(fract(cells.x) - 0.5)))
		* smoothstep(0.25, 0.46, fract(cells.y)) * (1.0 - smoothstep(0.5, 0.84, fract(cells.y)));
	COLOR = vec4(0.71, 0.78, 0.81, drop * step(0.87 - intensity * 0.28, random) * intensity * 0.55);
}
