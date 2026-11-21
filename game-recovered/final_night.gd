extends RefCounted

const Alien = preload("res://hallazgos_sueno.gd")
const Kit = preload("res://equipo_campo.gd")
const CaveRunes = preload("res://piedra_cueva.gd")
const Structures = preload("res://estructuras.gd")
const Stone = preload("res://piedra_serrana.gd")
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
const ENTRY := Vector3(0, 0.08, 15)
const MOUTH_Z := 0.0
const DROP_Z := -14.4
const LIP := Vector3(0, 0.09, -13.45)
const LOWER_FLOOR := -6.1
const CHECKPOINT := Vector3(0, LOWER_FLOOR + 0.08, -17.0)
const STATION := Vector3(-4.6, -6.0, -69.0)
const TUNNEL_Z := -77.0
const EXIT_Z := -148.0
const RETURN_START := Vector3(0, 0.08, EXIT_Z - 1.0)
const HEADING := PI
const BOUNDS := Rect2(-31, EXIT_Z - 6, 62, 192)
const RUNES_FOOT := Vector3(12.5, -6.27, -46.4)
# Cada sección define distancia, eje, piso, semiancho y altura.
const CAVE_SECTIONS := [
	[0.0, -0.15, 0.0, 3.15, 4.12], [-2.5, -0.35, -0.06, 3.0, 3.68],
	[-5.4, 0.10, -0.11, 3.4, 3.90], [-8.8, 0.65, 0.08, 4.0, 4.15],
	[-12.0, 0.32, 0.04, 4.45, 4.50], [DROP_Z, 0.0, 0.0, 4.6, 4.65],
	[DROP_Z - 0.04, 0.0, LOWER_FLOOR, 4.6, 10.75],
	[-18.5, -0.48, LOWER_FLOOR, 5.15, 10.5], [-22.5, -1.12, -6.38, 6.15, 8.65],
	[-27.0, -1.9, -6.55, 7.65, 7.8], [-30.6, -1.8, -6.49, 9.1, 8.5],
	[-35.0, -0.3, -6.35, 11.2, 9.75], [-39.5, 1.5, -6.31, 13.40, 10.8],
	[-44.0, 3.2, -6.29, 14.05, 12.45], [-49.5, 3.9, -6.20, 13.60, 11.12],
	[-54.5, 2.5, -6.00, 12.0, 8.4], [-59.0, 0.8, -6.12, 9.30, 7.5],
	[-64.0, -1.4, -6.01, 7.4, 7.15], [-68.5, -1.1, STATION.y, 7.6, 6.6],
	[-72.3, -1.8, STATION.y, 7.45, 6.0], [-76.5, -2.1, -5.94, 5.20, 5.25],
	[-80.2, -2.0, -5.80, 3.2, 3.7], [-84.0, -2.85, -5.60, 2.75, 3.5],
	[-88.0, -5.02, -5.22, 2.8, 3.38], [-92.0, -8.15, -5.05, 2.68, 3.23],
	[-96.5, -9.65, -4.68, 3.35, 3.45], [-101.0, -9.37, -3.85, 3.30, 3.45],
	[-105.0, -7.72, -3.25, 2.6, 3.30], [-109.0, -4.85, -2.53, 2.52, 3.15],
	[-113.0, -1.8, -2.20, 2.47, 3.12], [-117.0, 0.5, -1.65, 2.55, 3.4],
	[-121.0, 2.1, -1.45, 2.62, 3.4], [-125.0, 1.95, -1.19, 2.67, 3.33],
	[-129.0, 0.55, -0.95, 2.65, 3.12], [-133.0, -0.32, -0.67, 2.62, 3.00],
	[-137.5, -0.70, -0.46, 2.54, 3.08], [-142.0, -0.45, -0.20, 2.65, 3.28],
	[-145.0, -0.24, -0.08, 2.82, 3.47], [EXIT_Z, 0.0, 0.0, 3.10, 3.82],
]
const CAVE_ARCH := [Vector2(-0.86, 0.0), Vector2(-1.01, 0.16), Vector2(-1.04, 0.39),
	Vector2(-0.91, 0.60), Vector2(-0.71, 0.82), Vector2(-0.47, 0.96), Vector2(-0.13, 1.0),
	Vector2(0.23, 0.95), Vector2(0.57, 0.88), Vector2(0.82, 0.73),
	Vector2(0.96, 0.50), Vector2(1.02, 0.25), Vector2(0.88, 0.0)]

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

