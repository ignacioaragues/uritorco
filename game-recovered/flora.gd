extends RefCounted

enum Kind { MOLLE, ESPINILLO, TALA, PIQUILLIN }

const PALETTES = [
	["48513b", "606e47", "7a8552", "9b9861"],
	["596342", "70804d", "89945a", "c9a94e"],
	["414d3d", "556649", "748761", "9b9c65"],
	["514e3a", "67694e", "7c7957", "a49773"],
]
const BRUSH = preload("res://follaje.gdshader")

static func tree(parent: Node3D, foot: Vector3, kind: Kind, size: float, angle: float):
	var tree_root := Node3D.new()
	parent.add_child(tree_root)
	tree_root.position = foot
	tree_root.scale = Vector3.ONE * size
	tree_root.rotation.y = angle
	var palette: Array = PALETTES[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(foot.x * 193.0 - foot.z * 47.0)) + 17
	var scrub := kind == Kind.PIQUILLIN
	var fork := Vector3(0.09, 0.45 if scrub else 1.04, -0.07)
	if kind == Kind.TALA: fork = Vector3(-0.23, 1.36, 0.12)
	branch(tree_root, Vector3.DOWN * 0.21, fork, 0.074 if scrub else 0.16, 0.046 if scrub else 0.097, true)
	var boughs := 6 if kind in [Kind.MOLLE, Kind.PIQUILLIN] else 4
	for index in boughs:
		var turn := TAU * index / boughs + rng.randf_range(-0.21, 0.21)
		var direction := Vector3(cos(turn), 0, sin(turn))
		var reach := rng.randf_range(0.86, 1.32)
		var height := rng.randf_range(0.52, 1.13)
		if kind == Kind.MOLLE:
			reach *= 1.44
		elif kind == Kind.TALA:
			height *= 1.76
			reach *= 0.81
		elif scrub:
			height *= 0.44
			reach *= 0.72
		var elbow := fork + direction * reach * 0.55 + Vector3.UP * height * 0.54
		var twig := fork + direction * reach + Vector3.UP * height
		branch(tree_root, fork - Vector3.UP * (0.09 * (index % 3)), elbow, 0.038 if scrub else 0.082, 0.03 if scrub else 0.054)
		branch(tree_root, elbow, twig, 0.03 if scrub else 0.054, 0.014)
		var base_size := Vector3(1.38, 0.70, 1.16)
		if kind == Kind.ESPINILLO: base_size = Vector3(0.96, 0.42, 0.77)
		if kind == Kind.TALA: base_size = Vector3(0.96, 0.91, 0.82)
		if scrub: base_size = Vector3(0.74, 0.47, 0.66)
		for cluster in 3:
			var side := Vector3(-direction.z, 0.0, direction.x)
			var center := twig + direction * (0.14 + cluster * 0.08) + side * (cluster - 1.0) * base_size.x * 0.34
			center.y += (0.05 + 0.12 * cluster) * base_size.y
			crown(tree_root, rng, center, base_size * rng.randf_range(0.78, 1.18), palette[mini(cluster, 2)], turn)
			if not scrub:
				var tuft := center + side * base_size.x * rng.randf_range(-0.36, 0.36) + direction * base_size.z * 0.22
				tuft.y += base_size.y * 0.23
				crown(tree_root, rng, tuft, base_size * rng.randf_range(0.43, 0.65), palette[(index + cluster) % 3], turn)
			if kind == Kind.ESPINILLO and (index + cluster) % 2 == 0:
				var flower := center + direction * 0.27 + Vector3.UP * 0.14
				for petal in 3:
					var spread := Vector3(0.064 * petal, 0.055 * sin(petal * 1.6), 0.047 * petal)
					crown(tree_root, rng, flower + spread, Vector3(0.108, 0.086, 0.111), palette[3], turn)

static func branch(parent: Node3D, start: Vector3, end: Vector3, base: float, tip: float, solid := false):
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 0
	mesh.height = start.distance_to(end)
	mesh.bottom_radius = base
	mesh.top_radius = tip
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = bark_material()
	parent.add_child(instance)
	instance.position = (start + end) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	if solid: instance.create_convex_collision()

