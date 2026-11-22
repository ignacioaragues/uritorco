extends RefCounted

const Creek = preload("res://cauce.gd")
const Flora = preload("res://flora.gd")
const Stone = preload("res://piedra_serrana.gd")
const Kit = preload("res://equipo_campo.gd")
const LOG := 0.18
const LEDGE := 0.64

static func build(valley):
	for junction in [
		[Creek.crossing_point(0.01) + Vector3(-3.1, 0, -1.2), "Pasarela · Quebrada sur →", 0.34],
		[Vector3(-35, 0, 43.8), "Pasarela · sendero alto ←", -0.25],
		[Vector3(-61, 0, 49), "Puesto · por el poste →", 2.7],
	]:
		var pos: Vector3 = junction[0]
		valley.route.signpost(pos, junction[1], junction[2], true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8421
	var cairn_rng := RandomNumberGenerator.new()
	cairn_rng.seed = 19432
	var rocks := Stone.surface()
	var tufts: Array[Vector4] = []
	for i in range(2, 39):
		var t := i / 40.0
		var foot := Creek.crossing_point(t)
		var heading := forward(t)
		var side := Vector3(heading.z, 0, -heading.x)
		if i % 3 == 0:
			var center := ground(foot + side * (2.28 if i % 2 == 0 else -2.28))
			Stone.cairn(valley, rocks, center, ground, cairn_rng)
		for j in 4:
			var near := ground(foot + side * (rng.randf_range(2.5, 7.6) * (-1.0 if j % 2 == 0 else 1.0)) + heading * rng.randf_range(-2.3, 2.3))
			tufts.append(Vector4(near.x, near.y - 0.04, near.z, rng.randf_range(0.61, 1.58)))
		if i % 4 == 0:
			var shoulder := ground(foot + side * (rng.randf_range(4.5, 9.3) * (-1 if i % 8 == 0 else 1)))
			Flora.tree(valley, shoulder, Flora.Kind.TALA if i > 21 else Flora.Kind.ESPINILLO, rng.randf_range(0.84, 1.35), rng.randf() * TAU)
		if i % 5 == 2:
			var base := ground(foot - side * (5.20 if i % 2 == 0 else -5.20))
			var block := Stone.fragment(rocks, base, Vector3(2.6, 0.92, 1.8), i * 1.09, cairn_rng, ground)
			Stone.solid(valley, base, block, "Laja de la quebrada")
	Stone.finish(valley, rocks, "Piedras de la quebrada")
	Flora.grass_batch(valley, tufts)
	dress_log(valley)
	dress_ledge(valley)
	dress_bridge(valley, rng)
	dress_banks(valley)

static func dress_banks(valley):
	var rng := RandomNumberGenerator.new()
	rng.seed = 62352
	var south_path := Creek.crossing_trace()
	var rule := Creek.marker()
	var bridge := Creek.crossing_point(1.0)
	for start in [-162, -110, -58, -6]:
		var roots: Array[Vector4] = []
		for i in range(7):
			var center := float(start) + i * 6.7 + rng.randf_range(-2.0, 2.0)
			var bank := -1.0 if i % 3 == 0 else 1.0
			for tuft in rng.randi_range(5, 9):
				var x := center + rng.randf_range(-3.8, 3.8)
				var z := Creek.channel_z(x) + bank * (water_width(x) + rng.randf_range(0.35, 2.9))
				var at := Vector2(x, z)
				if at.distance_to(Vector2(rule.x, rule.z)) < 5.5 or absf(x - bridge.x) < 4.5: continue
				if Creek.trail_distance(at) < 1.9 or Creek.near_south_path(at, south_path, 2.65): continue
				var foot := ground(Vector3(x, 0.0, z))
				if foot.y < water_level(x) - 0.20: continue
				var rise := maxf(ground(foot + Vector3.BACK * 0.6).y, ground(foot + Vector3.FORWARD * 0.6).y) - foot.y
				if rise > 0.36: continue
				roots.append(Vector4(x, foot.y - 0.085, z, rng.randf_range(0.66, 1.18)))
		Flora.herb_batch(valley, roots, Flora.Herb.CORTADERA)

static func ground(at: Vector3) -> Vector3:
	return Creek.surface_point(at)

static func forward(t: float) -> Vector3:
	var direction := Creek.crossing_point(t + 0.01) - Creek.crossing_point(t - 0.01)
	return Vector3(direction.x, 0, direction.z).normalized()

static func beam(valley, a: Vector3, b: Vector3, width: float, height: float, tone: String, solid := false, label := "") -> MeshInstance3D:
	var board: MeshInstance3D = valley.box((a + b) * 0.5, Vector3(width, height, a.distance_to(b)), tone, solid, label)
	board.look_at(b, Vector3.FORWARD if absf((b - a).normalized().y) > 0.97 else Vector3.UP)
	valley.timber(board, true)
	return board

static func dress_log(valley):
	var foot := ground(Creek.crossing_point(LOG))
	var heading := forward(LOG)
	var cross := Vector3(heading.z, 0, -heading.x)
	var a := ground(foot - cross * 2.65) + Vector3.UP * 0.33
	var b := ground(foot + cross * 2.7) + Vector3.UP * 0.29
	var trunk := CylinderMesh.new()
	trunk.radial_segments = 10
	trunk.height = a.distance_to(b)
	trunk.bottom_radius = 0.28
	trunk.top_radius = 0.19
	var log: MeshInstance3D = valley.prop(trunk, (a + b) * 0.5, "685447", true, "Tronco caído")
	log.get_child(0).set_meta("footstep", &"wood")
	log.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	valley.timber(log)
	for i in 3:
		var root := b.lerp(a, 0.1 + 0.12 * i)
		beam(valley, root, root + heading * (0.38 + i * 0.12) + Vector3.UP * (0.27 - 0.04 * i), 0.09, 0.10, "6e5342")

static func dress_ledge(valley):
	var foot := ground(Creek.crossing_point(LEDGE))
	var heading := forward(LEDGE)
	var slab: MeshInstance3D = valley.box(foot + heading * 0.4 + Vector3.UP * 0.39, Vector3(3.6, 1.0, 1.8), "82756a", true, "Subir al escalón")
	slab.get_child(0).set_meta("footstep", &"stone")
	slab.rotation.y = atan2(heading.x, heading.z)
	slab.material_override = Stone.paint("82756a")
	var rocks := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 18128
	for side in [-1.0, 1.0]:
		var cross := Vector3(heading.z, 0, -heading.x) * float(side)
		var at := ground(foot + cross * 2.2 + heading * 0.84)
		var rock := Stone.fragment(rocks, at, Vector3(1.42, 1.04, 1.78), float(side) * 1.18, rng, ground)
		Stone.solid(valley, at, rock, "Hombro de la laja")
	Stone.finish(valley, rocks, "Laterales de la laja")

static func mark_position() -> Vector3:
	return ground(Creek.crossing_point(1.0)) + Vector3(1.02, 0.77, 0.92)

static func glimpse(valley: Node3D) -> Node3D:
	var figure := Node3D.new()
	figure.name = "Figura del otro lado"
	valley.add_child(figure)
	figure.position = ground(Creek.crossing_point(1.0) + Vector3(-1.66, 0, 17.4))
	figure.rotation.y = -0.18
	var shade := StandardMaterial3D.new()
	shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.albedo_color = Color("#171d20")
	Kit.shell(figure, [
		Vector4(0.48, 0.18, 0.11, -0.048), Vector4(0.92, 0.22, 0.15, -0.01),
		Vector4(1.34, 0.25, 0.145, 0.012), Vector4(1.46, 0.095, 0.092, 0.004)
	], shade, 0.62, true)
	var head := SphereMesh.new()
	head.radius = 0.111
	head.height = 0.27
	head.radial_segments = 9
	head.rings = 5
	Kit.mesh_part(figure, head, Vector3(-0.018, 1.57, 0.004), shade)
	for x in [-0.094, 0.094]:
		Kit.cylinder(figure, Vector3(x, 0.36, 0.0), 0.064, 0.102, 0.73, shade).rotation.z = x * 0.59
	return figure

static func dress_bridge(valley, rng: RandomNumberGenerator):
	var bank := ground(Creek.crossing_point(1.0))
	var deck := bank + Vector3.UP * 0.09
	for i in 20:
		var z := -0.50 + i * 0.41
		var tint: String = ["806a54", "8d775e", "6d5849"][i % 3]
		var width := 2.19 - (maxi(0, i - 16) * 0.27)
		var x := 0.0 if i < 17 else -0.15 * (i - 16)
		var board: MeshInstance3D = valley.box(deck + Vector3(x, 0, z), Vector3(width, 0.15, rng.randf_range(0.365, 0.40)), tint, true)
		board.get_child(0).set_meta("footstep", &"wood")
		board.rotation.y = rng.randf_range(-0.033, 0.033)
		valley.timber(board, true)
	for x in [-0.79, 0.79]:
		beam(valley, deck + Vector3(x, -0.15, -0.58), deck + Vector3(x, -0.22, 8.03), 0.19, 0.28, "574939", true)
		for z in [1.0, 4.3]:
			var base := ground(deck + Vector3(x, 0, z))
			beam(valley, base - Vector3.UP * 0.11, deck + Vector3(x, -0.10, z), 0.21, 0.21, "5f5148")
	for x in [-1.04, 1.04]:
		for z in [0.41, 3.4]:
			beam(valley, deck + Vector3(x, -0.24, z), deck + Vector3(x, 0.94, z), 0.14, 0.16, "745c49", true)
		beam(valley, deck + Vector3(x, 0.85, 0.36), deck + Vector3(x, 0.76, 3.82), 0.13, 0.16, "79644f", true)
	beam(valley, deck + Vector3(-0.94, 0.78, 4.76), deck + Vector3(0.93, 0.72, 4.57), 0.14, 0.16, "694f41", true)
	beam(valley, deck + Vector3(-0.94, 0.12, 4.76), deck + Vector3(-0.94, 0.80, 4.76), 0.12, 0.13, "705647", true)
	beam(valley, deck + Vector3(0.94, 0.12, 4.57), deck + Vector3(0.94, 0.75, 4.57), 0.12, 0.13, "705647", true)
	var marker := mark_position()
	var stake: MeshInstance3D = valley.box(marker - Vector3.UP * 0.24, Vector3(0.19, 0.83, 0.30), "b79e76", true, "Pasarela de la quebrada")
	valley.timber(stake)
	for line in 4:
		var longer := 0.20 if line == 2 else 0.12
		valley.box(marker + Vector3(-0.101, -0.09 - 0.095 * line, 0.025), Vector3(0.008, 0.015, longer), "514839")
	for i in range(-11, 12):
		var x := bank.x + i * 0.81
		var z := Creek.channel_z(x) + rng.randf_range(-3.1, 3.1)
		var stone_at := ground(Vector3(x, 0, z))
		var size := rng.randf_range(0.28, 0.82)
		valley.stone(stone_at + Vector3.UP * (0.08 * size), Vector3(1.21, 0.54, 0.93) * size, "767167")

static func water(valley) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := PackedVector3Array()
	for i in range(107):
		var x := -163.0 + i * 2
		var z := Creek.channel_z(x)
		var width := water_width(x)
		var height := water_level(x)
		var current := PackedVector3Array([Vector3(x, height, z - width), Vector3(x, height, z + width)])
		if i > 0:
			for vertex in [previous[0], current[0], previous[1], previous[1], current[0], current[1]]:
				surface.set_normal(Vector3.UP)
				surface.add_vertex(vertex)
		previous = current
	var stream := MeshInstance3D.new()
	stream.mesh = surface.commit()
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flow := ShaderMaterial.new()
	flow.shader = preload("res://arroyo.gdshader")
	flow.set_shader_parameter("sediment", 0.68)
	stream.material_override = flow
	valley.add_child(stream)
	return stream

static func water_width(x: float) -> float:
	return lerpf(5.2, 8.1, Creek.creek_extension(x)) + 0.65 * sin(x * 0.14)

static func water_level(x: float) -> float:
	var depth := 0.78 * smoothstep(-163.0, -155.0, x) * (1.0 - smoothstep(41.0, 49.0, x))
	return Creek.height(x, Creek.channel_z(x), false) + depth - 0.22 * (1.0 - smoothstep(0.0, 0.12, depth))

static func water_depth(pos: Vector3) -> float:
	if pos.x < -163.0 or pos.x > 49.0: return 0.0
	var x := floorf((pos.x + 163.0) * 0.5) * 2.0 - 163.0
	var t := (pos.x - x) * 0.5
	var center := lerpf(Creek.channel_z(x), Creek.channel_z(x + 2.0), t)
	if absf(pos.z - center) > lerpf(water_width(x), water_width(x + 2.0), t): return 0.0
	return maxf(0.0, lerpf(water_level(x), water_level(x + 2.0), t) - pos.y)
