extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const TIRE_RADIUS := 0.48
const WHEEL_ARCH := 0.565
const AXLES := [-2.44, 2.31]
const FRONT := 3.68
const REAR := -3.62

# Cada estación define la anchura y la caída del techo al llegar a las puntas.
const STATIONS := [
	Vector3(REAR, 0.85, 0.16), Vector3(-3.49, 0.94, 0.096), Vector3(-3.24, 0.987, 0.025),
	Vector3(-3.04, 1.0, 0.0), Vector3(3.04, 1.0, 0.0), Vector3(3.32, 0.985, 0.033),
	Vector3(3.53, 0.95, 0.091), Vector3(FRONT, 0.88, 0.17),
]
const SECTION := [
	Vector2(0.63, -0.98), Vector2(0.70, -1.09), Vector2(0.86, -1.16), Vector2(1.12, -1.197),
	Vector2(1.55, -1.20), Vector2(2.27, -1.198), Vector2(2.50, -1.16), Vector2(2.64, -1.09),
	Vector2(2.75, -0.93), Vector2(2.82, -0.66), Vector2(2.86, -0.32), Vector2(2.87, 0),
	Vector2(2.86, 0.32), Vector2(2.82, 0.66), Vector2(2.75, 0.93), Vector2(2.64, 1.09),
	Vector2(2.50, 1.16), Vector2(2.27, 1.198), Vector2(1.55, 1.20), Vector2(1.12, 1.197),
	Vector2(0.86, 1.16), Vector2(0.70, 1.09), Vector2(0.63, 0.98),
]

static func build(parent: Node3D, at: Vector3):
	var bus := Kit.item(parent, at, "Subir al ómnibus", Vector3.UP * 1.61, Vector3(7.36, 2.4, 2.38))
	bus.name = "Ómnibus"
	var metal := bodywork("8e9083", bus.global_position.y, 0.64)
	var rubber := Kit.material("333631")
	var glass := Kit.tinted_glass("536463")
	var frame := Kit.material("4b4940", false, 0.71)
	var paint := bodywork("c0b598", bus.global_position.y, 0.92)
	paint.set_shader_parameter("coach_livery", true)
	var body := Kit.mesh_part(bus, shell_mesh(), Vector3.ZERO, paint)
	body.name = "Carrocería curva"
	for side in [-1.0, 1.0]:
		side_details(bus, side, glass, rubber, metal)
		wheels(bus, side, rubber, frame, metal)
	coach_ends(bus, metal, rubber, glass, frame)

static func bus_station(x: float) -> Vector2:
	for i in range(1, STATIONS.size()):
		var right: Vector3 = STATIONS[i]
		if x > right.x: continue
		var left: Vector3 = STATIONS[i - 1]
		return Vector2(left.y, left.z).lerp(Vector2(right.y, right.z), inverse_lerp(left.x, right.x, x))
	return Vector2(STATIONS[-1].y, STATIONS[-1].z)

static func arch_height(x: float) -> float:
	var lift := 0.0
	for axle: float in AXLES:
		var dx := x - axle
		var radicand := WHEEL_ARCH * WHEEL_ARCH - dx * dx
		if radicand > 0.0:
			lift = maxf(lift, TIRE_RADIUS + sqrt(radicand) - SECTION[0].x)
	return lift

