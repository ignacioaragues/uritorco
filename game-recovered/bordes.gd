extends RefCounted

const Departure = preload("res://salida.gd")
const Creek = preload("res://cauce.gd")
const Stone = preload("res://piedra_serrana.gd")
const Flora = preload("res://flora.gd")

static func dress(valley):
	var cover := Node3D.new()
	cover.name = "Límites del monte"
	valley.add_child(cover)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53212
	var faces := Stone.surface()
	var roots: Array[Vector4] = []
	var scrub: Array[Vector4] = []
	for i in 39:
		var z := -64.0 + 5.35 * i
		var east := 69.0 + 8.2 * sin(z * 0.051)
		var west := -(Creek.west_limit(z) + 15.0)
		for x in [east, west]:
			var outward := signf(x)
			var buckle := sin(z * 0.14 + outward) + 0.62 * sin(z * 0.26)
			var bed := Vector3(x + 1.8 * buckle + rng.randf_range(-0.85, 0.85), 0.0, z)
			if Departure.trail_clearance(Vector2(bed.x, bed.z)) < 8.0:
				bed.z += 13.0 if bed.z > Departure.MARA_END.z else -13.0
			var foot := Creek.surface_point(bed) - Vector3.UP * 0.19
			var crest := 0.5 + 0.5 * sin(z * 0.12 + outward * 0.79)
			var size := Vector3(rng.randf_range(5.7, 8.1), 3.25 + 1.9 * crest, rng.randf_range(6.9, 9.3))
			var turn := 0.28 * buckle
			var shape := Stone.fragment(faces, foot, size, turn, rng, Creek.surface_point, Stone.FRACTURE_PROFILE, true)
			Stone.solid(cover, foot, shape, "Afloramiento del monte")
			if i % 3 != 2 and Departure.trail_clearance(Vector2(bed.x - outward * 2.8, bed.z + 1.85)) > 5.8:
				var chip := Creek.surface_point(bed + Vector3(outward * -2.8, 0.0, 1.85)) - Vector3.UP * 0.15
				var slab_size := Vector3(3.4 + 0.82 * crest, 0.66 + 0.95 * crest, 5.2)
				var slab := Stone.fragment(faces, chip, slab_size, turn + 0.12, rng, Creek.surface_point, Stone.LAJA_PROFILE, true)
				Stone.solid(cover, chip, slab, "Laja al pie del afloramiento")
				Stone.scree(faces, chip, Vector3(0.0, 0.0, outward), 5.7, Creek.surface_point, rng)
			if i % 3 == 0:
				var root := Creek.surface_point(foot + Vector3(outward * 5.5, 0, 1.8))
				Flora.tree(cover, root, Flora.Kind.MOLLE if i % 2 == 0 else Flora.Kind.ESPINILLO, rng.randf_range(0.85, 1.17), rng.randf() * TAU)
			for k in 6:
				var spread := Vector3(outward * rng.randf_range(-20.0, 19.0), 0, rng.randf_range(-2.7, 2.7))
				var root := Creek.surface_point(foot + spread)
				if Departure.trail_clearance(Vector2(root.x, root.z)) < 2.8: continue
				var tuft := Vector4(root.x, root.y - 0.065, root.z, rng.randf_range(0.54, 1.4))
				if k % 3 == 0: scrub.append(tuft)
				else: roots.append(tuft)
	for i in 38:
		var x := -174.0 + i * 6.9
		var z := 147.0 + 5.0 * sin(x * 0.075)
		var foot := Creek.surface_point(Vector3(x, 0, z)) - Vector3.UP * 0.20
		var crest := 0.5 + 0.5 * sin(x * 0.16)
		var stone := Stone.fragment(faces, foot, Vector3(9.1, 3.3 + crest * 2.55, 6.2 + crest),
			0.24 * cos(x * 0.23), rng, Creek.surface_point, Stone.OUTCROP_PROFILE, true)
		Stone.solid(cover, foot, stone, "Afloramiento de la quebrada baja")
		if i % 5 == 1:
			var root := Creek.surface_point(foot + Vector3(2.3, 0.0, -5.9))
			Flora.tree(cover, root, Flora.Kind.TALA, 0.86 + crest * 0.36, rng.randf() * TAU)
		for k in 5:
			var root := Creek.surface_point(foot + Vector3(rng.randf_range(-4.0, 4.0), 0.0, rng.randf_range(-23.0, 13.0)))
			roots.append(Vector4(root.x, root.y - 0.05, root.z, rng.randf_range(0.65, 1.35)))
	Stone.finish(cover, faces, "Afloramientos y roca expuesta")
	Flora.grass_batch(cover, roots)
	Flora.herb_batch(cover, scrub, Flora.Herb.ROMERILLO)
