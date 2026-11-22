extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Signage = preload("res://carteleria.gd")
const Stone = preload("res://piedra_serrana.gd")
const Flora = preload("res://flora.gd")

const REEL_AT := 0.52
const SPLICE_AT := 23.0 / 32.0
const FACE_AT := 0.93
const BORE_START := -2.46
const BORE_SPACING := 0.615
const BORE_RADIUS := 0.052
const BORE_DEPTH := 0.062
const REEL := "Carrete de cable"
const SPLICE := "Casilla de empalme"
const FACE := "Frente de cantera"
const NOTES := {
	REEL: "El cable todavía tiene las vueltas parejas de fábrica. Alguien trabó el carrete con dos tacos y dejó afuera la punta, atada con alambre.",
	SPLICE: "Adentro quedaron dos bornes partidos. En la tapa, escrito con lápiz de carpintero: «Si vuelve a cortarse, revisar primero el tramo del malacate».",
	FACE: "En el granito quedaron medias perforaciones, todas en fila. En el último corte hay una cuña oxidada que nadie llegó a sacar.",
}

static func build(valley):
	var route = valley.route
	var section := Node3D.new()
	section.name = "Camino del cable"
	valley.add_child(section)
	build_reel(roadside(section, route, REEL_AT, 3.15), route)
	var splice := roadside(section, route, SPLICE_AT, -3.85)
	var pole: Vector3 = route.terrain_point(route.cable_pole(SPLICE_AT))
	build_splice(splice, route, pole)
	build_face(roadside(section, route, FACE_AT, 5.4), route)
	dress_verge(section, route)

static func dress_verge(parent: Node3D, route):
	var rng := RandomNumberGenerator.new()
	rng.seed = 27031
	var talus_rng := RandomNumberGenerator.new()
	talus_rng.seed = 252701
	var ground := Callable(route, "terrain_point")
	var faces := Stone.surface()
	var tufts: Array[Vector4] = []
	var scrub: Array[Vector4] = []
	var dry_grass: Array[Vector4] = []
	for i in range(20):
		var t := 0.07 + i * 0.046
		var at: Vector3 = route.quarry_point(t)
		var side: Vector3 = route.quarry_side(t)
		var margin_left := -1.0 if i % 3 == 0 else 1.0
		var outward := side * margin_left
		var heading := Vector3(outward.z, 0.0, -outward.x)
		for blade in talus_rng.randi_range(5, 10):
			var verge := at - outward * talus_rng.randf_range(3.4, 7.8)
			verge += heading * talus_rng.randf_range(-2.3, 4.1)
			var root: Vector3 = ground.call(verge) - Vector3.UP * 0.050
			dry_grass.append(Vector4(root.x, root.y, root.z, talus_rng.randf_range(0.69, 1.28)))
		if minf(absf(t - route.WEST_JOIN), minf(absf(t - REEL_AT), minf(absf(t - SPLICE_AT), absf(t - FACE_AT)))) < 0.023:
			continue
		var foot: Vector3 = ground.call(at + outward * rng.randf_range(4.0, 10.8))
		if i % 3 != 1:
			var width := rng.randf_range(1.2, 3.0)
			var size_m := Vector3(width, width * rng.randf_range(0.31, 0.68), width * 0.73)
			var turn := atan2(-heading.z, heading.x) + rng.randf_range(-0.34, 0.34)
			var profile := Stone.FRACTURE_PROFILE if i % 3 == 0 else Stone.LAJA_PROFILE
			var mass := Stone.fragment(faces, foot, size_m, turn, talus_rng, ground, profile, true)
			Stone.solid(parent, foot, mass, "Granito de la cantera")
			Stone.scree(faces, foot, heading, width, ground, talus_rng)
		for blade in rng.randi_range(6, 14):
			var jitter := Vector3(rng.randf_range(-1.7, 1.7), 0, rng.randf_range(-2.8, 2.8))
			var tuft: Vector3 = ground.call(foot + jitter) - Vector3.UP * 0.05
			var size_m := rng.randf_range(0.48, 1.1)
			if blade % 3 == 0 and (tuft - at).dot(side * margin_left) > 3.7:
				scrub.append(Vector4(tuft.x, tuft.y - 0.03, tuft.z, size_m))
			else:
				tufts.append(Vector4(tuft.x, tuft.y, tuft.z, size_m))
		if i % 5 in [1, 4]:
			var farther: Vector3 = ground.call(foot + side * margin_left * rng.randf_range(3.8, 6.7))
			var kind := Flora.Kind.MOLLE if i % 2 == 0 else Flora.Kind.ESPINILLO
			Flora.tree(parent, farther, kind, rng.randf_range(0.88, 1.35), rng.randf() * TAU)
	Stone.finish(parent, faces, "Afloramientos junto al cable")
	Flora.grass_batch(parent, tufts)
	Flora.herb_batch(parent, scrub, Flora.Herb.ROMERILLO)
	Flora.herb_batch(parent, dry_grass, Flora.Herb.PAJA)

