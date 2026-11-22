extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Creek = preload("res://cauce.gd")
const PATH := [Vector2(3.8, -13.2), Vector2(12, -16.8), Vector2(18.6, -10.8), Vector2(22.8, -0.6),
	Vector2(22.7, 12.0), Vector2(23.9, 25.0), Vector2(27.8, 37.4), Vector2(29.6, 49.7), Vector2(28.2, 62.0)]
const RADIO_STOP := Vector3(23.9, 0, 25.0)
const END := Vector3(28.2, 0, 62.0)
const MARA_PATH := [Vector2(29.6, 49.7), Vector2(31.6, 55.4), Vector2(33.4, 59.6), Vector2(41.8, 61.1)]
const MARA_END := Vector3(41.8, 0, 61.1)
const BUS_STOP := Vector3(144, 0, -429)
const MARA_STOP := Vector3(-148, 0, -421)
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

static func bus(valley) -> Vector3:
	var start: Vector3 = valley.route.terrain_point(BUS_STOP)
	var road := Kit.material("535453", false, 0.96)
	var board := Kit.material("cbbe99", true)
	var metal := Kit.material("514f3e")
	var grass := Vector3.UP * 0.04
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(-20, 20):
		for offset in [Vector2.ZERO, Vector2.RIGHT, Vector2(0, 5), Vector2.RIGHT, Vector2(1, 5), Vector2(0, 5)]:
			var p: Vector3 = valley.route.terrain_point(start + Vector3(i + offset.x, 0, offset.y - 2))
			surface.add_vertex(p + grass)
	surface.generate_normals()
	Kit.mesh_part(valley, surface.commit(), Vector3.ZERO, road)
	var stop := Node3D.new()
	valley.add_child(stop)
	stop.position = start
	for x in [-1.7, 1.7]:
		var base: Vector3 = valley.route.terrain_point(start + Vector3(x, 0, -2.28)) - start
		Kit.block(stop, base + Vector3.UP * 1.35, Vector3(0.12, 2.71, 0.14), metal)
	Kit.block(stop, Vector3(0, 2.65, -2.01), Vector3(3.9, 0.10, 1.27), metal)
	Kit.block(stop, Vector3(0, 0.62, -1.93), Vector3(2.64, 0.079, 0.37), board)
	Kit.block(stop, Vector3(0, 1.86, -2.24), Vector3(1.98, 0.31, 0.04), board)
	var label := Label3D.new()
	label.text = "ÓMNIBUS · CAPILLA DEL MONTE"
	label.font_size = 42
	label.pixel_size = 0.0024
	label.outline_size = 0
	label.modulate = Color("#494733")
	stop.add_child(label)
	label.position = Vector3(0, 1.86, -2.19)
	var vehicle: Vector3 = valley.route.terrain_point(start + Vector3(3.0, 0.0, 1.1))
	var bus_body := Kit.item(valley, vehicle, "Subir al ómnibus", Vector3.UP * 1.55, Vector3(7.35, 2.82, 2.4))
	var paint := Kit.material("b3af8f", false, 0.67)
	var dark := Kit.material("405152", false, 0.48)
	var red := Kit.material("875548")
	var rubber := Kit.material("353432")
	Kit.block(bus_body, Vector3.UP * 1.72, Vector3(7.32, 2.16, 2.37), paint)
	Kit.block(bus_body, Vector3.UP * 0.91, Vector3(7.36, 0.37, 2.40), red)
	Kit.block(bus_body, Vector3(3.67, 1.98, 0), Vector3(0.026, 0.68, 1.95), dark)
	for side in [-1.0, 1.0]:
		for i in 7:
			Kit.block(bus_body, Vector3(-2.88 + 0.96 * i, 2.02, side * 1.19), Vector3(0.79, 0.68, 0.021), dark)
		for x in [-2.44, 2.31]:
			Kit.cylinder(bus_body, Vector3(x, 0.47, side * 1.08), 0.50, 0.50, 0.31, rubber).rotation.x = PI * 0.5
	return valley.route.terrain_point(start + Vector3(0.35, 0, -0.74)) + Vector3.UP * 0.08