static func shell_mesh() -> ArrayMesh:
	var profile_x: Array[float] = []
	for station: Vector3 in STATIONS:
		profile_x.append(station.x)
	for axle: float in AXLES:
		for index in 13:
			profile_x.append(axle + (index - 6.0) * WHEEL_ARCH / 6.0)
	profile_x.sort()
	var vertices := PackedVector3Array()
	for x in profile_x:
		var station := bus_station(x)
		var arch := arch_height(x)
		var roof_sweep := 1.0 - smoothstep(0.89, 1.0, station.x)
		for point: Vector2 in SECTION:
			var roof := smoothstep(1.65, 2.85, point.x)
			var bottom := 1.0 - smoothstep(0.63, 1.15, point.x)
			vertices.append(Vector3(x - signf(x) * roof_sweep * roof * 0.09,
				point.x - station.y * roof + bottom * arch, point.y * station.x))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices: surface.add_vertex(vertex)
	var span := SECTION.size()
	for row in profile_x.size() - 1:
		for i in span:
			var a := row * span + i
			var b := row * span + (i + 1) % span
			for index in [a, a + span, b, b, a + span, b + span]: surface.add_index(index)
	for side in [-1, 1]:
		var first := 0 if side < 0 else (profile_x.size() - 1) * span
		var end := REAR if side < 0 else FRONT
		var center := vertices.size() + (0 if side < 0 else 1)
		surface.add_vertex(Vector3(end, 1.68, 0))
		for i in span:
			var a := first + i
			var b := first + (i + 1) % span
			for index in ([center, a, b] if side < 0 else [center, b, a]): surface.add_index(index)
	surface.generate_normals()
	return surface.commit()

static func side_details(bus: Node3D, side: float, glass: Material, rubber: Material, metal: Material):
	var direction := Vector3.BACK * side
	for i in 7:
		var x := -2.87 + i * 0.95
		var window := Vector2(x, 2.057)
		var frame_size := Vector2(0.862, 0.696)
		var projection := func(p: Vector2) -> Vector3:
			return Vector3(p.x, p.y, side * (bus_station(p.x).x * 1.184 + 0.024))
		var pane := func(p: Vector2) -> Vector3: return projection.call(p) + direction * 0.010
		panel(bus, window, frame_size, 0.084, projection, direction, rubber)
		panel(bus, window, frame_size - Vector2(0.061, 0.064), 0.061, pane, direction, glass)
		var bottom: Vector3 = pane.call(window + Vector2(0, -0.104))
		Kit.block(bus, bottom + direction * 0.013, Vector3(0.766, 0.019, 0.023), metal)
	var molding := PackedVector3Array()
	for station: Vector3 in STATIONS:
		molding.append(Vector3(station.x, 1.265, side * (1.195 * station.y + 0.007)))
	Kit.cord(bus, molding, 0.021, metal)
	coach_label(bus, Vector3(-0.50, 1.475, side * 1.211), 0.0 if side > 0.0 else PI, 0.0027, "CAPILLA DEL MONTE")
	if side < 0.0:
		var seam := Kit.material("51463f", false, 0.73)
		for x in [2.39, 3.02]:
			Kit.block(bus, Vector3(x, 1.489, -(1.197 * bus_station(x).x + 0.011)), Vector3(0.014, 0.484, 0.015), seam)
		Kit.block(bus, Vector3(2.71, 1.578, -1.219), Vector3(0.139, 0.025, 0.038), metal)

static func wheels(bus: Node3D, side: float, rubber: Material, frame: Material, metal: Material):
	for x: float in AXLES:
		var hub := Vector3(x, TIRE_RADIUS, side * 1.075)
		var tire := Kit.cylinder(bus, hub, TIRE_RADIUS, TIRE_RADIUS, 0.33, rubber)
		tire.name = "Neumático"
		tire.rotation.x = PI * 0.5
		(tire.mesh as CylinderMesh).radial_segments = 24
		Kit.cylinder(bus, hub + Vector3.BACK * side * 0.17,
			0.249, 0.249, 0.043, metal).rotation.x = PI * 0.5
		Kit.cylinder(bus, hub + Vector3.BACK * side * 0.198,
			0.123, 0.123, 0.043, frame).rotation.x = PI * 0.5
		for lug in 6:
			var angle := TAU * lug / 6
			Kit.block(bus, hub + Vector3(cos(angle) * 0.167, sin(angle) * 0.167, side * 0.204),
				Vector3(0.035, 0.034, 0.028), metal)
		var arch := PackedVector3Array()
		for k in 17:
			var angle := lerpf(0.27, PI - 0.27, k / 16.0)
			arch.append(Vector3(x + cos(angle) * WHEEL_ARCH, TIRE_RADIUS + sin(angle) * WHEEL_ARCH, side * 1.202))
		Kit.cord(bus, arch, 0.026, rubber)

