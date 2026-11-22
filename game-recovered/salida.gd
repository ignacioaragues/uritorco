extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Arrival = preload("res://llegada.gd")
const Flora = preload("res://flora.gd")
const LastNight = preload("res://final_night.gd")
const Stone = preload("res://piedra_serrana.gd")
const PATH := [Vector2(3.8, -13.2), Vector2(12, -16.8), Vector2(18.6, -10.8), Vector2(22.8, -0.6),
	Vector2(22.7, 12.0), Vector2(23.9, 25.0), Vector2(27.8, 37.4), Vector2(29.6, 49.7), Vector2(28.2, 62.0)]
const RADIO_STOP := Vector3(23.9, 0, 25.0)
const END := Vector3(28.2, 0, 62.0)
const MARA_PATH := [Vector2(29.6, 49.7), Vector2(31.6, 55.4), Vector2(33.4, 59.6), Vector2(41.8, 61.1)]
const MARA_END := Vector3(41.8, 0, 61.1)
const BUS_ROAD_POSITION := Vector3(1.65, 0, -4.2)
const BUS_START := Vector3(6.10, 0, -6.45)
const BUS_BOUNDS := Rect2(-30, -16, 60, 35)
const MARA_SITE := Vector3(-760, 72, 1650)
const MARA_START := Vector3(0, 0.02, -2.10)
const MARA_BOUNDS := Rect2(-26, -23, 52, 52)
const SCENE_LAYER := 1 << 19
const TIRE_RADIUS := 0.48
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
		coach(roadside, Arrival.surface_point(0, BUS_ROAD_POSITION))
	return roadside.to_global(Arrival.surface_point(0, BUS_START) + Vector3.UP * 0.02)

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
		var lane := 4.3 * sin((z + 4.5) * 0.093) * smoothstep(0.0, 9.0, z + 4.5)
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

static func coach(parent: Node3D, vehicle: Vector3):
	var shell := Kit.item(parent, vehicle, "Subir al ómnibus", Vector3.UP * 1.55, Vector3(7.39, 2.82, 2.41))
	shell.name = "Ómnibus"
	var paint := bodywork("c0b598", shell.global_position.y, 0.92)
	var burgundy := bodywork("884f43", shell.global_position.y, 0.96)
	var aluminum := bodywork("8d8d81", shell.global_position.y, 0.68)
	var rubber := Kit.material("3e3b35")
	var glass := Kit.tinted_glass("536463")
	var floor_heat := Kit.material("514841", false, 0.77)
	Kit.block(shell, Vector3.UP * 1.68, Vector3(7.32, 2.12, 2.36), paint)
	Kit.block(shell, Vector3.UP * 0.91, Vector3(7.38, 0.39, 2.41), burgundy)
	Kit.block(shell, Vector3.UP * 1.22, Vector3(7.37, 0.044, 2.39), aluminum)
	Kit.block(shell, Vector3.UP * 2.74, Vector3(7.19, 0.15, 2.28), paint)
	Kit.block(shell, Vector3.UP * 2.835, Vector3(7.06, 0.055, 1.98), paint)
	for side in [-1.0, 1.0]:
		Kit.block(shell, Vector3(0, 2.651, side * 1.186), Vector3(7.20, 0.068, 0.065), aluminum)
		Kit.block(shell, Vector3(0, 0.655, side * 1.17), Vector3(7.23, 0.095, 0.075), floor_heat)
		for i in 7:
			var window := Vector3(-2.88 + 0.96 * i, 2.06, side * 1.184)
			Kit.block(shell, window, Vector3(0.86, 0.79, 0.031), rubber)
			Kit.block(shell, window + Vector3.BACK * side * 0.018, Vector3(0.749, 0.678, 0.025), glass)
			Kit.block(shell, window + Vector3(0, -0.123, side * 0.033), Vector3(0.751, 0.023, 0.023), aluminum)
		for x in [-2.44, 2.31]:
			var hub := Vector3(x, TIRE_RADIUS, side * 1.093)
			var axle := Kit.cylinder(shell, hub, TIRE_RADIUS, TIRE_RADIUS, 0.33, rubber)
			axle.name = "Neumático"
			axle.rotation.x = PI * 0.5
			(axle.mesh as CylinderMesh).radial_segments = 24
			Kit.cylinder(shell, hub + Vector3.BACK * side * 0.18,
				0.254, 0.254, 0.044, aluminum).rotation.x = PI * 0.5
			Kit.cylinder(shell, hub + Vector3.BACK * side * 0.21,
				0.136, 0.136, 0.046, floor_heat).rotation.x = PI * 0.5
			for lug in 6:
				var angle := TAU * lug / 6
				Kit.block(shell, hub + Vector3(cos(angle) * 0.171, sin(angle) * 0.171, side * 0.211),
					Vector3(0.035, 0.034, 0.023), aluminum)
		coach_label(shell, Vector3(-0.57, 1.45, side * 1.188), 0 if side > 0 else PI, 0.0028, "CAPILLA DEL MONTE")
	front_and_rear(shell, aluminum, rubber, glass)

