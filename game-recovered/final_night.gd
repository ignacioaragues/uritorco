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
const ENTRY := Vector3(0, 0.08, 11)
const MOUTH_Z := -1.0
const LIP := Vector3(0, 0.08, -9.1)
const LOWER_FLOOR := -4.4
const CHECKPOINT := Vector3(0, LOWER_FLOOR + 0.08, -17)
const TUNNEL_Z := -34.0
const EXIT_Z := -56.4
const RETURN_START := Vector3(0, 0.7, -57)
const HEADING := PI
const BOUNDS := Rect2(-42, -150, 84, 197)
const FORK_Z := -85.0
const CLEARING := Vector2(24.0, -121.0)
const RETURN := Vector2(-21.5, -137.0)
const RUNES_FOOT := Vector3(12.45, LOWER_FLOOR + 0.01, -29.7)

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

static func build_cave(v):
	var first: int = v.get_child_count()
	var stone = preload("res://piedra_serrana.gd")
	for piece in [
		[Vector3(0, -0.5, -6), Vector3(8.4, 1.0, 8.0), "5f554a"],
		[Vector3(0, LOWER_FLOOR - 0.6, -21.5), Vector3(9.2, 1.2, 27.0), "4f493f"],
	]:
		var floor_mesh: MeshInstance3D = v.box(CAVE + piece[0], piece[1], piece[2], true)
		floor_mesh.material_override = stone.paint(piece[2])
		floor_mesh.get_child(0).set_meta("footstep", &"stone")
	var rise := Vector3(0, LOWER_FLOOR, -34.6)
	var out := Vector3(0, RETURN_START.y, -56.0)
	var ramp: MeshInstance3D = v.box(CAVE + rise.lerp(out, 0.5) - Vector3.UP * 0.37,
		Vector3(8.8, 0.72, rise.distance_to(out) + 0.35), "514d40", true)
	ramp.look_at(CAVE + out - Vector3.UP * 0.37)
	ramp.material_override = stone.paint("514d40")
	for side in [-1.0, 1.0]:
		if side < 0:
			rock_wall(v, Vector3(-4.75, -0.64, -17.75), Vector3(1.4, 10.4, 36), "514b43")
		else:
			rock_wall(v, Vector3(4.75, -0.64, -6), Vector3(1.4, 10.4, 12), "514b43")
			rock_wall(v, Vector3(4.75, -0.64, -19.6), Vector3(1.4, 10.4, 5.3), "514b43")
			rock_wall(v, Vector3(4.75, -0.64, -32.2), Vector3(1.4, 10.4, 7.0), "514b43")
		rock_wall(v, Vector3(side * 3.65, 1.05, -44.5), Vector3(1.55, 12.0, 22.5), "504a41")
		for i in 13:
			var z := -1.8 - i * 2.62
			if side > 0 and ((z < -11.5 and z > -17.5) or (z < -21.8 and z > -28.8)): continue
			var edge := Vector3(side * (3.98 + 0.32 * sin(i * 2.8)), -0.35, z)
			var crag: MeshInstance3D = v.stone(CAVE + edge, Vector3(1.75, 10.0, 4.05), "65594c", true)
			crag.material_override = stone.paint("65594c")
		for i in 11:
			var z := -34.0 - i * 2.0
			var y := lerpf(LOWER_FLOOR, RETURN_START.y, (z + 34.0) / -22.0)
			var crag: MeshInstance3D = v.stone(CAVE + Vector3(side * (3.17 + 0.22 * sin(i)), y + 0.65, z),
				Vector3(1.75, 4.15, 3.25), "5d564a", true)
			crag.material_override = stone.paint("5d564a")
	rock_wall(v, Vector3(0, 4.15, -18), Vector3(10.4, 1.8, 36.0), "554b42")
	for opening in [Vector2(-14.46, 5.6), Vector2(-25.05, 6.5)]:
		rock_wall(v, Vector3(4.75, 1.96, opening.x), Vector3(1.5, 5.2, opening.y), "514b43")
	build_gallery(v)
	var tunnel_roof: MeshInstance3D = rock_wall(v,
		Vector3(0, rise.lerp(out, 0.5).y + 3.05, -44.7), Vector3(8.1, 1.5, 22.0), "4c463d")
	tunnel_roof.rotation.x = atan2(out.y - rise.y, rise.z - out.z)
	for i in 7:
		var overhang: MeshInstance3D = v.stone(CAVE + Vector3((i - 3) * 1.52, 3.38 - 0.69 * absf(i - 3) + 0.25 * sin(i), -0.90),
			Vector3(2.65, 2.12 + 0.55 * cos(i), 4.1), "746959", true)
		overhang.material_override = stone.paint("746959")
	build_cave_approach(v)
	build_cave_cover(v)
	var anchor := Vector3(0, 0.3, -8.7)
	var rope := PackedVector3Array([anchor + CAVE, CAVE + Vector3(0, 0.11, -9.76), CAVE + Vector3(0, 0.02, -10.26)])
	for step in 12:
		var t := (step + 1) / 12.0
		rope.append(CAVE + Vector3(0.045 * sin(t * 9.2), lerpf(-0.32, LOWER_FLOOR + 0.07, t), -10.29 - 0.12 * t))
	Kit.cord(v, rope, 0.042, Kit.material("b59a70"))
	Kit.item(v, CAVE + Vector3(0, 0.25, -9.35), "Cuerda de descenso", Vector3.ZERO,
		Vector3(0.38, 0.38, 1.82)).collision_layer = 2
	var pin: MeshInstance3D = v.stone(CAVE + anchor - Vector3.UP * 0.10, Vector3(0.76, 0.43, 0.52), "a79b86")
	pin.material_override = stone.paint("a79b86")
	var base := CAVE + Vector3(0, LOWER_FLOOR - 0.7, 0)
	v.timber(v.box(base + Vector3(-2.55, 1.15, -28), Vector3(1.1, 0.9, 3), "63503f", true))
	v.box(base + Vector3(-2.48, 1.79, -28), Vector3(0.75, 0.38, 0.76), "414948", true, "Receptor")
	for i in range(3):
		v.box(base + Vector3(-2.075, 1.79, -28.28 + i * 0.21), Vector3(0.04, 0.075, 0.1), "9c8567")
	v.box(base + Vector3(-2.48, 1.63, -26.85), Vector3(0.48, 0.055, 0.64), "a09273", true, "Cuadernos de observación")
	var tripod: = base + Vector3(2.4, 0.7, -30.3)
	for leg in [Vector3(-0.25, 0, 0.17), Vector3(0.25, 0, 0.17), Vector3(0, 0, -0.28)]:
		var foot: Vector3 = tripod + leg
		var strut = v.box(foot.lerp(tripod + Vector3.UP * 0.95, 0.5), Vector3(0.04, 0.04, 0.99), "665e51")
		strut.look_at(tripod + Vector3.UP * 0.95)
	v.box(tripod + Vector3.UP * 0.99, Vector3(0.28, 0.15, 0.29), "50545a")
	var lamp = v.box(base + Vector3(-2.48, 1.88, -28.35), Vector3(0.085, 0.042, 0.035), "b65734")
	lamp.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Kit.cord(v, PackedVector3Array([
		CAVE + Vector3(-2.78, -3.5, -28.1), CAVE + Vector3(-2.89, -4.34, -29.2),
		CAVE + Vector3(-2.10, -4.35, -32.5), CAVE + Vector3(-1.55, -4.35, -34.8),
		CAVE + Vector3(-1.47, -3.07, -40.2), CAVE + Vector3(-1.30, -1.85, -45.5),
		CAVE + Vector3(-1.60, -0.49, -51.1), CAVE + Vector3(-1.65, 0.55, -55.5),
	]), 0.030, Kit.material("675540"))
	build_return(v)
	var cave := Node3D.new()
	cave.name = "Cueva y regreso"
	v.add_child(cave)
	cave.position = CAVE
	while v.get_child(first) != cave:
		v.get_child(first).reparent(cave)
	cave.rotation.y = HEADING