static func cave_point(local: Vector3) -> Vector3:
	return CAVE + local.rotated(Vector3.UP, HEADING)

static func cave_local(position: Vector3) -> Vector3:
	return (position - CAVE).rotated(Vector3.UP, -HEADING)

static func build_cave(v) -> Node3D:
	var first: int = v.get_child_count()
	var shell := Stone.surface()
	var rings: Array[PackedVector3Array] = []
	for row in CAVE_SECTIONS.size():
		rings.append(cave_ring(CAVE_SECTIONS[row], row))
	for row in rings.size() - 1:
		var upper := rings[row]
		var lower := rings[row + 1]
		for i in upper.size():
			var j := (i + 1) % upper.size()
			var tone := Color("#625a50").lerp(Color("#83776a"), 0.43 + 0.18 * sin(row * 2.03 + i * 1.34))
			if j == 0: tone = Color("#5d5448").lightened(0.04 + 0.025 * cos(row))
			Stone.triangle(shell, upper[i], upper[j], lower[i], tone)
			Stone.triangle(shell, upper[j], lower[j], lower[i], tone)
	var cavern := Stone.finish(v, shell, "Galerías de la cueva")
	cavern.position = CAVE
	cavern.create_trimesh_collision()
	cavern.get_child(0).set_meta("footstep", &"cave")
	build_cave_approach(v)
	build_portal(v, rings[0], 1.0)
	build_portal(v, rings[-1], -1.0)
	for light_data in [[Vector3(0.6, 3.5, 1.8), 0.83, 17.0], [Vector3(0.2, 1.93, EXIT_Z - 1.0), 0.51, 17.0]]:
		var light := OmniLight3D.new()
		light.light_color = Color("#a5b4d1")
		light.light_energy = light_data[1]
		light.omni_range = light_data[2]
		light.shadow_enabled = true
		v.add_child(light)
		light.position = CAVE + light_data[0]
	dress_cave(v)
	var cave := Node3D.new()
	cave.name = "Cueva"
	v.add_child(cave)
	cave.position = CAVE
	while v.get_child(first) != cave:
		v.get_child(first).reparent(cave)
	var edge := StaticBody3D.new()
	edge.name = "BordeDelPozo"
	var wall := BoxShape3D.new()
	wall.size = Vector3(10.0, 4.8, 0.14)
	var collision := CollisionShape3D.new()
	collision.shape = wall
	edge.add_child(collision)
	cave.add_child(edge)
	edge.position = Vector3(0.0, 2.30, DROP_Z)
	cave.rotation.y = HEADING
	return cave

static func cave_ring(section: Array, row: int) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in CAVE_ARCH.size():
		var arch: Vector2 = CAVE_ARCH[i]
		var overhead := sin(PI * arch.y * 0.5)
		# Mantener iguales los dos perfiles del pozo por encima del borde.
		var shape := mini(row, 5) if row in [5, 6] else row
		var pulse := sin(shape * 1.84 + i * 2.3)
		var x: float = section[1] + section[3] * (arch.x + 0.045 * pulse)
		var y: float = section[2] + section[4] * arch.y + overhead * pulse * 0.22
		ring.append(Vector3(x, y, section[0]))
	return ring

static func gallery_center(z: float) -> Vector3:
	for i in CAVE_SECTIONS.size() - 1:
		var a: Array = CAVE_SECTIONS[i]
		var b: Array = CAVE_SECTIONS[i + 1]
		if z <= a[0] and z >= b[0]:
			var t := inverse_lerp(a[0], b[0], z)
			return Vector3(lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), z)
	return Vector3.ZERO

