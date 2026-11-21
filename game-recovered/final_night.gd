extends RefCounted

const Alien = preload("res://hallazgos_sueno.gd")
const Kit = preload("res://equipo_campo.gd")
const CaveRunes = preload("res://piedra_cueva.gd")
const Structures = preload("res://estructuras.gd")
const DREAM_BOUNDS := Rect2(-73.0, -144.0, 146.0, 177.0)
const DREAM_ARCH_DISTANCES := [17.0, 38.0, 62.0, 92.0]

const CAVE: = Vector3(0, 80, 1900)
const DOOR := Vector3(39.5, 0, -57)
const STOP := Vector3(-3.2, 0, -70)
const DOOR_PATH_END := DOOR + Vector3(0, 0, -2.6)
const PLANET := Vector3(0, 88, 2450)
const GROUND_COLORS = [Color("436b7d"), Color("805740"), Color("544363")]
const ROCK_COLORS = [Color("638295"), Color("93694f"), Color("594666")]
# Altura, ancho, fondo y desplazamiento de cada sección de la roca.
const MINERAL_PROFILES = [
	[Vector4(-0.12, 0.80, 0.86, 0.0), Vector4(0.16, 1.0, 0.96, -0.10),
		Vector4(0.62, 0.68, 0.72, 0.12), Vector4(0.84, 0.48, 0.53, 0.27),
		Vector4(1.0, 0.17, 0.30, 0.45)],
	[Vector4(-0.15, 0.87, 0.92, 0.0), Vector4(0.16, 1.0, 1.0, 0.0),
		Vector4(0.46, 0.86, 0.86, 0.02), Vector4(0.51, 0.63, 0.76, -0.12),
		Vector4(0.81, 0.61, 0.66, -0.17), Vector4(0.95, 0.39, 0.48, -0.21)],
	[Vector4(-0.14, 0.91, 0.78, 0.0), Vector4(0.18, 1.0, 0.83, 0.13),
		Vector4(0.54, 0.78, 0.68, 0.34), Vector4(0.81, 0.56, 0.52, 0.61),
		Vector4(0.99, 0.16, 0.33, 0.87)],
]
const ENTRY: = Vector3(0, 0.08, -5)
const LIP := Vector3(0, 0.08, -9.1)
const CHECKPOINT: = Vector3(0, 0.78, -23)
const RETURN_START := Vector3(0, 0, -48)
const FORK_Z := -60.0
const CLEARING := Vector2(14.0, -79.0)
const RETURN := Vector2(-8.5, -88.0)
const RUNES_FOOT := Vector3(2.24, 0.71, -32.3)

static func near_stop(position: Vector3) -> bool:
	return position.distance_squared_to(STOP) < 64.0

static func door_approach(progress: float) -> Vector3:
	var point := STOP.lerp(DOOR_PATH_END, progress)
	point.z += sin(PI * progress) * 1.9
	return point

static func door_path_distance(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var start := Vector2(STOP.x, STOP.z)
	var end := Vector2(DOOR_PATH_END.x, DOOR_PATH_END.z)
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end))

static func build_cave(v):
	v.box(CAVE + Vector3(0, -0.45, -5), Vector3(8, 0.9, 12), "474239", true)
	v.box(CAVE + Vector3(0, -3.25, -18.8), Vector3(9.1, 1.3, 38.5), "292725", true)
	for ledge in [[-0.65, 0.13, -13.1], [0.65, 0.38, -16.6], [-0.45, 0.62, -20.1]]:
		v.box(CAVE + Vector3(ledge[0], ledge[1] - 0.45, ledge[2]), Vector3(2.5, 0.9, 2.35), "5c5349", true)
	v.box(CAVE + Vector3(0, 0.25, -29), Vector3(8, 0.9, 15.5), "47443d", true)
	var mouth: MeshInstance3D = v.box(CAVE + Vector3(0, 0.25, -43), Vector3(10, 0.9, 15), "484b37", true)
	mouth.get_child(0).set_meta("footstep", &"stone")
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
	CaveRunes.build(v, CAVE + RUNES_FOOT)
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
	var outskirts := smoothstep(15.0, 30.0, edge) * (1.4 + cos(x * 0.083 - distance * 0.11))
	match variant:
		1:
			var blue_gully := -3.8 * exp(-pow((x + 47.0) / 19.0, 2.0) - pow((distance - 52.0) / 19.0, 2.0))
			return relief + 0.7 * sin(distance * 0.13) + outskirts * 1.7 + blue_gully
		2:
			var terrace := smoothstep(16.0, 32.0, edge) * 2.1 * sin(x * 0.14 + 0.038 * distance)
			var bowl := -5.1 * exp(-pow((x - 43.0) / 19.0, 2.0) - pow((distance - 115.0) / 20.0, 2.0))
			return relief * 0.55 + 1.8 * sin(distance * 0.069) + terrace + bowl
		_:
			var fold := 5.3 * smoothstep(16.0, 30.0, edge) * sin(distance * 0.048 + 0.07 * x) * exp(-pow((distance - 110.0) / 52.0, 2.0))
			return relief * 1.30 + 0.9 * sin(distance * 0.16) + fold

