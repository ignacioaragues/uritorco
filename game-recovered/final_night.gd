extends RefCounted

const CAVE: = Vector3(0, 80, 1900)
const DOOR := Vector3(18, 0, -52)
const PLANET := Vector3(0, 88, 2450)
const GROUND_COLORS = [Color("544663"), Color("354b4c"), Color("615062")]
const ROCK_COLORS = ["746182", "698283", "7a6479"]
const ENTRY: = Vector3(0, 0.08, -5)
const LIP := Vector3(0, 0.08, -9.1)
const CHECKPOINT: = Vector3(0, 0.78, -23)
const RETURN_START := Vector3(0, 0, -48)
const FORK_Z := -60.0
const CLEARING := Vector2(14.0, -79.0)
const RETURN := Vector2(-8.5, -88.0)

static func build_cave(v):
	v.box(CAVE + Vector3(0, -0.45, -5), Vector3(8, 0.9, 12), "474239", true)
	v.box(CAVE + Vector3(0, -3.25, -18.8), Vector3(9.1, 1.3, 38.5), "292725", true)
	for ledge in [[-0.65, 0.13, -13.1], [0.65, 0.38, -16.6], [-0.45, 0.62, -20.1]]:
		v.box(CAVE + Vector3(ledge[0], ledge[1] - 0.45, ledge[2]), Vector3(2.5, 0.9, 2.35), "5c5349", true)
	v.box(CAVE + Vector3(0, 0.25, -29), Vector3(8, 0.9, 15.5), "47443d", true)
	v.box(CAVE + Vector3(0, 0.25, -43), Vector3(10, 0.9, 15), "484b37", true)
	for side in [-1, 1]:
		v.box(CAVE + Vector3(side * 4.2, 1.2, -18), Vector3(0.65, 8, 37), "383632", true)
		for i in range(13):
			v.stone(CAVE + Vector3(side * (3.3 + 0.32 * sin(i)), 1.8, -3 - i * 2.55), Vector3(2.4, 6.5, 4.0), "544d44")
		for i in range(6):
			var base: = CAVE + Vector3(side * (4 + sin(i) * 0.8), 0.7, -38 - i * 2.15)
			v.box(base + Vector3.UP * 1.8, Vector3(0.22, 3.6, 0.22), "43372e")
			v.stone(base + Vector3.UP * 3.45, Vector3(3.4, 3.7, 4.9), "393f32")
	v.box(CAVE + Vector3(0, 4.05, -20), Vector3(9, 0.8, 32), "393630", true)
	v.box(CAVE + Vector3(-2.55, 1.15, -28), Vector3(1.1, 0.9, 3), "63503f", true)
	v.box(CAVE + Vector3(-2.48, 1.79, -28), Vector3(0.75, 0.38, 0.76), "414948", true, "Receptor")
	for i in range(3):
		v.box(CAVE + Vector3(-2.075, 1.79, -28.28 + i * 0.21), Vector3(0.04, 0.075, 0.1), "9c8567")
	v.box(CAVE + Vector3(-2.48, 1.63, -26.85), Vector3(0.48, 0.055, 0.64), "a09273", true, "Cuadernos de observación")
	var tripod: = CAVE + Vector3(2.4, 0.7, -30.3)
	for leg in [Vector3(-0.25, 0, 0.17), Vector3(0.25, 0, 0.17), Vector3(0, 0, -0.28)]:
		var foot: Vector3 = tripod + leg
		var strut = v.box(foot.lerp(tripod + Vector3.UP * 0.95, 0.5), Vector3(0.04, 0.04, 0.99), "665e51")
		strut.look_at(tripod + Vector3.UP * 0.95)
	v.box(tripod + Vector3.UP * 0.99, Vector3(0.28, 0.15, 0.29), "50545a")
	var lamp = v.box(CAVE + Vector3(-2.48, 1.88, -28.35), Vector3(0.085, 0.042, 0.035), "b65734")
	lamp.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	v.box(CAVE + Vector3(1.05, 1.43, -36.1), Vector3(0.15, 1.44, 0.15), "a19272", true, "Salida de la cueva")
	build_return(v)

static func trail_x(z: float, clearing: bool) -> float:
	if clearing:
		return CLEARING.x * smoothstep(FORK_Z, CLEARING.y, z)
	return RETURN.x * smoothstep(FORK_Z, RETURN.y, z) + 1.8 * sin(PI * smoothstep(FORK_Z, RETURN.y, z))

