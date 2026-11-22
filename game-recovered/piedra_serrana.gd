extends RefCounted

const FINISH = preload("res://piedra_serrana.gdshader")
const SIDES := 8
const PALETTE := ["#978f86", "#a09a90", "#9b9288", "#ac9c91", "#8a857c"]
const BLOCK_PROFILE := [Vector2(-0.12, 0.86), Vector2(0.23, 1.0), Vector2(0.70, 0.80), Vector2(0.94, 0.49)]
const LAJA_PROFILE := [Vector2(-0.28, 0.88), Vector2(0.16, 1.0), Vector2(0.72, 0.91), Vector2(0.91, 0.74)]
const OUTCROP_PROFILE := [Vector2(-0.27, 0.89), Vector2(0.15, 1.0), Vector2(0.58, 0.84), Vector2(0.90, 0.55)]

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
	var proportions := [
		Vector3(1.00, 0.72, 1.00),
		Vector3(0.90, 0.91, 0.84),
		Vector3(1.06, 0.62, 0.94),
		Vector3(1.23, 0.40, 0.69),
		Vector3(0.75, 0.88, 1.16),
	]
	var vertices := fragment(faces, Vector3.ZERO, proportions[variant], 0.0, rng)
	faces.generate_normals()
	return {"mesh": faces.commit(), "vertices": vertices, "base": vertices.slice(0, SIDES)}

static func fragment(faces: SurfaceTool, at: Vector3, size: Vector3, turn: float, rng: RandomNumberGenerator,
		ground := Callable(), profile: Array = BLOCK_PROFILE) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	var radii := PackedFloat32Array()
	var heights := PackedFloat32Array()
	for side in SIDES:
		radii.append(rng.randf_range(0.82, 1.07))
		heights.append(rng.randf_range(-0.12, 0.09))
	for ring in profile.size():
		for side in SIDES:
			var angle := TAU * side / SIDES
			var radius: float = radii[side] * profile[ring].y * 0.5
			var local := Vector3(cos(angle) * size.x * radius, (profile[ring].x + heights[side]) * size.y, sin(angle) * size.z * radius)
			local.x += (ring - 1) * size.x * 0.024
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
