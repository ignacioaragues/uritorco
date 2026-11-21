extends RefCounted

const Signage = preload("res://carteleria.gd")
const FieldKit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Flora = preload("res://flora.gd")
const Stone = preload("res://piedra_serrana.gd")
const STOP_START := Vector3(-2.82, 0.12, -6.43)
const STOP_CENTER := Vector3(-0.57, 0.0, -9.55)
const BRIDGE_WATER_Y := -0.71
const BRIDGE_WATER_Z := -10.45
const BRIDGE_WATER_WIDTH := 15.8

const ACTIONS = ["Recoger la mochila", "Saltar el tronco", "", "Probar la brújula", "Consultar el mapa", "Trepar con la cuerda", "Encender la linterna", "Seguir el sendero"]
const HEADINGS = [0.0, -0.52, 0.72, 1.05, -0.8, 0.26, -1.19, 0.5]
const DUSK = [0.0, 0.0, 0.0, 0.25, 0.45, 0.63, 0.91, 1.0]
const DARK = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.64, 0.90]
const LEDGE_ROPE = [
	Vector3(0.16, 0.073, -10.18), Vector3(0.10, 0.69, -10.29),
	Vector3(0.10, 1.30, -10.56), Vector3(0.12, 1.44, -10.63),
	Vector3(0.14, 1.49, -10.73), Vector3(0.19, 1.50, -11.04),
	Vector3(0.32, 1.55, -11.57),
]
const SOIL = ["77765d", "786e50", "697353", "7d7958", "83724f", "777260", "666754", "6f7259"]
const TRACK = ["9c815c", "aa866a", "98836a", "a88c65", "be9b71", "987457", "937a62", "988571"]

static func origin(index: int) -> Vector3:
	return Vector3(index * 240, 76, 1200)

static func local_position(index: int, point: Vector3) -> Vector3:
	return (point - origin(index)).rotated(Vector3.UP, -HEADINGS[index])

static func world_position(index: int, point: Vector3) -> Vector3:
	return origin(index) + point.rotated(Vector3.UP, HEADINGS[index])

static func spawn_point(index: int) -> Vector3:
	return world_position(index, STOP_START if index == 0 else Vector3.UP * 0.12)

static func spawn_heading(index: int) -> float:
	return -0.94 if index == 0 else HEADINGS[index]

static func track_x(index: int, distance: float) -> float:
	match index:
		3: return 3.6 * sin(distance * 0.13)
		4: return -4.8 * sin(distance * 0.105)
		6: return 5.0 * sin(distance * 0.113)
		7: return -4.4 * sin(distance * 0.14) + 0.11 * distance
		_: return 4.7 * sin(distance * 0.103) * smoothstep(15.0, 29.0, absf(distance))

static func ground_height(index: int, x: float, distance: float) -> float:
	if index == 0:
		var shoulder := smoothstep(9.0, 32.0, absf(distance - 3.0))
		return (2.0 + 1.65 * sin(x * 0.08 + distance * 0.12)) * shoulder
	var off_track := absf(x - track_x(index, distance))
	var bank := (2.6 + 1.8 * sin(x * 0.11 + distance * 0.15 + index)) * smoothstep(2.3, 17.0, off_track)
	match index:
		1, 5:
			var flanks := 8.0 * smoothstep(1.4, 3.65, absf(x))
			return bank + flanks * smoothstep(5.0, 9.2, distance) * (1.0 - smoothstep(11.6, 17.0, distance))
		2:
			var center := 10.45 + 2.7 * sin(x * 0.09) * smoothstep(3.0, 14.0, absf(x))
			var shore := lerpf(3.04, 5.92, smoothstep(1.43, 3.28, absf(x)))
			var across := absf(distance - center)
			var creek := 1.0 - smoothstep(1.65, shore, across)
			var pool := 0.88 * smoothstep(2.0, 3.85, x) * (1.0 - smoothstep(4.84, 7.9, x))
			pool *= 1.0 - smoothstep(0.53, 2.36, across)
			return bank * (1.0 - creek) - (1.70 + pool) * creek
		6:
			return bank - 4.9 * smoothstep(0.0, 25.0, distance) + 0.3 * sin(distance * 0.26)
		7:
			return bank + 2.45 * sin(distance * 0.095) - 1.75 * smoothstep(21.0, 35.0, distance)
		_:
			return bank + 0.34 * sin(distance * 0.16)

