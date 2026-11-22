extends RefCounted

const FINISH = preload("res://piedra_serrana.gdshader")
const SIDES := 8
const PALETTE := ["#978f86", "#a09a90", "#9b9288", "#ac9c91", "#8a857c"]
const BLOCK_PROFILE := [Vector2(-0.12, 0.86), Vector2(0.23, 1.0), Vector2(0.70, 0.80), Vector2(0.94, 0.49)]
const LAJA_PROFILE := [Vector2(-0.28, 0.88), Vector2(0.16, 1.0), Vector2(0.72, 0.91), Vector2(0.91, 0.74)]
const OUTCROP_PROFILE := [Vector2(-0.27, 0.89), Vector2(0.15, 1.0), Vector2(0.58, 0.84), Vector2(0.90, 0.55)]
const FRACTURE_PROFILE := [Vector2(-0.29, 0.91), Vector2(0.12, 1.0), Vector2(0.61, 0.92), Vector2(0.90, 0.64)]
const HILLSIDE_FORMS := [
	[Vector3(1.00, 0.71, 1.00), BLOCK_PROFILE],
	[Vector3(0.87, 0.91, 0.84), FRACTURE_PROFILE],
	[Vector3(1.13, 0.55, 0.93), OUTCROP_PROFILE],
	[Vector3(1.25, 0.34, 0.75), LAJA_PROFILE],
	[Vector3(0.70, 0.85, 1.16), OUTCROP_PROFILE],
	[Vector3(1.13, 0.61, 0.72), FRACTURE_PROFILE],
	[Vector3(0.86, 0.51, 1.21), LAJA_PROFILE],
]

static func surface() -> SurfaceTool:
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	return stone

static func paint(tint: String = "") -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FINISH
	if not tint.is_empty():
		material.set_shader_parameter("colored_mesh", false)
		material.set_shader_parameter("stone_tint", Color(tint))
	return material

static func finish(parent: Node3D, faces: SurfaceTool, name: String) -> MeshInstance3D:
	faces.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = faces.commit()
	mesh.material_override = paint()
	parent.add_child(mesh)
	return mesh

static func hillside_form(variant: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1549 + variant * 29
	var faces := surface()
	var form: Array = HILLSIDE_FORMS[variant]
	var vertices := fragment(faces, Vector3.ZERO, form[0], 0.0, rng, Callable(), form[1], true)
	faces.generate_normals()
	return {"mesh": faces.commit(), "vertices": vertices, "base": vertices.slice(0, SIDES)}

static func fragment(faces: SurfaceTool, at: Vector3, size: Vector3, turn: float, rng: RandomNumberGenerator,
		ground := Callable(), profile: Array = BLOCK_PROFILE, fractured := false) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	var radii := PackedFloat32Array()
	var heights := PackedFloat32Array()
	for side in SIDES:
		radii.append(rng.randf_range(0.82, 1.07))
		heights.append(rng.randf_range(-0.12, 0.09))
	var fracture := Vector2.ZERO
	if fractured: fracture = Vector2.from_angle(rng.randf_range(0.0, TAU))
	for ring in profile.size():
		for side in SIDES:
			var angle := TAU * side / SIDES
			var radius: float = radii[side] * profile[ring].y * 0.5
			var local := Vector3(cos(angle) * size.x * radius, (profile[ring].x + heights[side]) * size.y, sin(angle) * size.z * radius)
			local.x += (ring - 1) * size.x * 0.024
			if fractured:
				var along := Vector2(cos(angle), sin(angle)).dot(fracture)
				var lift: float = maxf(0.0, profile[ring].x)
				local.x += fracture.x * size.x * lift * 0.13
				local.z += fracture.y * size.z * lift * 0.17
				local.y += along * size.y * lift * 0.22
			var world := at + local.rotated(Vector3.UP, turn)
			if ring == 0 and ground.is_valid():
				var bed: Vector3 = ground.call(world)
				world.y = minf(world.y, bed.y - 0.055)
			vertices.append(world)
	var tint := Color(PALETTE[rng.randi_range(0, PALETTE.size() - 1)])
	for ring in range(profile.size() - 1):
		for side in SIDES:
			var a := ring * SIDES + side
			var b := ring * SIDES + (side + 1) % SIDES
			var color := tint.darkened(0.10 - ring * 0.035).lerp(Color("#665b50"), 0.045 * float(side % 3))
			triangle(faces, vertices[a], vertices[b], vertices[a + SIDES], color)
			triangle(faces, vertices[b], vertices[b + SIDES], vertices[a + SIDES], color)
	var top := (profile.size() - 1) * SIDES
	for side in range(1, SIDES - 1):
		triangle(faces, vertices[top], vertices[top + side], vertices[top + side + 1], tint.lightened(0.035))
	return vertices

static func scree(faces: SurfaceTool, at: Vector3, heading: Vector3, width: float,
		ground: Callable, rng: RandomNumberGenerator):
	var across := Vector3(-heading.z, 0, heading.x)
	for chip in rng.randi_range(5, 9):
		var shift := heading * width * rng.randf_range(-0.30, 0.54)
		shift += across * width * rng.randf_range(0.16, 0.58)
		var foot: Vector3 = ground.call(at + shift)
		var length := width * rng.randf_range(0.055, 0.21)
		var size := Vector3(length, length * rng.randf_range(0.20, 0.49), length * rng.randf_range(0.58, 0.91))
		fragment(faces, foot - Vector3.UP * 0.012, size, atan2(-heading.z, heading.x) + rng.randf_range(-0.50, 0.50),
			rng, ground, LAJA_PROFILE)

static func triangle(faces: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color):
	faces.set_smooth_group(-1)
	for vertex in [a, b, c]:
		faces.set_color(color)
		faces.add_vertex(vertex)

static func solid(parent: Node3D, at: Vector3, vertices: PackedVector3Array, name: String, tag := ""):
	var hull := ConvexPolygonShape3D.new()
	var local := PackedVector3Array()
	for point in vertices: local.append(point - at)
	hull.points = local
	var collision := CollisionShape3D.new()
	collision.shape = hull
	var body := StaticBody3D.new()
	body.name = name
	if not tag.is_empty(): body.set_meta("item", tag)
	body.add_child(collision)
	parent.add_child(body, true)
	body.position = at

static func cairn(parent: Node3D, faces: SurfaceTool, base: Vector3, ground: Callable, rng: RandomNumberGenerator, tag := ""):
	var stack := PackedVector3Array()
	var foot := base
	var scale_m := rng.randf_range(0.85, 1.28)
	var count := rng.randi_range(3, 4)
	for level in count:
		var width := (0.82 - level * 0.16) * scale_m
		var height := (0.25 - level * 0.027) * scale_m
		var stones := fragment(faces, foot, Vector3(width, height, width * rng.randf_range(0.68, 0.89)),
			rng.randf() * TAU, rng, ground if level == 0 else Callable())
		stack.append_array(stones)
		foot += Vector3(rng.randf_range(-0.061, 0.061), height * 0.80, rng.randf_range(-0.061, 0.061))
	solid(parent, base, stack, "Pirca", tag)
