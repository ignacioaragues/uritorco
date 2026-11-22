extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Stone = preload("res://piedra_serrana.gd")
const Flora = preload("res://flora.gd")
const Finds = preload("res://exploracion.gd")
const Visual = preload("res://hallazgo_visual.gd")
const BOOK := "Cuaderno del campamento"
const TRIPOD := "Trípode vacío"
const CRATE_TOP := 0.48

static func build(valley, camp_point: Vector3) -> MeshInstance3D:
	var camp := Node3D.new()
	camp.name = "Campamento de la cumbre"
	valley.add_child(camp)
	var route = valley.route
	camp.position = route.terrain_point(camp_point)
	var ground := func(at: Vector3) -> Vector3:
		return camp.to_local(route.terrain_point(camp.to_global(at)))
	var notch: Vector3 = camp.to_local(route.summit_point(0.84))
	tripod(camp, ground, notch)
	shelter(camp, ground)
	crate(camp, ground)
	field_gear(camp, ground)
	fire_ring(camp, ground)
	return notebook(camp)

static func fire_ring(camp: Node3D, ground: Callable):
	var spot: Vector3 = ground.call(Vector3(-5.1, 0, 1.4))
	var fire := Kit.item(camp, spot, "Fogata apagada", Vector3.UP * 0.14, Vector3(0.86, 0.24, 0.86))
	fire.collision_layer = 2
	fire.collision_mask = 0
	var ash := Kit.material("373531")
	var wood := Refuge.wood("43382e")
	var rng := RandomNumberGenerator.new()
	rng.seed = 32407
	var ash_surface := SurfaceTool.new()
	ash_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ash_rim := PackedVector3Array()
	for i in 13:
		var angle := TAU * i / 13.0
		ash_rim.append(ground.call(spot + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(0.25, 0.40)))
	for i in ash_rim.size():
		for vertex in [spot, ash_rim[i], ash_rim[(i + 1) % ash_rim.size()]]:
			ash_surface.add_vertex(vertex + Vector3.UP * 0.013)
	ash_surface.generate_normals()
	Kit.mesh_part(camp, ash_surface.commit(), Vector3.ZERO, ash)
	var stones := Stone.surface()
	for i in 8:
		var angle := TAU * i / 8.0 + rng.randf_range(-0.14, 0.14)
		var at: Vector3 = ground.call(spot + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(0.42, 0.52))
		Stone.fragment(stones, at, Vector3(rng.randf_range(0.24, 0.36), rng.randf_range(0.09, 0.20), 0.26), angle, rng, ground)
	Stone.finish(camp, stones, "Piedras tiznadas de la fogata").material_override = Stone.paint("6e685d")
	for i in 6:
		var direction := Vector3(cos(i * 2.4), 0, sin(i * 2.4))
		var start: Vector3 = ground.call(spot - direction * rng.randf_range(0.09, 0.26))
		var end: Vector3 = ground.call(spot + direction * rng.randf_range(0.16, 0.33))
		pipe(camp, start + Vector3.UP * (0.03 + i * 0.009), end + Vector3.UP * 0.026, rng.randf_range(0.022, 0.044), 0.017, wood)
	var edge: Vector3 = ground.call(spot + Vector3(0, 0, 0.55))
	var band := Kit.item(camp, edge + Vector3.UP * 0.065, "Pulsera de excursión", Vector3.UP * 0.03, Vector3(0.23, 0.13, 0.15))
	band.collision_layer = 2
	band.collision_mask = 0
	band.set_meta("find_id", Finds.CAMP_BAND)
	band.add_to_group("field_finds")
	var paper := Kit.material("c9b590", true)
	var blue := Kit.material("3c6465")
	var loop := PackedVector3Array([Vector3(-0.12, 0.01, 0.04), Vector3(-0.07, 0.008, -0.05),
		Vector3(0.075, 0.009, -0.041), Vector3(0.093, 0.026, 0.035), Vector3(-0.044, 0.030, 0.058)])
	for i in loop.size() - 1:
		var from := loop[i]
		var to := loop[i + 1]
		var strip := Kit.block(band, (from + to) * 0.5, Vector3(0.029, 0.004, from.distance_to(to) + 0.006), paper)
		strip.rotation.y = atan2(to.x - from.x, to.z - from.z)
	var stamp := Kit.block(band, Vector3(0.074, 0.022, -0.005), Vector3(0.019, 0.005, 0.037), blue)
	stamp.rotation.y = 0.24
	Visual.glint(band, Vector3.UP * 0.07, Color("#d9c1a4"))