static func front_and_rear(shell: Node3D, aluminum: Material, rubber: Material, glass: Material):
	for side in [-1.0, 1.0]:
		var end: float = side * 3.68
		Kit.block(shell, Vector3(end, 2.10, 0), Vector3(0.055, 0.83, 2.07), rubber)
		Kit.block(shell, Vector3(end + side * 0.035, 2.10, 0), Vector3(0.025, 0.72, 1.965), glass)
		Kit.block(shell, Vector3(end + side * 0.052, 2.10, 0), Vector3(0.029, 0.75, 0.052), aluminum)
		Kit.block(shell, Vector3(end, 0.766, 0), Vector3(0.19, 0.142, 2.42), aluminum)
		var lamp := Kit.material("d9c594" if side > 0 else "874c3e", false, 0.36)
		for edge in [-0.83, 0.83]:
			var lamp_position := Vector3(end + side * 0.025, 1.112, edge)
			Kit.cylinder(shell, lamp_position, 0.167, 0.167, 0.073, aluminum).rotation.z = PI * 0.5
			Kit.cylinder(shell, lamp_position + Vector3.RIGHT * side * 0.045, 0.136, 0.136, 0.053, lamp).rotation.z = PI * 0.5
		var plate := Kit.material("c8bb9f")
		Kit.block(shell, Vector3(end + side * 0.06, 0.911, 0), Vector3(0.036, 0.132, 0.36), plate)
	var grille := Kit.material("534d41", false, 0.62)
	Kit.block(shell, Vector3(3.721, 1.118, 0), Vector3(0.06, 0.288, 1.03), grille)
	for level in 5:
		Kit.block(shell, Vector3(3.761, 1.01 + 0.05 * level, 0), Vector3(0.025, 0.019, 0.96), aluminum)
	for side in [-1.0, 1.0]:
		var wiper := Kit.block(shell, Vector3(3.745, 1.927, side * 0.496),
			Vector3(0.016, 0.024, 0.59), rubber)
		wiper.rotation.x = side * 0.23
		Kit.block(shell, Vector3(3.38, 2.286, side * 1.32), Vector3(0.038, 0.042, 0.33), aluminum)
		Kit.block(shell, Vector3(3.36, 2.31, side * 1.464), Vector3(0.098, 0.239, 0.135), rubber)
	coach_label(shell, Vector3(3.67, 2.624, 0), PI * 0.5, 0.0017, "CAPILLA DEL MONTE")

static func bodywork(tint: String, height: float, exposure: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://chapa_omnibus.gdshader")
	material.set_shader_parameter("enamel", Color(tint))
	material.set_shader_parameter("axle_height", height)
	material.set_shader_parameter("exposure", exposure)
	return material

static func coach_label(parent: Node3D, point: Vector3, yaw: float, size: float, content: String):
	var label := Label3D.new()
	label.text = content
	label.font_size = 45
	label.pixel_size = size
	label.outline_size = 0
	label.modulate = Color("#754b3e")
	parent.add_child(label)
	label.position = point
	label.rotation.y = yaw
