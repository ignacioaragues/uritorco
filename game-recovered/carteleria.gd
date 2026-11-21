extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const STATION := "Puesto de Observación Serrana"
const DESTINATION := "Capilla del Monte"

static func solid(parent: Node3D, at: Vector3, size: Vector3, finish: Material, tag := "") -> StaticBody3D:
	var part := Kit.item(parent, at, tag, Vector3.ZERO, size)
	Kit.block(part, Vector3.ZERO, size, finish)
	return part

static func printed_face(parent: Node3D, at: Vector3, size: Vector2, coating: Color, lines: Array, graphics: Array = [], reverse := false):
	var print_view := SubViewport.new()
	print_view.disable_3d = true
	print_view.size = Vector2i(512, roundi(512.0 * size.y / size.x))
	print_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(print_view)
	var ink := Node2D.new()
	print_view.add_child(ink)
	var pixel_size := Vector2(print_view.size)
	var pixels_per_meter := pixel_size.x / size.x
	ink.draw.connect(func():
		ink.draw_rect(Rect2(Vector2.ZERO, pixel_size), coating)
		for graphic in graphics:
			var rect: Rect2 = graphic[0]
			var top_left := pixel_size * 0.5 + Vector2(rect.position.x, -rect.end.y) * pixels_per_meter
			ink.draw_rect(Rect2(top_left, rect.size * pixels_per_meter), graphic[1])
		var font := ThemeDB.fallback_font
		for row in lines:
			var center: Vector2 = row[0]
			var size_px := maxi(1, roundi(float(row[2]) * pixels_per_meter))
			var max_width := float(row[4]) * pixels_per_meter if row.size() > 4 else pixel_size.x * 0.90
			var text: PackedStringArray = str(row[1]).split("\n")
			for line in text:
				var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				if width > max_width:
					size_px = maxi(1, floori(size_px * max_width / width))
			var line_height := font.get_height(size_px) * 0.88
			var baseline := pixel_size * 0.5 + Vector2(center.x, -center.y) * pixels_per_meter
			baseline.y += (font.get_ascent(size_px) - font.get_descent(size_px)) * 0.5
			baseline.y -= (text.size() - 1) * line_height * 0.5
			for line in text:
				var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				ink.draw_string(font, baseline - Vector2(width * 0.5, 0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, row[3])
				baseline.y += line_height)
	var finish := StandardMaterial3D.new()
	finish.albedo_texture = print_view.get_texture()
	finish.roughness = 0.78
	finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var mesh := QuadMesh.new()
	mesh.size = size
	var face := Kit.mesh_part(parent, mesh, at, finish)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if reverse: face.rotation.y = PI

static func plate(parent: Node3D, at: Vector3, size: Vector2, coating: Color, angle: float, lines: Array, graphics: Array = [], reverse := false) -> Node3D:
	var card := Node3D.new()
	parent.add_child(card)
	card.position = at
	card.rotation.y = angle
	var frame := Kit.material("666965", false, 0.66)
	Kit.block(card, Vector3.ZERO, Vector3(size.x, size.y, 0.040), frame)
	var painted_size := size - Vector2(0.026, 0.026)
	printed_face(card, Vector3(0, 0, 0.0255), painted_size, coating, lines, graphics)
	if reverse: printed_face(card, Vector3(0, 0, -0.0207), painted_size, coating, lines, graphics, true)
	for x in [-size.x * 0.5 + 0.034, size.x * 0.5 - 0.034]:
		var rivet := Kit.cylinder(card, Vector3(x, 0, 0.030), 0.010, 0.009, 0.009, frame)
		rivet.rotation.x = PI / 2.0
	return card

static func station(parent: Node3D):
	var post := Node3D.new()
	parent.add_child(post)
	post.position = Vector3(-2.47, 0.0, -15.95)
	post.rotation.y = PI - 0.25
	var iron := Kit.material("626963")
	for x in [-0.67, 0.67]:
		solid(post, Vector3(x, 0.77, 0), Vector3(0.071, 1.54, 0.073), iron)
		Kit.block(post, Vector3(x, 0.068, 0), Vector3(0.18, 0.14, 0.18), Kit.material("827c67"))
	var sign := plate(post, Vector3(0, 1.33, 0.055), Vector2(1.55, 0.56), Color("#434b43"), 0.0, [
		[Vector2(0, 0.090), STATION.to_upper(), 0.070, Color("#dfd6bf")],
		[Vector2(0, -0.111), "URITORCO", 0.113, Color("#eee3c8")],
	], [[Rect2(-0.61, 0, 1.22, 0.009), Color("#a89a77")]])
	Kit.item(sign, Vector3.ZERO, "", Vector3.ZERO, Vector3(1.55, 0.56, 0.052))

static func trail_post(parent: Node3D, at: Vector3, caption: String, heading: float, local: bool, reverse := false):
	var iron := Kit.material("655e51" if local else "646a65", false, 0.77)
	solid(parent, at + Vector3.UP * 0.70, Vector3(0.13, 1.56, 0.12), iron)
	var size := Vector2(1.68 if local else 1.38, 0.40 if "\n" in caption else 0.32)
	var sign := plate(parent, at + Vector3(0, 1.27, 0) + Vector3(sin(heading), 0, cos(heading)) * 0.073,
		size, Color("#545b42" if local else "#655e49"), heading,
		[[Vector2.ZERO, caption.to_upper(), 0.093, Color("#f2e7c8")]], [],
		reverse)
	Kit.item(sign, Vector3.ZERO, "", Vector3.ZERO, Vector3(size.x, size.y, 0.047))

static func bus_plate(parent: Node3D, at: Vector3, width: float) -> Node3D:
	var cream := Color("#f1ece0")
	var enamel := Color("#354c56")
	var icon_x := -width * 0.38
	return plate(parent, at, Vector2(width, 0.38), enamel, 0.0, [
		[Vector2(width * 0.092, 0.085), "ÓMNIBUS", 0.070, cream],
		[Vector2(width * 0.092, -0.071), DESTINATION.to_upper(), minf(0.103, width * 0.085), cream, width * 0.70],
	], [
		[Rect2(icon_x - 0.073, -0.035, 0.145, 0.102), cream],
		[Rect2(icon_x - 0.055, 0.011, 0.111, 0.042), enamel],
		[Rect2(icon_x - 0.057, -0.055, 0.024, 0.027), cream],
		[Rect2(icon_x + 0.036, -0.055, 0.024, 0.027), cream],
	])

static func flag(parent: Node3D, at: Vector3):
	var steel := Kit.material("626963")
	solid(parent, at + Vector3.UP * 0.83, Vector3(0.068, 1.66, 0.074), steel)
	var sign := bus_plate(parent, at + Vector3(0, 1.46, 0.052), 1.02)
	Kit.item(sign, Vector3.ZERO, "", Vector3.ZERO, Vector3(1.02, 0.38, 0.095))

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
	var steel := Kit.material("52665c", false, 0.84)
	var galvanized := Kit.material("777e73", false, 0.79)
	var stone := Kit.material("9c8b70")
	var seated := Refuge.wood("907456", true)
	var edge := Kit.material("415047")
	var fastener := Kit.material("a39879", false, 0.61)
	Kit.block(stop, Vector3(0, 0.014, 0.02), Vector3(3.69, 0.034, 1.58), stone)
	Kit.block(stop, Vector3(0.0, 0.009, 0.823), Vector3(3.68, 0.027, 0.065), Kit.material("85765f"))
	for sign_x in [-1.68, 1.68]:
		solid(stop, Vector3(sign_x, 1.10, 0.71), Vector3(0.10, 2.20, 0.105), steel)
		solid(stop, Vector3(sign_x, 1.01, -0.68), Vector3(0.10, 2.03, 0.105), steel)
		Kit.block(stop, Vector3(sign_x, 0.065, 0.71), Vector3(0.22, 0.13, 0.20), stone)
		var rafter := Kit.block(stop, Vector3(sign_x, 2.20, 0.01), Vector3(0.09, 0.12, 1.55), steel)
		rafter.rotation.x = -0.12
	for i in 6:
		var x := -1.38 + i * 0.55
		Kit.block(stop, Vector3(x, 0.69, -0.70), Vector3(0.528, 1.33, 0.10), galvanized if i % 3 == 2 else steel)
		for y in [0.11, 1.268]:
			var bolt := Kit.cylinder(stop, Vector3(x + 0.202, y, -0.644), 0.011, 0.011, 0.009, fastener)
			bolt.rotation.x = PI * 0.5
	solid(stop, Vector3(0, 0.69, -0.735), Vector3(3.35, 1.34, 0.09), steel)
	solid(stop, Vector3(-1.68, 0.62, -0.30), Vector3(0.108, 1.24, 0.71), galvanized)
	Kit.block(stop, Vector3(0.0, 1.356, -0.69), Vector3(3.35, 0.044, 0.113), edge)
	Kit.block(stop, Vector3(0, 2.285, 0.869), Vector3(3.98, 0.103, 0.072), steel)
	Kit.block(stop, Vector3(0, 2.085, -0.888), Vector3(3.98, 0.073, 0.068), galvanized)
	roof(stop, galvanized)

	var bench_tag := "Banco" if playable else ""
	Kit.item(stop, Vector3(0, 0.482, -0.295), bench_tag, Vector3.ZERO, Vector3(2.68, 0.095, 0.43))
	for z in [-0.45, -0.30, -0.15]:
		Kit.block(stop, Vector3(0, 0.498, z), Vector3(2.68, 0.061, 0.130), seated)
	for x in [-1.0, 1.0]:
		solid(stop, Vector3(x, 0.25, -0.30), Vector3(0.071, 0.47, 0.35), steel, bench_tag)
	solid(stop, Vector3(0, 0.773, -0.51), Vector3(2.68, 0.142, 0.064), seated, bench_tag)
	for x in [-1.08, 1.08]:
		var bolt := Kit.cylinder(stop, Vector3(x, 0.773, -0.474), 0.013, 0.013, 0.008, fastener)
		bolt.rotation.x = PI * 0.5