static func return_height(x: float, z: float) -> float:
	var relief := 0.5 * sin(z * 0.19 + x * 0.15) + 0.46 * cos(x * 0.27 - z * 0.11)
	var bank := 3.2 * smoothstep(13.0, 33.0, absf(x))
	return 0.7 + smoothstep(-50.48, -57.0, z) * (relief + bank - 0.065 * (-z - 57.0))

static func build_return(v):
	const COLUMNS := 43
	const ROWS := 34
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in ROWS:
		var z := -50.48 - row * 2.0
		for column in COLUMNS:
			var x := -42.0 + column * 2.0
			var distance := absf(x - trail_x(z, false))
			if z < FORK_Z:
				var clearing_distance := absf(x - trail_x(z, true))
				distance = minf(distance, clearing_distance + 4.0 * smoothstep(-81.0, -86.0, z))
			var trail := 1.0 - smoothstep(1.45, 3.6, distance)
			var grass := Color("#3f4a38").lightened(0.09 * sin(x * 0.61 + z * 0.48))
			surface.set_color(grass.lerp(Color("#827757"), trail))
			surface.add_vertex(Vector3(x, return_height(x, z), z))
	for row in ROWS - 1:
		for column in COLUMNS - 1:
			var a := row * COLUMNS + column
			for index in [a, a + COLUMNS, a + 1, a + 1, a + COLUMNS, a + COLUMNS + 1]:
				surface.add_index(index)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	v.add_child(ground)
	ground.position = CAVE
	ground.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = 441
	for i in 120:
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-116.0, -51.0)
		if absf(x - trail_x(z, false)) < 3.7 or absf(x - trail_x(z, true)) < 3.8: continue
		if Vector2(x, z).distance_to(CLEARING) < 7.4: continue
		var foot := CAVE + Vector3(x, return_height(x, z), z)
		if i % 3 == 0:
			v.box(foot + Vector3.UP * 1.3, Vector3(0.23, 2.75, 0.23), "4d4335")
			v.stone(foot + Vector3.UP * 2.95, Vector3(3.2, 2.4, 3.8), "424b39")
		else:
			v.stone(foot + Vector3.DOWN * 0.05, Vector3(2.4, rng.randf_range(0.55, 1.7), 1.8), "585849", true)
	var marker := CAVE + Vector3(RETURN.x + 1.0, return_height(RETURN.x + 1.0, RETURN.y), RETURN.y)
	for level in 4:
		v.stone(marker + Vector3.UP * (0.16 + level * 0.2), Vector3(0.9 - level * 0.15, 0.28, 0.66 - level * 0.11), "98907c", true)

static func build_door(v):
	for side in [-1, 1]:
		v.plaster(v.box(DOOR + Vector3(side * 1.97, 1.32, -4.8), Vector3(2.65, 2.64, 0.24), "b09d80", true))
		v.plaster(v.box(DOOR + Vector3(side * 3.22, 1.32, -7.25), Vector3(0.24, 2.64, 5.05), "a9967d", true))
		var roof: MeshInstance3D = v.box(DOOR + Vector3(side * 1.73, 2.79, -7.25), Vector3(3.71, 0.17, 5.6), "6d5849")
		roof.rotation.z = -side * 0.13
	v.plaster(v.box(DOOR + Vector3(0, 1.32, -9.78), Vector3(6.52, 2.64, 0.24), "a9967d", true))
	v.plaster(v.box(DOOR + Vector3(0, 2.46, -4.8), Vector3(1.29, 0.37, 0.24), "b09d80", true))
	v.timber(v.box(DOOR + Vector3(0, 1.12, -4.74), Vector3(1.29, 2.24, 0.14), "705342", true, "Puerta de Mara"))
	v.box(DOOR + Vector3(0.42, 1.12, -4.65), Vector3(0.12, 0.065, 0.06), "a08d68")
	v.box(DOOR + Vector3(0, 0.073, -4.36), Vector3(1.68, 0.146, 0.91), "8d806d", true)
	v.box(DOOR + Vector3(-2.0, 1.48, -4.655), Vector3(1.24, 0.91, 0.07), "695744")
	v.box(DOOR + Vector3(-2.0, 1.48, -4.608), Vector3(1.09, 0.77, 0.025), "596566")
	v.box(DOOR + Vector3(-2.0, 1.48, -4.587), Vector3(0.045, 0.80, 0.018), "8b795f")
	v.box(DOOR + Vector3(0.88, 1.06, -4.63), Vector3(0.30, 0.25, 0.18), "75634f")

