extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Arrival = preload("res://llegada.gd")
const Flora = preload("res://flora.gd")
const LastNight = preload("res://final_night.gd")
const Stone = preload("res://piedra_serrana.gd")
const Coach = preload("res://omnibus.gd")
const Garden = preload("res://jardin_mara.gd")
const PATH := [Vector2(3.8, -13.2), Vector2(12, -16.8), Vector2(18.6, -10.8), Vector2(22.8, -0.6),
	Vector2(22.7, 12.0), Vector2(23.9, 25.0), Vector2(27.8, 37.4), Vector2(29.6, 49.7), Vector2(28.2, 62.0),
	Vector2(25.2, 72), Vector2(22.4, 86), Vector2(12.0, 124)]
const RADIO_STOP := Vector3(23.9, 0, 25.0)
const END := Vector3(28.2, 0, 62.0)
const FORK := Vector3(29.6, 0, 49.7)
const MARA_PATH := [Vector2(29.6, 49.7), Vector2(31.6, 55.4), Vector2(33.4, 59.6), Vector2(41.8, 61.1),
	Vector2(53.7, 66.4), Vector2(63.5, 78), Vector2(79.0, 92.0)]
const MARA_END := Vector3(41.8, 0, 61.1)
const BUS_ROAD_POSITION := Vector3(1.65, 0, -4.2)
const BUS_BOUNDS := Rect2(-30, -16, 60, 35)
const MARA_SITE := Vector3(-760, 72, 1650)
const MARA_START := Vector3(2.07, 0.02, 4.50)
const MARA_BOUNDS := Rect2(-26, -23, 52, 52)
const SCENE_LAYER := 1 << 19
const PACK_ITEMS := ["Observar el Cielo", "Recorte de astronomía", "Postal de Paula", "Dibujos"]
const PACK_NAMES := ["el libro", "los papeles", "la postal", "los dibujos"]

static func near(at: Vector3, point: Vector3, radius: float) -> bool:
	return Vector2(at.x - point.x, at.z - point.z).length_squared() < radius * radius

static func edge_distance(point: Vector2) -> float:
	var best := INF
	for i in PATH.size() - 1:
		best = minf(best, Geometry2D.get_closest_point_to_segment(point, PATH[i], PATH[i + 1]).distance_to(point))
	return best

static func open(valley):
	var knots := PackedVector2Array(PATH)
	valley.route.ground_material.set_shader_parameter("departure_path", knots)
	valley.route.ground_material.set_shader_parameter("departure_branch", PackedVector2Array(MARA_PATH))
	valley.route.ground_material.set_shader_parameter("departure_open", true)
	valley.route.signpost(Vector3(11.9, 0.0, -19.1), "Bajada a la ruta →", PI * 0.5, true)
	valley.route.signpost(Vector3(27.8, 0.0, 30.0), "Ruta · Capilla del Monte ↑", PI, true)
	valley.route.signpost(Vector3(27.0, 0.0, 49.0), "Camino vecinal ←\nRuta ↑", PI, true)

static func trail_end(destination: String) -> Vector3:
	return MARA_END if destination == "mara" else END

static func isolate(scene: Node3D):
	for part in scene.find_children("*", "VisualInstance3D", true, false):
		(part as VisualInstance3D).layers |= SCENE_LAYER

static func bus(roadside: Node3D) -> Vector3:
	if not roadside.has_node("Ómnibus"):
		Coach.build(roadside, Arrival.surface_point(0, BUS_ROAD_POSITION))
	var start := Vector3(12.9, 0, Arrival.branch_z(12.9))
	return roadside.to_global(Arrival.surface_point(0, start) + Vector3.UP * 0.02)

static func mara(valley) -> Node3D:
	var yard := Node3D.new()
	yard.name = "Escena del puesto de Mara"
	valley.add_child(yard)
	yard.position = MARA_SITE
	var finish := Arrival.terrain_material(8, "6c7258", "9d8868")
	finish.set_shader_parameter("lane_to_house", true)
	var terrain := Kit.mesh_part(yard, Arrival.terrain_mesh(mara_height), Vector3.ZERO, finish)
	terrain.name = "Terreno del puesto de Mara"
	terrain.create_trimesh_collision()
	Arrival.build_ridges(yard, Vector3.ZERO, 8, Arrival.ridge_materials(valley))
	var first: int = valley.get_child_count()
	LastNight.build_door(valley, MARA_SITE)
	for prop in valley.get_children().slice(first):
		prop.reparent(yard)
	dress_mara_yard(yard)
	Garden.dress(yard)
	dress_mara_woodland(yard)
	return yard