static func path_point(index: int, distance: float) -> Vector3:
	var x := track_x(index, distance)
	return Vector3(x, ground_height(index, x, distance), -distance)

static func branch_z(x: float) -> float:
	return -7.6 - 0.245 * (x - 2.8) + 1.7 * sin((x - 2.8) * 0.15)

static func reached_exit(index: int, local: Vector3) -> bool:
	if index == 0: return local.x > 12.0 and absf(local.z - branch_z(local.x)) < 3.2
	var cut := 25.0 if index >= 6 else 18.0
	return local.z < -cut and absf(local.x - track_x(index, -local.z)) < 3.0

static func left_fragment(local: Vector3) -> bool:
	return absf(local.x) > 24.0 or local.z > 9.6 or local.z < -33.0

static func safe_saved_position(index: int, position: Vector3, action_done: bool) -> Vector3:
	var local := local_position(index, position)
	if not action_done and index in [1, 5] and local.z < -10.15:
		local = path_point(index, 7.2)
	var floor_y := ground_height(index, local.x, -local.z)
	if index == 2 and absf(local.x) < 1.38 and local.z < -6.94 and local.z > -14.47:
		floor_y = 0.008
	elif index == 5 and absf(local.x) < 1.76 and local.z < -10.72 and local.z > -12.54:
		floor_y = 1.43
	local.y = maxf(local.y, floor_y + 0.045)
	return world_position(index, local)

static func rope_route() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for offset in [
		Vector3(0.04, 0.02, -9.87), Vector3(0.06, 0.37, -9.94),
		Vector3(0.08, 0.78, -10.04), Vector3(0.10, 1.18, -10.16),
		Vector3(0.12, 1.52, -10.25), Vector3(0.14, 1.52, -11.05),
		Vector3(0.14, 1.45, -11.38)
	]:
		points.append(world_position(5, offset))
	return points

static func show_fragment(v, active: int):
	for index in v.arrival_fragments.size():
		var fragment: Node3D = v.arrival_fragments[index]
		fragment.visible = index == active
		fragment.process_mode = Node.PROCESS_MODE_INHERIT if index == active else Node.PROCESS_MODE_DISABLED

static func build_fragments(v):
	var ridges := ridge_materials(v)
	for index in ACTIONS.size():
		var center := origin(index)
		var first: int = v.get_child_count()
		build_ground(v, center, index)
		dress_landscape(v, center, index)
		build_ridges(v, center, index, ridges)
		match index:
			0: build_stop(v, center)
			1: build_log(v, center)
			2: build_bridge(v, center)
			5: build_laja(v, center)
		var props: Array[Node] = v.get_children().slice(first)
		var fragment := Node3D.new()
		v.add_child(fragment)
		fragment.position = center
		for prop in props: prop.reparent(fragment)
		fragment.rotation.y = HEADINGS[index]
		fragment.hide()
		fragment.process_mode = Node.PROCESS_MODE_DISABLED
		v.arrival_fragments.append(fragment)

