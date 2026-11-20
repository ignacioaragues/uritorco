shader_type spatial;
render_mode cull_disabled;

uniform sampler2D paper : source_color, filter_linear_mipmap;
uniform sampler2D drawing : source_color, filter_linear_mipmap;
uniform vec4 tile = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 stroke = texture(drawing, tile.xy + clamp((UV - vec2(0.07)) / 0.86, vec2(0.002), vec2(0.998)) * tile.zw);
	float brightness = dot(stroke.rgb, vec3(0.299, 0.587, 0.114));
	float margin = step(0.07, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float ink = (1.0 - smoothstep(0.15, 0.79, brightness)) * stroke.a * margin;
	ALBEDO = texture(paper, UV).rgb * mix(1.0, 0.19, ink);
	ROUGHNESS = 0.96;
}