static func mara_height(x: float, distance: float) -> float:
	var verge := smoothstep(12.0, 46.0, maxf(absf(x), absf(distance)))
	var slope := 1.9 * sin(x * 0.073 + distance * 0.068) + 1.4 * sin(distance * 0.115 - x * 0.048)
	var hills := 7.8 * exp(-Vector2((x + 39.0) / 27.0, (distance - 7.0) / 34.0).length_squared())
	hills += 5.2 * exp(-Vector2((x - 33.0) / 29.0, (distance - 36.0) / 30.0).length_squared())
	return (slope + hills) * verge

static func dress_mara_yard(yard: Node3D):
	var rng := RandomNumberGenerator.new()
	rng.seed = 1284
	var faces := Stone.surface()
	var grass: Array[Vector4] = []
	for i in 195:
		var x := rng.randf_range(-49.0, 52.0)
		var z := rng.randf_range(-51.0, 53.0)
		if absf(x) < 4.7 and z > -12.0 and z < 4.0: continue
		var lane := 4.3 * sin((z + 4.5) * 0.093) * smoothstep(3.0, 13.0, z + 4.5)
		if z > -4.85 and absf(x - lane) < 2.38: continue
		var at := Vector3(x, mara_height(x, -z), z)
		if i % 19 == 0 and absf(x) > 7.0:
			var species := Flora.Kind.TALA if i % 2 == 0 else Flora.Kind.MOLLE
			Flora.tree(yard, at - Vector3.UP * 0.03, species, rng.randf_range(0.79, 1.42), rng.randf() * TAU)
		elif i % 6 == 0:
			var size_m := rng.randf_range(0.52, 1.50)
			var shape := Stone.fragment(faces, at - Vector3.UP * 0.075, Vector3(1.25, 0.44, 0.93) * size_m,
				rng.randf() * TAU, rng, Callable(), Stone.LAJA_PROFILE)
			if MARA_BOUNDS.has_point(Vector2(at.x, at.z)):
				Stone.solid(yard, at, shape, "Piedra del puesto")
		else:
			grass.append(Vector4(at.x, at.y - 0.062, at.z, rng.randf_range(0.55, 1.39)))
	Stone.finish(yard, faces, "Lajas del puesto")
	Flora.grass_batch(yard, grass)

static func dress_mara_woodland(yard: Node3D):
	var rng := RandomNumberGenerator.new()
	rng.seed = 9371
	var grass: Array[Vector4] = []
	var shrubs: Array[Vector4] = []
	var groves := [
		Vector2(-8, -3), Vector2(-11, 0), Vector2(-9, 6), Vector2(-14, 9),
		Vector2(8, -6), Vector2(14, -2), Vector2(11, 5), Vector2(16, 10),
		Vector2(-6, -12), Vector2(-13, -12), Vector2(-5, -19), Vector2(2, -15),
		Vector2(8, -14), Vector2(14, -18), Vector2(-19, -7), Vector2(19, -8),
	]
	for i in groves.size():
		var grove: Vector2 = groves[i]
		var species := [Flora.Kind.MOLLE, Flora.Kind.ESPINILLO, Flora.Kind.TALA][i % 3] as Flora.Kind
		Flora.tree(yard, Vector3(grove.x, mara_height(grove.x, -grove.y) - 0.04, grove.y),
			species, rng.randf_range(0.72, 1.16), rng.randf() * TAU, 1.0, i % 7 == 1)
		for j in 18:
			var point := grove + Vector2(rng.randf_range(-3.2, 3.2), rng.randf_range(-2.6, 2.6))
			var lane := 4.3 * sin((point.y + 4.5) * 0.093) * smoothstep(3.0, 13.0, point.y + 4.5)
			if point.y > -4.85 and absf(point.x - lane) < 2.5: continue
			if absf(point.x) < 5.6 and point.y > -11.0 and point.y < 5.0: continue
			var root := Vector4(point.x, mara_height(point.x, -point.y) - 0.043, point.y, rng.randf_range(0.48, 1.25))
			if j % 4 == 0:
				shrubs.append(root)
			else:
				grass.append(root)
	Flora.grass_batch(yard, grass)
	Flora.herb_batch(yard, shrubs, Flora.Herb.ROMERILLO)
