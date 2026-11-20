shader_type canvas_item;

uniform sampler2D view : hint_screen_texture, filter_linear, repeat_disable;
uniform float submerged : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = SCREEN_UV;
	vec2 ripple = vec2(sin(p.y * 73.0 + TIME * 1.9), sin(p.x * 44.0 - TIME * 1.4));
	vec3 scene = texture(view, p + ripple * 0.003 * submerged).rgb;
	scene *= mix(vec3(1.0), vec3(0.55, 0.86, 0.83), submerged);
	COLOR = vec4(mix(scene, vec3(0.12, 0.25, 0.24), submerged * 0.30), 1.0);
}
