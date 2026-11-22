extends RefCounted

const FUR = """
shader_type spatial;
render_mode cull_disabled;
uniform bool scaled_hide = false;
varying vec3 local;
void vertex() { local = VERTEX; }
float speckle(vec3 cell) {
	return fract(sin(dot(cell, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
void fragment() {
	float grain_blend = 1.0 - smoothstep(0.25, 1.8, length(fwidth(local * 87.0)));
	float grain = 0.92 + 0.11 * sin(local.z * 81.0 + local.y * 44.0)
		* sin(local.x * 106.0 - local.y * 61.0);
	vec3 tone = COLOR.rgb * (0.98 + 0.14 * (grain - 0.92) + 0.12 * (speckle(floor(local * 87.0)) - 0.5) * grain_blend);
	if (scaled_hide) {
		vec3 rows = local * vec3(68.0, 62.0, 65.0);
		float shade = 0.5 + 0.5 * sin(local.z * 109.0 + local.x * 17.0 + sin(local.x * 40.0 + local.y * 22.0));
		float spots = speckle(floor(rows + vec3(floor(rows.z) * 0.49, 0.0, 0.0)));
		float plates = smoothstep(0.46, 0.78, mix(shade, spots, 0.42));
		float amount = (0.22 + 0.74 * plates) * (0.57 + 0.43 * grain_blend);
		tone = mix(tone, COLOR.rgb * vec3(2.33, 2.21, 2.02), amount);
	}
	ALBEDO = tone;
	ROUGHNESS = 0.94;
}
"""

var brush := Shader.new()

func _init():
	brush.code = FUR

func ring(z: float, y: float, wide: float, height: float, x := 0.0) -> Array:
	return [Vector3(x, y, z), wide, height]

func triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, paint: Array, outward: Vector3):
	var normal := (c - a).cross(b - a).normalized()
	var points := [a, b, c]
	if normal.dot(outward) < 0.0:
		normal = -normal
		points = [a, c, b]
		paint = [paint[0], paint[2], paint[1]]
	for i in 3:
		surface.set_color(paint[i])
		surface.set_normal(normal)
		surface.add_vertex(points[i])

func loft(surface: SurfaceTool, profile: Array, section: int, coloring: Callable, follows_axis := false):
	for i in range(profile.size() - 1):
		var start: Vector3 = profile[i][0]
		var finish: Vector3 = profile[i + 1][0]
		var start_basis := ring_axes(profile, i) if follows_axis else Basis.IDENTITY
		var end_basis := ring_axes(profile, i + 1) if follows_axis else Basis.IDENTITY
		for side in section:
			var turn_a := TAU * side / section
			var turn_b := TAU * (side + 1) / section
			var start_a: Vector3 = start + start_basis.x * (cos(turn_a) * profile[i][1]) + start_basis.y * (sin(turn_a) * profile[i][2])
			var start_b: Vector3 = start + start_basis.x * (cos(turn_b) * profile[i][1]) + start_basis.y * (sin(turn_b) * profile[i][2])
			var end_a: Vector3 = finish + end_basis.x * (cos(turn_a) * profile[i + 1][1]) + end_basis.y * (sin(turn_a) * profile[i + 1][2])
			var end_b: Vector3 = finish + end_basis.x * (cos(turn_b) * profile[i + 1][1]) + end_basis.y * (sin(turn_b) * profile[i + 1][2])
			var outward: Vector3 = (start_a + start_b) * 0.5 - start
			var colors := [coloring.call(start_a, side), coloring.call(start_b, side), coloring.call(end_a, side),
				coloring.call(end_b, side)]
			triangle(surface, start_a, start_b, end_a, [colors[0], colors[1], colors[2]], outward)
			triangle(surface, end_a, start_b, end_b, [colors[2], colors[1], colors[3]], outward)

func ring_axes(profile: Array, index: int) -> Basis:
	var previous: Vector3 = profile[maxi(0, index - 1)][0]
	var next: Vector3 = profile[mini(profile.size() - 1, index + 1)][0]
	var facing := (next - previous).normalized()
	var reference := Vector3.UP if absf(facing.x) > 0.9 else Vector3.RIGHT
	var width := (reference - facing * facing.dot(reference)).normalized()
	return Basis(width, facing.cross(width).normalized(), facing)

