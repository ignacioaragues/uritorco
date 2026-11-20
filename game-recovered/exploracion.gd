extends RefCounted

const Flora = preload("res://flora.gd")
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

# Los índices corresponden a las láminas del cuaderno.
const FINDS = {
	"tiesto": [0, "Tiesto con guarda", Vector2(-35.5, -23.2), "Asomaba de la tierra junto a una laja del oeste. La guarda sigue el borde. Uno de los surcos todavía tiene tierra. Dibujé cómo estaba apoyado."],
	"tortero": [1, "Tortero de piedra", Vector2(31, 13.6), "A la sombra del mollar. La perforación se ensancha de un lado. Se parece a los torteros que vi en el museo. Dibujé el lado más gastado."],
	"mano": [2, "Mano de moler", Vector2(-30.0, 59.5), "En el recodo del cauce. La cara que queda arriba brilla como si la hubieran pulido. Al lado hay una piedra chata con una marca ancha. Dibujé la pieza de canto."],
	"vasija": [3, "Vasija de barro", Vector2(-8.4, -64.5), "Asomaba entre las raíces, por arriba de la parada. Tiene el borde grueso y una rajadura con tierra adentro. La dibujé en el hueco, con la boca hacia la ladera."],
	"negativo": [4, "Negativo velado", Vector2(42.6, -0.6), "En el borde del mollar, contra la luz. Uno de los cuadros tiene dos manchas. La mayor podría ser una raya de la película. Dibujé también las perforaciones."],
	"cinta": [5, "Casete rajado", Vector2(-201.8, -574.4), "Entre el cable y la cantera, detrás de unas lajas. La caja se abre por una esquina. Hay cinta entre los dos carretes. Al margen de la etiqueta, alguien escribió «canal libre»."],
	"placa": [6, "Chapa perforada", Vector2(14, 46), "En la vuelta por el sur. Los agujeros tienen rebaba de un solo lado. Si la levanto hacia el cielo, parecen un grupo de estrellas. Cambia por completo al girarla."],
	"lata": [7, "Croquis en una lata", Vector2(-47.6, -473), "En la subida al abra, detrás de una piedra. Dentro de la lata quedó un croquis doblado. Dos líneas cruzan una ladera. El papel se rompe justo donde se juntan."]
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
	for path in [EAST, WEST, SOUTH]:
		for i in range(path.size() - 1):
			result.append(path[i])
			result.append(path[i + 1])
	return result

static func clearance(point: Vector2) -> float:
	var distance := INF
	for path in [EAST, WEST, SOUTH]:
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
	for path in [EAST, WEST, SOUTH]:
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
	var footprint := ground(entry[2], valley.route)
	var old_piece := int(entry[0]) < 4
	var root := Node3D.new()
	valley.add_child(root)
	if old_piece:
		var exposed := 0.27 if id == "tiesto" else 0.16
		valley.stone(footprint + Vector3.DOWN * 0.11, Vector3(1.35, exposed * 2.0 + 0.24, 0.97), "877b6a", true)
		root.position = footprint + Vector3.UP * exposed
	else:
		var stand: MeshInstance3D = valley.stone(footprint + Vector3.UP * 0.35, Vector3(1.55, 0.78, 1.18), "807565", true)
		root.position = stand.position + Vector3.UP * 0.38
	root.rotation.y = sin(footprint.x * 0.82) * 0.58
	match int(entry[0]):
		0:
			var sherd := shard(root, "8e523f")
			shard_incision(sherd)
		1:
			piece(root, lathe([Vector2(0.07, 0.0), Vector2(0.23, 0.0), Vector2(0.25, 0.045),
				Vector2(0.17, 0.14), Vector2(0.07, 0.14), Vector2(0.07, 0.0)]), Vector3.ZERO, "8c8070")
		2:
			var handstone := SphereMesh.new()
			handstone.radial_segments = 8
			handstone.rings = 4
			var stone := piece(root, handstone, Vector3(0, 0.115, 0), "988c76")
			stone.scale = Vector3(0.56, 0.24, 0.29)
			stone.rotation.y = 0.48
		3:
			for side in [-1.0, 1.0]:
				var start := Vector3(side * 0.58, -0.27, -0.20)
				var knot := Vector3(side * 0.38, 0.034, -0.17 + side * 0.16)
				Flora.branch(root, start, knot, 0.08, 0.032)
				Flora.branch(root, knot, Vector3(side * 0.28, -0.04, 0.24), 0.032, 0.009)
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
			var panel := shard(root, "92928b")
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
