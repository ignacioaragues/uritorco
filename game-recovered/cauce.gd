extends RefCounted

const LIMIT_Z := 122.0
const CROSSING_X := -139.0
const TURN_COUNT := 48
const RETURN_COUNT := 12
const SOUTH_KNOTS := [
	Vector2(-39, -17), Vector2(-44, 0), Vector2(-46, 17), Vector2(-52, 30),
	Vector2(-63, 44), Vector2(-81, 52), Vector2(-98, 63), Vector2(-111, 73),
	Vector2(-126, 77), Vector2(-140, 88)
]
const RETURN_KNOTS := [
	Vector2(-63, 44), Vector2(-48, 49), Vector2(-36, 49), Vector2(-31, 47.7), Vector2(-31, 46)
]
const PATH := [
	Vector2(3.8, -14.0), Vector2(3.8, -18.4), Vector2(-5, -19), Vector2(-15, -17),
	Vector2(-21, -11), Vector2(-23, 4), Vector2(-20, 18),
	Vector2(-24, 34), Vector2(-31, 46), Vector2(-27, 57),
	Vector2(-19, 68), Vector2(-20, 77)
]

static func channel_z(x: float) -> float:
	return 82.0 + 4.6 * sin(x * 0.082) + 1.4 * sin(x * 0.17) + creek_extension(x) * 24.0

static func creek_extension(x: float) -> float:
	return smoothstep(54.0, 140.0, -x)

static func height(x: float, z: float) -> float:
	var descent := -11.0 * smoothstep(22.0, 69.0, z)
	var downstream := creek_extension(x)
	var bank_width := lerpf(9.2, 18.6, downstream)
	var bed := 1.0 - smoothstep(2.0, bank_width, absf(z - channel_z(x)))
	var far_bank := (8.0 + 3.0 * cos(x * 0.11)) * smoothstep(90.0, 130.0, z)
	var ridge := 9.0 * smoothstep(31.0, 55.0, absf(x)) * smoothstep(28.0, 52.0, z) * (1.0 - 0.66 * bed)
	var relief := sin(x * 0.13 + z * 0.11) * smoothstep(23.0, 40.0, z) * 0.48
	var mollar := 2.9 * (1.0 - smoothstep(0.12, 1.0, Vector2((x - 43) / 18.0, (z - 12) / 22.0).length()))
	var lajas := 2.4 * (1.0 - smoothstep(0.08, 1.0, Vector2((x + 41) / 16.0, (z + 15) / 19.0).length()))
	var side_ridges := (6.5 * exp(-Vector2((x + 91.0) / 38.0, (z - 23.0) / 24.0).length_squared())
		+ 9.0 * exp(-Vector2((x + 159.0) / 29.0, (z - 75.0) / 26.0).length_squared())) * smoothstep(38.0, 61.0, -x)
	return descent - (3.1 + downstream * 2.0) * bed + far_bank + ridge * (1.0 - downstream * 0.66) + relief + mollar + lajas + side_ridges

static func point(x: float, z: float) -> Vector3:
	return Vector3(x, height(x, z), z)

static func marker() -> Vector3:
	return point(-18.8, channel_z(-18.8))

static func post() -> Vector3:
	return point(-32.6, 46.0)

static func trail_point(progress: float) -> Vector3:
	var step := clampf(progress, 0.0, 1.0) * (PATH.size() - 1)
	var index := mini(int(step), PATH.size() - 2)
	var position: Vector2 = PATH[index].lerp(PATH[index + 1], step - index)
	return point(position.x, position.y)