func polygon(surface: SurfaceTool, vertices: PackedVector3Array, color: Color, normal: Vector3):
	for i in range(1, vertices.size() - 1):
		triangle(surface, vertices[0], vertices[i], vertices[i + 1], [color, color, color], normal)

func tinted(tone: Color) -> Callable:
	return func(at: Vector3, side: int) -> Color:
		return tone.lightened(0.075 * (0.5 + 0.5 * sin(side * 7.7 + at.z * 38.0)))

func cavy_color(at: Vector3, side: int) -> Color:
	var back := Color("#594f40").lerp(Color("#88775e"), 0.5 + 0.5 * sin(at.z * 98.0 + side * 2.1))
	var flank := Color("#8c775d").lerp(back, smoothstep(0.042, 0.125, at.y))
	return flank.lerp(Color("#ada084"), 1.0 - smoothstep(0.027, 0.056, at.y))

func make_chingolo(parent: Node3D) -> Node3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var chest := Color("#b7ad95")
	var wing := Color("#655641")
	var collar := Color("#986349")
	var gray := Color("#a3a29a")
	var stripe := Color("#2e3030")
	loft(surface, [ring(-0.092, 0.066, 0.004, 0.005), ring(-0.055, 0.074, 0.023, 0.027),
		ring(-0.006, 0.065, 0.034, 0.040), ring(0.038, 0.061, 0.026, 0.028),
		ring(0.077, 0.056, 0.007, 0.013)], 12,
		func(point: Vector3, _side: int): return collar if point.z < -0.044 else (wing if point.y > 0.069 else chest))
	loft(surface, [ring(-0.116, 0.118, 0.001, 0.001), ring(-0.097, 0.118, 0.014, 0.016),
		ring(-0.070, 0.122, 0.024, 0.029), ring(-0.049, 0.119, 0.019, 0.022),
		ring(-0.036, 0.110, 0.005, 0.008)], 12,
		func(point: Vector3, _side: int): return stripe if point.y > 0.139 or (absf(point.x) > 0.013 and point.y > 0.113 and point.y < 0.125) else gray)
	loft(surface, [ring(-0.137, 0.110, 0.001, 0.001), ring(-0.110, 0.111, 0.011, 0.008)], 8, tinted(Color("#786d60")))
	for side in [-1.0, 1.0]:
		polygon(surface, PackedVector3Array([Vector3(side * 0.027, 0.093, -0.027), Vector3(side * 0.037, 0.072, 0.028),
			Vector3(side * 0.018, 0.047, 0.101), Vector3(side * 0.023, 0.055, 0.009)]), wing, Vector3(side, 0.2, 0))
		loft(surface, [ring(0.009, 0.006, 0.0022, 0.002, side * 0.013),
			ring(0.015, 0.039, 0.003, 0.005, side * 0.013)], 6, tinted(Color("#816d5f")), true)
	polygon(surface, PackedVector3Array([Vector3(-0.011, 0.065, 0.035), Vector3(0.011, 0.065, 0.035),
		Vector3(0.017, 0.049, 0.140), Vector3(-0.017, 0.049, 0.140)]), wing, Vector3.UP)
	var bird := finish(parent, surface, "Chingolo", false)
	for side in [-1.0, 1.0]:
		var extended := SurfaceTool.new()
		extended.begin(Mesh.PRIMITIVE_TRIANGLES)
		polygon(extended, PackedVector3Array([Vector3(0, 0.002, -0.036), Vector3(side * 0.043, 0.014, -0.027),
			Vector3(side * 0.108, -0.008, 0.018), Vector3(side * 0.103, -0.013, 0.053),
			Vector3(side * 0.048, -0.003, 0.039), Vector3(0, 0, 0.029)]), wing, Vector3.UP)
		var feathers := finish(bird, extended, "Ala", false)
		feathers.position = Vector3(side * 0.026, 0.081, -0.005)
		feathers.hide()
	return bird

