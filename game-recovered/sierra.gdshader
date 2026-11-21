shader_type sky;

uniform float dusk : hint_range(0.0, 1.0) = 0.0;
uniform float nightfall : hint_range(0.0, 1.0) = 0.0;
uniform vec4 high_day : source_color = vec4(0.38,0.57,0.71,1.0);
uniform vec4 rim_day : source_color = vec4(0.95,0.77,0.62,1.0);
uniform vec4 high_night : source_color = vec4(0.039,0.054,0.116,1.0);
uniform vec4 rim_night : source_color = vec4(0.19,0.205,0.30,1.0);

uniform vec4 catalog[32];
uniform vec3 planet_dirs[2];
uniform vec3 galactic_pole;
uniform vec3 moon_dir;
uniform vec3 daylight_dir = vec3(0.69, 0.41, 0.59);
uniform float moon_radius = 0.083;
uniform float other_world = 0.0;
uniform float cloud_cover = 0.0;
uniform float cloud_pattern = 0.0;
uniform vec2 cloud_drift = vec2(0.0);
uniform float storm_amount = 0.0;
uniform float cirrus_amount = 0.32;
uniform float valley_mist = 0.0;

float cloud_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float star_field(vec3 dir) {
	vec3 axis = abs(dir);
	vec3 face = dir;
	float seed = 19.3;
	if (axis.y > max(axis.x,axis.z)) {
		face = dir.xzy;
		seed = 46.2;
	} else if (axis.x > axis.z) {
		face = dir.yzx;
		seed = 76.9;
	}
	float side = sign(face.z);
	vec2 cell = floor(face.xy / abs(face.z) * 41.0);
	vec2 key = cell + vec2(seed * side, seed);
	float power = cloud_hash(key + vec2(17.3, 29.1));
	if (power < 0.42) return 0.0;
	vec2 offset = vec2(cloud_hash(key), cloud_hash(key + vec2(31.5, 7.4)));
	vec3 point = normalize(vec3((cell + mix(vec2(0.21), vec2(0.79), offset)) / 41.0, side));
	float radius = mix(0.0013, 0.0032, power * power);
	return (1.0 - smoothstep(radius * 0.3, radius, length(face - point))) * (0.13 + power * power * 0.66);
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

vec3 night_stars(vec3 sight) {
	float band = 1.0 - smoothstep(0.025, 0.24, abs(dot(sight, galactic_pole)));
	vec3 glow = vec3(0.0);
	if (band > 0.0) {
		float dust = cloud_texture(sight.xz * 12.0 + sight.y * vec2(7.0, 5.0));
		glow = vec3(0.078, 0.087, 0.12) * band * (0.12 + 0.52 * dust);
	}
	float points = star_field(sight);
	for (int i = 0; i < 32; i++) {
		float power = clamp(1.30 - 0.25 * catalog[i].w, 0.48, 1.80);
		float radius = 0.0038 * power;
		vec3 offset = sight - catalog[i].xyz;
		points += power * (1.0 - smoothstep(radius * radius * 0.0256, radius * radius, dot(offset, offset)));
	}
	glow += vec3(0.90, 0.93, 1.0) * points;
	float jupiter = length(sight - planet_dirs[0]);
	float saturn = length(sight - planet_dirs[1]);
	glow += vec3(1.0, 0.91, 0.73) * (1.42 * (1.0 - smoothstep(0.0015, 0.0045, jupiter)) + 0.22 * exp(-jupiter * jupiter * 38000.0));
	glow += vec3(1.0, 0.78, 0.53) * (0.93 * (1.0 - smoothstep(0.0011, 0.0034, saturn)) + 0.11 * exp(-saturn * saturn * 64000.0));
	return glow;
}

// Project the solar direction onto the visible lunar hemisphere for the terminator.
vec3 disc(vec3 sight, vec3 center, vec3 light, float radius, vec3 tint, vec3 backdrop, float opacity, float shadow) {
	vec3 offset = (sight-center)/radius;
	float r = length(offset);
	if (r>1.15) return backdrop;
	vec3 normal = normalize(offset-center*sqrt(max(0.0,1.0-r*r)));
	float lit = smoothstep(-0.025,0.06,dot(normal,light));
	vec3 right = normalize(cross(center, abs(center.y) > 0.98 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0)));
	vec2 surface = vec2(dot(offset, right), dot(offset, cross(right, center)));
	float maria = 0.72 + 0.30 * cloud_texture(surface * 3.4 + vec2(5.3, 13.1));
	float edge = 1.0 - smoothstep(0.95, 1.035, r);
	return mix(backdrop, tint * (0.065 + lit * maria), edge * opacity * mix(lit, 1.0, shadow));
}