static func dream_surface(variant: int, local: Vector2) -> Vector3:
	var x := floorf(local.x / 4.0) * 4.0
	var d := floorf(-local.y / 4.0) * 4.0
	var u := (local.x - x) * 0.25
	var v := (-local.y - d) * 0.25
	var a := planet_height(variant, x, d)
	var b := planet_height(variant, x + 4.0, d)
	var c := planet_height(variant, x, d + 4.0)
	var e := planet_height(variant, x + 4.0, d + 4.0)
	var height := a * (1.0 - u - v) + b * u + c * v if u + v <= 1.0 else e * (u + v - 1.0) + b * (1.0 - v) + c * (1.0 - u)
	return PLANET + Vector3(local.x, height, local.y)

static func dream_point(variant: int, distance: float) -> Vector3:
	var x := dream_x(variant, distance)
	return PLANET + Vector3(x, planet_height(variant, x, distance), -distance)

static func final_arch() -> Vector3:
	return dream_arch(DREAM_ARCH_DISTANCES.size() - 1)

static func dream_arch(index: int) -> Vector3:
	return dream_point(3, DREAM_ARCH_DISTANCES[index])

static func build_planet(valley, variant: int) -> Node3D:
	var root := Node3D.new()
	var first_prop: int = valley.get_child_count()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const COLUMNS := 73
	const ROWS := 64
	for row in ROWS:
		var distance := 4.0 * row - 64.0
		for column in COLUMNS:
			var x := 4.0 * column - 144.0
			surface.add_vertex(Vector3(x, planet_height(variant, x, distance), -distance))
	for row in range(ROWS - 1):
		for column in range(COLUMNS - 1):
			var a := row * COLUMNS + column
			for index in [a, a + COLUMNS, a + 1, a + 1, a + COLUMNS, a + COLUMNS + 1]:
				surface.add_index(index)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var material := dream_rock(variant, GROUND_COLORS[variant - 1], false)
	ground.material_override = material
	valley.add_child(ground)
	ground.position = PLANET
	ground.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = 571 + variant
	var crag := dream_rock(variant, ROCK_COLORS[variant - 1], true)
	dress_minerals(valley, variant, crag, rng)
	if variant == 3:
		var arch_stone := dream_rock(variant, Color("#827286"), true)
		for i in DREAM_ARCH_DISTANCES.size():
			Structures.arch(valley, dream_arch(i), 1.12 + i * 0.22, true, i * 0.11, arch_stone)
	var props: Array[Node] = []
	for i in range(first_prop, valley.get_child_count()):
		props.append(valley.get_child(i))
	valley.add_child(root)
	for prop in props: prop.reparent(root)
	dress_dream_landmarks(root, variant, crag)
	return root

static func dream_rock(variant: int, tint: Color, stone: bool) -> ShaderMaterial:
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://suelo_sueno.gdshader")
	paint.set_shader_parameter("ground_tint", tint)
	paint.set_shader_parameter("terrain_style", variant)
	paint.set_shader_parameter("bedrock", stone)
	paint.set_shader_parameter("planet_origin", PLANET)
	return paint

static func dress_minerals(parent: Node3D, variant: int, material: Material, rng: RandomNumberGenerator):
	for side: float in [-1.0, 1.0]:
		for slot in range(-3, 21):
			if (slot + variant + (1 if side < 0.0 else 0)) % 5 == 0: continue
			var distance := slot * 7.0 + rng.randf_range(-2.8, 2.8)
			var x := dream_x(variant, distance) + side * rng.randf_range(8.5, 17.6)
			var foot := dream_surface(variant, Vector2(x, -distance))
			var size := Vector3(rng.randf_range(2.0, 4.6), rng.randf_range(3.1, 7.8), rng.randf_range(1.6, 3.6))
			if variant == 2: size *= Vector3(1.73, 0.43, 1.30)
			if variant == 3: size *= Vector3(1.14, 1.08, 0.76)
			if near_dream_access(variant, Vector2(x, -distance), maxf(size.x, size.z) * 0.7 + 1.8): continue
			mineral(parent, foot, size, variant, material, rng, true)
			if slot % 3 == 1:
				var chip := dream_surface(variant, Vector2(x + side * 1.6, -distance + 2.5))
				mineral(parent, chip, size * Vector3(0.38, 0.25, 0.41), variant, material, rng, true)
		for slot in range(-2, 10):
			var distance := slot * 20.0 + rng.randf_range(-6.0, 6.0)
			var x := side * rng.randf_range(76.0, 95.0)
			var foot := dream_surface(variant, Vector2(x, -distance))
			var shelf := Vector3(rng.randf_range(22.0, 44.0), rng.randf_range(12.0, 27.0), rng.randf_range(16.0, 30.0))
			if variant == 2: shelf *= Vector3(1.16, 0.60, 1.2)
			mineral(parent, foot, shelf, variant, material, rng)
	for distance in [-52.0, 155.0, 174.0]:
		mineral(parent, dream_point(variant, distance), Vector3(47, 18, 21), variant, material, rng)