func make_cavy(parent: Node3D) -> Node3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [
		ring(0.124, 0.065, 0.006, 0.010), ring(0.106, 0.071, 0.032, 0.034),
		ring(0.074, 0.075, 0.052, 0.051), ring(0.026, 0.071, 0.057, 0.056),
		ring(-0.030, 0.068, 0.052, 0.049), ring(-0.063, 0.072, 0.040, 0.037),
		ring(-0.091, 0.074, 0.038, 0.032), ring(-0.117, 0.064, 0.028, 0.026),
		ring(-0.138, 0.054, 0.013, 0.016), ring(-0.143, 0.056, 0.002, 0.004),
	], 12, cavy_color)
	loft(surface, [ring(-0.134, 0.057, 0.010, 0.008), ring(-0.142, 0.058, 0.012, 0.008),
		ring(-0.148, 0.056, 0.002, 0.003)], 8, tinted(Color("#3a2d28")))
	for side in [-1.0, 1.0]:
		var m := float(side)
		var eye := Vector3(m * 0.037, 0.079, -0.102)
		var brow := eye + Vector3(-m * 0.002, 0.010, 0.002)
		polygon(surface, [brow + Vector3(0, -0.001, -0.013), brow + Vector3(-m * 0.004, 0.005, -0.003),
			brow + Vector3(0, 0.003, 0.013), brow + Vector3(m * 0.004, -0.002, 0.007)], Color("#cab996"), Vector3(m, 0.4, 0))
		polygon(surface, [eye + Vector3(-m * 0.002, 0, -0.007), eye + Vector3(-m * 0.001, 0.006, 0.002),
			eye + Vector3(m * 0.003, 0.001, 0.008), eye + Vector3(m * 0.001, -0.005, 0.001)], Color("#241c1b"), Vector3(m, 0, 0))
		var ear := Vector3(m * 0.030, 0.096, -0.070)
		var rim := PackedVector3Array([ear+Vector3(0, 0, -0.005), ear+Vector3(m*0.008, 0.013, -0.007),
			ear+Vector3(m*0.012, 0.021, 0.002), ear+Vector3(m*0.008, 0.019, 0.009), ear+Vector3(0, 0.004, 0.011)])
		polygon(surface, rim, Color("#6b5b4c"), Vector3(m * 0.55, 0.23, -0.60))
		polygon(surface, [rim[0] + Vector3.FORWARD * 0.002, rim[2].lerp(ear, 0.29) + Vector3.FORWARD * 0.002,
			rim[3].lerp(ear, 0.33) + Vector3.FORWARD * 0.002], Color("#4e403a"), Vector3(m, 0.3, -0.60))
	var cavy := finish(parent, surface, "Cuis moro", false)
	for side in [-1.0, 1.0]:
		cavy_leg(cavy, side, -0.069)
		cavy_leg(cavy, side, 0.061)
	return cavy

func cavy_leg(cavy: Node3D, side: float, longitudinal: float):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [[Vector3.ZERO, 0.013, 0.017], [Vector3(side * 0.008, -0.021, 0.004), 0.008, 0.009],
		[Vector3(side * 0.009, -0.037, -0.006), 0.010, 0.007],
		[Vector3(side * 0.009, -0.039, -0.020), 0.006, 0.004]], 7, tinted(Color("#88765e")), true)
	var foot := finish(cavy, surface, "Pata", false)
	foot.position = Vector3(side * 0.033, 0.041, longitudinal)

func fox_color(at: Vector3, side: int) -> Color:
	var saddle := Color("#575650").lerp(Color("#827e71"), 0.5 + 0.5 * sin(side * 8.2 + at.z * 33.0))
	var flank := Color("#927c62").lerp(saddle, smoothstep(0.33, 0.51, at.y))
	if at.z < -0.42:
		flank = Color("#aa8462").lerp(Color("#746f63"), smoothstep(0.57, 0.66, at.y))
	var bib := 1.0 - smoothstep(0.415, 0.54, at.y) if at.z < -0.38 else 1.0 - smoothstep(0.29, 0.38, at.y)
	return flank.lerp(Color("#cabc9c"), bib * 0.92)

