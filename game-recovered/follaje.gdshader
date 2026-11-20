shader_type spatial;

uniform vec4 tint : source_color;
uniform float pattern = 0.0;
varying vec3 brush_position;

void vertex() {
	brush_position = VERTEX;
	float edge = sin(VERTEX.x * 19.0 + pattern) * sin(VERTEX.z * 16.0 - VERTEX.y * 14.0);
	VERTEX += NORMAL * edge * 0.051;
}

void fragment() {
	vec3 p = brush_position;
	float shade = sin(p.x * 23.0 - p.y * 13.0 + sin(p.z * 21.0 + pattern));
	float strokes = sin(p.x * 71.0 + sin(p.y * 29.0 + p.z * 42.0) * 2.1 + p.z * 27.0) * shade;
	ALBEDO = tint.rgb * (0.94 + 0.07 * shade + 0.038 * strokes);
	ROUGHNESS = 1.0;
}