static func build_gallery(v):
	rock_wall(v, Vector3(9.6, LOWER_FLOOR - 0.58, -21.5), Vector3(13.6, 1.16, 21.0), "4e473c")
	rock_wall(v, Vector3(9.8, 0.28, -21.5), Vector3(13.6, 1.55, 21.0), "514638")
	rock_wall(v, Vector3(16.1, -1.8, -21.5), Vector3(1.5, 6.2, 21.8), "50473c")
	rock_wall(v, Vector3(9.8, -1.8, -11.5), Vector3(13.1, 6.2, 1.45), "564a3e")
	rock_wall(v, Vector3(9.8, -1.8, -31.6), Vector3(13.1, 6.2, 1.45), "52493f")
	rock_wall(v, Vector3(0.25, -1.35, -19.75), Vector3(8.4, 6.3, 2.3), "625445")
	var finish := preload("res://piedra_serrana.gd").paint("68594a")
	for detail in [
		[Vector3(-2.12, -1.65, -18.53), Vector3(4.1, 6.20, 2.40)],
		[Vector3(1.28, -1.55, -19.05), Vector3(4.2, 6.2, 2.3)],
		[Vector3(3.95, -2.50, -19.18), Vector3(1.35, 4.45, 2.2)],
		[Vector3(9.9, -2.08, -19.6), Vector3(2.9, 6.1, 5.65)],
		[Vector3(10.1, -2.5, -25.0), Vector3(3.1, 4.1, 4.3)],
		[Vector3(14.93, -3.1, -13.7), Vector3(2.8, 3.0, 4.4)],
		[Vector3(14.66, -2.94, -27.4), Vector3(2.5, 3.4, 3.4)],
		[Vector3(7.3, -3.73, -30.5), Vector3(3.45, 1.7, 2.0)],
		[Vector3(6.1, -0.9, -13.0), Vector3(6.2, 2.40, 3.0)],
	]:
		var rock: MeshInstance3D = v.stone(CAVE + detail[0], detail[1], "68594a", true)
		rock.material_override = finish
	CaveRunes.build(v, CAVE + RUNES_FOOT)

