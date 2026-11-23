extends RefCounted

const Flora = preload("res://flora.gd")
const Stone = preload("res://piedra_serrana.gd")

static func build(route):
	var hillside := Node3D.new()
	hillside.name = "Ladera del ascenso"
	route.add_child(hillside)
	var ground := func(at: Vector3) -> Vector3:
		return route.surface_point(at.x, route.ORIGIN_Z - at.z)
	var stone_faces := Stone.surface()
	var tufts: Array[Vector4] = []
	var tussocks: Array[Vector4] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 32619
	for index in range(1, 99):
		var progress := index / 100.0
		var at: Vector3 = route.ascent_point(progress)
		var next: Vector3 = route.ascent_point(progress + 0.01)
		var side := lateral(at, next)
		var sign_of_side := -1.0 if (index / 6) % 2 == 0 else 1.0
		if index % 5 == 0:
			var base: Vector3 = ground.call(at + side * (2.08 * sign_of_side))
			if clear_of_other_trails(route, base, 2.4):
				Stone.cairn(hillside, stone_faces, base, ground, rng)
		if index % 3 == 0:
			var base: Vector3 = ground.call(at + side * (rng.randf_range(4.0, 9.8) * sign_of_side))
			var width := rng.randf_range(0.9, 3.7)
			var height := width * rng.randf_range(0.22, 0.49)
			if clear_of_other_trails(route, base, 2.0 + width * 0.5):
				var vertices := Stone.fragment(stone_faces, base, Vector3(width, height, width * 0.71), rng.randf() * TAU, rng, ground)
				Stone.solid(hillside, base, vertices, "Afloramiento")
		for i in (18 if index % 4 == 0 else 9):
			var offset := rng.randf_range(2.8, 8.5) * (-1.0 if i % 2 == 0 else 1.0)
			var patch: Vector3 = ground.call(at.lerp(next, rng.randf()) + side * offset)
			var size_m := rng.randf_range(0.48, 1.45) * lerpf(1.0, 0.72, progress)
			var root := Vector4(patch.x, patch.y - 0.085, patch.z, size_m)
			if index > 27 and index % 9 in [0, 1, 2, 3] and absf(offset) > 2.5:
				tussocks.append(root)
			else:
				tufts.append(root)
		if index < 61 and index % 7 == 0:
			var foot: Vector3 = ground.call(at + side * (5.2 * sign_of_side))
			var kind := Flora.Kind.ESPINILLO if index < 23 else Flora.Kind.PIQUILLIN
			if clear_of_other_trails(route, foot, 3.5):
				Flora.tree(hillside, foot, kind, rng.randf_range(0.78, 1.24), rng.randf() * TAU)
	var approach: Vector3 = route.summit_point(route.SUMMIT_JOIN)
	var peak: Vector3 = route.summit_point(1.0)
	var peak_side := lateral(approach, peak)
	for index in range(1, 14):
		var t := lerpf(route.SUMMIT_JOIN, 1.0, index / 14.0)
		var at: Vector3 = route.summit_point(t)
		var next: Vector3 = route.summit_point(t + 0.01)
		var side := lateral(at, next)
		var mark_side := 1.0 if index % 3 > 0 else -1.0
		var base: Vector3 = ground.call(at + side * (2.15 * mark_side))
		Stone.cairn(hillside, stone_faces, base, ground, rng)
		for i in 7:
			var shoulder: Vector3 = ground.call(at.lerp(next, rng.randf()) + peak_side * rng.randf_range(2.7, 7.8) * (-mark_side if i % 2 == 0 else mark_side))
			var size_m := rng.randf_range(0.40, 0.90)
			tussocks.append(Vector4(shoulder.x, shoulder.y - 0.085, shoulder.z, size_m))
		if index % 2 == 0:
			var ledge: Vector3 = ground.call(at - side * rng.randf_range(4.3, 7.8) * mark_side)
			var shape := Stone.fragment(stone_faces, ledge, Vector3(2.4, 0.58, 1.71), rng.randf() * TAU, rng, ground)
			Stone.solid(hillside, ledge, shape, "Laja")
	Stone.finish(hillside, stone_faces, "Piedras del ascenso")
	Flora.grass_batch(hillside, tufts)
	Flora.herb_batch(hillside, tussocks, Flora.Herb.PAJA)

static func lateral(from: Vector3, to: Vector3) -> Vector3:
	var delta := to - from
	return Vector3(delta.z, 0, -delta.x).normalized()

static func clear_of_other_trails(route, at: Vector3, margin: float) -> bool:
	var d: float = route.ORIGIN_Z - at.z
	if absf(at.x - route.trail(d)) < margin: return false
	if d > 124.0 and d < 218.0 and absf(at.x - route.detour(d)) < margin: return false
	if d > 300.0 and d < 610.0 and absf(at.x - route.quarry_point((d - 300.0) / 310.0).x) < margin: return false
	var connector: float = route.western_x_at(at.z)
	return absf(at.x - connector) >= margin
