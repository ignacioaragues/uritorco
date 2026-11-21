extends RefCounted

const Visual = preload("res://hallazgo_visual.gd")
const Flora = preload("res://flora.gd")
const Stone = preload("res://piedra_serrana.gd")
const Creek = preload("res://cauce.gd")
const Trail = preload("res://travesia.gd")

const EAST = [Vector2(4.3, -16.4), Vector2(10.6, -17.3), Vector2(16.5, -12.8),
	Vector2(22.4, -6.8), Vector2(29, 0.9), Vector2(36.2, 7.4), Vector2(39.4, 12.4)]
const WEST = [Vector2(3.8, -16.6), Vector2(-4.8, -19), Vector2(-12, -21.8),
	Vector2(-19, -25), Vector2(-25, -24.1), Vector2(-32, -20.2), Vector2(-39, -17)]
const SOUTH = [Vector2(39.4, 12.4), Vector2(35, 21), Vector2(25.8, 31),
	Vector2(15, 39), Vector2(1, 49), Vector2(-11, 56), Vector2(-27, 57)]
const MOLLAR := Vector2(39.4, 12.4)
const LAJAS := Vector2(-39, -17)
const WEST_LINK := [LAJAS, Vector2(-36.2, -12.9), Vector2(-33.7, -7.3),
	Vector2(-34.8, 1.8), Vector2(-31.7, 12.2), Vector2(-27.2, 18.8), Creek.PATH[6]]
const EAST_LINK := [EAST[3], Vector2(18.6, 0.5), Vector2(16.9, 10.0),
	Vector2(18.8, 20.7), Vector2(22.8, 27.5), SOUTH[2]]
const PATHS := [EAST, WEST, SOUTH, WEST_LINK, EAST_LINK]

# Los índices corresponden a las láminas del cuaderno.
const FINDS = {
	"tiesto": [0, "Tiesto con guarda", Vector2(-35.5, -23.2), "Asomaba de la tierra junto a una laja del oeste. La guarda sigue el borde. Uno de los surcos todavía tiene tierra. Dibujé cómo estaba apoyado."],
	"tortero": [1, "Tortero de piedra", Vector2(31, 13.6), "A la sombra del mollar. La perforación se ensancha de un lado. Se parece a los torteros que vi en el museo. Dibujé el lado más gastado."],
	"mano": [2, "Mano de moler", Vector2(-31.8, 60.9), "En el recodo del cauce. La cara que queda arriba brilla como si la hubieran pulido. Al lado hay una piedra chata con una marca ancha. Dibujé la pieza de canto."],
	"vasija": [3, "Vasija de barro", Vector2(-23.8, -61.4), "Asomaba al pie de dos piquillines, al oeste de la huella. Tiene el borde grueso y una rajadura con tierra adentro. La dibujé en el hueco, con la boca hacia la ladera."],
	"negativo": [4, "Negativo velado", Vector2(42.6, -0.6), "En el borde del mollar, contra la luz. Uno de los cuadros tiene dos manchas. La mayor podría ser una raya de la película. Dibujé también las perforaciones."],
	"cinta": [5, "Casete rajado", Vector2(-201.8, -574.4), "Entre el cable y la cantera, detrás de unas lajas. La caja se abre por una esquina. Hay cinta entre los dos carretes. Al margen de la etiqueta, alguien escribió «canal libre»."],
	"placa": [6, "Chapa perforada", Vector2(14, 46), "Asomaba por debajo de una laja en la vuelta por el sur. Los agujeros tienen rebaba de un solo lado. Si la levanto hacia el cielo, parecen un grupo de estrellas. Cambia por completo al girarla."],
	"lata": [7, "Croquis en una lata", Vector2(-47.6, -473), "En la subida al abra, detrás de una piedra. Dentro de la lata quedó un croquis doblado. Dos líneas cruzan una ladera. El papel se rompe justo donde se juntan."]
}

# Inclinación, rumbo y altura sobre el terreno. El lado abierto queda fuera de la huella (+Z local).
const FIND_POSES := {
	"tiesto": Vector3(-0.38, -2.71, 0.025),
	"tortero": Vector3(0.19, -2.04, 0.042),
	"mano": Vector3(0.09, -0.94, 0.045),
	"vasija": Vector3(0.28, -1.40, -0.17),
	"negativo": Vector3(0.15, 2.41, 0.022),
	"cinta": Vector3(0.17, -0.80, -0.008),
	"placa": Vector3(0.17, 0.62, 0.022),
	"lata": Vector3(-0.12, -1.27, 0.004),
}

