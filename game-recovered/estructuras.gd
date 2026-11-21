extends RefCounted

const Kit = preload("res://equipo_campo.gd")

static func arch(v, origin: Vector3, scale_m: float, interactive: bool = false, tilt: float = 0.0, stone: Material = null):
	for side in [-1, 1]:
		var size := Vector3(0.32, 2.8, 0.52) * scale_m
		var pillar: MeshInstance3D = v.box(origin + Vector3(side * 1.15, 1.4, 0) * scale_m, size, "666d7c", interactive)
		pillar.rotation.z = side * 0.18 + tilt
		if stone:
			pillar.mesh = chipped_block(size, side * 1.58 + tilt)
			pillar.material_override = stone
	var cap_size := Vector3(2.75, 0.36, 0.48) * scale_m
	var cap: MeshInstance3D = v.box(origin + Vector3(0.1, 2.73, 0) * scale_m, cap_size, "8b8992", interactive)
	cap.rotation.z = 0.22 + tilt
	if stone:
		cap.mesh = chipped_block(cap_size, 1.86 + tilt)
		cap.material_override = stone

static func chipped_block(size: Vector3, variation: float) -> ArrayMesh:
	const EDGES := [Vector2(1, -0.58), Vector2(1, 0.61), Vector2(0.63, 1), Vector2(-0.62, 1),
		Vector2(-1, 0.62), Vector2(-1, -0.58), Vector2(-0.66, -1), Vector2(0.54, -1)]
	var vertices := PackedVector3Array()
	var levels := [Vector2(0.53, 0.01), Vector2(0.51, 0.78), Vector2(0.39, 0.94),
		Vector2(0.08, 1.03), Vector2(-0.29, 0.94), Vector2(-0.53, 0.96)]
	for level in levels.size():
		for i in EDGES.size():
			var edge: Vector2 = EDGES[i]
			var chip := 0.065 * sin(i * 1.8 + level * 2.9 + variation)
			var side_scale: float = levels[level].y
			var height: float = levels[level].x
			vertices.append(Vector3((edge.x * side_scale * (1.0 + chip) + 0.08 * sin(level + variation)) * size.x * 0.5,
				(height + 0.055 * sin(i + variation + level)) * size.y,
				edge.y * side_scale * (1.0 + 0.5 * chip) * size.z * 0.5))
	return Kit.rings(vertices, EDGES.size())
