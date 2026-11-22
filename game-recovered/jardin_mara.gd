extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Flora = preload("res://flora.gd")
const Refuge = preload("res://refugio.gd")
const Stone = preload("res://piedra_serrana.gd")

static func dress(yard: Node3D):
	var garden := Node3D.new()
	garden.name = "Jardín del puesto de Mara"
	yard.add_child(garden)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23671
	flowerbed(garden, Vector3(-2.31, 0, -3.55), Vector2(1.12, 0.51), rng)
	flowerbed(garden, Vector3(2.27, 0, -3.23), Vector2(1.08, 0.54), rng)
	fence(garden, rng)
	for site: Vector3 in [
		Vector3(-4.64, 5.65, -7.15), Vector3(4.43, 5.12, -8.0),
		Vector3(-7.82, 6.35, -9.76), Vector3(7.86, 5.21, -11.48),
	]:
		pine(garden, Vector3(site.x, 0, site.z), site.y, rng)

static func flowerbed(garden: Node3D, at: Vector3, span: Vector2, rng: RandomNumberGenerator):
	var bed := Node3D.new()
	bed.name = "Cantero de piedra"
	garden.add_child(bed, true)
	bed.position = at
	var soil := CylinderMesh.new()
	soil.top_radius = 1.0
	soil.bottom_radius = 1.0
	soil.height = 0.107
	soil.radial_segments = 26
	var mound := Kit.mesh_part(bed, soil, Vector3.UP * 0.05, Kit.material("514234"))
	mound.scale = Vector3(span.x, 1.0, span.y)
	var stones := Stone.surface()
	for i in 15:
		var angle := TAU * i / 15
		var rim := Vector3(cos(angle) * span.x, -0.042, sin(angle) * span.y)
		var size := Vector3(rng.randf_range(0.28, 0.37), rng.randf_range(0.15, 0.22), rng.randf_range(0.22, 0.33))
		var tangent := atan2(-cos(angle) * span.y, -sin(angle) * span.x)
		var stone := Stone.fragment(stones, rim, size, tangent + rng.randf_range(-0.20, 0.20), rng,
			Callable(), Stone.LAJA_PROFILE, true)
		Stone.solid(bed, rim, stone, "Borde del cantero")
	Stone.finish(bed, stones, "Lajas del cantero")
	var stems := SurfaceTool.new()
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tuft in 20:
		var angle := TAU * tuft / 20.0 + rng.randf_range(-0.27, 0.27)
		var radius := rng.randf_range(0.24, 0.84)
		var loam := Vector3(cos(angle) * span.x * radius, 0.094, sin(angle) * span.y * radius)
		var palette := [Color("dca140"), Color("e0c993"), Color("bb795e"), Color("a08da8")]
		var tint: Color = palette[floori(tuft * 0.25) % palette.size()]
		bloom(stems, loam, rng.randf_range(0.14, 0.53), tint, rng)
	Flora.plant_batch(bed, stems.commit(), "Flores del cantero")

static func bloom(surface: SurfaceTool, foot: Vector3, height: float, tint: Color, rng: RandomNumberGenerator):
	var turn := rng.randf_range(0.0, TAU)
	var along := Vector3(cos(turn), 0.0, sin(turn))
	var across := Vector3(-along.z, 0.0, along.x)
	var olive := Color("536551")
	var leaf := Color("7b8b5f")
	var crown := foot + Vector3.UP * height + along * rng.randf_range(0.025, 0.09)
	var stalk := foot.lerp(crown, 0.54) - along * 0.022
	for side in [along, across]:
		Flora.ribbon(surface, foot, stalk, crown, side, 0.009, olive.darkened(0.18), olive, 0.78)
	for i in 4:
		var root := foot.lerp(crown, 0.14 + i * 0.16)
		var direction := Basis(Vector3.UP, i * 2.30) * along
		var reach := rng.randf_range(0.07, 0.15) * (0.54 + height)
		Flora.ribbon(surface, root, root + (direction + Vector3.UP * 0.49) * reach * 0.6,
			root + (direction + Vector3.UP * 0.24) * reach, Vector3(-direction.z, 0, direction.x),
			0.018 * (0.75 + height), olive, leaf, 1.04)
	var normal := (Vector3.UP * 0.78 + along * 0.63).normalized()
	var radius := rng.randf_range(0.033, 0.057)
	for petal in 7:
		var angle := TAU * petal / 7.0 + turn
		var direction := across.rotated(normal, angle)
		var axis := normal.cross(direction)
		var shade := tint.darkened(0.28)
		var tip := crown + direction * radius + normal * 0.007
		var mid := crown + direction * radius * 0.64
		for vertex in [crown, mid - axis * (radius * 0.25), tip, crown, tip, mid + axis * (radius * 0.25)]:
			surface.set_normal(normal)
			surface.set_color(shade if vertex == crown else tint)
			surface.add_vertex(vertex)
		var inner := crown + normal * 0.008
		var seed := Color("815332") if tint.r > 0.77 else Color("b78c55")
		for vertex in [inner, inner + direction * radius * 0.27, inner + across.rotated(normal, angle + TAU / 7.0) * radius * 0.27]:
			surface.set_normal(normal)
			surface.set_color(seed)
			surface.add_vertex(vertex)