static func ground(point: Vector2, route) -> Vector3:
	if point.y < -72.0: return route.surface_point(point.x, Trail.ORIGIN_Z - point.y)
	return Creek.point(point.x, point.y)

static func path_point(path: Array, progress: float) -> Vector2:
	var step := clampf(progress, 0.0, 1.0) * (path.size() - 1)
	var index := mini(int(step), path.size() - 2)
	return path[index].lerp(path[index + 1], step - index)

static func segments() -> PackedVector2Array:
	var result := PackedVector2Array()
	for path in PATHS:
		for i in range(path.size() - 1):
			result.append(path[i])
			result.append(path[i + 1])
	return result

static func clearance(point: Vector2) -> float:
	var distance := INF
	for path in PATHS:
		for i in range(path.size() - 1):
			var closest := Geometry2D.get_closest_point_to_segment(point, path[i], path[i + 1])
			distance = minf(distance, point.distance_squared_to(closest))
	for find in FINDS.values():
		distance = minf(distance, point.distance_squared_to(find[2]))
	return sqrt(distance)

static func build(valley):
	var route = valley.route
	route.signpost(ground(Vector2(12.5, -16.1), route) + Vector3(0.0, 0, 1.1),
		"Mirador del mollar", "Mollar →", -0.48, true)
	route.signpost(ground(Vector2(-12, -23.2), route) + Vector3(0, 0, 2.4),
		"Loma de las lajas", "Lajas ←", 0.77, true)
	for junction in [
		[WEST_LINK[0], Vector2(4.2, 0.6), "Vuelta de las lajas", "Vuelta al cauce →", 0.30],
		[WEST_LINK[-1], Vector2(-1.9, -2.1), "Vuelta de las lajas", "← Loma de las lajas", 2.68],
		[EAST_LINK[0], Vector2(1.81, -0.65), "Atajo del este", "Mollar  /  Cauce →", 0.24],
		[EAST_LINK[-1], Vector2(-1.0, 2.2), "Atajo del este", "↑ Atajo al puesto", PI],
	]:
		var at: Vector2 = junction[0] + junction[1]
		var foot := Creek.surface_point(Vector3(at.x, 0.0, at.y))
		route.signpost(foot, junction[2], junction[3], junction[4], true)
	for site in [MOLLAR, LAJAS]:
		var point := ground(site, route)
		valley.stone(point + Vector3(0.0, 0.22, -1.1), Vector3(1.67, 0.52, 0.78), "857363", true)
		for i in 3:
			valley.stone(point + Vector3(1.2, 0.14 + i * 0.17, -0.94),
				Vector3(0.64 - i * 0.13, 0.27, 0.41 - i * 0.08), "998d75")
	for id in FINDS:
		dress_find(valley, id)
	var vegetation := [
		[Flora.Kind.MOLLE, 42, 16, 1.65], [Flora.Kind.MOLLE, 33, 16, 1.55],
		[Flora.Kind.MOLLE, 42, 24, 1.42], [Flora.Kind.MOLLE, 37, 28, 1.1],
		[Flora.Kind.MOLLE, 44, 33, 1.27], [Flora.Kind.ESPINILLO, 29, 8, 0.96],
		[Flora.Kind.ESPINILLO, 25, -10, 1.13], [Flora.Kind.ESPINILLO, 19, -16, 0.96],
		[Flora.Kind.ESPINILLO, -9, -28, 1.01], [Flora.Kind.ESPINILLO, -26, -30, 0.91],
		[Flora.Kind.TALA, 18, 34, 1.22], [Flora.Kind.TALA, 1, 57, 1.25],
		[Flora.Kind.TALA, -19, 51, 1.06], [Flora.Kind.TALA, -11, 31, 1.01],
		[Flora.Kind.PIQUILLIN, -30, -16, 1.28], [Flora.Kind.PIQUILLIN, -36, -12, 1.2],
		[Flora.Kind.PIQUILLIN, -41, -26, 0.88], [Flora.Kind.PIQUILLIN, 35, 4, 0.97],
		[Flora.Kind.PIQUILLIN, 9, 49, 1.3], [Flora.Kind.PIQUILLIN, -10, 61, 1.4],
	]
	for plant in vegetation:
		var at := Vector2(plant[1], plant[2])
		if clearance(at) >= 2.65:
			Flora.tree(valley, ground(at, route), plant[0], plant[3], at.x * 0.71)
	dress_verges(valley)