static func dream_x(variant: int, distance: float) -> float:
	match variant:
		1: return 5.5 * sin(distance * 0.09)
		2: return -8.0 * sin(distance * 0.055)
		_: return 5.0 * sin(distance * 0.10)

static func planet_height(variant: int, x: float, distance: float) -> float:
	var edge := absf(x - dream_x(variant, distance))
	var banks := smoothstep(6.0, 36.0, edge)
	var relief := (6.0 + 4.0 * sin(distance * 0.12 + x * 0.09 + variant)) * banks
	match variant:
		1: return relief + 0.7 * sin(distance * 0.13)
		2: return relief * 0.55 + 1.8 * sin(distance * 0.069)
		_: return relief * 1.30 + 0.9 * sin(distance * 0.16)

static func dream_point(variant: int, distance: float) -> Vector3:
	var x := dream_x(variant, distance)
	return PLANET + Vector3(x, planet_height(variant, x, distance), -distance)

static func final_arch() -> Vector3:
	return dream_point(3, 46.0)

static func build_planet(valley, variant: int) -> Node3D:
	var root := Node3D.new()
	var first_prop: int = valley.get_child_count()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const COLUMNS := 73
	const ROWS := 53
	for row in ROWS:
		var distance := 4.0 * row - 64.0
		for column in COLUMNS:
			var x := 4.0 * column - 144.0
			var tone := 0.11 * sin(row * 0.57 + column * 0.84) + 0.06 * cos(column * 0.29 - row * 0.92)
			surface.set_color(GROUND_COLORS[variant - 1].lightened(tone))
			surface.add_vertex(Vector3(x, planet_height(variant, x, distance), -distance))
	for row in range(ROWS - 1):
		for column in range(COLUMNS - 1):
			var a := row * COLUMNS + column
			for index in [a, a + COLUMNS, a + 1, a + 1, a + COLUMNS, a + COLUMNS + 1]:
				surface.add_index(index)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	valley.add_child(ground)
	ground.position = PLANET
	ground.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = 571 + variant
	for side in [-1, 1]:
		for distance in range(-22, 62, 5):
			var x: float = dream_x(variant, distance) + side * rng.randf_range(5.5, 14.0)
			var foot := PLANET + Vector3(x, planet_height(variant, x, distance), -distance)
			var size := Vector3(rng.randf_range(1.6, 3.2), rng.randf_range(3.8, 7.5), rng.randf_range(1.4, 2.8))
			if variant == 2: size = Vector3(size.x * 1.8, size.y * 0.36, size.z)
			var rock: MeshInstance3D = valley.stone(foot + Vector3.UP * size.y * 0.23, size, ROCK_COLORS[variant - 1])
			rock.rotation.z = rng.randf_range(-0.45, 0.45)
		for distance in range(-44, 90, 12):
			var x: float = side * rng.randf_range(22.0, 36.0)
			var foot := PLANET + Vector3(x, planet_height(variant, x, distance), -distance)
			valley.stone(foot, Vector3(16.0, rng.randf_range(12.0, 24.0), 15.0), ROCK_COLORS[variant - 1])
	for distance in [-31.0, 67.0, 82.0]:
		valley.stone(dream_point(variant, distance), Vector3(28, 17, 10), ROCK_COLORS[variant - 1])
	if variant == 3:
		for i in 5:
			var arch := dream_point(3, 10.0 + 9.0 * i)
			preload("res://estructuras.gd").arch(valley, arch, 1.05 + i * 0.13, true, i * 0.11)
		var glow: MeshInstance3D = valley.stone(final_arch() + Vector3(0, 1.65, 0.36), Vector3(0.58, 0.68, 0.31), "e4ccaa")
		(glow.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var props: Array[Node] = []
	for i in range(first_prop, valley.get_child_count()):
		props.append(valley.get_child(i))
	valley.add_child(root)
	for prop in props: prop.reparent(root)
	return root