static func trail_distance(position: Vector2) -> float:
	if position.y < -21.0 or position.y > 83.0: return INF
	var nearest := INF
	for index in range(PATH.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(position, PATH[index], PATH[index + 1])
		nearest = minf(nearest, position.distance_squared_to(closest))
	return sqrt(nearest)

static func outer_height(x: float, z: float) -> float:
	var west_extension := 112.0 * smoothstep(10.0, 70.0, z)
	var width := absf(x) if x > 0 else maxf(0.0, -x - west_extension)
	var outskirts := maxf(smoothstep(56.0, 150.0, width), smoothstep(166.0, 280.0, z))
	var hills := (5.4 + 4.0 * sin(x * 0.018 + z * 0.019) + 3.7 * sin(z * 0.031 - x * 0.021))
	hills *= smoothstep(-72.0, 8.0, z)
	return lerpf(height(x, z), hills, outskirts)

static func west_limit(z: float) -> float:
	return 46.0 + 119.0 * smoothstep(-2.0, 57.0, z)

static func curve(knots: Array, progress: float) -> Vector2:
	var step := clampf(progress, 0.0, 1.0) * (knots.size() - 1)
	var i := mini(int(step), knots.size() - 2)
	var start: Vector2 = knots[i]
	return start.cubic_interpolate(knots[i + 1], knots[maxi(i - 1, 0)], knots[mini(i + 2, knots.size() - 1)], step - i)

static func south_knots() -> Array:
	var knots := SOUTH_KNOTS.duplicate()
	knots.append(Vector2(CROSSING_X, channel_z(CROSSING_X) - 7.70))
	return knots

static func crossing_point(progress: float) -> Vector3:
	var at := curve(south_knots(), progress)
	return Vector3(at.x, outer_height(at.x, at.y), at.y)

static func return_point(progress: float) -> Vector3:
	var at := curve(RETURN_KNOTS, progress)
	return Vector3(at.x, outer_height(at.x, at.y), at.y)

static func crossing_trace() -> PackedVector2Array:
	var points := PackedVector2Array()
	var knots := south_knots()
	for i in TURN_COUNT + 1: points.append(curve(knots, float(i) / TURN_COUNT))
	for i in RETURN_COUNT + 1: points.append(curve(RETURN_KNOTS, float(i) / RETURN_COUNT))
	return points

static func build_ground(valley, material: ShaderMaterial):
	var columns := PackedFloat32Array()
	for x in range(-360, -184, 8): columns.append(x)
	for x in range(-184, 57, 2): columns.append(x)
	for x in range(64, 361, 8): columns.append(x)
	var rows := PackedFloat32Array()
	for z in range(-72, 167, 2): rows.append(z)
	for z in range(174, 511, 8): rows.append(z)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in rows:
		for x in columns:
			surface.add_vertex(Vector3(x, outer_height(x, z), z))
	var width := columns.size()
	for row in range(rows.size() - 1):
		for column in range(width - 1):
			var a := row * width + column
			for index in [a, a + 1, a + width, a + 1, a + width + 1, a + width]:
				surface.add_index(index)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	ground.material_override = material
	valley.add_child(ground)
	ground.create_trimesh_collision()

static func dress(valley, field_trail_clearance: Callable):
	var route = valley.route
	route.signpost(point(-23.3, 18), "Sendero del cauce", "Cauce · bajada")
	var date_post := post()
	valley.box(date_post + Vector3.UP * 0.88, Vector3(0.24, 1.8, 0.23), "675747", true, "Poste")
	valley.box(date_post + Vector3(0.14, 1.31, -0.02), Vector3(0.047, 0.23, 0.23), "998567", true, "Poste")
	var stake := marker()
	valley.box(stake + Vector3.UP * 0.62, Vector3(0.19, 1.24, 0.13), "86705b", true, "Regla del cauce")
	for i in range(6):
		valley.box(stake + Vector3(0, 0.17 + i * 0.18, -0.07), Vector3(0.16, 0.04, 0.012), "e4d3a7")
	var rng := RandomNumberGenerator.new()
	rng.seed = 954
	var south_path := crossing_trace()
	for i in range(155):
		var x := rng.randf_range(-52.0, 52.0)
		var z := channel_z(x) + rng.randf_range(-3.9, 3.9)
		var width := rng.randf_range(0.3, 0.9)
		valley.stone(point(x, z), Vector3(width, 0.18, width * 0.72), ["837b71", "998c7d", "6a645c"][i % 3])
	for i in range(95):
		var x := rng.randf_range(-52.0, 52.0)
		var z := rng.randf_range(22.0, 125.0)
		if trail_distance(Vector2(x, z)) < 4.0 or absf(z - channel_z(x)) < 5.5: continue
		var size_m := rng.randf_range(0.7, 2.8)
		var obstruction_radius := 1.73 + size_m * 0.92
		var at := Vector2(x, z)
		if near_south_path(at, south_path, obstruction_radius) or field_trail_clearance.call(at) < obstruction_radius:
			# Keep the valley's random sequence when clearing the new solid boulders.
			valley.rng.randf()
			if i % 3 == 0: valley.rng.randf()
			continue
		var foot := point(x, z)
		valley.stone(foot + Vector3.UP * size_m * 0.25, Vector3(1.7, 0.9, 1.5) * size_m, "74725c", true)
		if i % 3 == 0:
			valley.box(foot + Vector3.UP * size_m * 0.58, Vector3(0.11, 1.15, 0.13) * size_m, "635648", true)
			valley.stone(foot + Vector3.UP * size_m * 1.24, Vector3(1.31, 0.91, 1.25) * size_m, "657253")
	for side in [-1, 1]:
		for z in range(32, 145, 13):
			var x: float = side * (50.0 + 2.0 * sin(z))
			if side < 0 and z < 98:
				x = -73.0 + 2.0 * sin(z)
			if near_south_path(Vector2(x, z), south_path, 6.9) or field_trail_clearance.call(Vector2(x, z)) < 6.9:
				x += side * 10.0
			var foot := Vector3(x, outer_height(x, z), z)
			valley.stone(foot, Vector3(10.0, 6.0 + 2.0 * cos(z), 11.0), "777562", true)

static func near_south_path(at: Vector2, path: PackedVector2Array, margin: float) -> bool:
	for index in range(path.size() - 1):
		if index == TURN_COUNT: continue
		var nearest := Geometry2D.get_closest_point_to_segment(at, path[index], path[index + 1])
		if at.distance_squared_to(nearest) < margin * margin: return true
	return false
