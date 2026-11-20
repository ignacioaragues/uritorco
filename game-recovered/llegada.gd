extends RefCounted

const ACTIONS = ["Recoger la mochila", "Saltar el tronco", "Agarrarte del pasamanos", "Probar la brújula", "Consultar el mapa", "Trepar con la cuerda", "Encender la linterna", "Seguir el sendero"]
const HEADINGS = [0.0, -0.52, 0.72, 1.05, -0.8, 0.26, -1.19, 0.5]
const SOIL = ["77765d", "786e50", "697353", "7d7958", "83724f", "777260", "666754", "6f7259"]
const TRACK = ["9c815c", "aa866a", "98836a", "a88c65", "be9b71", "987457", "937a62", "988571"]

static func origin(index: int) -> Vector3:
	return Vector3(index * 240, 76, 1200)

static func local_position(index: int, point: Vector3) -> Vector3:
	return (point - origin(index)).rotated(Vector3.UP, -HEADINGS[index])

static func world_position(index: int, point: Vector3) -> Vector3:
	return origin(index) + point.rotated(Vector3.UP, HEADINGS[index])

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
			var creek := 1.0 - smoothstep(1.65, 3.04, absf(distance - center))
			return bank * (1.0 - creek) - 1.70 * creek
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
		v.arrival_fragments[index].visible = index == active

static func build_fragments(v):
	for index in ACTIONS.size():
		var center := origin(index)
		var first: int = v.get_child_count()
		build_ground(v, center, index)
		dress_landscape(v, center, index)
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
		v.arrival_fragments.append(fragment)

static func build_ground(v, center: Vector3, index: int):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs := PackedFloat32Array()
	for x in range(-116, -24, 4): xs.append(x)
	for x in range(-24, 25): xs.append(x)
	for x in range(28, 117, 4): xs.append(x)
	var distances := PackedFloat32Array()
	for d in range(-42, -14, 4): distances.append(d)
	for d in range(-14, 49): distances.append(d)
	for d in range(52, 101, 4): distances.append(d)
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
	ground.material_override = material