static func rock_wall(v, at: Vector3, size: Vector3, tint: String) -> MeshInstance3D:
	var stone = preload("res://piedra_serrana.gd")
	var wall: MeshInstance3D = v.box(CAVE + at, size, tint, true)
	wall.material_override = stone.paint(tint)
	return wall

static func descent_route() -> Array[Vector3]:
	var points: Array[Vector3] = [LIP, Vector3(0, 0.10, -10.56)]
	for step in 6:
		points.append(Vector3(0, lerpf(0.10, LOWER_FLOOR + 0.08, (step + 1) / 6.0), -10.60))
	points.append(Vector3(0, LOWER_FLOOR + 0.08, -11.45))
	for i in points.size(): points[i] = cave_point(points[i])
	return points

static func build_cave_approach(v):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground_at := func(x: float, z: float) -> Vector3:
		var banks := smoothstep(4.1, 21.0, absf(x))
		var rise := (9.0 + 4.0 * sin(z * 0.14 + x * 0.03)) * banks
		rise += 16.0 * smoothstep(14.0, 58.0, z)
		return Vector3(x, rise, z)
	for row in 24:
		var z := -2.0 + row * 4.0
		for column in 42:
			var x := -84.0 + column * 4.0
			for offset in [Vector2.ZERO, Vector2.RIGHT * 4, Vector2.DOWN * 4, Vector2.RIGHT * 4,
					Vector2.ONE * 4, Vector2.DOWN * 4]:
				surface.add_vertex(ground_at.call(x + offset.x, z + offset.y))
	surface.generate_normals()
	var hill := MeshInstance3D.new()
	hill.mesh = surface.commit()
	hill.material_override = preload("res://piedra_serrana.gd").paint("69614d")
	v.add_child(hill)
	hill.position = CAVE
	hill.create_trimesh_collision()
	for side in [-1.0, 1.0]:
		for i in 8:
			var x: float = side * (7.4 + i * 1.2)
			var z := 2.0 + i * 3.2
			var foot: Vector3 = ground_at.call(x, z)
			var stone: MeshInstance3D = v.stone(CAVE + foot + Vector3.DOWN * 0.48,
				Vector3(4.0 + 1.1 * cos(i), 3.7, 4.9), "706851", true)
			stone.material_override = preload("res://piedra_serrana.gd").paint("706851")

