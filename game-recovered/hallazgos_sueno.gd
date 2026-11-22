extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Visual = preload("res://hallazgo_visual.gd")

const FINDS = {
	"sueno_diapa": [0, "Horquilla de dos puntas", Vector2(-43, -47), "Entre las estrías azules. Las puntas curvas nunca se tocan. Oí un zumbido al acercarme y se cortó justo cuando dibujé la separación.", 1],
	"sueno_prisma": [1, "Prisma en dos aros", Vector2(34, -102), "En el hueco de las agujas. Un aro está roto. La piedra del centro cambia de color al mirar por la rotura. Dibujé el soporte antes de que se me olvidara.", 1],
	"sueno_espiral": [2, "Placa en espiral", Vector2(-40, -74), "En una terraza cobriza. Los surcos se estrechan hacia el centro. Parecen pistas sobre una placa. Cada vez que me agachaba contaba una menos.", 2],
	"sueno_jaula": [3, "Armazón vacío", Vector2(42, -118), "En el cuenco oscuro. Los bordes se encuentran sin soldaduras. Hay un lado abierto y del otro sale un hilo frío. Yo esperaba encontrar algo en el medio.", 2],
	"sueno_semilla": [4, "Cápsula estriada", Vector2(-51, -65), "En el nido mineral. Tiene una costilla color hueso y surcos verdes. Parece una semilla hasta que uno se fija en las uniones.", 3],
	"sueno_lamina": [5, "Fragmento de obsidiana", Vector2(49, -108), "En el pliegue negro. Le falta un pedazo y en el canto se ven tres hilos separados. Los dibujé como pude. En el suelo, los tres apuntaban hacia el mismo lado.", 3],
}
const SITES = [
	[["Estrías azules", Vector2(-43, -47)], ["Agujas huecas", Vector2(34, -102)]],
	[["Terrazas de cobre", Vector2(-40, -74)], ["Cuenco negro", Vector2(42, -118)]],
	[["Nido mineral", Vector2(-51, -65)], ["Pliegue de obsidiana", Vector2(49, -108)]],
]

static func luminous(tint: String, light: float = 0.50) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint)
	mat.metallic = 0.42
	mat.roughness = 0.41
	mat.emission_enabled = true
	mat.emission = Color(tint)
	mat.emission_energy_multiplier = light
	return mat

static func strut(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material):
	var bar := Kit.cylinder(parent, a.lerp(b, 0.5), radius, radius * 0.86, a.distance_to(b), mat)
	bar.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

static func beam_path(parent: Node3D, points: PackedVector3Array, radius: float, material: Material):
	for i in range(1, points.size()):
		strut(parent, points[i - 1], points[i], radius, material)

static func loop(parent: Node3D, center: Vector3, radius: float, height: float, width: float, material: Material, segments: int = 18, end: float = TAU):
	var points := PackedVector3Array()
	for j in segments + 1:
		var a := float(j) / segments * end
		points.append(center + Vector3(radius * cos(a), height * sin(a), 0))
	beam_path(parent, points, width, material)

static func artifact(parent: Node3D) -> Node3D:
	var instrument := Node3D.new()
	instrument.name = "Artefacto"
	parent.add_child(instrument)
	var metal := Kit.material("364956", false, 0.42)
	var edge := luminous("5da6b8", 0.46)
	var fibre := luminous("9adcdf", 0.82)
	var cap := SphereMesh.new()
	cap.radius = 0.031
	cap.height = 0.059
	cap.radial_segments = 6
	cap.rings = 2
	for scale in [1.0, 0.59]:
		var e: float = 0.218 * scale
		var shift := Vector3(0.059, 0.045, -0.025) * (1.0 - float(scale))
		for i in 8:
			var a := Vector3(-e if i & 1 == 0 else e, -e if i & 2 == 0 else e, -e if i & 4 == 0 else e)
			Kit.mesh_part(instrument, cap, a + shift, metal).scale = Vector3.ONE * scale
			for bit in [1, 2, 4]:
				if i & bit: continue
				var b := a
				b[0 if bit == 1 else (1 if bit == 2 else 2)] = e
				strut(instrument, a + shift, b + shift, 0.017 * scale, metal)
				if (i + bit) % 3 == 0:
					var seam := Vector3(0.004, 0.009, 0.010)
					strut(instrument, a.lerp(b, 0.14) + shift + seam, a.lerp(b, 0.79) + shift + seam, 0.008 * scale, edge)
	var seed := Kit.mesh_part(instrument, cap, Vector3(0.019, 0.023, -0.012), fibre)
	seed.scale = Vector3(0.96, 1.83, 0.84)
	seed.rotation.z = 0.51
	return instrument

static func artifact_glow(parent: Node3D):
	var halo_colors := Gradient.new()
	halo_colors.offsets = PackedFloat32Array([0.0, 0.26, 0.64, 1.0])
	halo_colors.colors = PackedColorArray([Color(0.47, 0.87, 0.95, 0.43), Color(0.39, 0.75, 0.87, 0.20),
		Color(0.29, 0.63, 0.77, 0.064), Color(0.29, 0.63, 0.77, 0.0)])
	var falloff := GradientTexture2D.new()
	falloff.gradient = halo_colors
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(0.5, 0.99)
	var glow := Sprite3D.new()
	glow.texture = falloff
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.pixel_size = 0.021
	glow.render_priority = -1
	parent.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color("7ec9dd")
	light.light_energy = 0.53
	light.omni_range = 2.4
	parent.add_child(light)

