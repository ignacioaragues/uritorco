shader_type spatial;

uniform vec4 stone_tint : source_color = vec4(0.54, 0.49, 0.43, 1.0);
uniform bool colored_mesh = true;
uniform float bedding = 0.0;
varying vec3 rock_position;
varying vec3 local_rock;

void vertex() {
	rock_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_rock = VERTEX;
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
	float weathering = mineral_noise(p * 1.4);
	float broad = mineral_noise(p * 6.6 + vec3(2.7, 6.1, -1.4));
	float aggregate = mineral_noise(p * 59.0);
	float resolved = 1.0 - smoothstep(0.008, 0.041, resolution);
	float flecks = resolved * (0.16 * smoothstep(0.62, 0.91, aggregate) - 0.20 * (1.0 - smoothstep(0.10, 0.31, aggregate)));
	vec3 paint = colored_mesh ? COLOR.rgb : stone_tint.rgb;
	vec3 stone = paint * (0.90 + 0.115 * weathering + 0.105 * broad + flecks);
	float patina = smoothstep(0.53, 0.86, 0.66 * weathering + 0.34 * broad);
	stone = mix(stone, paint * vec3(0.87, 0.92, 0.77), patina * 0.62);
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
