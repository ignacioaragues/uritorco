shader_type spatial;
render_mode cull_disabled;

uniform vec4 zinc : source_color = vec4(0.63, 0.65, 0.63, 1.0);
uniform vec4 old_zinc : source_color = vec4(0.48, 0.52, 0.53, 1.0);
uniform vec4 iron_oxide : source_color = vec4(0.41, 0.29, 0.21, 1.0);
uniform float wave_width = 0.148;

float hash_cell(vec2 p) {
	vec3 n = fract(vec3(p.xyx) * 0.1031);
	n += dot(n, n.yzx + 33.33);
	return fract((n.x + n.y) * n.z);
}

float wear(vec2 p) {
	vec2 cell = floor(p);
	vec2 a = smoothstep(0.0, 1.0, fract(p));
	return mix(mix(hash_cell(cell), hash_cell(cell + vec2(1, 0)), a.x),
		mix(hash_cell(cell + vec2(0, 1)), hash_cell(cell + vec2(1, 1)), a.x), a.y);
}

void fragment() {
	vec2 at = UV;
	float panel_width = wave_width * 7.0;
	float panel = floor(at.x / panel_width);
	float panel_seam = 1.0 - smoothstep(0.006, 0.020, abs(fract(at.x / panel_width + 0.5) - 0.5) * panel_width);
	float lap = 1.0 - smoothstep(0.008, 0.030, abs(at.y - 4.4));
	float spots = wear(at * vec2(9.0, 4.5));
	float streak = wear(at * vec2(14.0, 1.45));
	float mica = hash_cell(floor(at * 61.0 + wear(at * 22.0) * 0.62));
	float opacity = 1.0 - smoothstep(0.005, 0.026, max(length(dFdx(at)), length(dFdy(at))));
	float older = 0.24 + hash_cell(vec2(panel, 4.0)) * 0.33 + streak * 0.26;
	vec3 metal = mix(zinc.rgb, old_zinc.rgb, older) * (0.91 + 0.16 * spots + (mica - 0.5) * 0.12 * opacity);
	float corrosion = smoothstep(0.61, 0.84, streak) * smoothstep(0.48, 0.77, spots);
	corrosion *= 0.18 + 0.52 * (1.0 - smoothstep(0.10, 0.62, min(at.y, 7.82 - at.y)));
	metal = mix(metal, iron_oxide.rgb, corrosion);
	metal *= 1.0 - 0.22 * max(panel_seam, lap);
	vec2 fastener = vec2((fract(at.x / (wave_width * 3.0)) - 0.16) * wave_width * 3.0,
		(fract((at.y + 0.82) / 1.56) - 0.5) * 1.56);
	float screw = 1.0 - smoothstep(0.013, 0.020, length(fastener));
	ALBEDO = mix(metal, old_zinc.rgb * 0.48, screw * opacity);
	ROUGHNESS = 0.66 + corrosion * 0.24;
	METALLIC = 0.28 * (1.0 - corrosion);
	SPECULAR = 0.31;
}
