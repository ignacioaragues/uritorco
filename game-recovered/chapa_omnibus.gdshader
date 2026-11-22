shader_type spatial;

uniform vec4 enamel : source_color = vec4(0.64, 0.61, 0.47, 1.0);
uniform float axle_height = 0.0;
uniform float exposure = 1.0;
uniform bool coach_livery = false;
varying vec3 panel_point;

float hash_cell(vec3 p) {
	vec3 s = fract(p * vec3(0.1031, 0.1030, 0.0973));
	s += dot(s, s.yzx + 33.33);
	return fract((s.x + s.y) * s.z);
}

float surface_wear(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = smoothstep(vec3(0.0), vec3(1.0), fract(p));
	float a = mix(hash_cell(cell), hash_cell(cell + vec3(1, 0, 0)), f.x);
	float b = mix(hash_cell(cell + vec3(0, 1, 0)), hash_cell(cell + vec3(1, 1, 0)), f.x);
	float c = mix(hash_cell(cell + vec3(0, 0, 1)), hash_cell(cell + vec3(1, 0, 1)), f.x);
	float d = mix(hash_cell(cell + vec3(0, 1, 1)), hash_cell(cell + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	panel_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 p = panel_point;
	float h = p.y - axle_height;
	float grain = surface_wear(p * 54.0);
	float streaks = surface_wear(p * vec3(24.0, 2.2, 22.0));
	float patches = surface_wear(p * 3.8);
	float motion = max(length(dFdx(p)), length(dFdy(p)));
	float resolved = 1.0 - smoothstep(0.007, 0.025, motion);
	float dust = (1.0 - smoothstep(0.33, 1.50, h + 0.23 * streaks)) * (0.31 + 0.33 * patches);
	float chipped = smoothstep(0.68, 0.85, 0.61 * streaks + 0.39 * grain)
		* (0.36 + dust * 0.64) * resolved;
	vec3 pigment = enamel.rgb;
	if (coach_livery) {
		float lower = 1.0 - smoothstep(1.20, 1.23, h);
		pigment = mix(pigment, vec3(0.49, 0.275, 0.224), lower);
	}
	vec3 faded = pigment * (0.87 + 0.15 * patches + 0.085 * streaks + 0.10 * (grain - 0.5) * resolved);
	vec3 oxidized = vec3(0.25, 0.18, 0.12) * (0.71 + 0.29 * grain);
	vec3 painted = mix(faded, oxidized, exposure * chipped);
	ALBEDO = mix(painted, vec3(0.32, 0.27, 0.19), dust * 0.49 * exposure);
	ROUGHNESS = 0.51 + 0.36 * dust * exposure;
	METALLIC = 0.11 * (1.0 - dust);
	SPECULAR = 0.31;
}
