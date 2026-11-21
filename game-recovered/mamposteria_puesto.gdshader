shader_type spatial;

uniform vec3 inner_face;
uniform vec4 lime : source_color = vec4(0.63, 0.55, 0.43, 1.0);
uniform vec4 dark_stone : source_color = vec4(0.35, 0.33, 0.30, 1.0);
uniform vec4 light_stone : source_color = vec4(0.59, 0.54, 0.47, 1.0);
uniform vec4 mortar : source_color = vec4(0.67, 0.61, 0.51, 1.0);

varying vec3 wall_point;
varying vec3 wall_face;

vec2 hash_cell(vec2 cell) {
	vec3 n = fract(vec3(cell.x, cell.y, cell.x) * vec3(0.1031, 0.1030, 0.0973));
	n += dot(n, n.yzx + 33.33);
	return fract((n.xx + n.yz) * n.zy);
}

float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = smoothstep(0.0, 1.0, fract(p));
	float a = mix(hash_cell(cell).x, hash_cell(cell + vec2(1, 0)).x, blend.x);
	float b = mix(hash_cell(cell + vec2(0, 1)).x, hash_cell(cell + vec2(1, 1)).x, blend.x);
	return mix(a, b, blend.y);
}

vec2 stone_center(vec2 cell) {
	float course = hash_cell(vec2(12.1, cell.y)).y;
	return cell + vec2(0.27 + course * 0.46, 0.5) + (hash_cell(cell) - 0.5) * vec2(0.52, 0.91);
}

void vertex() {
	wall_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wall_face = NORMAL;
}

void fragment() {
	vec2 face_point = vec2(abs(wall_face.x) > 0.5 ? wall_point.z : wall_point.x, wall_point.y);
	if (abs(wall_face.y) > 0.5) {
		face_point = wall_point.xz;
	}
	float stains = 0.83 + grain(face_point * 2.7) * 0.17 + grain(face_point * 15.0) * 0.08;
	ROUGHNESS = 0.96;
	SPECULAR = 0.20;
	if (dot(wall_face, inner_face) > 0.9) {
		ALBEDO = lime.rgb * stains;
	} else {
		float mip = max(length(dFdx(face_point)), length(dFdy(face_point)));
		vec2 warp = vec2(grain(face_point * 8.7 + vec2(7.1, 0.0)), grain(face_point * 13.0));
		vec2 point = face_point * vec2(3.20, 4.36) + (warp - 0.5) * 0.30;
		vec2 origin = floor(point);
		vec2 nearest = vec2(-100.0);
		vec2 stone = vec2(0.0);
		float distance_sq = 8.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 cell = origin + vec2(float(x), float(y));
				vec2 center = stone_center(cell);
				vec2 offset = center - point;
				float d = dot(offset, offset);
				if (d < distance_sq) {
					distance_sq = d;
					nearest = center;
					stone = cell;
				}
			}
		}
		float edge = 1.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 center = stone_center(origin + vec2(float(x), float(y)));
				vec2 between = center - nearest;
				if (dot(between, between) > 0.001) {
					edge = min(edge, dot((center + nearest) * 0.5 - point, normalize(between)));
				}
			}
		}
		vec2 variation = hash_cell(stone + vec2(40.0, 9.0));
		float width = mix(0.021, 0.047, grain(face_point * 21.0));
		float stone_mask = smoothstep(width - mip, width + 0.017 + mip, edge);
		float bevel = smoothstep(width, width + 0.13, edge);
		float speckle = grain(face_point * 86.0);
		float resolution = 1.0 - smoothstep(0.007, 0.028, mip);
		float facets = grain(face_point * 12.0 + stone * 0.27);
		float quartz = smoothstep(0.76, 0.9, speckle) * resolution;
		vec3 rock = mix(dark_stone.rgb, light_stone.rgb, variation.x);
		rock *= mix(vec3(0.93, 1.01, 1.03), vec3(1.04, 0.99, 0.90), variation.y);
		rock *= stains * (0.80 + 0.14 * bevel + 0.18 * facets + 0.13 * quartz);
		vec3 joint = mortar.rgb * (0.73 + stains * 0.23 + (speckle - 0.5) * 0.09 * resolution);
		float splash = smoothstep(0.02, 0.52, wall_point.y + 0.28 * grain(face_point * 4.3));
		ALBEDO = mix(joint, rock, stone_mask) * mix(vec3(0.76, 0.77, 0.68), vec3(1.0), splash);

		float relief = (0.009 * bevel + 0.006 * facets * bevel + (speckle - 0.5) * 0.0015 * resolution)
			* (1.0 - smoothstep(0.012, 0.060, mip));
		vec3 dx = dFdx(VERTEX);
		vec3 dy = dFdy(VERTEX);
		vec3 across = cross(dy, NORMAL);
		vec3 up = cross(NORMAL, dx);
		float area = dot(dx, across);
		NORMAL = normalize(max(0.0000001, abs(area)) * NORMAL
			- sign(area) * (across * dFdx(relief) + up * dFdy(relief)));
	}
}
