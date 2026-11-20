extends RefCounted

const LIMIT_Z := 122.0
const GROUND := Color("#82795b")
const FOOTPATH := Color("#aa8c68")
const GRAVEL := Color("#867d72")
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
	return descent - 3.1 * bed + far_bank + ridge + relief

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

static func build_ground(valley):
	const COLUMNS := 57
	const ROWS := 120
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	surface.set_material(material)
	for row in ROWS:
		var z := -72.0 + row * 2.0
		for column in COLUMNS:
			var x := -56.0 + column * 2.0
			var grain := sin(x * 2.37 + sin(z)) * cos(z * 1.72)
			var track := 1.0 - smoothstep(0.9, 2.7, trail_distance(Vector2(x, z)) + grain * 0.26)
			var channel := 1.0 - smoothstep(2.2, 7.5, absf(z - channel_z(x)))
			var color := GROUND.lerp(FOOTPATH, track).lerp(GRAVEL, channel * 0.95)
			surface.set_color(color.darkened(maxf(0.0, grain * 0.10)))
			surface.add_vertex(point(x, z))
	for row in range(ROWS - 1):
		for column in range(COLUMNS - 1):
			var a := row * COLUMNS + column
			for index in [a, a + 1, a + COLUMNS, a + 1, a + COLUMNS + 1, a + COLUMNS]:
				surface.add_index(index)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
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