static func build_cave_cover(v):
	var shell := SurfaceTool.new()
	shell.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim := PackedVector3Array()
	const COLS := 19
	const ROWS := 15
	for row in ROWS:
		var z := -0.85 - row * 3.4
		for column in COLS:
			var x := (column - 9) * 4.0
			var flank := smoothstep(3.0, 25.0, absf(x))
			var depth := smoothstep(-0.75, -13.0, z)
			var height := 4.65 - 4.0 * flank
			height += depth * (10.8 + 4.6 * sin(x * 0.14 + z * 0.088))
			height += (0.35 + 1.9 * depth) * sin(x * 0.5 + z * 0.2)
			height *= 1.0 - 0.77 * smoothstep(-37.0, -48.5, z)
			var vertex := Vector3(x, height, z)
			if row == 0: rim.append(vertex)
			shell.add_vertex(vertex)
	for row in ROWS - 1:
		for column in COLS - 1:
			var a := row * COLS + column
			for index in [a, a + COLS, a + 1, a + 1, a + COLS, a + COLS + 1]:
				shell.add_index(index)
	var start := COLS * ROWS
	for col in COLS - 1:
		var left := rim[col]
		var right := rim[col + 1]
		if absf((left.x + right.x) * 0.5) < 6.0: continue
		var foot_left := Vector3(left.x, -1.1, left.z)
		var foot_right := Vector3(right.x, -1.1, right.z)
		for vertex in [left, right, foot_left, foot_right]: shell.add_vertex(vertex)
		for index in [start, start + 1, start + 2, start + 1, start + 3, start + 2]: shell.add_index(index)
		start += 4
	shell.generate_normals()
	var cover := MeshInstance3D.new()
	cover.mesh = shell.commit()
	cover.material_override = preload("res://piedra_serrana.gd").paint("665c4e")
	v.add_child(cover)
	cover.position = CAVE
	cover.create_trimesh_collision()

static func trail_x(z: float, clearing: bool) -> float:
	if clearing:
		return CLEARING.x * smoothstep(FORK_Z, CLEARING.y, z)
	return RETURN.x * smoothstep(FORK_Z, RETURN.y, z) + 4.5 * sin(PI * smoothstep(-57.0, RETURN.y, z))

static func return_height(x: float, z: float) -> float:
	var relief := 0.5 * sin(z * 0.19 + x * 0.15) + 0.46 * cos(x * 0.27 - z * 0.11)
	var bank := 3.2 * smoothstep(13.0, 33.0, absf(x))
	return 0.7 + smoothstep(-56.0, -65.0, z) * (relief + bank - 0.065 * (-z - 65.0))

static func build_return(v):
	const COLUMNS := 43
	const ROWS := 65
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in ROWS:
		var z := -55.85 - row * 2.0
		for column in COLUMNS:
			var x := -42.0 + column * 2.0
			var distance := absf(x - trail_x(z, false))
			if z < FORK_Z:
				var clearing_distance := absf(x - trail_x(z, true))
				distance = minf(distance, clearing_distance + 4.0 * smoothstep(CLEARING.y - 4.0, CLEARING.y - 9.0, z))
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
	var material := preload("res://piedra_serrana.gd").paint()
	ground.material_override = material
	v.add_child(ground)
	ground.position = CAVE
	ground.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = 441
	for i in 300:
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-171.0, -57.0)
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
