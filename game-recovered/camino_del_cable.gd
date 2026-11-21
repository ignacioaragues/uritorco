extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Signage = preload("res://carteleria.gd")
const Stone = preload("res://piedra_serrana.gd")

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
	build_reel(roadside(section, route, 0.52, 3.15), route)
	const SPLICE_POLE := 23.0 / 32.0
	var splice := roadside(section, route, SPLICE_POLE, -3.85)
	var pole: Vector3 = route.terrain_point(route.quarry_point(SPLICE_POLE))
	build_splice(splice, route, pole)
	build_face(roadside(section, route, 0.93, 5.4), route)

static func roadside(parent: Node3D, route, progress: float, offset: float) -> Node3D:
	var center: Vector3 = route.quarry_point(progress)
	var tangent: Vector3 = route.quarry_point(progress + 0.005) - route.quarry_point(progress - 0.005)
	var side := Vector3(tangent.z, 0, -tangent.x).normalized()
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
	Kit.block(panel, Vector3(0, 0, 0.095), Vector3(0.77, 0.58, 0.036), Kit.material("737769"))
	Kit.block(panel, Vector3(0.28, -0.12, 0.128), Vector3(0.15, 0.036, 0.043), metal)
	Signage.lettering(panel, Vector3(0, 0.13, 0.116), "EMPALME 23", 0.077, Color("#ded1ac"))
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
	quarry_step(site, route, faces, 3.8, -0.4, 1.25, Color("#85796b"))
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
	var groove := Stone.paint("554b44")
	for x in [-2.46, -1.84, -1.23, -0.61, 0.0, 0.65, 1.28, 1.91, 2.53]:
		var height := rng.randf_range(0.32, 0.67)
		Kit.block(site, Vector3(x, 1.12 - height * 0.5, -0.368), Vector3(0.054, height, 0.031), groove)
	Kit.block(site, Vector3(0.66, 0.63, -0.305), Vector3(0.038, 0.16, 0.18), Kit.material("785745")).rotation.x = -0.4

static func quarry_step(site: Node3D, route, faces: SurfaceTool, half_width: float, front: float, height: float, stone: Color):
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
		Stone.triangle(faces, rim[i], rim[j], base[i], tint)
		Stone.triangle(faces, rim[j], base[j], base[i], tint)
	var crown := site.to_global(Vector3(0, height - 0.10, front - 1.25))
	for i in rim.size():
		Stone.triangle(faces, crown, rim[(i + 1) % rim.size()], rim[i], stone.lightened(0.08 + 0.03 * (i % 3)))
	rim.append_array(base)
	Stone.solid(site.get_parent(), site.global_position, rim, FACE, FACE)