func make_fox(parent: Node3D) -> Node3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [
		ring(0.355,0.402,0.013,0.020), ring(0.325,0.418,0.077,0.111),
		ring(0.240,0.432,0.111,0.131), ring(0.133,0.432,0.089,0.103),
		ring(0.004,0.451,0.108,0.118), ring(-0.108,0.453,0.127,0.144),
		ring(-0.216,0.459,0.110,0.140), ring(-0.309,0.483,0.093,0.123),
		ring(-0.388,0.556,0.080,0.093), ring(-0.460,0.590,0.091,0.083),
		ring(-0.514,0.580,0.078,0.066), ring(-0.561,0.547,0.045,0.048),
		ring(-0.651,0.529,0.024,0.025), ring(-0.671,0.527,0.002,0.004),
	], 10, fox_color)
	loft(surface, [
		ring(0.276,0.450,0.031,0.037), ring(0.388,0.400,0.063,0.065,-0.018),
		ring(0.512,0.319,0.092,0.079,-0.056), ring(0.656,0.247,0.088,0.077,-0.109),
		ring(0.792,0.237,0.055,0.055,-0.151), ring(0.891,0.262,0.027,0.028,-0.194),
		ring(0.941,0.272,0.005,0.006,-0.205),
	], 9, func(at: Vector3, side: int) -> Color:
		return Color("#8c8170").lerp(Color("#35312f"), smoothstep(0.57, 0.85, at.z)).darkened(0.18 * (0.5 + 0.5 * sin(side * 2.1 + at.z * 28.0))))
	loft(surface, [ring(-0.645,0.529,0.021,0.019), ring(-0.662,0.530,0.026,0.019),
		ring(-0.673,0.532,0.020,0.014), ring(-0.681,0.530,0.004,0.004)], 8, tinted(Color("#342b27")))
	for side in [-1.0, 1.0]:
		var m := float(side)
		var ear_a := Vector3(m * 0.029, 0.630, -0.432)
		var ear_b := Vector3(m * 0.102, 0.604, -0.455)
		var ear_tip := Vector3(m * 0.101, 0.790, -0.412)
		var ear_back := Vector3(m * 0.067, 0.624, -0.385)
		polygon(surface, [ear_a, ear_b, ear_tip], Color("#927254"), Vector3.FORWARD)
		polygon(surface, [ear_b, ear_back, ear_tip], Color("#6f5344"), Vector3(m, 0.4, 0.3))
		polygon(surface, [ear_back, ear_a, ear_tip], Color("#7d6550"), Vector3.BACK)
		var inset := Vector3.FORWARD * 0.003
		polygon(surface, [ear_a.lerp(ear_b,0.28).lerp(ear_tip,0.14) + inset,
			ear_a.lerp(ear_b,0.76).lerp(ear_tip,0.13) + inset, ear_tip.lerp((ear_a+ear_b)*0.5,0.27) + inset],
			Color("#55433a"), Vector3.FORWARD)
		polygon(surface, [Vector3(m * 0.082, 0.601, -0.522), Vector3(m * 0.082, 0.591, -0.503),
			Vector3(m * 0.083, 0.609, -0.493), Vector3(m * 0.080, 0.611, -0.508)], Color("#302723"), Vector3(m, 0, 0))
	var fox := finish(parent, surface, "Zorro gris pampeano", false)
	for side in [-1.0, 1.0]:
		fox_leg(fox, side, false)
		fox_leg(fox, side, true)
	return fox

