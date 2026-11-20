shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_tone : source_color;
uniform vec4 dyed_tone : source_color;
uniform float period = 0.48;
uniform float grain_scale = 450.0;
varying vec3 cloth_position;

void vertex() {
	cloth_position = VERTEX;
}

void fragment() {
	vec3 p = cloth_position;
	float phase = fract((p.z + p.y * 0.12) / period + 0.014 * sin(p.x * 17.0));
	float band = smoothstep(0.10, 0.13, phase) * (1.0 - smoothstep(0.48, 0.51, phase));
	float border = smoothstep(0.57, 0.58, phase) * (1.0 - smoothstep(0.62, 0.63, phase));
	float warp = sin(p.x * grain_scale + 0.8 * sin(p.z * 35.0));
	float weft = sin((p.z - p.y * 0.42) * grain_scale * 0.77);
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	float thread = warp * weft * (1.0 - smoothstep(0.001, 0.005, footprint));
	float nap = sin(p.x * 31.0 + cos(p.z * 16.0)) * sin(p.z * 24.0 - p.y * 18.0);
	vec3 pigment = mix(base_tone.rgb, dyed_tone.rgb, 0.79 * band + 0.58 * border);
	ALBEDO = pigment * (1.0 + 0.10 * thread + 0.05 * nap);
	ROUGHNESS = 0.96;
}