static func roadside(parent: Node3D, route, progress: float, offset: float) -> Node3D:
	var center: Vector3 = route.quarry_point(progress)
	var side: Vector3 = route.quarry_side(progress)
	var site := Node3D.new()
	parent.add_child(site)
	site.position = route.terrain_point(center + side * offset)
	var facing := -side * signf(offset)
	site.rotation.y = atan2(facing.x, facing.z)
	return site

static func footing(site: Node3D, route, top: Vector3, size: Vector2, material: Material):
	var bottom := top.y
	for x in [-0.5, 0.5]:
		for z in [-0.5, 0.5]:
			var corner := site.to_global(top + Vector3(x * size.x, 0, z * size.y))
			bottom = minf(bottom, route.terrain_point(corner).y - site.global_position.y)
	var height := top.y - bottom + 0.08
	Signage.solid(site, top - Vector3.UP * height * 0.5, Vector3(size.x, height, size.y), material)

static func build_reel(site: Node3D, route):
	site.name = REEL
	var wood := Refuge.wood("86654c", true)
	var worn := Refuge.wood("6d5240", true)
	var metal := Kit.material("554e43")
	var cable := Kit.material("3c3c36")
	for x in [-0.52, 0.52]:
		footing(site, route, Vector3(x, 0.16, 0.0), Vector2(0.33, 1.45), worn)
		for z in [-0.34, 0.34]:
			Kit.block(site, Vector3(x, 0.21, z), Vector3(0.27, 0.14, 0.22), wood).rotation.x = z * -1.2
	var reel := Kit.item(site, Vector3(0, 0.84, 0), REEL, Vector3.ZERO, Vector3(1.21, 1.30, 1.20))
	Kit.cylinder(reel, Vector3.ZERO, 0.36, 0.36, 0.97, cable).rotation.z = PI * 0.5
	for edge in [-1.0, 1.0]:
		Kit.cylinder(reel, Vector3(edge * 0.53, 0, 0), 0.68, 0.68, 0.16, wood).rotation.z = PI * 0.5
		Kit.cylinder(reel, Vector3(edge * 0.622, 0, 0), 0.113, 0.113, 0.045, metal).rotation.z = PI * 0.5
		for i in 4:
			var angle := TAU * i / 4.0 + 0.36
			var bolt := Vector3(edge * 0.619, sin(angle) * 0.46, cos(angle) * 0.46)
			Kit.cylinder(reel, bolt, 0.022, 0.022, 0.032, metal).rotation.z = PI * 0.5
	var windings := PackedVector3Array()
	for i in range(15 * 20 + 1):
		var angle := TAU * i / 20.0
		windings.append(Vector3(lerpf(-0.45, 0.45, i / 300.0), cos(angle) * 0.365, sin(angle) * 0.365))
	Kit.cord(reel, windings, 0.028, cable)
	Kit.cord(reel, PackedVector3Array([
		windings[-1], Vector3(0.41, 0.36, 0.21), Vector3(0.31, 0.27, 0.40),
		Vector3(0.09, 0.16, 0.57), Vector3(-0.16, 0.07, 0.64),
	]), 0.028, cable)