static func build_ground(v, center: Vector3, index: int):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs := PackedFloat32Array()
	for x in range(-212, -116, 12): xs.append(x)
	for x in range(-116, -24, 4): xs.append(x)
	for x in range(-24, 25): xs.append(x)
	for x in range(28, 117, 4): xs.append(x)
	for x in range(128, 213, 12): xs.append(x)
	var distances := PackedFloat32Array()
	for d in range(-198, -42, 12): distances.append(d)
	for d in range(-42, -14, 4): distances.append(d)
	for d in range(-14, 49): distances.append(d)
	for d in range(52, 101, 4): distances.append(d)
	for d in range(112, 221, 12): distances.append(d)
	for d in distances:
		for x in xs:
			surface.add_vertex(Vector3(x, ground_height(index, x, d), -d))
	for row in range(distances.size() - 1):
		for column in range(xs.size() - 1):
			var a := row * xs.size() + column
			var b := a + xs.size()
			for point in [a, b, a + 1, a + 1, b, b + 1]:
				surface.add_index(point)
	surface.generate_normals()
	var ground: MeshInstance3D = v.prop(surface.commit(), center, SOIL[index], true)
	var material := ShaderMaterial.new()
	material.shader = preload("res://llegada_suelo.gdshader")
	material.set_shader_parameter("fragment_index", index)
	material.set_shader_parameter("soil_tint", Color(SOIL[index]))
	material.set_shader_parameter("track_tint", Color(TRACK[index]))
	material.set_shader_parameter("brushwork", preload("res://tierra_serrana.webp"))
	ground.material_override = material

