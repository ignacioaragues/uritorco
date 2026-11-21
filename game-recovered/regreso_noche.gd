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
var foliage: Array[ShaderMaterial] = []
var bark: Material
var crowns: Array[ArrayMesh] = []
var trunk: CylinderMesh

func _ready():
	hillside = Stone.paint()
	foliage.assign([Flora.leaf_material("4e5841", 0.18), Flora.leaf_material("38493c", 0.63)])
	bark = Flora.bark_material()
	crowns.assign([Flora.crown_mesh(1.53), Flora.crown_mesh(3.18)])
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

static func surface_point(at: Vector3) -> Vector3:
	var cell := float(TILE) / STEPS
	var west := floorf(at.x / cell) * cell
	var north := ceilf(at.z / cell) * cell
	var u := (at.x - west) / cell
	var v := (north - at.z) / cell
	var a := ground_height(west, north)
	var b := ground_height(west + cell, north)
	var c := ground_height(west, north - cell)
	var d := ground_height(west + cell, north - cell)
	at.y = a * (1.0 - u - v) + b * u + c * v if u + v <= 1.0 else d * (u + v - 1.0) + b * (1.0 - v) + c * (1.0 - u)
	return at

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
	var origin := patch.position
	var ground := func(at: Vector3) -> Vector3:
		return surface_point(origin + at) - origin
	var molles: Array[Transform3D] = []
	var talas: Array[Transform3D] = []
	var stems: Array[Transform3D] = []
	var tufts: Array[Vector4] = []
	var rocks := Stone.surface()
	var has_rocks := false
	for i in 23:
		var x := rng.randf_range(2.0, TILE - 2.0)
		var z := -rng.randf_range(3.0, TILE - 2.0)
		var local := origin + Vector3(x, 0, z)
		if local.z > -12.0 and absf(local.x) < 7.5: continue
		var foot: Vector3 = ground.call(Vector3(x, 0, z))
		if i % 3 != 0:
			var size_m := rng.randf_range(0.77, 1.46)
			var turn := Basis(Vector3.UP, rng.randf() * TAU)
			var tall := posmod(i + key.x + key.y, 5) >= 3
			var height := (2.47 if tall else 1.66) * size_m
			var limb := Vector3(0.33, height, 0.27) * Vector3(size_m, 1.0, size_m)
			var root := foot + Vector3.UP * (height * 0.44 - 0.065)
			stems.append(Transform3D(turn.scaled_local(limb), root))
			Kit.item(patch, root, "", Vector3.ZERO, limb * Vector3(0.85, 1.0, 0.85)).basis = turn
			var leaves := talas if tall else molles
			var spacing := (0.82 if tall else 1.35) * size_m
			var canopy := (Vector3(1.42, 1.10, 1.29) if tall else Vector3(2.25, 0.81, 1.71)) * size_m
			var fork := foot + Vector3.UP * height * 0.54
			for arm in 4:
				var angle := arm * 1.82 + i * 0.29
				var reach := turn * Vector3(cos(angle), 0, sin(angle)) * spacing * (0.39 + arm * 0.12)
				var tip := foot + reach + Vector3.UP * height * (0.86 + 0.09 * arm)
				var direction := tip - fork
				var branch := Basis(Quaternion(Vector3.UP, direction.normalized()))
				stems.append(Transform3D(branch.scaled_local(Vector3(0.128 * size_m, direction.length(), 0.10 * size_m)), fork.lerp(tip, 0.5)))
				leaves.append(Transform3D(turn.scaled_local(canopy * (1.0 - 0.074 * arm)), tip))
		else:
			var size_m := rng.randf_range(0.5, 1.7)
			has_rocks = true
			var form := Stone.fragment(rocks, foot, Vector3(1.68, 0.80, 1.24) * size_m, rng.randf() * TAU, rng, ground)
			if size_m > 1.12: Stone.solid(patch, foot, form, "Granito")
			for scatter in [Vector3(-1.2, 0, 0.26), Vector3(0.46, 0, -0.97), Vector3(1.35, 0, 0.58)]:
				var at: Vector3 = ground.call(foot + scatter * size_m)
				tufts.append(Vector4(at.x, at.y - 0.04, at.z, 0.52 + size_m * 0.17))
	batch(patch, crowns[0], foliage[0], molles)
	batch(patch, crowns[1], foliage[1], talas)
	batch(patch, trunk, bark, stems)
	if has_rocks: Stone.finish(patch, rocks, "Piedras del monte")
	Flora.grass_batch(patch, tufts)

static func batch(patch: Node3D, mesh: Mesh, finish: Material, transforms: Array[Transform3D]):
	if transforms.is_empty(): return
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
