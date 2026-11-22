extends RefCounted

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
			var foot := Creek.surface_point(Vector3(x + rng.randf_range(-1.5, 1.5), 0.0, z))
			var size := Vector3(rng.randf_range(5.7, 8.1), rng.randf_range(2.8, 5.2), rng.randf_range(6.4, 9.0))
			var shape := Stone.fragment(faces, foot, size, rng.randf_range(-0.36, 0.36), rng, Creek.surface_point, Stone.FRACTURE_PROFILE, true)
			Stone.solid(cover, foot, shape, "Afloramiento del monte")
			if i % 3 == 0:
				var outward := signf(x)
				var root := Creek.surface_point(foot + Vector3(outward * 5.5, 0, 1.8))
				Flora.tree(cover, root, Flora.Kind.MOLLE if i % 2 == 0 else Flora.Kind.ESPINILLO, rng.randf_range(0.85, 1.17), rng.randf() * TAU)
			for k in 6:
				var outward := signf(x)
				var spread := Vector3(outward * rng.randf_range(-20.0, 19.0), 0, rng.randf_range(-2.7, 2.7))
				var root := Creek.surface_point(foot + spread)
				var tuft := Vector4(root.x, root.y - 0.065, root.z, rng.randf_range(0.54, 1.4))
				if k % 3 == 0: scrub.append(tuft)
				else: roots.append(tuft)
	for i in 38:
		var x := -174.0 + i * 6.9
		var z := 147.0 + 5.0 * sin(x * 0.075)
		var foot := Creek.surface_point(Vector3(x, 0, z))
		var stone := Stone.fragment(faces, foot, Vector3(8.2, rng.randf_range(3.3, 6.1), 5.9),
			0.15 * cos(x * 0.23), rng, Creek.surface_point, Stone.OUTCROP_PROFILE, true)
		Stone.solid(cover, foot, stone, "Afloramiento de la quebrada baja")
		for k in 5:
			var root := Creek.surface_point(foot + Vector3(rng.randf_range(-4.0, 4.0), 0.0, rng.randf_range(-23.0, 13.0)))
			roots.append(Vector4(root.x, root.y - 0.05, root.z, rng.randf_range(0.65, 1.35)))
	Stone.finish(cover, faces, "Afloramientos y roca expuesta")
	Flora.grass_batch(cover, roots)
	Flora.herb_batch(cover, scrub, Flora.Herb.ROMERILLO)