static func pipe(parent: Node3D, from: Vector3, to: Vector3, base: float, tip: float, finish: Material) -> MeshInstance3D:
	var bar := Kit.cylinder(parent, (from + to) * 0.5, base, tip, from.distance_to(to), finish)
	bar.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return bar

static func solid(mesh: MeshInstance3D, label := ""):
	mesh.create_convex_collision()
	if not label.is_empty(): mesh.get_child(0).set_meta("item", label)

static func tripod(camp: Node3D, ground: Callable, notch: Vector3):
	var stand := Node3D.new()
	stand.name = "Trípode de observación"
	camp.add_child(stand)
	var enamel := Kit.material("626763", false, 0.67)
	var metal := Kit.material("807c6c", false, 0.54)
	var rubber := Kit.material("373b38", false, 0.93)
	var tape := Kit.material("48423d", true)
	var base: Vector3 = ground.call(Vector3(2.1, 0, -0.80))
	var pivot := base + Vector3.UP * 1.13
	for index in 3:
		var turn := TAU * index / 3.0 + 0.67
		var radial := Vector3(cos(turn), 0, sin(turn))
		var foot: Vector3 = ground.call(base + radial * 0.59)
		foot.y -= 0.018
		var hinge := pivot - Vector3.UP * 0.085 + radial * 0.071
		var joint := foot.lerp(hinge, 0.52)
		solid(pipe(stand, foot, joint, 0.017, 0.018, metal), TRIPOD)
		solid(pipe(stand, joint, hinge, 0.026, 0.022, enamel), TRIPOD)
		var axis := (hinge - foot).normalized()
		pipe(stand, foot, foot + axis * 0.077, 0.030, 0.024, rubber)
		pipe(stand, joint - axis * 0.025, joint + axis * 0.066, 0.032, 0.030, rubber)
		Kit.block(stand, joint + radial * 0.027 + Vector3.UP * 0.015, Vector3(0.024, 0.058, 0.032), metal).rotation.y = -turn
		pipe(stand, pivot - Vector3.UP * 0.34, foot.lerp(hinge, 0.65), 0.011, 0.010, enamel)
		if index == 1:
			for strip in 2:
				var mark := foot.lerp(joint, 0.57) + axis * (strip * 0.017)
				pipe(stand, mark, mark + axis * 0.024, 0.021, 0.021, tape)
	Kit.cylinder(stand, pivot - Vector3.UP * 0.17, 0.026, 0.024, 0.29, metal)
	solid(Kit.cylinder(stand, pivot, 0.098, 0.076, 0.084, rubber), TRIPOD)
	var head := Node3D.new()
	stand.add_child(head)
	head.position = pivot + Vector3.UP * 0.058
	var facing := (notch - base).slide(Vector3.UP)
	head.rotation.y = atan2(facing.x, facing.z)
	solid(Kit.block(head, Vector3.ZERO, Vector3(0.14, 0.047, 0.183), enamel), TRIPOD)
	Kit.block(head, Vector3(0.0, 0.023, 0.0), Vector3(0.123, 0.015, 0.156), rubber)
	Kit.cylinder(head, Vector3.UP * 0.038, 0.014, 0.014, 0.022, metal)
	pipe(head, Vector3(-0.058, -0.018, -0.032), Vector3(-0.20, -0.15, -0.26), 0.012, 0.010, metal)
	pipe(head, Vector3(-0.165, -0.119, -0.202), Vector3(-0.226, -0.172, -0.311), 0.018, 0.018, rubber)

static func shelter(camp: Node3D, ground: Callable):
	var tarp := Node3D.new()
	tarp.name = "Lona con vientos"
	camp.add_child(tarp)
	var wood := Refuge.wood("79674c")
	var iron := Kit.material("6a695e")
	var rope := Kit.material("b7a68a", true)
	var corners := PackedVector3Array()
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var front := i >= 2
		var foot: Vector3 = ground.call(Vector3(-2.62 + side * 1.12, 0, 0.62 if front else -1.22))
		var top := foot + Vector3(side * -0.040, (1.95 if front else 0.75) - (0.16 if side > 0 else 0), 0.022)
		corners.append(top)
		solid(pipe(tarp, foot - Vector3.UP * 0.05, top + Vector3.UP * 0.04, 0.043, 0.029, wood))
		var stake: Vector3 = ground.call(foot + Vector3(side * 0.49, 0, 0.56 if front else -0.49))
		var eye := stake + Vector3.UP * 0.13
		pipe(tarp, stake - Vector3.UP * 0.065, eye, 0.023, 0.017, iron)
		Kit.cord(tarp, PackedVector3Array([top, top.lerp(eye, 0.57) - Vector3.UP * 0.047, eye]), 0.008, rope)
		Kit.cylinder(tarp, top + Vector3.UP * 0.010, 0.031, 0.028, 0.020, iron)
	var fabric := ShaderMaterial.new()
	fabric.shader = preload("res://lona_campamento.gdshader")
	var sheet := Kit.mesh_part(tarp, canvas(corners), Vector3.ZERO, fabric)
	sheet.name = "Paño de lona"
	sheet.create_trimesh_collision()
	var collision: CollisionShape3D = sheet.get_child(0).get_child(0)
	(collision.shape as ConcavePolygonShape3D).backface_collision = true

