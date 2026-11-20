extends RefCounted

const LIMIT_Z := 122.0
const PATH := [
	Vector2(3.8, -14.0), Vector2(3.8, -18.4), Vector2(-5, -19), Vector2(-15, -17),
	Vector2(-21, -11), Vector2(-23, 4), Vector2(-20, 18),
	Vector2(-24, 34), Vector2(-31, 46), Vector2(-27, 57),
	Vector2(-19, 68), Vector2(-20, 77)
]

static func channel_z(x: float) -> float:
	return 82.0 + 4.6 * sin(x * 0.082) + 1.4 * sin(x * 0.17)

static func height(x: float, z: float) -> float:
	var descent := -11.0 * smoothstep(22.0, 69.0, z)
	var bed := 1.0 - smoothstep(2.0, 9.2, absf(z - channel_z(x)))
	var far_bank := (8.0 + 3.0 * cos(x * 0.11)) * smoothstep(90.0, 130.0, z)
	var ridge := 9.0 * smoothstep(31.0, 55.0, absf(x)) * smoothstep(28.0, 52.0, z) * (1.0 - 0.66 * bed)
	var relief := sin(x * 0.13 + z * 0.11) * smoothstep(23.0, 40.0, z) * 0.48
	var mollar := 2.9 * (1.0 - smoothstep(0.12, 1.0, Vector2((x - 43) / 18.0, (z - 12) / 22.0).length()))
	var lajas := 2.4 * (1.0 - smoothstep(0.08, 1.0, Vector2((x + 41) / 16.0, (z + 15) / 19.0).length()))
	return descent - 3.1 * bed + far_bank + ridge + relief + mollar + lajas

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
	var outskirts := maxf(smoothstep(56.0, 150.0, absf(x)), smoothstep(166.0, 280.0, z))
	var hills := (5.4 + 4.0 * sin(x * 0.018 + z * 0.019) + 3.7 * sin(z * 0.031 - x * 0.021))
	hills *= smoothstep(-72.0, 8.0, z)
	return lerpf(height(x, z), hills, outskirts)

static func build_ground(valley, material: ShaderMaterial):
	var columns := PackedFloat32Array()
	for x in range(-360, -56, 8): columns.append(x)
	for x in range(-56, 57, 2): columns.append(x)
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

static func dress(valley):
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
		var foot := point(x, z)
		valley.stone(foot + Vector3.UP * size_m * 0.25, Vector3(1.7, 0.9, 1.5) * size_m, "74725c")
		if i % 3 == 0:
			valley.box(foot + Vector3.UP * size_m * 0.58, Vector3(0.11, 1.15, 0.13) * size_m, "635648")
			valley.stone(foot + Vector3.UP * size_m * 1.24, Vector3(1.31, 0.91, 1.25) * size_m, "657253")
	for side in [-1, 1]:
		for z in range(32, 145, 13):
			var x: float = side * (50.0 + 2.0 * sin(z))
			valley.stone(point(x, z), Vector3(10.0, 6.0 + 2.0 * cos(z), 11.0), "777562")
