extends Node3D


const ORIGIN_Z: = -76.0
const WEST_START_Z := -22.0
const WEST_JOIN := 0.44
const HALF_WIDTH: = 360.0
const FAR: = 980.0
const CREST: = 922.0
const LAJA_FORK := 124.0
const LAJA_JOIN := 218.0
const CREEK_DISTANCE: = 96.0
const SUMMIT_JOIN: = 0.37
var rng: = RandomNumberGenerator.new()
var ground_rows: = PackedFloat32Array()
var ground_material: ShaderMaterial
var fox: = Node3D.new()
var legs: Array[Node3D] = []
var fox_waits: = false
var fox_departure: = -1.0
var fox_start: = Vector3.ZERO
var fox_speed: = 1.4
var time: = 0.0


static func trail(d: float) -> float:
	return -1.9 + 54.0 * sin(d / 83.0) + 18.0 * sin(d / 27.0)

static func detour(d: float) -> float:
	return trail(d) + 36.0 * sin(PI * clampf(inverse_lerp(LAJA_FORK, LAJA_JOIN, d), 0, 1))

static func creek_overlook(t: float) -> Vector3:
	var d: = lerpf(43.0, 104.0, t)
	var x: = trail(d) - 19.0 * sin(PI * t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func elevation(x: float, d: float) -> float:
	var t: = smoothstep(0, 65, d)
	var roll: = 6.0 * sin(d / 63.0) + 4.0 * sin(x / 53.0 + d / 89.0)
	var shoulder: = 20.0 * pow(clampf(absf(x - trail(d)) / 180.0, 0, 1), 2)
	var lip: = 3.1 * smoothstep(169.8, 170.2, d) * (1.0 - smoothstep(9, 26, absf(x - trail(170)))) * (1.0 - smoothstep(180, 218, d))
	var summit: = 45.0 * exp( - pow((x - 146.0) / 76.0, 2) - pow((d - 948.0) / 61.0, 2))
	var bed: = CREEK_DISTANCE + 2.0 * sin((x - trail(CREEK_DISTANCE)) / 14.0)
	var banks: = 1.0 - smoothstep(1.8, 8.0, absf(d - bed))
	var reach: = 1.0 - smoothstep(47.0, 69.0, absf(x - trail(CREEK_DISTANCE)))
	return summit + (0.136 * maxf(0, d) + roll + shoulder) * t + lip - 2.3 * banks * reach

func at(x: float, d: float) -> Vector3:
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

func surface_point(x: float, d: float) -> Vector3:
	var row := clampi(ground_rows.bsearch(d), 1, ground_rows.size() - 1)
	var near := float(ground_rows[row - 1])
	var far := float(ground_rows[row])
	var left := clampf(floorf((x + HALF_WIDTH) / 4.0) * 4.0 - HALF_WIDTH, -HALF_WIDTH, HALF_WIDTH - 4.0)
	var u := clampf((x - left) * 0.25, 0.0, 1.0)
	var w := clampf(inverse_lerp(near, far, d), 0.0, 1.0)
	var height: float
	if u + w <= 1.0:
		height = elevation(left, near) * (1.0 - u - w) + elevation(left + 4.0, near) * u + elevation(left, far) * w
	else:
		height = elevation(left + 4.0, far) * (u + w - 1.0) + elevation(left, far) * (1.0 - u) + elevation(left + 4.0, near) * (1.0 - w)
	return Vector3(x, height, ORIGIN_Z - d)

func creek_marker() -> Vector3:
	return at(trail(CREEK_DISTANCE) + 1.5, CREEK_DISTANCE)

static func make_ground_material(route_to_creek: PackedVector2Array, mara_start: Vector3, mara_end: Vector3, exploration: PackedVector2Array) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://monte.gdshader")
	var west := western_approach(0.0)
	var cable := western_approach(1.0)
	var east := eastern_access(0.0)
	var ascent := eastern_access(1.0)
	material.set_shader_parameter("west_start", Vector2(west.x, west.z))
	material.set_shader_parameter("west_end", Vector2(cable.x, cable.z))
	material.set_shader_parameter("east_start", Vector2(east.x, east.z))
	material.set_shader_parameter("east_end", Vector2(ascent.x, ascent.z))
	material.set_shader_parameter("mara_start", Vector2(mara_start.x, mara_start.z))
	material.set_shader_parameter("mara_end", Vector2(mara_end.x, mara_end.z))
	material.set_shader_parameter("creek_path", route_to_creek)
	material.set_shader_parameter("exploration_segments", exploration)
	material.set_shader_parameter("soil_detail", load("res://tierra_serrana.webp"))
	return material

func _ready():
	rng.seed = 853
	for i in range(-1, 246): ground_rows.append(i * 4.0)
	for d in range(89, 106):
		if d % 4 != 0: ground_rows.append(float(d))
	ground_rows.append(169.8)
	ground_rows.append(170.2)
	ground_rows.sort()
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for d in ground_rows:
		for ix in range(181):
			var x: = - HALF_WIDTH + ix * 4
			surface.add_vertex(at(x, d))
	for j in range(ground_rows.size() - 1):
		for i in range(180):
			var a: = j * 181 + i
			for index in [a, a + 181, a + 1, a + 1, a + 181, a + 182]: surface.add_index(index)
	surface.generate_normals()
	var land: = MeshInstance3D.new()
	land.mesh = surface.commit()
	land.material_override = ground_material
	add_child(land)
	land.create_trimesh_collision()
	signpost(creek_overlook(0.0) + Vector3(-1.6, 0, 0), "Desvío del cauce", "Mirador del cauce ↖")
	var overlook: = creek_overlook(0.63)
	signpost(overlook + Vector3(-1.4, 0, 0), "Mirador del cauce", "Mirador del cauce")
	box(self, Vector3(0.42, 0.43, 1.35), overlook + Vector3(-1.4, 0.2, -1.3), "978a73")
	signpost(at(trail(124) + 2, 124), "Paso de la laja", "Filo por la laja  ↑\nRodeo por la vaguada  →")
	build_laja_rope()
	signpost(at(trail(CREST), CREST), "Hito del filo", "Filo del puesto")
	plant()
	make_wildlife()
	fox.hide()
	var repeater: = at(trail(420) + 1.6, 420)
	signpost(repeater, "Antena del abra", "Radio · Abra del viento")
	box(self, Vector3(0.08, 4.0, 0.08), repeater + Vector3(0, 2, 0), "655a50")
	for h in [2.85, 3.45, 3.94]:
		box(self, Vector3(1.15, 0.04, 0.07), repeater + Vector3(0, h, 0), "737a75")
	signpost(at(trail(292) - 1.7, 292), "Sala de las sierras", "Museo de sitio →")
	signpost(Vector3(western_x_at(-27.0) - 1.8, 0.0, -27.0), "Sendero oeste", "Cantera ↖", 0.0, true)
	signpost(western_approach(1.0) + Vector3(2.0, 0.0, 0.0), "Sendero oeste", "Refugio · senda del oeste")

func laja_rope_route() -> Array[Vector3]:
	var x := trail(170.0) - 0.64
	var foot := surface_point(x, 169.30) + Vector3.UP * 0.04
	var landing := surface_point(x, 171.02)
	var points: Array[Vector3] = [foot]
	for i in range(1, 8):
		var progress := i / 7.0
		points.append(Vector3(x, lerpf(foot.y, landing.y + 0.22, progress), foot.z - 0.15 * progress))
	points.append(landing + Vector3.UP * 0.22)
	points.append(landing + Vector3.UP * 0.055)
	return points

func build_laja_rope():
	var x := trail(170.0) - 0.42
	var lower := surface_point(x, 169.68)
	var upper := surface_point(x, 170.94)
	var line := [
		lower + Vector3(0.04, 0.29, 0.03),
		Vector3(x - 0.07, lerpf(lower.y, upper.y, 0.52), lower.z - 0.05),
		Vector3(x + 0.05, upper.y + 0.13, ORIGIN_Z - 170.08),
		upper + Vector3(0.18, 0.12, 0.0)
	]
	for i in range(line.size() - 1):
		var from: Vector3 = line[i]
		var to: Vector3 = line[i + 1]
		var loop := box(self, Vector3(0.057, 0.057, from.distance_to(to) + 0.035), from.lerp(to, 0.5), "c3a178")
		loop.look_at(to)
		var shape := CollisionShape3D.new()
		var hitbox := BoxShape3D.new()
		hitbox.size = Vector3(0.20, 0.20, from.distance_to(to) + 0.06)
		shape.shape = hitbox
		var grip := StaticBody3D.new()
		grip.collision_layer = 2
		grip.set_meta("item", "Cuerda de la laja")
		loop.add_child(grip)
		grip.add_child(shape)
	box(self, Vector3(0.16, 0.14, 0.17), line[-1], "827665")

func signpost(pos: Vector3, tag: String, caption: String, facing: float = 0.0, painted: bool = false):
	if painted:
		painted_signpost(pos, tag, caption, facing)
		return
	var pole: = box(self, Vector3(0.17, 1.5, 0.14), pos + Vector3.UP * 0.75, "6c5443")
	pole.create_trimesh_collision()
	pole.get_child(0).set_meta("item", tag)
	var board: = box(self, Vector3(1.35, 0.43, 0.1), pos + Vector3.UP * 1.25, "665847")
	board.rotation.y = facing
	board.create_trimesh_collision()
	board.get_child(0).set_meta("item", tag)
	var text: = Label3D.new()
	board.add_child(text)
	text.position.z = 0.114
	text.text = caption
	text.font_size = 32
	text.pixel_size = 0.002
	text.modulate = Color("#e6d8b5")
	text.double_sided = true

func painted_signpost(pos: Vector3, tag: String, caption: String, facing: float):
	var stake := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.height = 1.58
	shaft.top_radius = 0.075
	shaft.bottom_radius = 0.096
	shaft.radial_segments = 6
	stake.mesh = shaft
	stake.material_override = sign_wood(Color("#776452"), false)
	add_child(stake)
	stake.position = pos + Vector3.UP * 0.77
	stake.rotation.z = 0.035 * sin(pos.x)
	stake.create_trimesh_collision()
	stake.get_child(0).set_meta("item", tag)

	var board := MeshInstance3D.new()
	board.mesh = sign_board()
	board.material_override = sign_wood(Color("#75604b"), true)
	add_child(board)
	var normal := Vector3(sin(facing), 0.0, cos(facing))
	board.position = pos + Vector3.UP * 1.27 + normal * 0.10
	board.rotation = Vector3(0.0, facing, 0.016 * sin(pos.z))
	board.create_trimesh_collision()
	board.get_child(0).set_meta("item", tag)

	var rivet := CylinderMesh.new()
	rivet.height = 0.018
	rivet.top_radius = 0.019
	rivet.bottom_radius = 0.023
	rivet.radial_segments = 6
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("#4c4240")
	iron.roughness = 0.82
	for x in [-0.72, 0.72]:
		var peg := MeshInstance3D.new()
		peg.mesh = rivet
		peg.material_override = iron
		board.add_child(peg)
		peg.position = Vector3(x, 0.0, 0.064)
		peg.rotation.x = PI * 0.5

	var text := Label3D.new()
	board.add_child(text)
	text.position.z = 0.075
	text.text = caption
	var lettering := FontVariation.new()
	lettering.base_font = ThemeDB.fallback_font
	lettering.variation_embolden = 0.48
	text.font = lettering
	text.font_size = 44
	text.pixel_size = 0.0029
	text.outline_size = 3
	text.outline_modulate = Color("#493e31")
	text.modulate = Color("#f0dbb0")

func sign_wood(tint: Color, horizontal: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://grain.gdshader")
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("across", horizontal)
	material.set_shader_parameter("grain_strength", 0.17)
	material.set_shader_parameter("fiber_scale", 94.0)
	return material

func sign_board() -> ArrayMesh:
	var outline := PackedVector2Array([
		Vector2(-0.76, -0.21), Vector2(-0.84, -0.16), Vector2(-0.82, 0.14), Vector2(-0.76, 0.21),
		Vector2(0.75, 0.22), Vector2(0.84, 0.14), Vector2(0.82, -0.14), Vector2(0.74, -0.20)
	])
	var profile := [Vector2(0.94, -0.06), Vector2(1.0, -0.035), Vector2(1.0, 0.035), Vector2(0.95, 0.06)]
	var corners := PackedVector3Array()
	for ring in profile:
		for point in outline:
			corners.append(Vector3(point.x * ring.x, point.y * ring.x, ring.y))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	var front := count * (profile.size() - 1)
	for i in count:
		var next := (i + 1) % count
		for vertex in [Vector3(0, 0, 0.06), corners[front + i], corners[front + next],
				Vector3(0, 0, -0.06), corners[next], corners[i]]:
			surface.add_vertex(vertex)
		for ring in range(profile.size() - 1):
			var a := ring * count
			var b := a + count
			for index in [a + i, a + next, b + i, b + i, a + next, b + next]:
				surface.set_smooth_group(-1)
				surface.add_vertex(corners[index])
	surface.generate_normals()
	return surface.commit()

func box(parent: Node3D, size_m: Vector3, pos: Vector3, color: String) -> MeshInstance3D:
	var mesh: = BoxMesh.new()
	mesh.size = size_m
	var node: = MeshInstance3D.new()
	node.mesh = mesh
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func scattered(mesh: PrimitiveMesh, transforms: Array[Transform3D], color: String):
	var batch: = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i in transforms.size(): batch.set_instance_transform(i, transforms[i])
	var inst: = MultiMeshInstance3D.new()
	inst.multimesh = batch
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	inst.material_override = mat
	add_child(inst)

func plant():
	var grass: Array[Transform3D] = []
	var shrubs: Array[Transform3D] = []
	var open_crowns: Array[Transform3D] = []
	var stems: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	for i in range(7600):
		var d: = rng.randf_range(8, FAR)
		var x: = trail(d) + rng.randf_range(-120, 120)
		var west_t := inverse_lerp(WEST_START_Z, quarry_point(WEST_JOIN).z, ORIGIN_Z - d)
		if west_t < 1.0 and absf(x - western_approach(west_t).x) < 3.8: continue
		if absf(d - 292) < 8 and absf(x - trail(292) - 10.5) < 11.5: continue
		if absf(x - trail(d)) < 2.6 or (d > 124 and d < 218 and absf(x - detour(d)) < 2.6): continue
		var pos: = at(x, d)
		var scale_m: = rng.randf_range(0.7, 1.8)
		var turn: = Basis(Vector3.UP, rng.randf() * TAU)
		if i % 12 == 0 and (d < 540 or i % 36 == 0):
			var open_tree := i % 24 == 0
			var trunk_height := 1.6 if open_tree else 2.3
			stems.append(Transform3D(turn.scaled(Vector3(0.19, trunk_height, 0.23) * scale_m), pos + Vector3.UP * trunk_height * 0.47 * scale_m))
			var crowns := open_crowns if open_tree else shrubs
			var canopy := Vector3(1.85, 0.80, 1.43) if open_tree else Vector3(2.25, 1.43, 1.82)
			for j in range(4 if open_tree else 3):
				var angle: = j * 2.1 + turn.get_euler().y
				crowns.append(Transform3D(turn.scaled(canopy * scale_m), pos + Vector3(cos(angle) * 0.81, trunk_height - 0.12 + j * 0.23, sin(angle) * 0.74) * scale_m))
		elif i % 8 == 0:
			rocks.append(Transform3D(turn.scaled(Vector3(2.1, 1.8, 2.4) * scale_m), pos))
		else:
			for j in range(4):
				var angle: = j * 1.57
				grass.append(Transform3D(turn.rotated(Vector3.FORWARD, 0.15 * j).scaled(Vector3(0.32, 0.74, 0.28) * scale_m), pos + Vector3(0.14 * cos(angle), 0.25, 0.14 * sin(angle)) * scale_m))
	var ball: = SphereMesh.new()
	ball.radial_segments = 7
	ball.rings = 3
	var blade: = CylinderMesh.new()
	blade.top_radius = 0.0
	blade.radial_segments = 3
	blade.height = 1
	scattered(blade, grass, "ae9865")
	scattered(ball, shrubs, "546447")
	scattered(ball, open_crowns, "7e8755")
	var bark := CylinderMesh.new()
	bark.top_radius = 0.25
	bark.radial_segments = 5
	bark.rings = 0
	bark.height = 1.0
	scattered(bark, stems, "705c49")
	scattered(ball, rocks, "8c7e72")

func animal_form(parent: Node3D, position: Vector3, proportions: Vector3, tint: String) -> MeshInstance3D:
	var form := SphereMesh.new()
	form.radial_segments = 9
	form.rings = 5
	var part := MeshInstance3D.new()
	part.mesh = form
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(tint)
	part.material_override = finish
	parent.add_child(part)
	part.position = position
	part.scale = proportions
	return part

func make_wildlife():
	add_child(fox)
	animal_form(fox, Vector3(0, 0.36, 0.021), Vector3(0.24, 0.27, 0.67), "89837c")
	animal_form(fox, Vector3(0, 0.36, -0.22), Vector3(0.19, 0.27, 0.31), "b7a38e")
	animal_form(fox, Vector3(0, 0.49, -0.32), Vector3(0.18, 0.16, 0.2), "9d8b7c")
	animal_form(fox, Vector3(0, 0.45, -0.431), Vector3(0.101, 0.093, 0.19), "b7a590")
	animal_form(fox, Vector3(0, 0.457, -0.52), Vector3(0.060, 0.045, 0.049), "4c443e")
	for side in [-1.0, 1.0]:
		var ear := animal_form(fox, Vector3(0.059 * side, 0.597, -0.30), Vector3(0.052, 0.146, 0.05), "766b61")
		ear.rotation.z = -side * 0.24
		animal_form(fox, Vector3(side * 0.079, 0.51, -0.386), Vector3(0.014, 0.017, 0.027), "4c4237")
	animal_form(fox, Vector3(0, 0.286, 0.457), Vector3(0.145, 0.16, 0.42), "7e776e").rotation.x = 0.31
	animal_form(fox, Vector3(0, 0.237, 0.642), Vector3(0.09, 0.11, 0.19), "514c46").rotation.x = 0.31
	for dx in [-0.071, 0.071]:
		for dz in [-0.19, 0.2]:
			legs.append(animal_form(fox, Vector3(dx, 0.16, dz), Vector3(0.065, 0.28, 0.075), "796555"))

func release_fox(linger: bool):
	fox_waits = false
	fox_departure = time
	fox_start = fox.position
	fox_speed = 1.0 if linger else 2.4

func _process(delta):
	time += delta
	var phase: = time * 0.18
	var d: = 47 + 5 * sin(phase)
	var x: = trail(47) + 7 * cos(phase)
	if fox_departure >= 0:
		var elapsed: = minf(time - fox_departure, 15.0) * fox_speed
		fox.position = at(fox_start.x + elapsed, ORIGIN_Z - fox_start.z + elapsed * 0.5)
		fox.rotation.y = -1.1
	elif not fox_waits:
		fox.position = at(x, d)
		fox.rotation.y = atan2(7 * sin(phase), 5 * cos(phase))
	for i in legs.size():
		legs[i].rotation.x = 0 if fox_waits or (fox_departure >= 0 and time - fox_departure >= 15) else sin(time * 5 + (PI if i in [1, 2] else 0.0)) * 0.42

static func quarry_point(t: float) -> Vector3:
	var d: = 300 + 310 * t
	var x: = trail(300) - 220 * t + 12 * sin(TAU * t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func western_approach(t: float) -> Vector3:
	var join := quarry_point(WEST_JOIN)
	var z := lerpf(WEST_START_Z, join.z, t)
	var x := lerpf(4.5 * sin(-WEST_START_Z / 13.0), join.x, t) - 39.0 * sin(PI * t)
	return Vector3(x, elevation(x, ORIGIN_Z - z), z)

static func western_x_at(z: float) -> float:
	var progress := clampf(inverse_lerp(WEST_START_Z, quarry_point(WEST_JOIN).z, z), 0.0, 1.0)
	return western_approach(progress).x

static func summit_point(t: float) -> Vector3:
	var d: = lerpf(CREST, 948, t) + 11 * sin(TAU * t)
	var x: = lerpf(trail(CREST), 146, t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func camp_point() -> Vector3:
	var beside_trail: = summit_point(0.49)
	var x: = beside_trail.x - 2.0
	var d: = ORIGIN_Z - beside_trail.z + 4.1
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func ascent_point(progress: float) -> Vector3:
	var join: = summit_point(SUMMIT_JOIN)
	var distance_along: = lerpf(8.0, ORIGIN_Z - join.z, progress)
	var x: = lerpf(33.0, join.x, progress)
	x += sin(PI * progress) * 128.0 + sin(TAU * progress * 4.0) * sin(PI * progress) * 16.0
	return Vector3(x, elevation(x, distance_along), ORIGIN_Z - distance_along)

static func eastern_access(progress: float) -> Vector3:
	const START_Z := -18.7
	var access := ascent_point(0.0)
	var z := lerpf(START_Z, access.z, progress)
	var x := lerpf(4.5 * sin(-START_Z / 13.0), access.x, smoothstep(0.0, 0.65, progress))
	return Vector3(x, elevation(x, ORIGIN_Z - z), z)

static func eastern_x_at(z: float) -> float:
	var progress := clampf(inverse_lerp(eastern_access(0.0).z, ascent_point(0.0).z, z), 0.0, 1.0)
	return eastern_access(progress).x

static func summit_return_marker(location: Vector3) -> Vector3:
	var best := INF
	var index := 0
	var points := PackedVector3Array()
	for step in range(101):
		points.append(ascent_point(step / 100.0))
	for step in range(1, 21):
		points.append(summit_point(lerpf(SUMMIT_JOIN, 1.0, step / 20.0)))
	for step in points.size():
		var distance := location.distance_squared_to(points[step])
		if distance < best:
			best = distance
			index = step
	return points[maxi(0, index - (4 if index > 104 else 8))]

static func legacy_crossing_point(progress: float) -> Vector3:
	var start: = quarry_point(0.53)
	var d: = ORIGIN_Z - start.z + progress * 221.0
	var x: = start.x - progress * 146.0 + 17.0 * sin(TAU * progress)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)