static func dress_landscape(v, center: Vector3, index: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = 263 + 117 * index
	var stones := Stone.surface()
	for side in [-1, 1]:
		for slot in 14:
			var d := rng.randf_range(-24.0, 84.0)
			var x: float = side * rng.randf_range(5.3, 27.0) + track_x(index, d)
			if not clear_verge(index, x, d, 3.9): continue
			var foot := center + Vector3(x, ground_height(index, x, d), -d)
			if slot % 4 == 1:
				var species: Flora.Kind = [Flora.Kind.MOLLE, Flora.Kind.TALA, Flora.Kind.ESPINILLO][(floori(slot * 0.25) + index) % 3]
				Flora.tree(v, foot, species, rng.randf_range(0.82, 1.42), rng.randf() * TAU)
			else:
				var size_m := rng.randf_range(0.65, 1.68)
				var rock := Stone.fragment(stones, foot, Vector3(2.3, 0.66, 1.88) * size_m, rng.randf() * TAU, rng)
				if absf(x) < 22.0 and d > -10.0 and d < 31.0:
					Stone.solid(v, foot, rock, "Piedra de la ladera")
	var roots := dress_verges(center, index, rng, stones)
	Stone.finish(v, stones, "Piedras de la huella")
	Flora.grass_batch(v, roots)

static func clear_verge(index: int, x: float, distance: float, shoulder: float) -> bool:
	if index == 0:
		var z := -distance
		var road := -3.0 + 3.1 * sin(x * 0.055) * smoothstep(13.0, 55.0, absf(x))
		if absf(z - road) < 3.28 + shoulder * 0.21: return false
		if x > 0.0 and absf(z - branch_z(x)) < shoulder: return false
		return absf(x - STOP_CENTER.x) > 2.80 or absf(z - STOP_CENTER.z) > 3.9
	if index == 2 and absf(distance - 10.45) < 5.10: return false
	if index in [1, 5] and distance > 6.9 and distance < 15.1 and absf(x) < 5.4: return false
	return absf(x - track_x(index, distance)) > shoulder

static func ridge_materials(v) -> Array[ShaderMaterial]:
	var materials: Array[ShaderMaterial] = []
	var colors := [Color("#70745e"), Color("#7b8980"), Color("#88959b")]
	for layer in colors.size():
		var finish := ShaderMaterial.new()
		finish.shader = preload("res://perfil_sierra.gdshader")
		finish.set_shader_parameter("stone", colors[layer])
		finish.set_shader_parameter("distance_layer", layer / 2.5)
		materials.append(finish)
		v.ridge_materials.append(finish)
	return materials

static func build_ridges(v, center: Vector3, index: int, materials: Array[ShaderMaterial]):
	const SECTIONS := 160
	const PROFILE := [Vector2(0.60, 0), Vector2(0.73, 0.15), Vector2(0.83, 0.41),
		Vector2(0.93, 0.73), Vector2(1.0, 1.0), Vector2(1.12, 0.52), Vector2(1.23, 0)]
	for layer in materials.size():
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var phase := 0.61 * index + 1.48 * layer
		var reach: float = [128.0, 235.0, 414.0][layer]
		for section in SECTIONS:
			var angle := TAU * section / SECTIONS
			var arm := Vector2(cos(angle), sin(angle))
			var spur := sin(angle * 8.0 + phase) * 0.54 + sin(angle * 17.0 - phase) * 0.27
			var broad := 0.58 * sin(angle * 3.0 + phase) + 0.31 * cos(angle * 7.0 - phase)
			var serration := 0.45 - absf(sin(angle * 11.0 - phase))
			var distance := reach * (1.0 + 0.13 * cos(angle * 2.0 - phase) + 0.075 * spur)
			var notch := pow(absf(arm.x), 18.0) if index in [0, 2] else pow(maxf(0, -arm.y), 22.0)
			var crest := distance * (0.151 + 0.075 * broad + 0.029 * spur + 0.031 * serration)
			crest *= 1.0 - notch * (0.98 if index in [0, 2] else (0.63 if layer == 0 else 0.24))
			for row in PROFILE:
				var radius: float = distance * (row.x + spur * 0.075 * sin(PI * row.y))
				var relief := 0.63 + 0.22 * cos(angle * 8.0 + phase + row.y) + 0.09 * cos(angle * 17.0 - phase)
				surface.set_uv(Vector2(relief, row.y))
				surface.add_vertex(Vector3(arm.x * radius, lerpf(-5.3, crest, pow(row.y, 1.24)), arm.y * radius))
		var stride := PROFILE.size()
		for section in SECTIONS:
			var next := (section + 1) % SECTIONS
			for row in range(stride - 1):
				var a := section * stride + row
				var b := next * stride + row
				for vertex in [a + 1, a, b + 1, b + 1, a, b]:
					surface.add_index(vertex)
		var ridge := MeshInstance3D.new()
		ridge.name = "Perfil serrano %d" % (layer + 1)
		ridge.mesh = surface.commit()
		ridge.material_override = materials[layer]
		ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		v.add_child(ridge)
		ridge.position = center

static func dress_verges(center: Vector3, index: int, rng: RandomNumberGenerator, stones: SurfaceTool) -> Array[Vector4]:
	var roots: Array[Vector4] = []
	for clump in 100:
		var distance := rng.randf_range(-10.0, 47.0)
		var side := -1.0 if clump % 2 == 0 else 1.0
		var x := track_x(index, distance) + side * rng.randf_range(2.1, 11.5)
		if index == 0: x = rng.randf_range(-24.0, 28.0)
		if not clear_verge(index, x, distance, 2.2): continue
		for tuft in rng.randi_range(2, 5):
			var t_x := x + rng.randf_range(-0.85, 0.85)
			var t_d := distance + rng.randf_range(-0.65, 0.65)
			if not clear_verge(index, t_x, t_d, 1.94): continue
			var foot := center + Vector3(t_x, ground_height(index, t_x, t_d) - 0.047, -t_d)
			roots.append(Vector4(foot.x, foot.y, foot.z, rng.randf_range(0.41, 0.97)))
		if clump % 3 == 0:
			var foot := center + Vector3(x, ground_height(index, x, distance) - 0.026, -distance)
			var width := rng.randf_range(0.12, 0.56)
			Stone.fragment(stones, foot, Vector3(width, width * rng.randf_range(0.27, 0.67), width * 0.73),
				rng.randf() * TAU, rng)
	return roots

static func build_stop(v, center: Vector3):
	Signage.shelter(v, center + STOP_CENTER)
	Signage.flag(v, center + Vector3(-3.72, 0, -8.73))
	Signage.trail_post(v, center + Vector3(4.7, 0.0, branch_z(4.7) - 1.52), "", "Refugio →", -0.72, true)
	v.arrival_bag = FieldKit.backpack(v, center + Vector3(-1.10, 0.318, -6.95), ACTIONS[0])
	v.arrival_bag.rotation.y = -0.14

static func build_log(v, center: Vector3):
	var log := CylinderMesh.new()
	log.top_radius = 0.24
	log.bottom_radius = 0.29
	log.height = 3.5
	log.radial_segments = 12
	var wood: MeshInstance3D = v.prop(log, center + Vector3(0.0, 0.22, -10.0), "69523b", true)
	wood.get_child(0).set_meta("footstep", &"wood")
	wood.rotation.z = PI / 2.0
	for offset in [-0.08, 0.07, 0.18]:
		var bark: MeshInstance3D = v.box(center + Vector3(0.0, 0.40 - offset * 0.25, -10 + offset), Vector3(3.26, 0.026, 0.038), "7a6247")
		bark.rotation.y = offset * 0.12
	var branch: MeshInstance3D = v.box(center + Vector3(1.13, 0.26, -9.86), Vector3(0.085, 0.083, 0.53), "6d5541")
	branch.rotation.y = 0.47

static func build_bridge(v, center: Vector3):
	var sheet := PlaneMesh.new()
	sheet.size = Vector2(228.0, BRIDGE_WATER_WIDTH)
	var water: MeshInstance3D = v.prop(sheet, center + Vector3(0, BRIDGE_WATER_Y, BRIDGE_WATER_Z), "466b6e")
	var flow := ShaderMaterial.new()
	flow.shader = preload("res://arroyo.gdshader")
	water.material_override = flow
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var nail := FieldKit.material("786b5b", false, 0.62)
	for index in 16:
		var plank := center + Vector3(0, -0.067, -7.18 - index * 0.47)
		var tone: String = ["8c775d", "81725d", "927e64", "877561"][index % 4]
		var board: MeshInstance3D = v.box(plank, Vector3(2.76, 0.15, 0.47), tone, true)
		board.get_child(0).set_meta("footstep", &"wood")
		(board.mesh as BoxMesh).size.z = 0.459
		var finish := Refuge.wood(tone, true)
		finish.set_shader_parameter("grain_strength", 0.125)
		board.material_override = finish
		for x in [-1.15, 1.15]:
			FieldKit.cylinder(board, Vector3(x, 0.076, 0.13), 0.018, 0.016, 0.006, nail)
	var railing := Refuge.wood("735944")
	for side in [-1, 1]:
		var rail: MeshInstance3D = v.box(center + Vector3(side * 1.38, 0.81, -10.45), Vector3(0.13, 0.11, 5.55), "735944", true)
		rail.material_override = railing
		for d in [8.17, 10.45, 12.72]:
			var post: MeshInstance3D = v.box(center + Vector3(side * 1.38, -0.45, -d), Vector3(0.13, 2.58, 0.14), "735944", true)
			post.material_override = railing

static func bridge_depth(pos: Vector3) -> float:
	var local := local_position(2, pos)
	if absf(local.x) >= 114.0 or absf(local.z - BRIDGE_WATER_Z) >= BRIDGE_WATER_WIDTH * 0.5: return 0.0
	return maxf(0.0, BRIDGE_WATER_Y - local.y)

static func build_laja(v, center: Vector3):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [
		[Vector3(-1.83, -0.12, -10.32), Vector3(1.83, -0.12, -10.32)],
		[Vector3(-1.68, 0.74, -10.43), Vector3(1.66, 0.75, -10.47)],
		[Vector3(-1.75, 1.43, -10.72), Vector3(1.75, 1.43, -10.72)],
		[Vector3(-1.88, 1.42, -12.53), Vector3(1.88, 1.42, -12.53)],
		[Vector3(-1.83, -0.12, -16.10), Vector3(1.83, -0.12, -16.10)]
	]
	for row in range(rows.size() - 1):
		for p in [rows[row][0], rows[row + 1][0], rows[row][1], rows[row][1], rows[row + 1][0], rows[row + 1][1]]:
			surface.set_smooth_group(-1)
			surface.add_vertex(p)
	surface.generate_normals()
	var slab: MeshInstance3D = v.prop(surface.commit(), center, "887a6d", true, ACTIONS[5])
	slab.get_child(0).set_meta("footstep", &"stone")
	slab.mesh = ledge_face(rows)
	var rock := Stone.paint("#948371")
	rock.set_shader_parameter("bedding", 0.72)
	slab.material_override = rock
	var pieces := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 53091
	for offset in [-1.54, 1.47]:
		Stone.fragment(pieces, center + Vector3(offset, 0.37, -11.02), Vector3(0.98, 0.93, 1.44), offset * 0.48, rng)
		Stone.fragment(pieces, center + Vector3(offset * 0.91, 0.12, -10.32), Vector3(0.68, 0.39, 0.74), -offset, rng)
	Stone.finish(v, pieces, "Piedras junto a la laja")
	var points := PackedVector3Array()
	for point: Vector3 in LEDGE_ROPE: points.append(center + point)
	var hemp := Refuge.cloth("bbaa83", "a4906e", 0.19)
	FieldKit.cord(v, points, 0.023, hemp)
	var peg := FieldKit.material("655345", false, 0.64)
	var anchor: Vector3 = center + LEDGE_ROPE.back()
	FieldKit.cylinder(v, anchor + Vector3.DOWN * 0.07, 0.018, 0.018, 0.13, peg)
	var knot := TorusMesh.new()
	knot.inner_radius = 0.030
	knot.outer_radius = 0.058
	var loop := FieldKit.mesh_part(v, knot, anchor, peg)
	loop.rotation.x = 0.68

static func ledge_face(rows: Array) -> ArrayMesh:
	const COLUMNS := 15
	const STEPS_PER_ROW := 4
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last_row := rows.size() - 1
	for row in range(last_row * STEPS_PER_ROW + 1):
		var level := float(row) / STEPS_PER_ROW
		var segment := mini(floori(level), last_row - 1)
		var step := level - segment
		for column in COLUMNS:
			var across := float(column) / (COLUMNS - 1)
			var lower: Vector3 = rows[segment][0].lerp(rows[segment][1], across)
			var upper: Vector3 = rows[segment + 1][0].lerp(rows[segment + 1][1], across)
			var point := lower.lerp(upper, step)
			var shoulder := smoothstep(0.22, 1.55, absf(point.x))
			point.z += sin(point.x * 5.8 + level * 3.7) * 0.11 * shoulder
			point.y += sin(point.x * 3.28 - level * 1.5) * shoulder * 0.064
			surface.add_vertex(point)
			if row > 0 and column > 0:
				var a := (row - 1) * COLUMNS + column - 1
				for vertex in [a, a + COLUMNS, a + 1, a + 1, a + COLUMNS, a + COLUMNS + 1]:
					surface.add_index(vertex)
	surface.generate_normals()
	return surface.commit()

static func sign_at(v, point: Vector3, caption: String):
	v.box(point + Vector3(0, 0.85, 0), Vector3(0.1, 1.7, 0.1), "5e5042")
	v.box(point + Vector3.UP * 1.55, Vector3(1.55, 0.48, 0.09), "514d40")
	var label: = Label3D.new()
	label.text = caption
	label.font_size = 38
	label.pixel_size = 0.0035
	label.modulate = Color("#ebdeba")
	v.add_child(label)
	label.position = point + Vector3(0, 1.55, -0.065)
	label.rotation.y = PI

static func build(v):
	v.build_yard_fence()
	sign_at(v, Vector3(v.path_x(-34) + 2, 0, -34), "PUESTO ↑")