static func dress_landscape(v, center: Vector3, index: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = 263 + 117 * index
	for side in [-1, 1]:
		for slot in 14:
			var d := rng.randf_range(-24.0, 84.0)
			var x: float = side * rng.randf_range(5.3, 27.0) + track_x(index, d)
			if index == 0 and (absf(d - 3.0) < 6.0 or (x > 0 and absf(-d - branch_z(x)) < 3.8)): continue
			if index == 2 and absf(d - 10.45) < 4.7: continue
			var foot := center + Vector3(x, ground_height(index, x, d), -d)
			var size_m := rng.randf_range(0.64, 1.8)
			v.stone(foot, Vector3(2.7, 1.0, 2.4) * size_m, ["827b64", "787858", "666950", "89795d"][slot % 4])
			if slot % 3 == index % 3:
				v.box(foot + Vector3.UP * size_m, Vector3(0.14, 2.05, 0.16) * size_m, "6b5745")
				v.stone(foot + Vector3.UP * 2.2 * size_m, Vector3(2.4, 1.42, 2.2) * size_m, ["657551", "58644e", "777856"][slot % 3])
		for i in 5:
			var d := -28.0 + i * 29.0
			var x: float = side * (34.0 + rng.randf_range(0.0, 10.0))
			if index == 0 and absf(d - 3.0) < 4.0: d -= 12.0
			if index == 2 and absf(d - 10.45) < 9.0: d += 13.0
			var hill := center + Vector3(x, ground_height(index, x, d), -d)
			v.stone(hill, Vector3(rng.randf_range(20, 34), rng.randf_range(12, 27), rng.randf_range(22, 44)), "69705d")
		for d in [-34.0, 32.0, 92.0]:
			var x: float = side * rng.randf_range(77.0, 95.0)
			v.stone(center + Vector3(x, 0.0, -d), Vector3(64, rng.randf_range(37, 56), 64), "6b7a73")
	for x in [-39.0, 9.0, 58.0]:
		v.stone(center + Vector3(x, 1.0, -91.0), Vector3(60, rng.randf_range(24.0, 48.0), 44), "69796f")
	dress_verges(v, center, index, rng)

static func dress_verges(v, center: Vector3, index: int, rng: RandomNumberGenerator):
	var grass := SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.set_material(material)
	for tuft in 65:
		var d := rng.randf_range(-12.0, 36.0)
		var side := -1.0 if tuft % 2 == 0 else 1.0
		var x := track_x(index, d) + side * rng.randf_range(1.92, 4.8)
		if index == 0:
			x = rng.randf_range(-14.0, 20.0)
			if absf(d - 3.0) < 3.6 or (x > 0 and absf(-d - branch_z(x)) < 2.8): continue
			if absf(x) < 2.1 and d > 5.6 and d < 9.1: continue
		elif d > 6.9 and d < 14.8 and index in [1, 2, 5]:
			continue
		var root := Vector3(x, ground_height(index, x, d) - 0.022, -d)
		for blade in 4:
			var angle := rng.randf() * TAU
			var lean := Vector3(cos(angle), 0, sin(angle))
			var offset := lean * rng.randf_range(0.05, 0.14)
			var width := Vector3(-offset.z, 0, offset.x) * 0.19
			var tip := root + offset * 1.34 + Vector3.UP * rng.randf_range(0.105, 0.43)
			for vertex in [root + width, root - width, tip]:
				grass.set_color(Color("#a9a075") if vertex == tip else Color("#656345"))
				grass.set_normal(Vector3.UP)
				grass.add_vertex(vertex)
	var verge := MeshInstance3D.new()
	verge.mesh = grass.commit()
	v.add_child(verge)
	verge.position = center

static func build_stop(v, center: Vector3):
	var shelter := center + Vector3(-0.57, 0.0, -7.95)
	v.timber(v.box(shelter + Vector3.UP * 2.23, Vector3(3.95, 0.18, 1.68), "8c7c66"))
	for x in [-1.73, 1.73]:
		for z in [-0.62, 0.62]:
			v.timber(v.box(shelter + Vector3(x, 1.05, z), Vector3(0.14, 2.1, 0.13), "695644", true))
	v.timber(v.box(shelter + Vector3(0.0, 0.55, -0.37), Vector3(2.7, 0.12, 0.49), "a38966", true))
	for x in [-1.0, 1.0]:
		v.box(shelter + Vector3(x, 0.25, -0.37), Vector3(0.16, 0.50, 0.38), "77634f")
	var bag := center + Vector3(0.68, 0.31, -6.31)
	v.arrival_bag = v.box(bag, Vector3(0.58, 0.60, 0.32), "596650", true, ACTIONS[0])
	v.box(bag + Vector3(0, 0.05, 0.17), Vector3(0.18, 0.39, 0.029), "9b8a65").reparent(v.arrival_bag)
	v.box(bag + Vector3(0, -0.12, 0.191), Vector3(0.44, 0.20, 0.10), "77815f").reparent(v.arrival_bag)
	for side in [-1, 1]:
		v.box(bag + Vector3(side * 0.18, 0, -0.18), Vector3(0.075, 0.53, 0.12), "4c4939").reparent(v.arrival_bag)
		v.box(bag + Vector3(side * 0.09, 0.345, 0), Vector3(0.035, 0.09, 0.035), "403c30").reparent(v.arrival_bag)
	v.box(bag + Vector3(0, 0.39, 0), Vector3(0.18, 0.026, 0.04), "403c30").reparent(v.arrival_bag)
	v.arrival_bag.rotation.y = -0.14

static func build_log(v, center: Vector3):
	var log := CylinderMesh.new()
	log.top_radius = 0.24
	log.bottom_radius = 0.29
	log.height = 3.5
	log.radial_segments = 12
	var wood: MeshInstance3D = v.prop(log, center + Vector3(0.0, 0.22, -10.0), "69523b", true)
	wood.rotation.z = PI / 2.0
	for offset in [-0.08, 0.07, 0.18]:
		var bark: MeshInstance3D = v.box(center + Vector3(0.0, 0.40 - offset * 0.25, -10 + offset), Vector3(3.26, 0.026, 0.038), "7a6247")
		bark.rotation.y = offset * 0.12
	var branch: MeshInstance3D = v.box(center + Vector3(1.13, 0.26, -9.86), Vector3(0.085, 0.083, 0.53), "6d5541")
	branch.rotation.y = 0.47

static func build_bridge(v, center: Vector3):
	var water: MeshInstance3D = v.box(center + Vector3(0, -0.71, -10.45), Vector3(228, 0.018, 11.0), "466b6e")
	water.material_override.roughness = 0.23
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for index in 16:
		var plank := center + Vector3(0, -0.067, -7.18 - index * 0.47)
		v.box(plank, Vector3(2.76, 0.15, 0.47), ["987954", "8d6e4b", "9c7c58"][index % 3], true)
	for side in [-1, 1]:
		var label := ACTIONS[2] if side == 1 else ""
		v.timber(v.box(center + Vector3(side * 1.38, 0.81, -10.45), Vector3(0.13, 0.11, 5.55), "735944", true, label))
		for d in [8.17, 10.45, 12.72]:
			v.timber(v.box(center + Vector3(side * 1.38, 0.41, -d), Vector3(0.13, 0.86, 0.14), "735944"))

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
	(slab.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	for offset in [-1.45, 1.3]:
		v.stone(center + Vector3(offset, 0.4, -11.0), Vector3(1.05, 1.39, 1.22), "7a7064")
	var points := [
		Vector3(0.17, 0.13, -10.14), Vector3(0.075, 0.66, -10.30),
		Vector3(0.11, 1.19, -10.55), Vector3(0.11, 1.46, -10.82),
		Vector3(0.20, 1.47, -11.16), Vector3(0.32, 1.58, -11.55)
	]
	for i in range(points.size() - 1):
		var from: Vector3 = center + points[i]
		var to: Vector3 = center + points[i + 1]
		var sway: MeshInstance3D = v.box(from.lerp(to, 0.5), Vector3(0.033, 0.033, from.distance_to(to) + 0.035), "c7a278")
		sway.look_at(to)
	var knot := TorusMesh.new()
	knot.inner_radius = 0.037
	knot.outer_radius = 0.082
	var loop: MeshInstance3D = v.prop(knot, center + Vector3(0.32, 1.55, -11.55), "b9956a")
	loop.rotation.z = 0.4
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
	for side in [-1, 1]:
		for i in 8:
			v.stone(Vector3(v.path_x(-18) + side * 2.4, 0.25, -18 + i * 0.48), Vector3(0.68, 0.5, 0.65), "80796a")