static func crown(parent: Node3D, rng: RandomNumberGenerator, center: Vector3, size: Vector3, tint: String, angle: float):
	var mesh := SphereMesh.new()
	mesh.radial_segments = 9
	mesh.rings = 5
	var leaf := MeshInstance3D.new()
	leaf.mesh = mesh
	leaf.material_override = leaf_material(tint, rng.randf_range(0.0, 27.0))
	parent.add_child(leaf)
	leaf.position = center
	leaf.rotation = Vector3(rng.randf_range(-0.2, 0.2), angle, rng.randf_range(-0.27, 0.27))
	leaf.scale = size

static func leaf_material(tint: String, pattern := 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BRUSH
	material.set_shader_parameter("tint", Color(tint))
	material.set_shader_parameter("pattern", pattern)
	return material

static func bark_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://grain.gdshader")
	material.set_shader_parameter("tint", Color("#685343"))
	material.set_shader_parameter("grain_strength", 0.24)
	material.set_shader_parameter("irregular", true)
	return material

static func crown_mesh(phase: float) -> ArrayMesh:
	var source := SphereMesh.new()
	source.radial_segments = 12
	source.rings = 6
	var arrays := source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for index in vertices.size():
		var vertex := vertices[index]
		var axis := vertex.normalized()
		var lobes := sin(axis.x * 5.2 + phase + axis.z * 2.1) * cos(axis.z * 4.5 - axis.y * 2.3)
		var fringe := sin(axis.y * 8.0 + axis.x * 5.4 - phase) * cos(axis.z * 7.3 + axis.x * 2.5)
		vertices[index] = vertex * (0.94 + 0.18 * lobes + 0.087 * fringe) + Vector3(axis.y * 0.048, axis.x * 0.041, 0.0)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var lobed := ArrayMesh.new()
	lobed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return lobed

static func grass_batch(parent: Node3D, roots: Array[Vector4]):
	if roots.is_empty(): return
	var meadow := MeshInstance3D.new()
	meadow.mesh = grass_mesh(roots)
	meadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	meadow.material_override = grass_material()
	parent.add_child(meadow)

static func grass_mesh(roots: Array[Vector4]) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var palette: Array[Color] = [Color("#76744d"), Color("#8c8152"), Color("#a09460"), Color("#b49f70")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 31311
	for patch in roots:
		var center := Vector3(patch.x, patch.y, patch.z)
		for i in range(9 if patch.w > 1.0 else 6):
			var angle := rng.randf_range(0.0, TAU)
			var direction := Vector3(cos(angle), 0, sin(angle))
			var side := Vector3(-direction.z, 0, direction.x)
			var foot := center + direction * rng.randf_range(0.04, 0.19) * patch.w
			var height := rng.randf_range(0.20, 0.53) * patch.w
			var bend := rng.randf_range(0.13, 0.33) * patch.w
			var width := rng.randf_range(0.014, 0.037) * patch.w
			var knee := foot + Vector3.UP * height * 0.61 + direction * bend * 0.28
			var tip := foot + Vector3.UP * height + direction * bend
			var lower := palette[i % 3].darkened(0.18)
			var outer := palette[1 + i % 3]
			var corners := [foot - side * width, foot + side * width, knee - side * width * 0.65, knee + side * width * 0.65, tip]
			for vertex in [0, 1, 2, 2, 1, 3, 2, 3, 4]:
				surface.set_color(lower if vertex < 2 else outer)
				surface.set_normal(Vector3(0.28 * direction.x, 0.90, 0.28 * direction.z).normalized())
				surface.add_vertex(corners[vertex])
	return surface.commit()

static func grass_material() -> StandardMaterial3D:
	var dry_grass := StandardMaterial3D.new()
	dry_grass.vertex_color_use_as_albedo = true
	dry_grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	dry_grass.roughness = 1.0
	return dry_grass
