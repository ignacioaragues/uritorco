extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const STATION := "Puesto de Observación Serrana"
const DESTINATION := "Capilla del Monte"

static func solid(parent: Node3D, at: Vector3, size: Vector3, finish: Material, tag := "") -> StaticBody3D:
	var part := Kit.item(parent, at, tag, Vector3.ZERO, size)
	Kit.block(part, Vector3.ZERO, size, finish)
	return part

static func lettering(parent: Node3D, at: Vector3, text: String, height: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.pixel_size = height / 72.0
	label.outline_size = 0
	label.modulate = color
	label.double_sided = false
	label.shaded = true
	parent.add_child(label)
	label.position = at
	return label

static func plate(parent: Node3D, at: Vector3, size: Vector2, coating: String, angle: float = 0.0) -> Node3D:
	var card := Node3D.new()
	parent.add_child(card)
	card.position = at
	card.rotation.y = angle
	var enamel := Kit.material(coating, false, 0.69)
	var frame := Kit.material("666965", false, 0.66)
	Kit.block(card, Vector3.ZERO, Vector3(size.x, size.y, 0.040), frame)
	Kit.block(card, Vector3(0, 0, 0.021), Vector3(size.x - 0.026, size.y - 0.026, 0.009), enamel)
	for x in [-size.x * 0.5 + 0.034, size.x * 0.5 - 0.034]:
		var rivet := Kit.cylinder(card, Vector3(x, 0, 0.030), 0.010, 0.009, 0.009, frame)
		rivet.rotation.x = PI / 2.0
	return card

static func station(parent: Node3D):
	var post := Node3D.new()
	parent.add_child(post)
	post.position = Vector3(-4.18, 0.0, -6.85)
	post.rotation.y = PI + 0.12
	var iron := Kit.material("626963")
	for x in [-0.67, 0.67]:
		solid(post, Vector3(x, 0.77, 0), Vector3(0.071, 1.54, 0.073), iron)
		Kit.block(post, Vector3(x, 0.068, 0), Vector3(0.18, 0.14, 0.18), Kit.material("827c67"))
	var sign := plate(post, Vector3(0, 1.33, 0.055), Vector2(1.55, 0.56), "434b43")
	lettering(sign, Vector3(0, 0.090, 0.028), STATION.to_upper(), 0.070, Color("#dfd6bf"))
	Kit.block(sign, Vector3(0, 0.004, 0.029), Vector3(1.22, 0.009, 0.004), Kit.material("a89a77"))
	lettering(sign, Vector3(0, -0.111, 0.028), "URITORCO", 0.113, Color("#eee3c8"))

static func trail_post(parent: Node3D, at: Vector3, tag: String, caption: String, heading: float, local: bool):
	var iron := Kit.material("655e51" if local else "646a65", false, 0.77)
	solid(parent, at + Vector3.UP * 0.74, Vector3(0.13, 1.48, 0.12), iron, tag)
	var size := Vector2(1.68 if local else 1.38, 0.40 if "\n" in caption else 0.32)
	var sign := plate(parent, at + Vector3(0, 1.27, 0) + Vector3(sin(heading), 0, cos(heading)) * 0.073,
		size, "545b42" if local else "655e49", heading)
	Kit.item(sign, Vector3.ZERO, tag, Vector3.ZERO, Vector3(size.x, size.y, 0.069))
	var label := lettering(sign, Vector3(0, 0, 0.032), caption.to_upper(), 0.093, Color("#f2e7c8"))
	var nominal := 1.0
	for line in label.text.split("\n"):
		nominal = maxf(nominal, ThemeDB.fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
	label.pixel_size = minf(label.pixel_size, (size.x - 0.19) / nominal)
	if tag in ["Antena del abra", "Hito del filo", "Hito de la cumbre"]:
		var reverse := lettering(sign, Vector3(0, 0, -0.021), label.text, label.pixel_size * label.font_size, label.modulate)
		reverse.rotation.y = PI

static func bus_icon(parent: Node3D, at: Vector3, pale: Material, dark: Material):
	Kit.block(parent, at + Vector3.UP * 0.013, Vector3(0.145, 0.095, 0.004), pale)
	Kit.block(parent, at + Vector3(0.006, 0.028, 0.003), Vector3(0.110, 0.039, 0.003), dark)
	for x in [-0.045, 0.048]:
		Kit.block(parent, at + Vector3(x, -0.039, 0), Vector3(0.024, 0.020, 0.004), pale)

static func bus_plate(parent: Node3D, at: Vector3, width: float, angle: float = 0.0) -> Node3D:
	var sign := plate(parent, at, Vector2(width, 0.38), "354c56", angle)
	var cream := Color("#f1ece0")
	bus_icon(sign, Vector3(-width * 0.40, 0, 0.036), Kit.material("ece5d4"), Kit.material("354c56"))
	lettering(sign, Vector3(width * 0.064, 0.086, 0.031), "ÓMNIBUS", 0.070, cream)
	lettering(sign, Vector3(width * 0.064, -0.071, 0.031), DESTINATION.to_upper(), minf(0.108, width * 0.088), cream)
	return sign

static func flag(parent: Node3D, at: Vector3):
	var steel := Kit.material("626963")
	solid(parent, at + Vector3.UP * 0.83, Vector3(0.068, 1.66, 0.074), steel, "Parada")
	var sign := bus_plate(parent, at + Vector3(0, 1.46, 0.052), 1.02)
	Kit.item(sign, Vector3.ZERO, "Parada", Vector3.ZERO, Vector3(1.02, 0.38, 0.095))

static func roof(parent: Node3D, finish: Material):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 96:
		var left := -1.98 + 3.96 * i / 96.0
		var right := left + 3.96 / 96.0
		var a := 0.023 * cos(TAU * i / 4.0)
		var b := 0.023 * cos(TAU * (i + 1) / 4.0)
		var A := Vector3(left, 2.12 + a, -0.90)
		var B := Vector3(right, 2.12 + b, -0.90)
		var C := Vector3(left, 2.34 + a, 0.91)
		var D := Vector3(right, 2.34 + b, 0.91)
		for vertex in [A, B, C, B, D, C, A, C, B, B, C, D]:
			surface.set_smooth_group(-1)
			surface.add_vertex(vertex)
	surface.generate_normals()
	Kit.mesh_part(parent, surface.commit(), Vector3.ZERO, finish)

static func shelter(parent: Node3D, at: Vector3, playable: bool = false):
	var stop := Node3D.new()
	stop.name = "Abrigo de ómnibus"
	parent.add_child(stop)
	stop.position = at
	var steel := Kit.material("485b55", false, 0.72)
	var galvanized := Kit.material("7d887e", false, 0.64)
	var stone := Kit.material("91836a")
	var seated := Kit.material("8a6c4f", true)
	Kit.block(stop, Vector3(0, 0.014, 0.02), Vector3(3.69, 0.034, 1.58), stone)
	for sign_x in [-1.68, 1.68]:
		solid(stop, Vector3(sign_x, 1.10, 0.71), Vector3(0.10, 2.20, 0.105), steel)
		solid(stop, Vector3(sign_x, 1.01, -0.68), Vector3(0.10, 2.03, 0.105), steel)
		Kit.block(stop, Vector3(sign_x, 0.065, 0.71), Vector3(0.22, 0.13, 0.20), stone)
		var rafter := Kit.block(stop, Vector3(sign_x, 2.20, 0.01), Vector3(0.09, 0.12, 1.55), steel)
		rafter.rotation.x = -0.12
	for i in 6:
		var x := -1.38 + i * 0.55
		Kit.block(stop, Vector3(x, 0.69, -0.70), Vector3(0.528, 1.33, 0.10), galvanized if i % 3 == 2 else steel)
	solid(stop, Vector3(0, 0.69, -0.735), Vector3(3.35, 1.34, 0.09), steel)
	solid(stop, Vector3(-1.68, 0.62, -0.30), Vector3(0.108, 1.24, 0.71), galvanized)
	Kit.block(stop, Vector3(0, 2.285, 0.869), Vector3(3.98, 0.103, 0.072), steel)
	Kit.block(stop, Vector3(0, 2.085, -0.888), Vector3(3.98, 0.073, 0.068), galvanized)
	roof(stop, galvanized)

	var bench_tag := "Banco" if playable else ""
	Kit.item(stop, Vector3(0, 0.465, -0.286), bench_tag, Vector3.ZERO, Vector3(2.68, 0.106, 0.44))
	for z in [-0.45, -0.30, -0.15]:
		Kit.block(stop, Vector3(0, 0.498, z), Vector3(2.68, 0.061, 0.130), seated)
	for x in [-1.0, 1.0]:
		Kit.block(stop, Vector3(x, 0.25, -0.30), Vector3(0.071, 0.47, 0.35), steel)
	Kit.block(stop, Vector3(0, 0.773, -0.51), Vector3(2.68, 0.142, 0.064), seated)