static func dress_verges(valley):
	var rng := RandomNumberGenerator.new()
	rng.seed = 746
	var roots: Array[Vector4] = []
	for path in PATHS:
		for leg in range(path.size() - 1):
			var start: Vector2 = path[leg]
			var end: Vector2 = path[leg + 1]
			var across := (end - start).orthogonal().normalized()
			for i in range(int(start.distance_to(end) * 1.8)):
				var sample := start.lerp(end, rng.randf()) + across * rng.randf_range(1.06, 5.3) * (-1.0 if i % 2 == 0 else 1.0)
				if clearance(sample) < 0.95 or Creek.trail_distance(sample) < 1.0: continue
				var foot := ground(sample, valley.route)
				roots.append(Vector4(foot.x, foot.y - 0.055, foot.z, rng.randf_range(0.43, 1.55)))
	Flora.grass_batch(valley, roots)

static func dress_find(valley, id: String):
	var entry: Array = FINDS[id]
	var site: Vector2 = entry[2]
	var route = valley.route
	var shelter := Node3D.new()
	valley.add_child(shelter)
	shelter.name = "Alrededores de " + id
	var pose: Vector3 = FIND_POSES[id]
	shelter.position = route.terrain_point(Vector3(site.x, 0, site.y))
	shelter.rotation.y = pose.y
	dress_hideout(shelter, route, id, entry[0])
	var root := Node3D.new()
	shelter.add_child(root)
	root.add_to_group("field_finds")
	root.set_meta("find_id", id)
	root.position.y = pose.z
	root.rotation.x = pose.x
	match int(entry[0]):
		0:
			var sherd := shard(root, "8e523f")
			shard_incision(sherd)
		1:
			piece(root, lathe([Vector2(0.07, 0.0), Vector2(0.23, 0.0), Vector2(0.25, 0.045),
				Vector2(0.17, 0.14), Vector2(0.07, 0.14), Vector2(0.07, 0.0)]), Vector3.ZERO, "8c8070")
		2:
			var grinding := lathe([Vector2(0, 0.009), Vector2(0.205, 0.009), Vector2(0.259, 0.037),
				Vector2(0.273, 0.082), Vector2(0.236, 0.151), Vector2(0.163, 0.186), Vector2(0.0, 0.193)], 13)
			var stone := piece(root, grinding, Vector3.ZERO, "897d69")
			stone.scale.z = 0.61
			stone.rotation.y = 0.48
			var face := lathe([Vector2(0.0, 0.010), Vector2(0.174, 0.010), Vector2(0.188, 0.019), Vector2(0.177, 0.025)], 14)
			piece(stone, face, Vector3(0, 0, 0), "ad9b80")
		3:
			piece(root, lathe([Vector2(0, 0), Vector2(0.15, 0), Vector2(0.22, 0.13),
				Vector2(0.20, 0.24), Vector2(0.14, 0.31), Vector2(0.15, 0.41),
				Vector2(0.115, 0.41), Vector2(0.106, 0.31), Vector2(0.14, 0.21), Vector2(0, 0.06)]),
				Vector3.ZERO, "704e40")
		4:
			slab(root, Vector3(0.62, 0.025, 0.22), Vector3(0, 0.028, 0), "574443")
			for i in 3:
				var slide := slab(root, Vector3(0.155, 0.007, 0.12), Vector3(i * 0.181 - 0.181, 0.045, 0), "927360")
				slide.rotation.y = 0.025 * i
			for i in 9:
				for side in [-1, 1]:
					slab(root, Vector3(0.028, 0.006, 0.021), Vector3(i * 0.064 - 0.25, 0.044, side * 0.087), "c49d78")
			for offset in [Vector3(-0.02, 0.05, 0.018), Vector3(0.04, 0.05, -0.013)]:
				slab(root, Vector3(0.012, 0.006, 0.01), offset, "efc898")
		5:
			slab(root, Vector3(0.53, 0.064, 0.32), Vector3(0, 0.034, 0), "544b43")
			slab(root, Vector3(0.43, 0.008, 0.21), Vector3(0, 0.069, -0.015), "b19c77")
			for x in [-0.134, 0.134]:
				var hub := lathe([Vector2(0.024, 0), Vector2(0.065, 0), Vector2(0.065, 0.014),
					Vector2(0.024, 0.014), Vector2(0.024, 0)])
				piece(root, hub, Vector3(x, 0.073, -0.03), "554f46")
			slab(root, Vector3(0.33, 0.04, 0.083), Vector3(0, 0.04, 0.127), "655c53")
		6:
			var panel := shard(root, "77766c")
			panel.scale = Vector3(1.24, 0.9, 1.0)
			for spot in [Vector2(-0.08, 0.06), Vector2(0.15, 0.02), Vector2(0.04, -0.075), Vector2(0.16, -0.10)]:
				piece(panel, lathe([Vector2(0.0, 0), Vector2(0.016, 0), Vector2(0.016, 0.005), Vector2(0.0, 0.005)]),
					Vector3(spot.x, 0.028, spot.y), "4b483e")
		7:
			var can := lathe([Vector2(0, 0), Vector2(0.19, 0), Vector2(0.19, 0.19),
				Vector2(0.164, 0.19), Vector2(0.164, 0.027), Vector2(0.0, 0.027)])
			piece(root, can, Vector3(0.10, 0, 0), "a08c69")
			var lid := lathe([Vector2(0.0, 0), Vector2(0.17, 0), Vector2(0.17, 0.016), Vector2(0.0, 0.016)])
			piece(root, lid, Vector3(-0.23, 0.022, 0.035), "8b8267")
			var paper := slab(root, Vector3(0.17, 0.015, 0.18), Vector3(0.11, 0.16, -0.025), "c5b589")
			paper.rotation.x = -0.36

	var glint_height: float = [0.054, 0.14, 0.15, 0.42, 0.063, 0.083, 0.048, 0.19][entry[0]]
	Visual.glint(root, Vector3(0.07, glint_height, 0.08), Color("#e2c29a"))
	var target := StaticBody3D.new()
	target.collision_layer = 2
	target.collision_mask = 0
	target.set_meta("item", entry[1])
	target.set_meta("find_id", id)
	root.add_child(target)
	var hitbox := BoxShape3D.new()
	hitbox.size = Vector3(0.66, 0.20, 0.46)
	if id == "vasija": hitbox.size = Vector3(0.47, 0.43, 0.47)
	var shape := CollisionShape3D.new()
	shape.shape = hitbox
	target.add_child(shape)
	shape.position.y = hitbox.size.y * 0.48