static func dream_access(variant: int, site: Vector2) -> Vector2:
	return Vector2(dream_x(variant, -site.y - 27.0), site.y + 27.0)

static func near_dream_access(variant: int, position: Vector2, clearance: float) -> bool:
	for site: Array in Alien.SITES[variant - 1]:
		var end: Vector2 = site[1]
		var at := Geometry2D.get_closest_point_to_segment(position, dream_access(variant, end), end)
		if position.distance_to(at) < clearance: return true
	return false

static func mineral(parent: Node3D, foot: Vector3, size: Vector3, variant: int, material: Material, rng: RandomNumberGenerator, solid := false):
	const SIDES := 8
	var shape: Array = MINERAL_PROFILES[variant - 1]
	var azimuth := rng.randf() * TAU
	var radii := PackedFloat32Array()
	var offsets := PackedFloat32Array()
	for side in SIDES:
		radii.append(rng.randf_range(0.81, 1.12))
		offsets.append(rng.randf_range(-0.065, 0.065))
	var rings := PackedVector3Array()
	for row: Vector4 in shape:
		for i in SIDES:
			var angle := TAU * i / SIDES
			var x := (cos(angle) * row.y * radii[i] + row.w) * size.x * 0.5
			var z := sin(angle) * row.z * radii[i] * size.z * 0.5
			rings.append(Vector3(x, (row.x + offsets[i]) * size.y, z).rotated(Vector3.UP, azimuth))
	var faces := SurfaceTool.new()
	faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(shape.size() - 1):
		for i in SIDES:
			var a := row * SIDES + i
			var b := row * SIDES + (i + 1) % SIDES
			for point in [a, b, a + SIDES, b, b + SIDES, a + SIDES]:
				faces.set_smooth_group(-1)
				faces.add_vertex(rings[point])
	var cap := (shape.size() - 1) * SIDES
	for i in range(1, SIDES - 1):
		for point in [cap, cap + i, cap + i + 1]:
			faces.set_smooth_group(-1)
			faces.add_vertex(rings[point])
	faces.generate_normals()
	var rock := Kit.mesh_part(parent, faces.commit(), foot, material)
	if solid: rock.create_convex_collision()

static func dress_dream_landmarks(parent: Node3D, variant: int, crag: ShaderMaterial):
	var sites: Array = Alien.SITES[variant - 1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42581 + variant
	for i in sites.size():
		var local: Vector2 = sites[i][1]
		var landmark := Node3D.new()
		parent.add_child(landmark)
		landmark.position = dream_surface(variant, local)
		var form: int = (variant - 1) * 2 + i
		var count: int = [9, 8, 6, 12, 9, 7][form]
		var tallest: float = [0.74, 5.9, 1.24, 1.11, 3.80, 2.74][form]
		for j in count:
			var angle := TAU * j / count + 0.49 * i
			var radius := 3.8 + 1.3 * sin(j * 1.78 + variant)
			var at := Vector2(cos(angle), sin(angle)) * radius
			if form == 0: at = Vector2(-7.0 + j * 1.62, 2.0 + sin(j * 0.62) * 1.8)
			if form == 2: at = Vector2(-7.0 + j * 2.18, 2.65 + j * 0.63)
			if form == 5: at = Vector2(-6.5 + j * 2.3, 2.0 + j * 0.48)
			var foot := dream_surface(variant, local + at) - landmark.position
			var wide: float = [3.5, 1.37, 2.97, 2.14, 1.61, 2.88][form]
			var height := tallest * rng.randf_range(0.66, 1.22)
			var size := Vector3(wide * rng.randf_range(0.82, 1.19), height, wide * (0.41 if form in [0, 5] else 0.72))
			if near_dream_access(variant, local + at, wide * 0.58 + 0.70): continue
			mineral(landmark, foot, size, variant, crag, rng, true)

	for id in Alien.FINDS:
		var artifact: Array = Alien.FINDS[id]
		if artifact[4] == variant:
			Alien.build_find(parent, id, dream_surface(variant, artifact[2]) + Vector3.UP * 0.052)