static func build_portal(v, opening: PackedVector3Array, outward: float):
	var face := Stone.surface()
	var rim := PackedVector3Array()
	for i in opening.size():
		var at := opening[i]
		var arch: Vector2 = CAVE_ARCH[i]
		var width := 20.0 if outward > 0.0 else 15.0
		var rise := 12.5 if outward > 0.0 else 10.0
		rim.append(Vector3(arch.x * width, lerpf(-0.64, rise + 2.6 * sin(i * 1.35), arch.y),
			at.z + outward * (0.8 + 1.6 * absf(arch.x) + 0.48 * sin(i * 0.9))))
	for i in opening.size() - 1:
		var shade := Color("#756d5f").lerp(Color("#4e4941"), 0.28 + 0.17 * sin(i * 1.23))
		if outward > 0.0:
			Stone.triangle(face, opening[i], rim[i], opening[i + 1], shade)
			Stone.triangle(face, opening[i + 1], rim[i], rim[i + 1], shade)
		else:
			Stone.triangle(face, opening[i], opening[i + 1], rim[i], shade)
			Stone.triangle(face, opening[i + 1], rim[i + 1], rim[i], shade)
	var portal := Stone.finish(v, face, "Boca" if outward > 0 else "Paredón del túnel")
	portal.position = CAVE
	portal.create_trimesh_collision()

static func descent_route() -> Array[Vector3]:
	var points: Array[Vector3] = [LIP, Vector3(0, 0.12, DROP_Z - 0.57)]
	for step in 8:
		points.append(Vector3(0, lerpf(0.12, LOWER_FLOOR + 0.09, (step + 1) / 8.0), DROP_Z - 0.62))
	points.append(CHECKPOINT)
	for i in points.size(): points[i] = cave_point(points[i])
	return points

static func dress_cave(v):
	var anchor := Vector3(-0.04, 0.24, -13.1)
	var rim := Vector3(0, 0.05, DROP_Z - 0.19)
	var hemp := Kit.material("b59a70")
	Kit.cord(v, PackedVector3Array([CAVE + anchor, CAVE + rim]), 0.042, hemp)
	var hanging := Node3D.new()
	hanging.name = "CuerdaDesplegada"
	v.add_child(hanging)
	hanging.position = CAVE + Vector3(0, LOWER_FLOOR + 0.06, DROP_Z - 0.36)
	var rope := PackedVector3Array([CAVE + rim - hanging.position])
	for i in 14:
		var t := (i + 1) / 14.0
		rope.append(CAVE + Vector3(0.038 * sin(t * 9.2), lerpf(-0.23, LOWER_FLOOR + 0.12, t),
			DROP_Z - 0.21 - 0.19 * t) - hanging.position)
	Kit.cord(hanging, rope, 0.042, hemp)
	var grip := Kit.item(v, CAVE + Vector3(0, 0.28, -13.65), "Cuerda de descenso", Vector3.ZERO,
		Vector3(0.45, 0.44, 1.52))
	grip.name = "AgarreDelPozo"
	grip.collision_layer = 2
	var pin: MeshInstance3D = v.stone(CAVE + anchor - Vector3.UP * 0.09, Vector3(0.84, 0.44, 0.67), "a79b86")
	pin.material_override = Stone.paint("a79b86")
	var faces := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1976
	for form in [
		[Vector3(4.8, -6.51, -26.8), Vector3(2.1, 4.2, 4.3)],
		[Vector3(-6.8, -6.43, -32.8), Vector3(2.9, 3.75, 4.6)],
		[Vector3(0.1, -6.32, -42.2), Vector3(6.6, 10.3, 11.0)],
		[Vector3(6.1, -6.25, -50.1), Vector3(2.8, 5.16, 5.0)],
		[Vector3(-5.8, -6.12, -57.4), Vector3(4.2, 5.2, 4.6)],
		[Vector3(4.0, -6.04, -62.2), Vector3(2.39, 3.8, 3.5)],
	]:
		var foot: Vector3 = CAVE + form[0]
		var geometry := Stone.fragment(faces, foot, form[1], rng.randf_range(-0.30, 0.30), rng)
		Stone.solid(v, foot, geometry, "Roca de la galería")
	Stone.finish(v, faces, "Afloramientos del interior")
	CaveRunes.build(v, CAVE + RUNES_FOOT)
	build_station(v)