static func dress_hideout(site: Node3D, route, id: String, index: int):
	var stones: Array = []
	var shrubs: Array = []
	match id:
		"tiesto":
			stones = [[Vector2(-0.22, -0.78), Vector3(1.80, 0.68, 0.94), 0.12]]
		"tortero":
			stones = [[Vector2(-0.50, -0.66), Vector3(1.28, 0.44, 0.73), -0.2]]
			shrubs = [[Vector2(0.81, -0.71), Flora.Kind.MOLLE, 0.97]]
		"mano":
			stones = [[Vector2(-0.47, -0.84), Vector3(1.70, 0.69, 1.00), 0.2]]
			var base := lathe([Vector2(0, 0.01), Vector2(0.26, 0.01), Vector2(0.32, 0.045),
				Vector2(0.27, 0.11), Vector2(0.19, 0.105), Vector2(0.15, 0.07), Vector2(0, 0.053)], 13)
			piece(site, base, bed_at(site, route, Vector2(0.42, 0.01)), "7f7563").scale.z = 0.76
		"vasija":
			stones = [[Vector2(0.03, -0.81), Vector3(1.36, 0.53, 0.83), -0.22]]
			shrubs = [[Vector2(-1.19, -0.82), Flora.Kind.PIQUILLIN, 1.18],
				[Vector2(1.24, -0.92), Flora.Kind.PIQUILLIN, 1.27]]
		"negativo":
			stones = [[Vector2(-0.55, -0.77), Vector3(0.86, 0.33, 0.78), 0.3]]
			shrubs = [[Vector2(1.03, -1.38), Flora.Kind.ESPINILLO, 0.99]]
			var branch := bed_at(site, route, Vector2(-0.68, -0.46))
			Flora.branch(site, branch, bed_at(site, route, Vector2(0.55, -0.42)) + Vector3.UP * 0.052, 0.09, 0.031, true)
		"cinta":
			stones = [[Vector2(-0.50, -0.81), Vector3(1.63, 0.82, 1.23), -0.2],
				[Vector2(0.61, -0.32), Vector3(0.96, 0.43, 1.06), 0.67]]
		"placa":
			stones = [[Vector2(0.14, -0.55), Vector3(1.74, 0.56, 1.13), 0.12]]
		"lata":
			stones = [[Vector2(-0.03, -1.09), Vector3(1.67, 0.94, 1.38), -0.26]]
	var anchors := Callable(route, "terrain_point")
	var rng := RandomNumberGenerator.new()
	rng.seed = 709 + 29 * index
	var faces := Stone.surface()
	for rock in stones:
		var at := site.to_global(bed_at(site, route, rock[0]))
		var shape := Stone.fragment(faces, at, rock[1], site.rotation.y + rock[2], rng, anchors)
		Stone.solid(site.get_parent(), at, shape, "Laja junto al hallazgo")
	Stone.finish(site.get_parent(), faces, "Piedras junto a " + id)
	for shrub in shrubs:
		Flora.tree(site, bed_at(site, route, shrub[0]), shrub[1], shrub[2], rng.randf_range(-PI, PI))
	var tufts: Array[Vector4] = []
	for i in 12:
		var x := rng.randf_range(0.48, 1.17) * (-1.0 if i % 2 == 0 else 1.0)
		var foot := bed_at(site, route, Vector2(x, rng.randf_range(-1.25, 0.40)))
		tufts.append(Vector4(foot.x, foot.y - 0.045, foot.z, rng.randf_range(0.35, 0.78)))
	Flora.grass_batch(site, tufts)