static func build_splice(site: Node3D, route, pole: Vector3):
	site.name = SPLICE
	var wood := Refuge.wood("675749")
	var siding := Refuge.wood("7b6d56")
	var metal := Kit.material("575e55")
	var block := Stone.paint("807666")
	var wire := Kit.material("48463e")
	footing(site, route, Vector3(0, 0.22, 0), Vector2(2.16, 1.44), block)
	Signage.solid(site, Vector3(0.0, 1.04, -0.58), Vector3(1.98, 1.65, 0.19), siding)
	for x in [-0.93, 0.93]:
		Signage.solid(site, Vector3(x, 1.04, -0.07), Vector3(0.17, 1.65, 1.15), wood)
	var roof := Signage.solid(site, Vector3(0, 1.92, -0.04), Vector3(2.39, 0.13, 1.60), metal)
	roof.rotation.x = 0.126
	for x in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		Kit.block(roof, Vector3(x, 0.073, 0), Vector3(0.044, 0.042, 1.60), metal)
	var panel := Signage.solid(site, Vector3(-0.16, 1.08, -0.41), Vector3(0.91, 0.74, 0.15), metal, SPLICE)
	Kit.block(panel, Vector3(0.28, -0.12, 0.128), Vector3(0.15, 0.036, 0.043), metal)
	Signage.printed_face(panel, Vector3(0, 0, 0.0755), Vector2(0.77, 0.58), Color("#737769"),
		[[Vector2(0, 0.108), "EMPALME 23", 0.077, Color("#ded1ac")]])
	Kit.cord(site, PackedVector3Array([
		site.to_local(pole + Vector3.UP * 2.72), Vector3(0.98, 2.03, 0.71),
		Vector3(0.66, 1.75, 0.49), Vector3(0.49, 1.49, 0.04),
		Vector3(0.24, 1.30, -0.32),
	]), 0.026, wire)

static func build_face(site: Node3D, route):
	site.name = FACE
	var faces := Stone.surface()
	var anchors := Callable(route, "terrain_point")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2709
	# Las dos gradas conservan el borde recto del corte y se abren contra el talud.
	quarry_step(site, route, faces, 3.8, -0.4, 1.25, Color("#85796b"), true)
	quarry_step(site, route, faces, 2.9, -1.72, 2.24, Color("#796d61"))
	for shoulder in [Vector3(-3.35, 0, -2.75), Vector3(3.24, 0, -2.85), Vector3(0.92, 0, -4.22)]:
		var rock: Vector3 = anchors.call(site.to_global(shoulder))
		var profile := Vector3(rng.randf_range(3.4, 4.2), rng.randf_range(1.44, 2.47), rng.randf_range(3.1, 4.0))
		var mass := Stone.fragment(faces, rock, profile, rng.randf() * TAU, rng, anchors)
		Stone.solid(site.get_parent(), rock, mass, "Talud de la cantera", FACE)
	for i in 9:
		var x := -3.65 + 0.87 * i + rng.randf_range(-0.28, 0.28)
		var loose: Vector3 = anchors.call(site.to_global(Vector3(x, 0, rng.randf_range(0.1, 1.40))))
		var scale_m := rng.randf_range(0.21, 0.48)
		var chips := Stone.fragment(faces, loose, Vector3(1.3, 0.65, 1.0) * scale_m, rng.randf() * TAU, rng, anchors)
		if i % 3 == 0: Stone.solid(site.get_parent(), loose, chips, "Desprendimiento")
	Stone.finish(site.get_parent(), faces, "Bancos de granito")
	var wedge := PrismMesh.new()
	wedge.size = Vector3(0.069, 0.148, 0.16)
	wedge.left_to_right = 0.71
	var iron := Kit.mesh_part(site, wedge, Vector3(BORE_SPACING, 0.72, -0.359), Kit.material("806052", false, 0.9))
	iron.rotation.x = -0.40

static func quarry_step(site: Node3D, route, faces: SurfaceTool, half_width: float, front: float, height: float, stone: Color, engraved := false):
	var top := [
		Vector3(-half_width, height - 0.42, front - 0.32), Vector3(-half_width * 0.69, height - 0.14, front),
		Vector3(-half_width * 0.24, height - 0.04, front), Vector3(half_width * 0.21, height, front),
		Vector3(half_width * 0.67, height - 0.13, front), Vector3(half_width, height - 0.34, front - 0.37),
		Vector3(half_width + 0.12, height - 0.53, front - 1.54), Vector3(half_width * 0.49, height - 0.39, front - 2.79),
		Vector3(-half_width * 0.36, height - 0.24, front - 2.86), Vector3(-half_width - 0.28, height - 0.49, front - 1.80),
	]
	var rim := PackedVector3Array()
	var base := PackedVector3Array()
	for point in top:
		var world := site.to_global(point)
		rim.append(world)
		base.append(route.terrain_point(world) - Vector3.UP * 0.22)
	for i in rim.size():
		var j := (i + 1) % rim.size()
		var tint := stone.darkened(0.10 * (i % 3))
		if engraved and i in [1, 2, 3]:
			chisel_face(site, route, faces, top[i], top[j], tint)
			continue
		Stone.triangle(faces, rim[i], rim[j], base[i], tint)
		Stone.triangle(faces, rim[j], base[j], base[i], tint)
	var crown := site.to_global(Vector3(0, height - 0.10, front - 1.25))
	for i in rim.size():
		Stone.triangle(faces, crown, rim[(i + 1) % rim.size()], rim[i], stone.lightened(0.08 + 0.03 * (i % 3)))
	rim.append_array(base)
	Stone.solid(site.get_parent(), site.global_position, rim, FACE, FACE)

