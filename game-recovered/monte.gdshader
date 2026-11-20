shader_type spatial;

uniform vec2 west_start;
uniform vec2 west_end;
uniform vec2 east_start;
uniform vec2 east_end;
uniform vec2 mara_start;
uniform vec2 mara_end;
uniform vec2 creek_path[12];
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float grain_at(vec2 p) {
	return sin(p.x * 5.1 + sin(p.y * 2.1)) * sin(p.y * 3.7);
}

float edge_distance(vec2 p, vec2 a, vec2 b) {
	vec2 segment = b - a;
	return length(p - a - segment * clamp(dot(p - a, segment) / dot(segment, segment), 0.0, 1.0));
}

float track(float distance, float width, float grain) {
	return 1.0 - smoothstep(width * 0.48, width, distance + grain * 0.22);
}

void fragment() {
	vec2 p = ground_position;
	float d = -76.0 - p.y;
	float grain = grain_at(p);
	float ridge_path = -1.9 + 54.0 * sin(d / 83.0) + 18.0 * sin(d / 27.0);
	float refuge_path = 4.5 * sin(-p.y / 13.0);
	float center = mix(refuge_path, ridge_path, smoothstep(-3.0, 3.0, d));
	float distance_to_path = abs(p.x - center);
	if (d > 124.0 && d < 218.0) {
		distance_to_path = min(distance_to_path, abs(p.x - ridge_path - 36.0 * sin(PI * (d - 124.0) / 94.0)));
	}
	if (d > 43.0 && d < 104.0) {
		float fork = ridge_path - 19.0 * sin(PI * (d - 43.0) / 61.0);
		distance_to_path = min(distance_to_path, abs(p.x - fork) + 0.46);
	}
	float trail_width = mix(1.87, 2.34, smoothstep(0.0, 26.0, d));
	float central = track(distance_to_path, trail_width, grain);
	central *= (1.0 - smoothstep(923.0, 926.0, d)) * (1.0 - smoothstep(-0.5, 1.5, p.y));

	float west_t = (p.y - west_start.y) / (west_end.y - west_start.y);
	float west = 0.0;
	if (west_t >= 0.0 && west_t <= 1.0) {
		float western_x = mix(west_start.x, west_end.x, west_t) - 39.0 * sin(PI * west_t);
		west = track(abs(p.x - western_x), 2.3, grain) * (1.0 - smoothstep(0.99, 1.0, west_t));
	}
	float east_t = (p.y - east_start.y) / (east_end.y - east_start.y);
	float east = 0.0;
	if (east_t >= 0.0 && east_t <= 1.0) {
		float eastern_x = mix(east_start.x, east_end.x, smoothstep(0.0, 0.65, east_t));
		east = track(abs(p.x - eastern_x), 1.9, grain);
	}
	float mara = 0.0;
	if (p.x > mara_start.x - 3.0 && p.x < mara_end.x + 3.0 && p.y > -74.0 && p.y < -51.0) {
		float t = clamp((p.x - mara_start.x) / (mara_end.x - mara_start.x), 0.0, 1.0);
		vec2 via = mix(mara_start, mara_end, t) + vec2(0.0, sin(PI * t) * 1.9);
		mara = track(length(p - via), 1.9, grain);
	}
	float low_trail = 0.0;
	if (abs(p.x) < 38.0 && p.y > -24.0 && p.y < 83.0) {
		float creek_trail = 50.0;
		for (int i = 0; i < 11; i++) {
			creek_trail = min(creek_trail, edge_distance(p, creek_path[i], creek_path[i + 1]));
		}
		low_trail = track(creek_trail, 2.55, grain);
	}
	float exposed = max(max(central, west), max(max(east, mara), low_trail));
	float band = sin(p.y * 0.031 + cos(p.x * 0.12));
	float stipple = sin(p.x * 1.04 + p.y * 0.52) * sin(p.y * 0.79 - p.x * 0.42);
	float north = smoothstep(-2.0, 36.0, d);
	vec3 clay = mix(vec3(0.374, 0.282, 0.187), vec3(0.46, 0.31, 0.18), north);
	vec3 soil = mix(vec3(0.222, 0.191, 0.116), mix(vec3(0.207, 0.181, 0.113), vec3(0.311, 0.272, 0.175), band * 0.5 + 0.5), north);
	soil *= 1.0 + 0.055 * stipple;
	vec3 ground = mix(soil, clay, exposed);
	float low_channel = 82.0 + 4.6 * sin(p.x * 0.082) + 1.4 * sin(p.x * 0.17);
	float low_water = (1.0 - smoothstep(2.2, 7.5, abs(p.y - low_channel))) * (1.0 - smoothstep(49.0, 71.0, abs(p.x)));
	float creek_x = -1.9 + 54.0 * sin(96.0 / 83.0) + 18.0 * sin(96.0 / 27.0);
	float creek_d = 96.0 + 2.0 * sin((p.x - creek_x) / 14.0);
	float creek = (1.0 - smoothstep(1.3, 4.8, abs(d - creek_d))) * (1.0 - smoothstep(46.0, 68.0, abs(p.x - creek_x)));
	ground = mix(ground, vec3(0.251, 0.221, 0.182), low_water);
	ground = mix(ground, vec3(0.33, 0.29, 0.24), creek);
	ALBEDO = ground * (0.98 + 0.042 * grain);
	ROUGHNESS = 1.0;
}
