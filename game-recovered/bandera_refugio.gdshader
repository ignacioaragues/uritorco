shader_type spatial;
render_mode cull_disabled;

uniform float breeze = 0.2;

vec3 cloth_point(vec2 uv, float time) {
	float u = uv.x;
	float v = uv.y;
	float gust = breeze * (0.76 + 0.24 * sin(time * 1.75));
	float motion = pow(u, 1.22);
	float fold = sin(u * 10.0 - time * 4.9 + v * 2.16);
	float curl = sin(u * 6.8 + time * 2.6 - v * 3.2);
	float x = 0.033 + u * (0.52 + gust * 0.59) * (1.0 - v * 0.36);
	float y = 3.02 - v * 0.61 - pow(u, 1.38) * (0.42 - gust * 0.39);
	x += (fold * 0.030 + curl * 0.032) * motion;
	y += (fold * 0.064 + curl * 0.055) * motion * mix(0.62, 1.17, gust);
	float z = motion * (fold * (0.062 + gust * 0.13) + curl * (0.091 + gust * 0.04));
	return vec3(x, y, z);
}

void vertex() {
	VERTEX = cloth_point(UV, TIME);
	vec3 across = cloth_point(UV + vec2(0.002, 0.0), TIME) - VERTEX;
	vec3 down = cloth_point(UV + vec2(0.0, 0.002), TIME) - VERTEX;
	NORMAL = normalize(cross(across, down));
}

void fragment() {
	float threads = sin(UV.x * 551.0) * sin(UV.y * 370.0);
	float resolved = 1.0 - smoothstep(0.008, 0.031, max(fwidth(UV.x), fwidth(UV.y)));
	ALBEDO = COLOR.rgb * (0.99 + threads * resolved * 0.029);
	ROUGHNESS = 0.96;
}
