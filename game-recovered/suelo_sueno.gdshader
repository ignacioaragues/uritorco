shader_type spatial;

uniform vec4 ground_tint : source_color;
uniform int terrain_style = 1;
uniform bool bedrock = false;
uniform vec3 planet_origin;
varying vec3 terrain_position;

void vertex() {
	terrain_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grit(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 n = vec4(dot(cell,vec2(41.17,289.2)),dot(cell+vec2(1,0),vec2(41.17,289.2)),
		dot(cell+vec2(0,1),vec2(41.17,289.2)),dot(cell+vec2(1,1),vec2(41.17,289.2)));
	n = fract(sin(n) * 4172.53);
	return mix(mix(n.x,n.y,f.x),mix(n.z,n.w,f.x),f.y);
}

vec2 chip_site(vec2 at) {
	vec2 seed = vec2(dot(at, vec2(78.9, 117.1)), dot(at, vec2(18.2, 146.7)));
	return vec2(0.16) + fract(sin(seed) * 31867.47) * 0.68;
}

float cracked_plates(vec2 p) {
	vec2 tile = floor(p);
	vec2 local = fract(p);
	float first = 10.0;
	float next = 10.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = vec2(float(x), float(y));
			vec2 offset = cell + chip_site(tile + cell) - local;
			float d = dot(offset, offset);
			next = min(next, max(d, first));
			first = min(first, d);
		}
	}
	return 1.0 - smoothstep(0.025, 0.11, next - first);
}

void fragment() {
	vec3 p = terrain_position - planet_origin;
	vec2 xz = p.xz;
	float broad = grit(xz * 0.131 + vec2(p.y * 0.28)) * 0.67 + grit(xz * 0.61) * 0.33;
	vec2 grain = xz * 9.7 + vec2(p.y * 5.7, p.y * 3.2);
	float resolved = 1.0 - smoothstep(0.23, 1.35, max(length(dFdx(grain)), length(dFdy(grain))));
	float fine = mix(0.5, grit(grain), resolved);
	float marks = 0.0;
	float roughness = 0.88;
	vec3 pigment = ground_tint.rgb * (0.71 + broad * 0.49 + fine * 0.13);
	vec3 vein;
	if (terrain_style == 1) {
		vec2 plates = vec2(xz.x + p.y * 0.52, xz.y + p.y * 0.24) * vec2(0.64, 0.49);
		plates += vec2(broad, grit(xz * 0.37 + vec2(3.2))) * 0.33;
		float fracture = cracked_plates(plates);
		float sheet = smoothstep(0.22, 0.79, broad - fracture * 0.13);
		pigment = mix(pigment, vec3(0.20, 0.37, 0.47), sheet * (bedrock ? 0.46 : 0.59));
		marks = fracture * (0.19 + 0.29 * smoothstep(0.23, 0.77, broad));
		vein = vec3(0.51, 0.64, 0.71);
		roughness = 0.83 - sheet * 0.21;
	} else if (terrain_style == 2) {
		float step_band = p.y * 2.4 + xz.x * 0.11 - xz.y * 0.047 + broad * 1.75;
		float layers = 1.0 - smoothstep(0.014, 0.16, abs(fract(step_band) - 0.55));
		float slate = smoothstep(0.13, 0.72, broad) * (0.57 + 0.19 * grit(xz * 0.33));
		float bowl = 1.0 - smoothstep(8.0, 22.0, length(xz - vec2(42.0, -118.0)));
		pigment = mix(pigment, vec3(0.28, 0.126, 0.077), slate * 0.53);
		pigment = mix(pigment, vec3(0.061, 0.051, 0.061), bowl * 0.78);
		marks = layers * (0.33 + slate * 0.27) * (1.0 - 0.55 * bowl);
		vein = vec3(0.63, 0.36, 0.21);
	} else {
		float fold = xz.x * 0.241 - xz.y * 0.19 - p.y * 0.91 + broad * 1.56;
		float ribbon = 1.0 - smoothstep(0.021, 0.17, abs(fract(fold) - 0.50));
		float exposed = smoothstep(0.26, 0.74, grit(xz * 0.48 + p.y * 0.32));
		float glass = smoothstep(0.32, 0.78, broad - ribbon * 0.22);
		pigment = mix(pigment, vec3(0.082, 0.061, 0.125), glass * (bedrock ? 0.71 : 0.52));
		marks = ribbon * exposed * (0.29 + fine * 0.24);
		vein = vec3(0.48, 0.34, 0.55);
		roughness = 0.87 - 0.32 * glass;
	}
	ALBEDO = mix(pigment, vein * (0.73 + fine * 0.25), marks * (bedrock ? 0.92 : 0.74));
	ROUGHNESS = roughness;
}
