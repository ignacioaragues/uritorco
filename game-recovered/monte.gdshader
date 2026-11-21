shader_type spatial;

uniform vec2 west_start;
uniform vec2 west_end;
uniform vec2 east_start;
uniform vec2 east_end;
uniform vec4 ascent_curve; // X y distancia de cada punta del sendero este.
uniform vec4 summit_curve;
uniform vec2 ascent_bend;
uniform vec2 summit_shape;
uniform bool mara_track = false;
uniform vec2 mara_start;
uniform vec2 mara_end;
uniform vec2 creek_path[12];
uniform vec2 exploration_segments[64];
uniform int exploration_segment_count = 0;
uniform vec2 south_paths[62];
uniform float wet_ground = 0.0;
uniform float surface_rain = 0.0;
uniform sampler2D soil_detail : filter_linear_mipmap, repeat_enable;
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
	float rise = (d - ascent_curve.y) / (ascent_curve.w - ascent_curve.y);
	float ascent = 0.0;
	float ascent_shoulder = 0.0;
	if (rise >= 0.0 && rise <= 1.0) {
		float bend = sin(PI * rise) * (ascent_bend.x + ascent_bend.y * sin(TAU * rise * 4.0));
		float distance = abs(p.x - mix(ascent_curve.x, ascent_curve.z, rise) - bend);
		ascent = track(distance, 1.60 + 0.22 * sin(rise * 51.0), grain);
		ascent_shoulder = 1.0 - smoothstep(1.8, 21.0, distance);
	}
	if (d > summit_curve.y - 16.0 && d < summit_curve.w + 18.0) {
		float t = clamp((p.x - summit_curve.x) / (summit_curve.z - summit_curve.x), summit_shape.x, 1.0);
		float ridge_d = mix(summit_curve.y, summit_curve.w, t) + summit_shape.y * sin(TAU * t);
		float ridge_x = mix(summit_curve.x, summit_curve.z, t);
		float distance = length(vec2(d - ridge_d, p.x - ridge_x));
		ascent = max(ascent, track(distance, 1.68, grain));
		ascent_shoulder = max(ascent_shoulder, 1.0 - smoothstep(1.8, 21.0, distance));
	}
	float mara = 0.0;
	if (mara_track && p.x > mara_start.x - 3.0 && p.x < mara_end.x + 3.0 && p.y > -74.0 && p.y < -51.0) {
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
	float local_trails = 0.0;
	if (abs(p.x) < 46.0 && p.y > -31.0 && p.y < 63.0) {
		float trail_distance = 50.0;
		for (int i = 0; i < exploration_segment_count; i += 2) {
			trail_distance = min(trail_distance, edge_distance(p, exploration_segments[i], exploration_segments[i + 1]));
		}
		local_trails = track(trail_distance, 1.8, grain);
	}
	float south = 0.0;
	if (p.x < -20.0 && p.x > -147.0 && p.y > -21.0 && p.y < 108.0) {
		float route = 200.0;
		for (int i = 0; i < 48; i++) {
			route = min(route, edge_distance(p, south_paths[i], south_paths[i + 1]));
		}
		float link = 200.0;
		if (p.x > -68.0 && p.y > 29.0 && p.y < 55.0) {
			for (int i = 49; i < 61; i++) {
				link = min(link, edge_distance(p, south_paths[i], south_paths[i + 1]));
			}
		}
		south = max(track(route, 1.95, grain), track(link, 1.42, grain));
	}
	float exposed = max(max(central, west), max(max(east, mara), max(south, max(low_trail, local_trails))));
	float band = sin(p.y * 0.031 + cos(p.x * 0.12));
	float stipple = sin(p.x * 1.04 + p.y * 0.52) * sin(p.y * 0.79 - p.x * 0.42);
	float north = smoothstep(-2.0, 36.0, d);
	vec3 clay = mix(vec3(0.374, 0.282, 0.187), vec3(0.46, 0.31, 0.18), north);
	vec3 soil = mix(vec3(0.222, 0.191, 0.116), mix(vec3(0.207, 0.181, 0.113), vec3(0.311, 0.272, 0.175), band * 0.5 + 0.5), north);
	soil *= 1.0 + 0.055 * stipple;
	vec3 ground = mix(soil, clay, exposed);
	float stony = smoothstep(0.25, 0.78, sin(d * 0.14 + p.x * 0.64) * 0.24 + band * 0.34 + 0.45);
	float highland = smoothstep(400.0, 900.0, d);
	vec3 shale = mix(vec3(0.302, 0.287, 0.217), vec3(0.381, 0.347, 0.287), highland);
	ground = mix(ground, shale, (0.25 + highland * 0.32) * stony * ascent_shoulder * (1.0 - exposed));
	vec3 ascent_soil = mix(vec3(0.392, 0.303, 0.199), vec3(0.43, 0.375, 0.295), highland);
	ground = mix(ground, ascent_soil, ascent * 0.88);
	float low_channel = 82.0 + 4.6 * sin(p.x * 0.082) + 1.4 * sin(p.x * 0.17) + 24.0 * smoothstep(54.0, 140.0, -p.x);
	float channel = (1.0 - smoothstep(2.2, 7.5, abs(p.y - low_channel)));
	float low_water = channel * (1.0 - max(smoothstep(49.0, 71.0, p.x), smoothstep(156.0, 207.0, -p.x)));
	ground = mix(ground, vec3(0.251, 0.221, 0.182), low_water);
	vec3 brushwork = texture(soil_detail, p * 0.22).rgb;
	float brush_value = dot(brushwork, vec3(0.30, 0.59, 0.11));
	float paint = clamp((brush_value - 0.516) * 2.4, -0.19, 0.19);
	float damp = wet_ground * (0.19 + 0.29 * low_water + 0.15 * south);
	float puddle = smoothstep(0.31, 0.79, band * 0.41 + stipple * 0.37 + paint);
	damp += wet_ground * 0.16 * puddle;
	float splash = 0.0;
	if (surface_rain > 0.01 && length(VERTEX) < 20.0) {
		vec2 cells = p * 5.0;
		float seed = fract(sin(dot(floor(cells), vec2(127.1, 311.7))) * 43758.5453);
		float age = fract(seed * 13.1 + TIME * (1.6 + seed * 1.4));
		vec2 offset = vec2(seed, fract(seed * 31.7)) * 0.52 + 0.24;
		float ring = abs(length(fract(cells) - offset) - age * 0.48);
		splash = (1.0 - smoothstep(0.029, 0.085, ring)) * (1.0 - smoothstep(0.05, 0.48, age));
		splash *= step(0.70, seed) * (1.0 - smoothstep(8.0, 20.0, length(VERTEX))) * surface_rain;
	}
	ALBEDO = ground * (0.98 + paint + 0.042 * grain - damp) + vec3(0.20, 0.24, 0.25) * splash;
	ROUGHNESS = 1.0 - damp * 0.47;
}