static func fence(garden: Node3D, rng: RandomNumberGenerator):
	var enclosure := Node3D.new()
	enclosure.name = "Cerca de madera"
	garden.add_child(enclosure)
	var weathered := [Refuge.wood("84725b", true), Refuge.wood("756653", true)]
	var end_grain := Refuge.wood("685849")
	var iron := Kit.material("555249", false, 0.60)
	for side in [-1.0, 1.0]:
		var line := PackedVector3Array([
			Vector3(1.43 * side, 0, -0.49), Vector3(3.44 * side, 0, -0.50),
			Vector3(5.59 * side, 0, -0.63), Vector3(5.83 * side, 0, -2.37),
			Vector3(5.83 * side, 0, -4.42), Vector3(5.88 * side, 0, -6.56),
		])
		for i in line.size():
			var height := rng.randf_range(0.84, 1.03)
			var post := Kit.item(enclosure, line[i], "", Vector3.UP * height * 0.5, Vector3(0.145, height, 0.151))
			post.name = "Poste"
			Kit.block(post, Vector3.UP * (height - 0.045) * 0.5, Vector3(0.145, height - 0.045, 0.151), end_grain)
			Kit.block(post, Vector3.UP * (height - 0.062), Vector3(0.158, 0.079, 0.165), weathered[i % 2]).rotation.z = (i % 3 - 1) * 0.13
			for y in [0.34, 0.69]:
				Kit.block(post, Vector3(0.0, y, 0.090), Vector3(0.029, 0.031, 0.024), iron)
			if i == 0: continue
			var span := line[i] - line[i - 1]
			for j in 2:
				var mid := (line[i] + line[i - 1]) * 0.5 + Vector3.UP * (0.34 + j * 0.35)
				var size := Vector3(span.length() - 0.10, 0.124, 0.081)
				var rail := Kit.item(enclosure, mid, "", Vector3.ZERO, size)
				rail.name = "Travesaño"
				rail.rotation = Vector3(0.0, atan2(-span.z, span.x), rng.randf_range(-0.017, 0.017))
				Kit.block(rail, Vector3.ZERO, size, weathered[(i + j) % 2])

static func pine(garden: Node3D, foot: Vector3, height: float, rng: RandomNumberGenerator):
	var tree := Node3D.new()
	tree.name = "Pino"
	garden.add_child(tree, true)
	tree.position = foot
	var top := Vector3(rng.randf_range(-0.21, 0.21), height, rng.randf_range(-0.16, 0.17))
	var fork := top * 0.48
	Flora.branch(tree, Vector3.DOWN * 0.05, fork, 0.15, 0.084, true)
	Flora.branch(tree, fork, top, 0.084, 0.016)
	var tones := ["485642", "56674a", "65714f", "43513e"]
	var phase := rng.randf_range(0.0, TAU)
	for tier in 6:
		var ratio := tier / 5.0
		var start := top * lerpf(0.38, 0.94, ratio)
		var reach := height * lerpf(0.215, 0.035, ratio)
		var branches := 5 if tier < 4 else 3
		for arm in branches:
			var angle := phase + arm * TAU / branches + tier * 1.12 + rng.randf_range(-0.22, 0.22)
			var outward := Vector3(cos(angle), 0, sin(angle))
			var length := reach * rng.randf_range(0.79, 1.19)
			var tip := start + outward * length - Vector3.UP * (0.20 * length)
			Flora.branch(tree, start, tip, 0.036 * (1.0 - ratio * 0.63), 0.008)
			Flora.crown(tree, rng, start.lerp(tip, 0.59) + Vector3.UP * 0.09,
				Vector3(1.15, 0.47 + 0.14 * ratio, 0.76) * length, tones[(arm + tier) % tones.size()], -angle)
			Flora.crown(tree, rng, tip + outward * (0.09 * length) + Vector3.UP * 0.044,
				Vector3(0.74, 0.37, 0.58) * length, tones[(arm + tier + 1) % tones.size()], -angle)
	Flora.crown(tree, rng, top - Vector3.UP * 0.22, Vector3(0.40, 0.70, 0.40), tones[1], phase)
