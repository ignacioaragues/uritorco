shader_type spatial;

uniform vec4 stone_tint : source_color = vec4(0.54, 0.49, 0.43, 1.0);
uniform bool colored_mesh = true;
uniform float bedding = 0.0;
varying vec3 rock_position;
varying vec3 local_rock;
varying float up_face;

void vertex() {
	rock_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_rock = VERTEX;
	up_face = normalize(MODEL_NORMAL_MATRIX * NORMAL).y;
}

float mineral_cell(vec3 p) {
	vec3 key = fract(p * vec3(0.1031, 0.1030, 0.0973));
	key += dot(key, key.yxz + 33.33);
	return fract((key.x + key.y) * key.z);
}

float mineral_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 blend = fract(p);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float a = mix(mineral_cell(cell), mineral_cell(cell + vec3(1, 0, 0)), blend.x);
	float b = mix(mineral_cell(cell + vec3(0, 1, 0)), mineral_cell(cell + vec3(1, 1, 0)), blend.x);
	float c = mix(mineral_cell(cell + vec3(0, 0, 1)), mineral_cell(cell + vec3(1, 0, 1)), blend.x);
	float d = mix(mineral_cell(cell + vec3(0, 1, 1)), mineral_cell(cell + vec3(1, 1, 1)), blend.x);
	return mix(mix(a, b, blend.y), mix(c, d, blend.y), blend.z);
}

void fragment() {
	vec3 p = rock_position;
	float resolution = max(length(dFdx(p)), length(dFdy(p)));
	float weathering = mineral_noise(p * vec3(1.2, 1.7, 1.2));
	float broad = mineral_noise(p * 5.2 + vec3(2.7, 6.1, -1.4) + weathering * 1.3);
	float aggregate = mineral_noise(p * 53.0 + vec3(broad * 2.8, weathering * 2.0, broad * 1.9));
	float resolved = 1.0 - smoothstep(0.008, 0.041, resolution);
	float flecks = resolved * (0.062 * smoothstep(0.66, 0.88, aggregate) - 0.080 * (1.0 - smoothstep(0.10, 0.37, aggregate)));
	vec3 paint = colored_mesh ? COLOR.rgb : stone_tint.rgb;
	vec3 stone = paint * (0.86 + 0.16 * weathering + 0.105 * broad + flecks);
	float oxidized = smoothstep(0.48, 0.81, weathering);
	stone = mix(stone, stone * vec3(1.12, 0.98, 0.84), oxidized * 0.57);
	float patches = mineral_noise(p * 3.7 + vec3(7.2, -2.8, 3.9));
	float lichen = smoothstep(0.58, 0.85, 0.61 * patches + 0.24 * weathering + 0.15 * broad);
	stone = mix(stone, stone * vec3(0.73, 0.79, 0.64), lichen * 0.62 * smoothstep(0.05, 0.78, up_face));
	float fault = dot(p, vec3(0.37, 1.72, -0.39)) + 0.34 * weathering + 0.13 * broad;
	float seam = 1.0 - smoothstep(0.006, 0.030, abs(fract(fault + 0.5) - 0.5));
	float interruptions = smoothstep(0.48, 0.77, 0.66 * patches + 0.34 * weathering);
	stone = mix(stone, paint * vec3(1.35, 1.29, 1.19), seam * interruptions * 0.37 * (1.0 - smoothstep(0.013, 0.059, resolution)));
	if (bedding > 0.0) {
		float x = local_rock.x;
		float height = local_rock.y + 0.09 * sin(x * 2.1) + 0.025 * sin(x * 7.8 + local_rock.z);
		float lower_joint = 1.0 - smoothstep(0.008, 0.044, abs(height - 0.35 + x * 0.062));
		float upper_joint = 1.0 - smoothstep(0.006, 0.033, abs(height - 0.99 - x * 0.037));
		float slant = x + 0.62 + 0.37 * height + 0.06 * sin(height * 14.2);
		float split = (1.0 - smoothstep(0.007, 0.041, abs(slant))) * (1.0 - smoothstep(0.89, 1.32, height));
		float cracks = lower_joint * smoothstep(-1.21, -0.15, x)
			+ upper_joint * (1.0 - smoothstep(0.19, 1.23, x)) + split * 0.7;
		float grain_break = 0.72 + 0.28 * sin(x * 7.0 + height * 11.9);
		stone *= 1.0 + bedding * (0.10 * broad - min(1.0, cracks) * 0.35 * grain_break);
	}
	ALBEDO = stone;
	ROUGHNESS = 0.94;
}
