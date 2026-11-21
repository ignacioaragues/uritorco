extends Node3D

const Stone = preload("res://piedra_serrana.gd")
const Flora = preload("res://flora.gd")
const Kit = preload("res://equipo_campo.gd")
const TILE := 64
const STEPS := 16
const RADIUS := 3

var tiles: Dictionary = {}
var current := Vector2i(1000000, 1000000)
var hillside: ShaderMaterial
var foliage: ShaderMaterial
var bark: Material
var crown: ArrayMesh
var trunk: CylinderMesh

func _ready():
	hillside = Stone.paint()
	foliage = Flora.leaf_material("424a38")
	bark = Flora.bark_material()
	crown = Flora.crown_mesh(1.53)
	trunk = CylinderMesh.new()
	trunk.top_radius = 0.30
	trunk.bottom_radius = 0.50
	trunk.height = 1.0
	trunk.radial_segments = 7

func follow(local: Vector3):
	var center := Vector2i(floori(local.x / TILE), maxi(0, floori(-local.z / TILE)))
	if center == current: return
	current = center
	for key: Vector2i in tiles.keys():
		if absi(key.x - center.x) > RADIUS or absi(key.y - center.y) > RADIUS:
			var piece: Node3D = tiles[key]
			remove_child(piece)
			piece.queue_free()
			tiles.erase(key)
	for row in range(maxi(center.y - RADIUS, 0), center.y + RADIUS + 1):
		for column in range(center.x - RADIUS, center.x + RADIUS + 1):
			var key := Vector2i(column, row)
			if not tiles.has(key): tiles[key] = make_tile(key)

static func ground_height(x: float, z: float) -> float:
	var near_exit := smoothstep(0.0, 20.0, -z)
	var roll := 1.49 * sin(x * 0.036 + z * 0.020) + 0.82 * cos(z * 0.063 - x * 0.041)
	roll += 0.64 * sin(x * 0.111 + z * 0.052)
	var hillside_edge := 10.8 * smoothstep(3.35, 12.0, absf(x)) * (1.0 - smoothstep(0.0, 19.0, -z))
	return roll * near_exit + hillside_edge

func make_tile(key: Vector2i) -> Node3D:
	var patch := Node3D.new()
	add_child(patch)
	patch.position = Vector3(key.x * TILE, 0, -key.y * TILE)
	var surface := Stone.surface()
	var width := STEPS + 1
	var spacing := float(TILE) / STEPS
	for row in width:
		for column in width:
			var at := Vector3(column * spacing, 0, -row * spacing)
			var world := patch.position + at
			at.y = ground_height(world.x, world.z)
			var soil := Color("#424739").lerp(Color("#61594a"), 0.27 + 0.19 * sin(world.x * 0.112 + world.z * 0.169))
			surface.set_color(soil)
			surface.add_vertex(at)
	for row in STEPS:
		for col in STEPS:
			var a := row * width + col
			for i in [a, a + width, a + 1, a + 1, a + width, a + width + 1]:
				surface.add_index(i)
	var ground := Stone.finish(patch, surface, "Monte")
	ground.material_override = hillside
	ground.create_trimesh_collision()
	if key.y == 0:
		var face := Stone.surface()
		for column in STEPS:
			var x := column * spacing
			var left := patch.position.x + x
			var right := left + spacing
			if absf((left + right) * 0.5) < 4.0: continue
			var top_a := Vector3(x, ground_height(left, 0.0), 0)
			var top_b := Vector3(x + spacing, ground_height(right, 0.0), 0)
			var base_a := Vector3(x, -3.5, 0)
			var base_b := Vector3(x + spacing, -3.5, 0)
			Stone.triangle(face, top_a, base_a, top_b, Color("#595346"))
			Stone.triangle(face, top_b, base_a, base_b, Color("#595346"))
		var cliff := Stone.finish(patch, face, "Pie del paredón")
		cliff.create_trimesh_collision()
	dress_tile(patch, key)
	return patch

func dress_tile(patch: Node3D, key: Vector2i):
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var crowns: Array[Transform3D] = []
	var stems: Array[Transform3D] = []
	var rocks := Stone.surface()
	var has_rocks := false
	for i in 23:
		var x := rng.randf_range(2.0, TILE - 2.0)
		var z := -rng.randf_range(3.0, TILE - 2.0)
		var local := patch.position + Vector3(x, 0, z)
		if local.z > -12.0 and absf(local.x) < 7.5: continue
		var foot := Vector3(x, ground_height(local.x, local.z) - 0.075, z)
		if i % 3 != 0:
			var size_m := rng.randf_range(0.77, 1.46)
			var turn := Basis(Vector3.UP, rng.randf() * TAU)
			var height := 1.82 * size_m
			var limb := Vector3(0.33, height, 0.27) * Vector3(size_m, 1.0, size_m)
			var root := foot + Vector3.UP * height * 0.44
			stems.append(Transform3D(turn.scaled_local(limb), root))
			Kit.item(patch, root, "", Vector3.ZERO, limb * Vector3(0.85, 1.0, 0.85)).basis = turn
			for branch in [Vector3(-0.43, 1.89, 0.05), Vector3(0.53, 2.17, -0.33), Vector3(0.04, 2.50, 0.38)]:
				var canopy := Vector3(2.11, 0.83, 1.56) * size_m
				crowns.append(Transform3D(turn.scaled_local(canopy), foot + turn * branch * size_m))
		else:
			var size_m := rng.randf_range(0.5, 1.7)
			has_rocks = true
			var form := Stone.fragment(rocks, foot, Vector3(1.68, 0.80, 1.24) * size_m, rng.randf() * TAU, rng)
			if size_m > 1.12: Stone.solid(patch, foot, form, "Granito")
	if not crowns.is_empty(): batch(patch, crown, foliage, crowns)
	if not stems.is_empty(): batch(patch, trunk, bark, stems)
	if has_rocks: Stone.finish(patch, rocks, "Piedras del monte")

static func batch(patch: Node3D, mesh: Mesh, finish: Material, transforms: Array[Transform3D]):
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for i in transforms.size():
		instances.set_instance_transform(i, transforms[i])
	var plants := MultiMeshInstance3D.new()
	plants.multimesh = instances
	plants.material_override = finish
	plants.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	patch.add_child(plants)
