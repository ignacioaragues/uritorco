extends RefCounted

static func arch(v, origin: Vector3, scale_m: float, interactive: bool = false, tilt: float = 0.0, tag: String = ""):
	for side in [-1, 1]:
		var pillar = v.box(origin + Vector3(side * 1.15, 1.4, 0) * scale_m, Vector3(0.32, 2.8, 0.52) * scale_m, "666d7c", interactive)
		pillar.rotation.z = side * 0.18 + tilt
	var cap = v.box(origin + Vector3(0.1, 2.73, 0) * scale_m, Vector3(2.75, 0.36, 0.48) * scale_m, "8b8992", interactive)
	cap.rotation.z = 0.22 + tilt
	var core = v.box(origin + Vector3(0, 1.28, 0) * scale_m, Vector3.ONE * 0.54 * scale_m, "b7a27d", not tag.is_empty(), tag)
	core.rotation = Vector3(0.61, 0.75, 0.39)