static func canvas(corners: PackedVector3Array) -> ArrayMesh:
	const COLUMNS := 18
	const ROWS := 13
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(ROWS + 1):
		for column in range(COLUMNS + 1):
			var u := column / float(COLUMNS)
			var v := row / float(ROWS)
			var from := corners[0].lerp(corners[1], u)
			var to := corners[2].lerp(corners[3], u)
			var point := from.lerp(to, v)
			point.x -= cos(u * PI) * 0.065
			point.z -= cos(v * PI) * 0.063
			point.y -= sin(PI * u) * (0.069 + sin(PI * v) * 0.135)
			point.y += sin(u * TAU * 1.5 + 0.5 * v) * sin(PI * v) * 0.036
			sheet.set_uv(Vector2(u, v))
			sheet.add_vertex(point)
	for row in ROWS:
		for column in COLUMNS:
			var a := row * (COLUMNS + 1) + column
			for index in [a, a + 1, a + COLUMNS + 1, a + 1, a + COLUMNS + 2, a + COLUMNS + 1]:
				sheet.add_index(index)
	sheet.generate_normals()
	return sheet.commit()

static func crate(camp: Node3D, ground: Callable):
	var box := Node3D.new()
	box.name = "Cajón de tablas"
	camp.add_child(box)
	var shades := [Refuge.wood("7b6751"), Refuge.wood("897259"), Refuge.wood("705d49")]
	var rim := Refuge.wood("9c8267", true)
	var iron := Kit.material("554f45", false, 0.61)
	var bottom := INF
	for x in [-0.36, 0.36]:
		for z in [-0.25, 0.25]:
			var foot: Vector3 = ground.call(Vector3(x, 0, z))
			bottom = minf(bottom, foot.y)
			var leg_height := CRATE_TOP - 0.055 - foot.y
			Kit.block(box, foot + Vector3.UP * (leg_height * 0.5 - 0.01), Vector3(0.105, leg_height + 0.03, 0.089), shades[2])
	var bottom_board := minf(CRATE_TOP - 0.20, bottom + 0.052)
	var board_height := (CRATE_TOP - 0.043 - bottom_board) / 3.0
	for index in 3:
		var y := bottom_board + (index + 0.5) * board_height
		for z in [-0.285, 0.285]:
			Kit.block(box, Vector3(0, y, z), Vector3(0.875, board_height - 0.008, 0.045), shades[index])
			for x in [-0.358, 0.358]:
				Kit.cylinder(box, Vector3(x, y, z + signf(z) * 0.023), 0.007, 0.007, 0.006, iron).rotation.x = PI * 0.5
		for x in [-0.416, 0.416]:
			Kit.block(box, Vector3(x, y, 0), Vector3(0.045, board_height - 0.008, 0.565), shades[2 - index])
	for index in 5:
		Kit.block(box, Vector3((index - 2) * 0.174, CRATE_TOP - 0.019, 0), Vector3(0.169, 0.038, 0.627), shades[index % 3])
	Kit.block(box, Vector3(0, CRATE_TOP - 0.053, 0.302), Vector3(0.887, 0.038, 0.030), rim)
	Kit.item(box, Vector3.ZERO, "", Vector3.UP * ((CRATE_TOP + bottom_board) * 0.5),
		Vector3(0.87, CRATE_TOP - bottom_board, 0.61))