func fox_leg(fox: Node3D, m: float, rear: bool):
	var pivot := Vector3(m * 0.072, 0.411 if rear else 0.423, 0.243 if rear else -0.225)
	var knee := Vector3(m * 0.025, -0.14, -0.082 if rear else 0.023)
	var ankle := Vector3(m * 0.025, -0.366, 0.037)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [
		[Vector3.ZERO, 0.060, 0.081],
		[knee, 0.043 if rear else 0.034, 0.043],
		[Vector3(m * 0.023, -0.272, 0.062 if rear else 0.027), 0.018, 0.022],
		[ankle, 0.017, 0.018],
		[ankle + Vector3(0.0, -0.032, -0.032), 0.021, 0.013],
		[ankle + Vector3(0.0, -0.029, -0.057), 0.008, 0.013],
	], 8, func(at: Vector3, sector: int) -> Color:
		var shade := Color("#a68162").lerp(Color("#45362f"), 1.0 - smoothstep(0.024, 0.14, at.y + pivot.y))
		return shade.darkened(0.14 * (0.5 + 0.5 * sin(sector * 2.0))), true)
	finish(fox, surface, "Pata", false).position = pivot

func tegu_color(at: Vector3, side: int) -> Color:
	return Color("#373532").lerp(Color("#74664f"), 0.50 - minf(at.y, 0.32) + 0.14 * sin(side * 1.7))

func make_tegu(parent: Node3D) -> Node3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [
		ring(0.819,0.016,0.005,0.004,-0.182), ring(0.680,0.025,0.015,0.016,-0.124),
		ring(0.535,0.041,0.024,0.024,-0.061), ring(0.410,0.060,0.038,0.035,-0.022),
		ring(0.292,0.078,0.053,0.058), ring(0.185,0.089,0.088,0.072),
		ring(0.073,0.101,0.107,0.083), ring(-0.041,0.102,0.099,0.083),
		ring(-0.139,0.117,0.074,0.067), ring(-0.242,0.144,0.060,0.063),
		ring(-0.293,0.162,0.079,0.071), ring(-0.349,0.173,0.085,0.063),
		ring(-0.405,0.183,0.064,0.055), ring(-0.463,0.174,0.042,0.029),
		ring(-0.482,0.173,0.010,0.014),
	], 13, tegu_color)
	var tegu := finish(parent, surface, "Lagarto overo", true)
	for side in [-1.0, 1.0]:
		tegu_leg(tegu, side, false, -0.144)
		tegu_leg(tegu, side, true, 0.163)
	return tegu

func tegu_leg(tegu: Node3D, m: float, rear: bool, z: float):
	var joint := Vector3(m * 0.051, 0.093, z)
	var palm := Vector3(m * (0.122 if rear else 0.109), -0.070, -0.045)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	loft(surface, [[Vector3.ZERO, 0.055, 0.042], [Vector3(m * 0.077, -0.017, 0.015), 0.034, 0.028],
		[palm, 0.027, 0.017], [palm + Vector3(m * 0.018, -0.009, -0.014), 0.021, 0.010]],
		8, tegu_color, true)
	for index in 4:
		var tip := palm + Vector3(m * (0.046 + index * 0.006), -0.016, -0.050 + index * 0.017)
		var root := palm + Vector3(m * 0.017, -0.007, -0.022 + index * 0.011)
		var bend := root.lerp(tip, 0.48) + Vector3.UP * 0.008
		loft(surface, [[root, 0.009, 0.008], [bend, 0.006, 0.007], [tip, 0.002, 0.002]],
			6, tinted(Color("#46413a")), true)
	var leg := finish(tegu, surface, "Pata", true)
	leg.position = joint
	leg.set_meta("walking_leg", true)

func finish(parent: Node3D, surface: SurfaceTool, title: String, scales: bool) -> Node3D:
	var animal := MeshInstance3D.new()
	animal.name = title
	animal.mesh = surface.commit()
	var paint := ShaderMaterial.new()
	paint.shader = brush
	paint.set_shader_parameter("scaled_hide", scales)
	animal.material_override = paint
	parent.add_child(animal)
	if title == "Lagarto overo":
		for side in [-1.0, 1.0]:
			var eye := SphereMesh.new()
			eye.radius = 0.012
			eye.height = 0.020
			eye.rings = 4
			eye.radial_segments = 8
			var iris := MeshInstance3D.new()
			iris.mesh = eye
			iris.position = Vector3(side * 0.074, 0.210, -0.387)
			iris.scale.x = 0.58
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("#382b28")
			material.roughness = 0.4
			iris.material_override = material
			animal.add_child(iris)
	return animal