static func chip(parent: Node3D, outline: PackedVector2Array, top: float, material: Material) -> MeshInstance3D:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangulated := Geometry2D.triangulate_polygon(outline)
	for i in triangulated:
		var p := outline[i]
		mesh.add_vertex(Vector3(p.x, top, p.y))
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var v := Vector3(a.x, top, a.y)
		var w := Vector3(b.x, top, b.y)
		for point in [v, w, w - Vector3.UP * 0.09, v, w - Vector3.UP * 0.09, v - Vector3.UP * 0.09]:
			mesh.add_vertex(point)
	mesh.generate_normals()
	return Kit.mesh_part(parent, mesh.commit(), Vector3.ZERO, material)

static func build_find(parent: Node3D, id: String, at: Vector3):
	var entry: Array = FINDS[id]
	var root := Kit.item(parent, at, entry[1], Vector3(0, 0.24, 0), Vector3(0.68, 0.52, 0.59))
	root.collision_layer = 2
	root.collision_mask = 0
	root.set_meta("find_id", id)
	root.add_to_group("field_finds")
	root.rotation.y = -0.20 + entry[0] * 0.41
	var brass := Kit.material("746057", false, 0.67)
	var nickel := Kit.material("46515a", false, 0.60)
	var blue := luminous("68a7a6")
	var violet := luminous("a88ebd", 0.31)
	var pale := luminous("c6b7a1", 0.18)
	match int(entry[0]):
		0:
			for side in [-1.0, 1.0]:
				beam_path(root, PackedVector3Array([Vector3(0,0.11,0), Vector3(side*0.16,0.21,0), Vector3(side*0.26,0.33,0), Vector3(side*0.27,0.48,-0.029), Vector3(side*0.21,0.54,-0.042)]), 0.028, blue)
			strut(root, Vector3(0,0.025,0.026), Vector3(0,0.14,0.00), 0.046, nickel)
		1:
			var prism := CylinderMesh.new()
			prism.radial_segments = 3
			prism.top_radius = 0.17
			prism.bottom_radius = 0.18
			prism.height = 0.35
			Kit.mesh_part(root, prism, Vector3(0, 0.25, 0), violet).rotation.x = 0.84
			loop(root, Vector3(0, 0.27, -0.14), 0.22, 0.19, 0.023, nickel)
			loop(root, Vector3(0, 0.25, 0.14), 0.22, 0.19, 0.023, nickel, 17, 5.22)
		2:
			var shape := PackedVector2Array([Vector2(-0.24,-0.21),Vector2(0.22,-0.23),Vector2(0.23,-0.09),Vector2(0.29,0.06),Vector2(0.18,0.24),Vector2(-0.22,0.21),Vector2(-0.26,0.10)])
			chip(root, shape, 0.142, brass)
			var spiral := PackedVector3Array()
			for i in 53:
				var a := i * 0.34
				var r := 0.023 + i * 0.00335
				spiral.append(Vector3(r * cos(a), 0.146, r * sin(a)))
			beam_path(root, spiral, 0.008, pale)
		3:
			var corners := [Vector3(0,0.54,0),Vector3(0,0.06,0),Vector3(0.27,0.31,0),Vector3(0,0.31,0.23),Vector3(-0.27,0.31,0),Vector3(0,0.31,-0.23)]
			for i in range(2, 6):
				for j in [0, 1, 2 + (i - 1) % 4]:
					strut(root, corners[i], corners[j], 0.018, blue if i % 2 == 0 else nickel)
		4:
			dress_capsule(root, blue, nickel, pale)
		5:
			var outline := PackedVector2Array([Vector2(-0.28,-0.13),Vector2(0.11,-0.19),Vector2(0.29,-0.10),Vector2(0.15,-0.03),Vector2(0.27,0.10),Vector2(0.14,0.17),Vector2(-0.23,0.14)])
			chip(root, outline, 0.153, nickel)
			for i in 3:
				strut(root, Vector3(-0.22,0.162,-0.085+i*0.065), Vector3(0.19-i*0.023,0.162,-0.098+i*0.065), 0.006, pale)
	Visual.glint(root, Vector3(0.09, 0.26 if entry[0] in [2, 4, 5] else 0.49, 0.14), Color("#bee8ee"))


static func dress_capsule(root: Node3D, body: Material, grooves: Material, rib: Material):
	var capsule := Node3D.new()
	root.add_child(capsule)
	capsule.rotation.z = -0.55
	var profile: Array[Vector4] = [Vector4(0.019,0.016,0.018,0),Vector4(0.061,0.096,0.061,0),
		Vector4(0.145,0.154,0.104,0),Vector4(0.245,0.170,0.118,0),Vector4(0.333,0.130,0.090,0),
		Vector4(0.414,0.076,0.053,0),Vector4(0.474,0.024,0.023,0),Vector4(0.488,0.012,0.009,0)]
	Kit.shell(capsule, profile, body, 0.87)
	for i in 8:
		var angle := TAU * i / 8.0
		var ridge := PackedVector3Array()
		for cut in profile:
			ridge.append(Vector3(cos(angle) * (cut.y + 0.009), cut.x, sin(angle) * (cut.z + 0.011)))
		beam_path(capsule, ridge, 0.009, grooves)
	var crescent := PackedVector3Array([Vector3(-0.027,0.041,0.029),Vector3(-0.094,0.087,0.076),
		Vector3(-0.138,0.165,0.103),Vector3(-0.130,0.263,0.107),Vector3(-0.089,0.342,0.084),
		Vector3(-0.047,0.401,0.054), Vector3(-0.008,0.448,0.030)])
	beam_path(capsule, crescent, 0.020, rib)
