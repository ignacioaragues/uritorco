shader_type spatial;

uniform vec4 tint : source_color;
uniform float fabric : hint_range(0.0, 1.0) = 0.0;
uniform float wear : hint_range(0.0, 1.0) = 0.45;
uniform float roughness : hint_range(0.0, 1.0) = 0.83;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position;
	float flecks = sin(p.x * 403.0 + p.y * 371.0) * cos(p.z * 312.0 - p.y * 186.0);
	float patch = sin(p.x * 27.0 - p.y * 29.0 + sin(p.z * 55.0)) * sin(p.z * 38.0 + p.y * 17.0);
	float weave = sin(p.y * 615.0 + sin(p.x * 22.0)) * sin((p.x + p.z * 0.67) * 684.0);
	float fibres = weave * (1.0 - smoothstep(0.0007, 0.0035, max(length(dFdx(p)), length(dFdy(p)))));
	float abrasion = 0.075 * patch + 0.018 * flecks + 0.085 * fibres * fabric;
	ALBEDO = tint.rgb * (0.97 + wear * abrasion);
	ROUGHNESS = roughness;
}
