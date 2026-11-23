float cloud_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float cloud_noise(vec2 p) {
	vec2 origin = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cloud_hash(origin), cloud_hash(origin + vec2(1.0, 0.0)), f.x),
		mix(cloud_hash(origin + vec2(0.0, 1.0)), cloud_hash(origin + vec2(1.0, 1.0)), f.x), f.y);
}

float cloud_texture(vec2 p) {
	float low = cloud_noise(p);
	p = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 2.1;
	return low * 0.55 + cloud_noise(p) * 0.26 + cloud_noise(p * 2.08 + 9.2) * 0.13 + cloud_noise(p * 4.17) * 0.06;
}

vec3 storm_cloud_color(vec3 sight, vec3 overhead, vec3 air, float rain, float mist, vec2 shift) {
	float height = max(sight.y, 0.0);
	vec2 deck_uv = sight.xz * vec2(3.9, 4.8) / (height + 0.37) + shift * 1.4;
	float billows = cloud_texture(deck_uv);
	float folds = cloud_texture(deck_uv * 2.02 + vec2(8.3, 13.9));
	float depth = smoothstep(0.23, 0.69, billows * 0.73 + folds * 0.27);
	vec3 underside = overhead * mix(0.58, 1.38, depth) * (1.0 - rain * 0.12);
	float low_veil = 1.0 - smoothstep(0.02, 0.23, height);
	vec3 horizon = air * mix(1.0, 1.31, depth);
	horizon = mix(horizon, air, low_veil * (0.75 + mist * 0.20));
	return mix(horizon, underside, smoothstep(0.06, 0.53, height));
}