static func notebook(camp: Node3D) -> MeshInstance3D:
	var book := Node3D.new()
	book.name = BOOK
	camp.add_child(book)
	book.position = Vector3(-0.02, CRATE_TOP + 0.003, 0.064)
	book.rotation.y = 0.18
	var binding := Kit.material("595447", true)
	var paper := Kit.material("cbb896", false, 0.99)
	var pale := Kit.material("d6c4a1", false, 0.98)
	var pencil := Kit.material("746755", false, 0.95)
	var cover := Kit.block(book, Vector3.UP * 0.009, Vector3(0.411, 0.018, 0.295), binding)
	Kit.item(book, Vector3.ZERO, BOOK, Vector3.UP * 0.045, Vector3(0.43, 0.085, 0.307))
	Kit.block(book, Vector3.UP * 0.019, Vector3(0.022, 0.025, 0.273), binding)
	for side in [-1.0, 1.0]:
		var leaves := Node3D.new()
		book.add_child(leaves)
		leaves.position = Vector3(0.100 * side, 0.032, 0.0)
		leaves.rotation.z = side * -0.055
		Kit.block(leaves, Vector3.ZERO, Vector3(0.191, 0.024, 0.272), paper)
		Kit.block(leaves, Vector3(0.0, 0.013, -0.002), Vector3(0.188, 0.004, 0.267), pale)
		for line in range(7):
			var length := 0.11 + 0.029 * sin(line * 3.0 + side)
			Kit.block(leaves, Vector3((length - 0.136) * 0.5, 0.016, -0.086 + line * 0.026),
				Vector3(length, 0.0014, 0.0035 if line == 0 else 0.0021), pencil)
	return cover

static func field_gear(camp: Node3D, ground: Callable):
	var bottle_foot: Vector3 = ground.call(Vector3(0.64, 0, -0.16))
	var thermo := Kit.item(camp, bottle_foot, "", Vector3.UP * 0.19, Vector3(0.147, 0.38, 0.147))
	thermo.name = "Termo esmaltado"
	var bottle := Kit.material("57706a", false, 0.63)
	var collar := Kit.material("aba794", false, 0.55)
	var rubber := Kit.material("4f4d44", false, 0.93)
	Kit.cylinder(thermo, Vector3.UP * 0.020, 0.072, 0.073, 0.038, rubber)
	Kit.cylinder(thermo, Vector3.UP * 0.169, 0.069, 0.074, 0.30, bottle)
	Kit.cylinder(thermo, Vector3.UP * 0.328, 0.050, 0.068, 0.034, bottle)
	Kit.cylinder(thermo, Vector3.UP * 0.356, 0.054, 0.054, 0.051, collar)
	Kit.cord(thermo, PackedVector3Array([Vector3(0.045, 0.278, 0), Vector3(0.094, 0.258, 0),
		Vector3(0.105, 0.194, 0), Vector3(0.070, 0.161, 0)]), 0.012, collar)
	var bag: Vector3 = ground.call(Vector3(-3.29, 0, -0.53))
	Kit.backpack(camp, bag, "").rotation.y = -0.85
	var roll_foot: Vector3 = ground.call(Vector3(-2.43, 0, -0.60))
	var roll := Kit.item(camp, roll_foot, "", Vector3.UP * 0.086, Vector3(0.55, 0.17, 0.18))
	roll.name = "Manta enrollada"
	roll.rotation.y = 0.24
	Kit.cylinder(roll, Vector3.UP * 0.085, 0.087, 0.079, 0.54, Kit.material("776e58", true)).rotation.z = PI * 0.5
	var binding := Kit.material("5b4f41", true)
	for tie in [-0.183, 0.188]:
		Kit.cylinder(roll, Vector3(tie, 0.086, 0), 0.089, 0.089, 0.025, binding).rotation.z = PI * 0.5

	var anchors := RandomNumberGenerator.new()
	anchors.seed = 60032
	var forms := Stone.surface()
	var roots: Array[Vector4] = []
	for i in 19:
		var x := anchors.randf_range(-4.35, -1.22)
		var z := anchors.randf_range(-1.86, 0.96)
		if z > 0.58 and x > -1.83: continue
		var foot: Vector3 = ground.call(Vector3(x, 0, z))
		if i % 3 == 0:
			var dimensions := Vector3(0.27, 0.11, 0.24) * anchors.randf_range(0.65, 1.65)
			Stone.fragment(forms, foot, dimensions, anchors.randf() * TAU, anchors, ground)
		else:
			roots.append(Vector4(foot.x, foot.y - 0.04, foot.z, anchors.randf_range(0.27, 0.73)))
	Stone.finish(camp, forms, "Piedras del campamento")
	Flora.grass_batch(camp, roots)