static func cut_descent(cave: Node3D):
	var grip: StaticBody3D = cave.get_node("AgarreDelPozo")
	var hanging: Node3D = cave.get_node("CuerdaDesplegada")
	grip.collision_layer = 0
	var fall := cave.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(hanging, "scale:y", 0.035, 0.62)
	fall.parallel().tween_property(hanging, "rotation:z", -0.22, 0.62)
	fall.tween_callback(func():
		hanging.hide()
		var coil := PackedVector3Array()
		for i in 42:
			var a := i * 0.27
			var radius := 0.29 + i * 0.004
			coil.append(hanging.position + Vector3(radius * cos(a), 0.012 + i * 0.001,
				-0.48 + radius * sin(a) * 0.57))
		Kit.cord(cave, coil, 0.035, Kit.material("a08964")))

static func build_station(v):
	var base := CAVE + STATION
	v.timber(v.box(base + Vector3(0, 0.45, 0), Vector3(1.17, 0.90, 3.27), "63503f", true))
	v.box(base + Vector3(-0.02, 1.10, -0.56), Vector3(0.76, 0.38, 0.78), "414948", true, "Receptor")
	for i in 3:
		v.box(base + Vector3(0.373, 1.10, -0.82 + i * 0.21), Vector3(0.04, 0.075, 0.1), "9c8567")
	var notebook: MeshInstance3D = v.box(base + Vector3(0.08, 0.93, 0.95),
		Vector3(0.53, 0.061, 0.68), "9d876a", true, "Cuaderno de observación")
	notebook.rotation.y = -0.13
	v.box(base + Vector3(0.08, 0.956, 0.95), Vector3(0.49, 0.011, 0.62), "c6b599").rotation.y = -0.13
	var tripod := base + Vector3(7.05, 0.02, -3.6)
	var head := tripod + Vector3.UP * 1.12
	for leg in [Vector3(-0.33, 0, 0.23), Vector3(0.33, 0, 0.23), Vector3(0, 0, -0.31)]:
		var foot: Vector3 = tripod + leg
		var strut: MeshInstance3D = v.box(foot.lerp(head, 0.5), Vector3(0.052, 0.052, foot.distance_to(head)), "665e51")
		strut.look_at(head)
	v.box(head, Vector3(0.31, 0.19, 0.40), "50545a", true)
	var lamp: MeshInstance3D = v.box(base + Vector3(0.37, 1.20, -0.58), Vector3(0.018, 0.039, 0.069), "a65634")
	lamp.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var wire := PackedVector3Array([base + Vector3(-0.10, 1.06, -0.92), base + Vector3(-0.56, 0.14, -1.73)])
	for z in range(-74, int(EXIT_Z) + 1, -2):
		wire.append(CAVE + gallery_center(z) + Vector3(-1.17, 0.064, 0))
	Kit.cord(v, wire, 0.032, Kit.material("77614b"))

static func build_cave_approach(v):
	var levels := Stone.surface()
	var ground_at := func(x: float, z: float) -> Vector3:
		var banks := smoothstep(4.5, 23.0, absf(x))
		var rise := (7.7 + 3.3 * sin(z * 0.094 + x * 0.13)) * banks * smoothstep(0.0, 8.0, z)
		rise += 13.0 * smoothstep(22.0, 61.0, z)
		return Vector3(x, rise, z)
	for row in 27:
		var z := row * 3.0
		for column in 50:
			var x := -75.0 + column * 3.0
			for offset in [Vector2.ZERO, Vector2.RIGHT * 3, Vector2.DOWN * 3, Vector2.RIGHT * 3,
					Vector2.ONE * 3, Vector2.DOWN * 3]:
				levels.set_color(Color("#716854").lightened(0.034 * sin(x * 0.31 + z * 0.35)))
				levels.add_vertex(ground_at.call(x + offset.x, z + offset.y))
	var ground := Stone.finish(v, levels, "Quebrada de la entrada")
	ground.position = CAVE
	ground.create_trimesh_collision()
	var scree := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 40114
	for side in [-1.0, 1.0]:
		for i in 13:
			var x: float = side * rng.randf_range(5.3, 21.8)
			var z := rng.randf_range(3.9, 29.0)
			var foot: Vector3 = ground_at.call(x, z)
			var size_m := rng.randf_range(1.2, 3.55)
			var shape := Stone.fragment(scree, CAVE + foot - Vector3.UP * 0.12,
				Vector3(1.5, 0.80, 1.08) * size_m, rng.randf() * TAU, rng)
			Stone.solid(v, CAVE + foot, shape, "Piedra de la quebrada")
	Stone.finish(v, scree, "Piedras al pie de la boca")

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