void sky(){
	float height = max(EYEDIR.y,0.0);
	float blend = smoothstep(0.0,0.79,height);
	float facing_sunset = pow(clamp(0.5 + dot(EYEDIR.xz, normalize(daylight_dir.xz)) * 0.5, 0.0, 1.0), 2.8);
	vec3 horizon = mix(rim_day.rgb, vec3(0.91,0.39,0.21), dusk * (0.20 + facing_sunset * 0.80));
	vec3 daytime = mix(horizon,high_day.rgb,blend);
	vec3 dark = mix(rim_night.rgb,high_night.rgb,smoothstep(0.0,0.48,height));
	vec3 earth = dark;
	if (nightfall > 0.0 && other_world < 1.0) earth += night_stars(EYEDIR);
	float from_sun = length(EYEDIR - daylight_dir);
	float solar_glow = exp(-from_sun * from_sun * 42.0) * smoothstep(-0.18, 0.20, daylight_dir.y);
	float sun_edge = (1.0 - smoothstep(0.017, 0.021, from_sun)) * smoothstep(-0.019, 0.008, EYEDIR.y);
	daytime += mix(vec3(1.0,0.91,0.76), vec3(1.0,0.49,0.24), dusk) * (solar_glow * 0.26 + sun_edge * 1.12);
	if (moon_dir.y > -moon_radius && EYEDIR.y > -0.008) {
		float phase = 0.5 - 0.5 * dot(daylight_dir, moon_dir);
		float moonlight = smoothstep(0.015, 0.085, phase) * smoothstep(-0.008, 0.048, EYEDIR.y);
		earth = disc(EYEDIR,moon_dir,daylight_dir,moon_radius,vec3(1.28,1.21,1.10),earth,moonlight,1.0);
		daytime = disc(EYEDIR,moon_dir,daylight_dir,moon_radius,vec3(1.03,1.06,1.10),daytime,moonlight * (0.48 + dusk * 0.19),dusk * 0.12);
	}
	vec3 alien = mix(vec3(0.19,0.095,0.18),vec3(0.024,0.013,0.07),blend);
	if (other_world > 0.0) alien += vec3(0.66,0.86,0.95)*star_field(EYEDIR.zxy);
	alien=disc(EYEDIR,normalize(vec3(0.35,0.48,-1.0)),normalize(vec3(-1.0,0.6,0.4)),0.038,vec3(0.95,0.72,0.51),alien,1.0,1.0);
	alien=disc(EYEDIR,normalize(vec3(0.08,0.66,-1.0)),normalize(vec3(-1.0,0.6,0.4)),0.016,vec3(0.65,0.83,0.91),alien,1.0,1.0);
	vec2 shift = vec2(cloud_pattern * 0.31, cloud_pattern * 0.59) + cloud_drift;
	vec2 alto = EYEDIR.xz * vec2(3.5, 7.0) / (height + 0.47) + shift;
	float silk = smoothstep(0.53, 0.75, cloud_texture(alto)) * cirrus_amount;
	vec2 p = EYEDIR.xz * vec2(5.2, 4.4) / (height + 0.38) + shift;
	float edge = mix(0.672, 0.322, cloud_cover);
	float density = cloud_texture(p);
	float mask = smoothstep(edge, edge + 0.14, density);
	float body = smoothstep(edge + 0.025, edge + 0.34, density);
	float glow = clamp(dot(daylight_dir, EYEDIR) * 0.53 + 0.45, 0.0, 1.0);
	float low_haze = smoothstep(0.018, 0.16, height);
	float horizon_veil = (1.0 - smoothstep(0.017, 0.17, height)) * valley_mist;
	daytime = mix(daytime, vec3(0.66, 0.71, 0.71), horizon_veil * (0.71 - dusk * 0.20));
	earth = mix(earth, dark, horizon_veil * 0.56);
	vec3 cloud_rim = mix(vec3(0.81, 0.85, 0.85), vec3(0.97, 0.93, 0.84), glow);
	cloud_rim = mix(cloud_rim, vec3(0.84, 0.60, 0.48), dusk * (0.45 + glow * 0.40));
	vec3 cloud_core = mix(vec3(0.79, 0.81, 0.80), vec3(0.43, 0.48, 0.51), cloud_cover);
	daytime = mix(daytime, cloud_rim, silk * low_haze);
	daytime = mix(daytime, mix(cloud_rim, cloud_core, body), mask * low_haze * 0.96);
	earth = mix(earth, dark * 0.94 + cloud_core * 0.014, mask * low_haze * (0.20 + 0.57 * cloud_cover));
	if (storm_amount > 0.0) {
		vec2 front_uv = EYEDIR.xz * vec2(2.5, 3.65) / (0.53 + height) + shift * 1.8;
		float front = cloud_texture(front_uv);
		float fine = cloud_texture(front_uv * 1.84 + 11.3);
		float underside = smoothstep(0.21, 0.85, front * 0.81 + fine * 0.19);
		vec3 low_cloud = mix(vec3(0.22, 0.29, 0.35), vec3(0.58, 0.63, 0.65), underside);
		low_cloud = mix(vec3(0.45, 0.52, 0.57), low_cloud, smoothstep(0.01, 0.37, height));
		float overcast = smoothstep(0.10, 0.62, storm_amount) * mix(1.0, 0.83, underside);
		if (storm_amount > 0.52) overcast = mix(overcast, 1.0, smoothstep(0.52, 0.68, storm_amount));
		daytime = mix(daytime, low_cloud, overcast);
		earth = mix(earth, dark * (0.79 + 0.31 * underside), overcast * 0.97);
	}
	COLOR=mix(daytime,mix(dark,mix(earth,alien,other_world),smoothstep(0.0,0.065,height)),nightfall);
}