static func bed_at(site: Node3D, route, offset: Vector2) -> Vector3:
	var flat := site.to_global(Vector3(offset.x, 0, offset.y))
	return site.to_local(route.terrain_point(flat))

static func slab(parent: Node3D, size: Vector3, position: Vector3, tint: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return piece(parent, mesh, position, tint)

static func piece(parent: Node3D, mesh: Mesh, position: Vector3, tint: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(tint)
	clay.roughness = 0.92
	clay.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = clay
	parent.add_child(node)
	node.position = position
	return node

static func lathe(profile: Array, sides: int = 14) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for i in sides:
			var a := TAU * i / sides
			var b := TAU * (i + 1) / sides
			var ring: Vector2 = profile[row]
			var top: Vector2 = profile[row + 1]
			var bottom_a := Vector3(cos(a) * ring.x, ring.y, sin(a) * ring.x)
			var bottom_b := Vector3(cos(b) * ring.x, ring.y, sin(b) * ring.x)
			var top_a := Vector3(cos(a) * top.x, top.y, sin(a) * top.x)
			var top_b := Vector3(cos(b) * top.x, top.y, sin(b) * top.x)
			for vertex in [bottom_a, top_b, bottom_b, bottom_a, top_a, top_b]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

static func shard(parent: Node3D, tint: String) -> MeshInstance3D:
	var outline := PackedVector2Array([Vector2(-0.24, -0.11), Vector2(-0.09, -0.18),
		Vector2(0.15, -0.14), Vector2(0.24, 0.03), Vector2(0.12, 0.16),
		Vector2(-0.13, 0.16), Vector2(-0.20, 0.077)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var lower_a := Vector3(a.x, 0.006, a.y)
		var lower_b := Vector3(b.x, 0.006, b.y)
		var top_a := lower_a + Vector3.UP * 0.019
		var top_b := lower_b + Vector3.UP * 0.019
		for vertex in [Vector3(0, 0.025, 0), top_a, top_b, lower_a, lower_b, top_a, top_a, lower_b, top_b]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return piece(parent, surface.commit(), Vector3.ZERO, tint)

static func shard_incision(parent: Node3D):
	for i in range(5):
		var x := -0.15 + 0.064 * i
		var mark := slab(parent, Vector3(0.088, 0.003, 0.01), Vector3(x, 0.027, -0.02), "543a30")
		mark.rotation.y = 0.74 if i % 2 == 0 else -0.74