static func coach_ends(bus: Node3D, metal: Material, rubber: Material, glass: Material, frame: Material):
	for side in [-1.0, 1.0]:
		var face: float = FRONT if side > 0.0 else REAR
		var direction: Vector3 = Vector3.RIGHT * side
		var projection := func(p: Vector2) -> Vector3:
			return Vector3(face + side * (0.050 - 0.039 * p.x * p.x - 0.035 * smoothstep(2.16, 2.52, p.y)), p.y, p.x)
		var pane := func(p: Vector2) -> Vector3: return projection.call(p) + direction * 0.012
		var width := 0.86 if side > 0.0 else 0.80
		for part in [-1.0, 1.0]:
			var position := Vector2(part * 0.437, 2.08)
			panel(bus, position, Vector2(width, 0.69), 0.128, projection, direction, rubber)
			panel(bus, position, Vector2(width - 0.058, 0.62), 0.106, pane, direction, glass)
		var bumper := PackedVector3Array()
		for i in 9:
			var across := lerpf(-1.07, 1.07, i / 8.0)
			bumper.append(Vector3(face + side * (0.128 - 0.105 * across * across), 0.755, across))
		Kit.cord(bus, bumper, 0.082, metal)
		for across in [-0.771, 0.771]:
			var at := Vector3(face + side * 0.051, 1.133, across)
			var lamp := Kit.material("ddcba1" if side > 0.0 else "934b3f", false, 0.37)
			Kit.cylinder(bus, at, 0.156, 0.156, 0.058, metal).rotation.z = PI * 0.5
			Kit.cylinder(bus, at + direction * 0.032, 0.125, 0.125, 0.028, lamp).rotation.z = PI * 0.5
		Kit.block(bus, Vector3(face + side * 0.052, 0.909, 0), Vector3(0.034, 0.108, 0.31), Kit.material("a8987e"))
	var front := FRONT + 0.057
	var grill := func(p: Vector2) -> Vector3: return Vector3(front - 0.065 * p.x * p.x, p.y, p.x)
	panel(bus, Vector2(0, 1.125), Vector2(0.949, 0.284), 0.066, grill, Vector3.RIGHT, frame)
	for level in 4:
		Kit.block(bus, Vector3(front + 0.012, 1.034 + 0.056 * level, 0), Vector3(0.024, 0.024, 0.86), metal)
	for side in [-1.0, 1.0]:
		var wiper := Kit.block(bus, Vector3(FRONT + 0.080, 1.919, side * 0.425),
			Vector3(0.018, 0.022, 0.48), rubber)
		wiper.rotation.x = side * 0.26
		Kit.block(bus, Vector3(3.29, 2.279, side * 1.255), Vector3(0.038, 0.038, 0.303), metal)
		Kit.block(bus, Vector3(3.27, 2.304, side * 1.408), Vector3(0.098, 0.217, 0.120), rubber)
	coach_label(bus, Vector3(FRONT + 0.009, 2.517, 0), PI * 0.5, 0.0013, "CAPILLA DEL MONTE")

static func panel(parent: Node3D, center: Vector2, size: Vector2, radius: float, project: Callable, normal: Vector3, finish: Material):
	var points := PackedVector3Array()
	for corner in 4:
		var phase := PI * 0.5 * corner
		var offset := Vector2(signf(cos(phase + PI * 0.25)), signf(sin(phase + PI * 0.25))) * (size * 0.5 - Vector2.ONE * radius)
		for edge in 4:
			points.append(project.call(center + offset + Vector2.from_angle(phase + PI * edge / 6.0) * radius))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var middle: Vector3 = project.call(center)
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var facing := (b - middle).cross(a - middle).dot(normal) > 0.0
		for vertex in ([middle, a, b] if facing else [middle, b, a]): surface.add_vertex(vertex)
	surface.generate_normals()
	var part := Kit.mesh_part(parent, surface.commit(), Vector3.ZERO, finish)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