static func chisel_face(site: Node3D, route, faces: SurfaceTool, left: Vector3, right: Vector3, tint: Color):
	var cuts: Array[float] = [left.x, right.x]
	for i in range(9):
		var bore := BORE_START + BORE_SPACING * i
		for fraction in [-1.0, -0.65, 0.0, 0.65, 1.0]:
			var x: float = bore + BORE_RADIUS * fraction
			if x > left.x and x < right.x: cuts.append(x)
	cuts.sort()
	var rows: Array[PackedVector3Array] = []
	var recesses := PackedFloat32Array()
	for x in cuts:
		var lip := left.lerp(right, inverse_lerp(left.x, right.x, x))
		var nearest := clampi(roundi((x - BORE_START) / BORE_SPACING), 0, 8)
		var gap := (x - BORE_START - nearest * BORE_SPACING) / BORE_RADIUS
		var depth := sqrt(maxf(0.0, 1.0 - gap * gap)) * BORE_DEPTH
		var top := site.to_global(lip)
		var base: Vector3 = route.terrain_point(top) - Vector3.UP * 0.22
		var reach := minf(0.48 + 0.15 * sin(nearest * 1.7), (top.y - base.y) * 0.78)
		rows.append(PackedVector3Array([top,
			site.to_global(lip - Vector3(0, 0.055, depth)),
			site.to_global(lip - Vector3(0, reach - 0.07, depth * 0.93)),
			site.to_global(lip - Vector3(0, reach, 0)), base]))
		recesses.append(depth)
	for i in range(rows.size() - 1):
		var a := rows[i]
		var b := rows[i + 1]
		for row in range(a.size() - 1):
			var shade := tint.darkened((recesses[i] + recesses[i + 1]) / (2.0 * BORE_DEPTH) * 0.33) if row in [1, 2] else tint
			Stone.triangle(faces, a[row], b[row], a[row + 1], shade)
			Stone.triangle(faces, b[row], b[row + 1], a[row + 1], shade)

static func dress_winch(parent: Node3D, end: Vector3):
	var steel := Kit.material("53574e", false, 0.81)
	var rust := Kit.material("745648", false, 0.89)
	var cable := Kit.material("494542")
	var machine := Node3D.new()
	machine.name = "Tambor del malacate"
	parent.add_child(machine)
	machine.position = end + Vector3(0, 0.85, -1.45)
	var drum := Kit.item(machine, Vector3.ZERO, "", Vector3.ZERO, Vector3(1.63, 0.66, 0.63))
	Kit.cylinder(drum, Vector3.ZERO, 0.23, 0.23, 1.26, steel).rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:
		Kit.cylinder(drum, Vector3(side * 0.64, 0, 0), 0.31, 0.31, 0.10, rust).rotation.z = PI * 0.5
		Kit.cylinder(drum, Vector3(side * 0.79, 0, 0), 0.081, 0.081, 0.30, steel).rotation.z = PI * 0.5
		Kit.block(machine, Vector3(side * 0.92, -0.07, 0.10), Vector3(0.18, 0.23, 0.48), rust)
		for z in [-0.092, 0.092]:
			Kit.cylinder(machine, Vector3(side * 0.94, 0.053, z), 0.023, 0.026, 0.029, steel)
	var windings := PackedVector3Array()
	for i in range(16 * 14 + 1):
		var phase := TAU * i / 14.0
		windings.append(Vector3(lerpf(-0.57, 0.57, i / 224.0), cos(phase) * 0.246, sin(phase) * 0.246))
	Kit.cord(drum, windings, 0.026, cable)
