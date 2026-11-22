extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const GRAIN = preload("res://grain.gdshader")
const CLOTH = preload("res://tejido_refugio.gdshader")
const BOOK_COVER = preload("res://libro_portada.webp")
const POSTCARD = preload("res://postal_munich.webp")
const NOTE_ART = preload("res://nota_turno.webp")
const CLIPPING_ART = preload("res://recorte_paula_2011.webp")
const Stone = preload("res://piedra_serrana.gd")
const ROOF_PITCH := 0.022
const ROOF_CENTER := Vector3(0, 3.002, 2.65)
const ROOF_WAVE := 0.148

static func masonry(wall: MeshInstance3D, inner_face: Vector3):
	var finish := ShaderMaterial.new()
	finish.shader = preload("res://mamposteria_puesto.gdshader")
	finish.set_shader_parameter("inner_face", inner_face)
	finish.set_shader_parameter("lime", wall.material_override.albedo_color)
	wall.material_override = finish
	wall.name = "Muro del puesto"

static func roof(parent: Node3D):
	const WIDTH := 7.85
	const DEPTH := 7.82
	var rafters := Node3D.new()
	rafters.name = "Cubierta del puesto"
	parent.add_child(rafters)
	rafters.position = ROOF_CENTER
	rafters.rotation.x = -ROOF_PITCH
	Kit.block(rafters, Vector3(0, -0.076, 0), Vector3(WIDTH - 0.22, 0.118, DEPTH - 0.24), wood("625349", true))
	var sheet := roof_sheet(rafters, WIDTH, DEPTH, Vector3.ZERO)
	sheet.create_trimesh_collision()

static func roof_sheet(parent: Node3D, width: float, depth: float, offset: Vector3) -> MeshInstance3D:
	const AMPLITUDE := 0.017
	var columns := ceili(width * 54.0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		var along := side * depth
		for column in range(columns + 1):
			var across := width * column / columns
			var phase := TAU * across / ROOF_WAVE
			var slope := TAU * AMPLITUDE / ROOF_WAVE * cos(phase)
			surface.set_normal(Vector3(-slope, 1.0, 0.0).normalized())
			surface.set_uv(Vector2(across, along))
			surface.add_vertex(Vector3(across - width * 0.5, AMPLITUDE * sin(phase), along - depth * 0.5))
	for column in columns:
		var back := column + columns + 1
		for index in [column, column + 1, back, column + 1, back + 1, back]:
			surface.add_index(index)
	var zinc := ShaderMaterial.new()
	zinc.shader = preload("res://chapa_puesto.gdshader")
	zinc.set_shader_parameter("wave_width", ROOF_WAVE)
	zinc.set_shader_parameter("sheet_depth", depth)
	var sheet := Kit.mesh_part(parent, surface.commit(), offset, zinc)
	sheet.name = "Chapa acanalada"
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	return sheet

static func wood(color: String, across := false) -> ShaderMaterial:
	var finish := ShaderMaterial.new()
	finish.shader = GRAIN
	finish.set_shader_parameter("tint", Color(color))
	finish.set_shader_parameter("across", across)
	finish.set_shader_parameter("irregular", true)
	finish.set_shader_parameter("grain_strength", 0.17)
	return finish

static func cloth(base: String, dye: String, period: float) -> ShaderMaterial:
	var finish := ShaderMaterial.new()
	finish.shader = CLOTH
	finish.set_shader_parameter("base_tone", Color(base))
	finish.set_shader_parameter("dyed_tone", Color(dye))
	finish.set_shader_parameter("period", period)
	return finish

static func curtain_rail(parent: Node3D, center: Vector3, width: float):
	var metal := Kit.material("6a5140", false, 0.55)
	var rod := Kit.cylinder(parent, center, 0.018, 0.018, width, metal)
	rod.rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		var end := center + Vector3.BACK * side * width * 0.5
		Kit.cylinder(parent, end, 0.031, 0.031, 0.035, metal).rotation.x = PI * 0.5
		Kit.block(parent, end + Vector3(0.083, -0.006, -side * 0.14), Vector3(0.168, 0.026, 0.038), metal)

static func curtain_panel(parent: Node3D, width: float, height: float) -> MeshInstance3D:
	const COLUMNS := 49
	const ROWS := 11
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in ROWS:
		var drop := float(row) / (ROWS - 1)
		for column in COLUMNS:
			var across := float(column) / (COLUMNS - 1)
			var wave := across * TAU * 6.0 + drop * across * 0.36
			var fold := sin(wave) * (0.026 + 0.012 * drop)
			var hem := sin(wave + 0.7) * 0.014 * drop * drop
			surface.add_vertex(Vector3(fold, -height * drop + hem, width * across))
			if row > 0 and column > 0:
				var a := (row - 1) * COLUMNS + column - 1
				for index in [a, a + 1, a + COLUMNS, a + 1, a + COLUMNS + 1, a + COLUMNS]:
					surface.add_index(index)
	surface.generate_normals()
	var panel := Kit.mesh_part(parent, surface.commit(), Vector3.ZERO, cloth("cbb796", "ada080", 0.61))
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	var edging := Kit.material("aa9675", true)
	for tab in range(7):
		Kit.block(panel, Vector3(0.0, 0.016, width * (0.036 + 0.155 * tab)), Vector3(0.049, 0.054, 0.041), edging)
	return panel

static func brace(parent: Node3D, foot: Vector3, joint: Vector3, thickness: float, finish: Material):
	var leg := Kit.block(parent, (foot + joint) * 0.5, Vector3(thickness, foot.distance_to(joint), thickness), finish)
	leg.quaternion = Quaternion(Vector3.UP, foot.direction_to(joint))

static func pad(parent: Node3D, center: Vector3, size: Vector3, finish: Material, corners := 0.32, outward := false) -> MeshInstance3D:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var z := size.z * 0.5
	var cushion := Kit.shell(parent, [
		Vector4(-y, 0.001, 0.001, 0), Vector4(-y * 0.98, x * 0.88, z * 0.90, 0),
		Vector4(-y * 0.46, x, z, 0), Vector4(y * 0.32, x, z, 0),
		Vector4(y * 0.89, x * 0.91, z * 0.92, 0), Vector4(y, 0.001, 0.001, 0),
	], finish, corners, outward)
	cushion.position = center
	return cushion

static func print_surface(parent: Node3D, pos: Vector3, size: Vector2, image: Texture2D) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = image
	ink.roughness = 0.92
	var picture := Kit.mesh_part(parent, quad, pos, ink)
	picture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return picture

static func desk_paper(parent: StaticBody3D, width: float, art: Texture2D):
	var dimensions := Vector2(width, width * art.get_height() / art.get_width())
	var print := print_surface(parent, Vector3.UP * 0.004, dimensions, art)
	print.rotation = Vector3(-PI / 2.0, PI, 0)
	print.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	print.material_override.alpha_scissor_threshold = 0.48

static func desk(parent: Node3D, drawers: Dictionary) -> StaticBody3D:
	var table := Kit.item(parent, Vector3(2.55, 0, 2.35), "", Vector3(0, 0.871, 0.008), Vector3(1.80, 0.069, 0.70))
	var timber := wood("735340")
	var pine := wood("aa805c", true)
	var worn_edge := wood("886548", true)
	var brass := Kit.material("a38863", false, 0.55)
	var shadow := Kit.material("4f3d32")
	for x in [-0.79, 0.79]:
		for z in [-0.25, 0.25]:
			Kit.item(table, Vector3(x * 1.02, 0.421, z * 1.04), "", Vector3.ZERO, Vector3(0.096, 0.84, 0.096))
			brace(table, Vector3(x * 1.03, 0.024, z * 1.07), Vector3(x, 0.82, z), 0.088, timber)
		Kit.block(table, Vector3(x, 0.76, 0), Vector3(0.077, 0.17, 0.56), timber)
		Kit.block(table, Vector3(x, 0.20, 0), Vector3(0.05, 0.082, 0.55), timber)
	Kit.block(table, Vector3(0, 0.71, 0.23), Vector3(1.58, 0.23, 0.07), timber)
	Kit.block(table, Vector3(0, 0.636, -0.03), Vector3(1.57, 0.035, 0.52), shadow)
	Kit.block(table, Vector3(0, 0.722, -0.05), Vector3(0.035, 0.16, 0.54), timber)
	Kit.block(table, Vector3(0, 0.87, 0), Vector3(1.80, 0.06, 0.70), worn_edge)
	Kit.block(table, Vector3(0, 0.898, 0), Vector3(1.778, 0.011, 0.679), pine)
	for x in [-0.397, 0.397]:
		var label := "Cajón izquierdo" if x < 0.0 else "Cajón derecho"
		var drawer := Kit.item(table, Vector3(x, 0.72, 0), label, Vector3(0, 0, -0.305), Vector3(0.75, 0.165, 0.036))
		drawers[label] = drawer
		Kit.block(drawer, Vector3(0, 0, -0.305), Vector3(0.75, 0.165, 0.032), pine)
		var bottom := Kit.block(drawer, Vector3(0, -0.064, -0.10), Vector3(0.71, 0.018, 0.40), shadow)
		bottom.create_convex_collision()
		bottom.get_child(0).set_meta("item", label)
		for side in [-0.35, 0.35]:
			Kit.block(drawer, Vector3(side, -0.021, -0.10), Vector3(0.019, 0.114, 0.40), timber)
		Kit.block(drawer, Vector3(0, -0.021, 0.101), Vector3(0.71, 0.107, 0.022), timber)
		Kit.cord(drawer, PackedVector3Array([
			Vector3(-0.067, 0.01, -0.325), Vector3(-0.052, -0.007, -0.349),
			Vector3(-0.035, -0.015, -0.357), Vector3(0.035, -0.015, -0.357),
			Vector3(0.052, -0.007, -0.349), Vector3(0.067, 0.01, -0.325),
		]), 0.007, brass)
		if x < 0.0:
			var paper := Kit.material("cabb96")
			Kit.block(drawer, Vector3(-0.132, -0.045, -0.144), Vector3(0.222, 0.021, 0.163), paper).rotation.y = 0.12
			Kit.cylinder(drawer, Vector3(0.142, -0.041, -0.23), 0.006, 0.006, 0.146, Kit.material("946831")).rotation.z = PI / 2.0
		else:
			for z in [-0.21, -0.154]:
				Kit.cylinder(drawer, Vector3(0.14, -0.038, z), 0.020, 0.020, 0.111, Kit.material("3f4b43", false, 0.47)).rotation.z = PI / 2.0
				Kit.cylinder(drawer, Vector3(0.201, -0.038, z), 0.013, 0.014, 0.014, brass).rotation.z = PI / 2.0
	return desk_items(parent)

static func spare_compass(drawer: Node3D) -> StaticBody3D:
	var compass := Kit.item(drawer, Vector3(-0.16, -0.054, -0.150), "Brújula de repuesto",
		Vector3.UP * 0.029, Vector3(0.118, 0.026, 0.125))
	compass.name = "Brújula de repuesto"
	compass.collision_layer = 0
	compass.collision_mask = 0
	compass.rotation.y = -0.30
	var brass := Kit.material("9c7944", false, 0.53)
	var brass_edge := Kit.material("bc9859", false, 0.49)
	var face := Kit.material("dfd1a9", false, 0.64)
	var ink := Kit.material("504336")
	var red := Kit.material("933e36")
	Kit.cylinder(compass, Vector3.UP * 0.011, 0.054, 0.055, 0.022, brass)
	Kit.cylinder(compass, Vector3.UP * 0.023, 0.055, 0.054, 0.005, brass_edge)
	Kit.cylinder(compass, Vector3.UP * 0.025, 0.049, 0.049, 0.004, face)
	Kit.cylinder(compass, Vector3.UP * 0.031, 0.0035, 0.0035, 0.005, brass)
	for i in 16:
		var angle := TAU * i / 16.0
		var point := Vector3(sin(angle), 0.0, -cos(angle))
		var mark := Kit.block(compass, Vector3.UP * 0.0273 + point * 0.044,
			Vector3(0.0019, 0.0005, 0.007 if i % 4 == 0 else 0.0035), red if i == 0 else ink)
		mark.rotation.y = -angle
	var needle := SurfaceTool.new()
	needle.begin(Mesh.PRIMITIVE_TRIANGLES)
	needle.set_normal(Vector3.UP)
	for sign_z in [-1.0, 1.0]:
		var shoulder := Vector3(0.0044, 0.030, 0.0)
		var point := Vector3(0.0, 0.030, sign_z * 0.033)
		needle.add_vertex(shoulder * Vector3(sign_z, 1, 1))
		needle.add_vertex(point)
		needle.add_vertex(shoulder * Vector3(-sign_z, 1, 1))
	var indicator := Kit.mesh_part(compass, needle.commit(), Vector3.ZERO, red)
	indicator.rotation.y = 0.33
	Kit.cord(compass, PackedVector3Array([Vector3(-0.009, 0.011, -0.048), Vector3(-0.012, 0.011, -0.061),
		Vector3(0, 0.011, -0.069), Vector3(0.012, 0.011, -0.061), Vector3(0.009, 0.011, -0.048)]), 0.0028, brass_edge)
	return compass

static func desk_items(parent: Node3D) -> StaticBody3D:
	var paper := Kit.material("e2d2ad")
	var note := Kit.item(parent, Vector3(1.96, 0.905, 2.35), "Nota", Vector3.UP * 0.011, Vector3(0.35, 0.043, 0.26))
	note.rotation.y = -0.18
	desk_paper(note, 0.33, NOTE_ART)
	var journal := Node3D.new()
	parent.add_child(journal)
	journal.position = Vector3(2.35, 0.904, 2.54)
	journal.rotation.y = -0.13
	var green := Kit.material("4d5847", true)
	Kit.block(journal, Vector3.UP * 0.017, Vector3(0.234, 0.024, 0.17), paper)
	for height in [0.004, 0.030]:
		Kit.block(journal, Vector3.UP * height, Vector3(0.248, 0.006, 0.182), green)
	Kit.block(journal, Vector3(-0.117, 0.017, 0), Vector3(0.023, 0.033, 0.181), green)
	Kit.block(journal, Vector3(0.019, 0.034, -0.024), Vector3(0.10, 0.0012, 0.049), paper)
	var pencil := Node3D.new()
	parent.add_child(pencil)
	pencil.position = Vector3(2.54, 0.914, 2.48)
	pencil.rotation.y = 0.31
	Kit.block(pencil, Vector3.ZERO, Vector3(0.012, 0.012, 0.133), Kit.material("c39450"))
	var tip := Kit.cylinder(pencil, Vector3(0, 0, -0.072), 0.006, 0.001, 0.020, Kit.material("ad8a64"))
	tip.rotation.x = -PI / 2.0
	Kit.block(pencil, Vector3(0, 0, 0.070), Vector3(0.013, 0.013, 0.016), Kit.material("925b48"))
	mug(parent, Vector3(2.93, 0.903, 2.21))
	return note

static func map_weight(parent: Node3D) -> StaticBody3D:
	var weight := Kit.item(parent, Vector3(1.97, 0.904, 2.34), "Piedra de Mara", Vector3(0.0, 0.027, 0), Vector3(0.19, 0.054, 0.136))
	weight.name = "Piedra de Mara"
	weight.rotation.y = -0.23
	var note := Kit.block(weight, Vector3(0.045, 0.005, 0.018), Vector3(0.254, 0.008, 0.178), Kit.material("baaa88"))
	note.rotation.y = 0.19
	Kit.block(weight, Vector3(0.090, 0.0095, 0.054), Vector3(0.091, 0.001, 0.0035), Kit.material("65594a")).rotation.y = 0.19
	var faces := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 322
	Stone.fragment(faces, Vector3.UP * 0.016, Vector3(0.179, 0.036, 0.132), 0.10, rng, Callable(), Stone.LAJA_PROFILE)
	var pebble := Stone.finish(weight, faces, "Laja con impresión vegetal")
	pebble.material_override = Stone.paint("#9d8973")
	var imprint := Kit.material("544837", false, 0.93)
	var stem := PackedVector3Array()
	for i in 9:
		var t := float(i) / 8.0
		stem.append(Vector3(lerpf(-0.051, 0.052, t), 0.051 + 0.002 * sin(t * 4.2), 0.011 - t * t * 0.028))
		if i in [0, 8]: continue
		for side in [-1, 1]:
			var length := 0.031 * sin(PI * t) + 0.004
			Kit.cord(weight, PackedVector3Array([stem[-1], stem[-1] + Vector3(0.008, 0, side * length * 0.55),
				stem[-1] + Vector3(0.017, -0.001, side * length)]), 0.0011, imprint)
	Kit.cord(weight, stem, 0.0015, imprint)
	return weight

static func wine_parcel(parent: Node3D, spot: Vector3) -> StaticBody3D:
	var bottle := Kit.item(parent, spot, "Botella de Mara", Vector3.UP * 0.16, Vector3(0.14, 0.32, 0.14))
	bottle.name = "Botella de Mara"
	bottle.rotation.y = 0.12
	var glass := Kit.material("424c32", false, 0.44)
	Kit.shell(bottle, [
		Vector4(0.317, 0.001, 0.001, 0), Vector4(0.317, 0.019, 0.019, 0),
		Vector4(0.308, 0.021, 0.021, 0), Vector4(0.303, 0.016, 0.016, 0),
		Vector4(0.253, 0.016, 0.016, 0), Vector4(0.239, 0.022, 0.022, 0),
		Vector4(0.221, 0.038, 0.038, 0), Vector4(0.201, 0.052, 0.052, 0),
		Vector4(0.184, 0.054, 0.054, 0), Vector4(0.026, 0.054, 0.054, 0),
		Vector4(0.011, 0.052, 0.052, 0), Vector4(0.005, 0.041, 0.041, 0),
		Vector4(0.005, 0.001, 0.001, 0),
	], glass, 1.0)
	var foil := Kit.material("743c41", false, 0.58)
	Kit.shell(bottle, [
		Vector4(0.321, 0.001, 0.001, 0), Vector4(0.319, 0.020, 0.020, 0),
		Vector4(0.308, 0.0215, 0.0215, 0), Vector4(0.304, 0.017, 0.017, 0),
		Vector4(0.274, 0.0165, 0.0165, 0),
	], foil, 1.0)
	var paper := Kit.material("d8bd91")
	Kit.shell(bottle, [
		Vector4(0.176, 0.0548, 0.0548, 0), Vector4(0.111, 0.0548, 0.0548, 0),
	], paper, 1.0)
	var border := Kit.material("8d4e49")
	Kit.shell(bottle, [Vector4(0.168, 0.055, 0.055, 0), Vector4(0.162, 0.055, 0.055, 0)], border, 1.0)
	var label := Label3D.new()
	label.text = "TINTO"
	label.modulate = Color("#633b36")
	label.font_size = 44
	label.pixel_size = 0.00043
	label.outline_size = 0
	bottle.add_child(label)
	label.rotation.y = PI
	label.position = Vector3(0.0, 0.138, -0.0555)
	wrap_bottle(bottle)
	return bottle

static func wrap_bottle(bottle: Node3D):
	# El pliego queda abierto de frente, con los dobleces apoyados en la repisa.
	var folds := PackedVector3Array()
	var columns := 16
	for i in range(columns + 1):
		var angle := lerpf(0.38, TAU - 0.42, float(i) / columns)
		var rim := 0.121 + 0.029 * sin(i * 0.54) + 0.008 * sin(i * 2.8)
		rim -= 0.046 * (1.0 - smoothstep(0.0, 3.0, i))
		var outward := Vector3(sin(angle), 0.0, -cos(angle))
		var splay := 0.086 + 0.019 * sin(i * 0.79 + 0.3)
		folds.append(outward * splay + Vector3.UP * 0.005)
		folds.append(outward * (0.057 + 0.009 * absf(sin(i * 2.6))) + Vector3.UP * 0.037)
		folds.append(outward * (0.062 + 0.012 * absf(sin(i * 1.1))) + Vector3.UP * rim)
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(columns):
		for panel in range(2):
			var a := i * 3 + panel
			for index in [a, a + 3, a + 1, a + 1, a + 3, a + 4]:
				sheet.set_uv(Vector2(floorf(index / 3.0) / columns, folds[index].y / 0.16))
				sheet.add_vertex(folds[index])
	sheet.generate_normals()

	var newsprint := Image.create_empty(384, 160, false, Image.FORMAT_RGB8)
	newsprint.fill(Color("#bbb09b"))
	var ink := Color("#696359")
	for column in range(6):
		var x := 11 + column * 63
		newsprint.fill_rect(Rect2i(x, 20 + 4 * (column % 3), 51, 4), ink)
		for row in range(13):
			for word in range(4):
				var width := 4 + (row * 13 + column * 7 + word * 11) % 6
				newsprint.fill_rect(Rect2i(x + word * 12, 36 + row * 8, width, 2), ink)
	var paper := StandardMaterial3D.new()
	paper.albedo_texture = ImageTexture.create_from_image(newsprint)
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.roughness = 1.0
	Kit.mesh_part(bottle, sheet.commit(), Vector3.ZERO, paper)

static func mug(parent: Node3D, pos: Vector3):
	var cup := Node3D.new()
	parent.add_child(cup)
	cup.position = pos
	cup.rotation.y = -0.26
	var enamel := Kit.material("d9c7a3", false, 0.58)
	var lip := Kit.material("53695f", false, 0.52)
	Kit.shell(cup, [
		Vector4(0.003, 0.001, 0.001, 0), Vector4(0.003, 0.041, 0.041, 0),
		Vector4(0.012, 0.055, 0.055, 0), Vector4(0.102, 0.059, 0.059, 0),
		Vector4(0.107, 0.053, 0.053, 0), Vector4(0.094, 0.049, 0.049, 0),
		Vector4(0.025, 0.045, 0.045, 0), Vector4(0.020, 0.001, 0.001, 0),
	], enamel, 1.0)
	Kit.shell(cup, [
		Vector4(0.103, 0.060, 0.060, 0), Vector4(0.109, 0.059, 0.059, 0),
		Vector4(0.109, 0.052, 0.052, 0), Vector4(0.103, 0.052, 0.052, 0),
	], lip, 1.0)
	Kit.cord(cup, PackedVector3Array([
		Vector3(0.054, 0.083, 0), Vector3(0.081, 0.086, 0), Vector3(0.100, 0.070, 0),
		Vector3(0.101, 0.049, 0), Vector3(0.085, 0.031, 0), Vector3(0.053, 0.027, 0),
	]), 0.009, enamel)
	Kit.cylinder(cup, Vector3.UP * 0.062, 0.048, 0.048, 0.003, Kit.material("584031", false, 0.68))

static func chair(parent: Node3D):
	var seat := Kit.item(parent, Vector3(2.55, 0, 1.64), "", Vector3.UP * 0.46, Vector3(0.44, 0.085, 0.42))
	seat.rotation.y = -0.14
	var finish := wood("946d50")
	var cross := wood("b48b64", true)
	pad(seat, Vector3.UP * 0.46, Vector3(0.44, 0.068, 0.42), cross)
	for side in [-1.0, 1.0]:
		var x: float = side * 0.169
		brace(seat, Vector3(x * 1.18, 0.022, 0.186), Vector3(x, 0.464, 0.153), 0.052, finish)
		brace(seat, Vector3(x * 1.18, 0.022, -0.209), Vector3(x, 0.49, -0.148), 0.053, finish)
		brace(seat, Vector3(x, 0.478, -0.148), Vector3(x, 0.98, -0.223), 0.051, finish)
		Kit.block(seat, Vector3(x, 0.225, -0.016), Vector3(0.033, 0.038, 0.345), finish)
	Kit.block(seat, Vector3(0, 0.255, 0.163), Vector3(0.35, 0.043, 0.043), cross)
	for i in 3:
		var y := 0.68 + i * 0.116
		var z := -0.179 - i * 0.016
		var slat := Kit.item(seat, Vector3(0, y, z), "", Vector3.ZERO, Vector3(0.379, 0.076, 0.037))
		Kit.block(slat, Vector3.ZERO, Vector3(0.379, 0.076, 0.037), cross)

static func bed(parent: Node3D):
	var bunk := Kit.item(parent, Vector3(2.55, 0, 4.5), "Cama", Vector3.UP * 0.40, Vector3(1.20, 0.80, 2.30))
	var frame := wood("775744")
	var sawn := wood("926b50", true)
	for x in [-0.538, 0.538]:
		for z in [-1.087, 1.087]:
			var height := 1.05 if z > 0.0 else 0.47
			Kit.block(bunk, Vector3(x, height * 0.5 + 0.02, z), Vector3(0.086, height, 0.092), frame)
		Kit.block(bunk, Vector3(x, 0.397, 0), Vector3(0.085, 0.175, 2.17), sawn)
	for z in [-1.087, 1.087]:
		Kit.block(bunk, Vector3(0, 0.403, z), Vector3(1.125, 0.186, 0.078), sawn)
	for y in [0.744, 0.938]:
		var board := Kit.item(bunk, Vector3(0, y, 1.09), "Cama", Vector3.ZERO, Vector3(1.07, 0.115, 0.058))
		Kit.block(board, Vector3.ZERO, Vector3(1.07, 0.115, 0.058), sawn)
	pad(bunk, Vector3.UP * 0.602, Vector3(1.145, 0.272, 2.19), Kit.material("c9bca0", true))
	pad(bunk, Vector3(0.025, 0.776, 0.793), Vector3(0.81, 0.151, 0.429), Kit.material("d4c5a5", true), 0.54).rotation.y = -0.065
	quilt(bunk)

static func quilt(bunk: Node3D):
	var profile := [
		Vector2(-0.612, 0.49), Vector2(-0.619, 0.63), Vector2(-0.583, 0.749),
		Vector2(-0.492, 0.786), Vector2(-0.35, 0.797), Vector2(-0.17, 0.783),
		Vector2(0, 0.791), Vector2(0.16, 0.779), Vector2(0.32, 0.789),
		Vector2(0.48, 0.782), Vector2(0.568, 0.737), Vector2(0.587, 0.615),
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seam := PackedVector3Array()
	var width := profile.size()
	for row in 27:
		var z := lerpf(-1.120, 0.548, row / 26.0)
		for col in width:
			var cross: Vector2 = profile[col]
			var fold := 0.015 * sin(z * 18.0 + cross.x * 12.0) + 0.009 * sin(z * 27.0 - col)
			var y := cross.y + fold - 0.135 * (1.0 - smoothstep(-1.12, -1.008, z))
			var at := Vector3(cross.x + 0.009 * sin(z * 14.0), y, z + 0.014 * sin(col * 0.65))
			surface.add_vertex(at)
			if row == 26: seam.append(at + Vector3.UP * 0.006)
			if row > 0 and col > 0:
				var a := (row - 1) * width + col - 1
				for index in [a, a + 1, a + width, a + 1, a + width + 1, a + width]:
					surface.add_index(index)
	surface.generate_normals()
	Kit.mesh_part(bunk, surface.commit(), Vector3.ZERO, cloth("566052", "9d8c65", 0.45))
	Kit.cord(bunk, seam, 0.009, Kit.material("777657", true))

static func floor_runner(parent: Node3D):
	Kit.block(parent, Vector3(1.27, 0.034, 3.95), Vector3(0.84, 0.014, 1.66), cloth("776352", "b0936d", 0.24))
	var fringe := SurfaceTool.new()
	fringe.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		for i in 22:
			var start := Vector3(-0.395 + i * 0.037, 0, side * 0.821)
			var end := start + Vector3(0.010 * sin(i * 1.47), 0, side * (0.057 + 0.009 * sin(i * 2.13)))
			var edge := Vector3.RIGHT * 0.0045
			for vertex in [start - edge, start + edge, end - edge, end - edge, start + edge, end + edge]:
				fringe.set_normal(Vector3.UP)
				fringe.add_vertex(vertex)
	var threads := Kit.mesh_part(parent, fringe.commit(), Vector3(1.27, 0.037, 3.95), cloth("aa8f67", "b49a72", 0.24))
	threads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func closed_book(parent: Node3D, ribbon: bool) -> StaticBody3D:
	var book := Kit.item(parent, Vector3(-1.75, 1.731, 5.758), "Observar el Cielo", Vector3.UP * 0.033, Vector3(0.302, 0.066, 0.443))
	book.name = "Observar el Cielo"
	book.rotation = Vector3(-0.90, -0.04, 0)
	var binding := Kit.material("37464c", true)
	var paper := Kit.material("cdbea1")
	var paper_shadow := Kit.material("aa9f88")
	for y in [0.005, 0.049]:
		Kit.block(book, Vector3.UP * y, Vector3(0.282, 0.009, 0.424), binding)
	Kit.block(book, Vector3(0.0, 0.027, 0), Vector3(0.269, 0.035, 0.406), paper)
	for y in [0.017, 0.025, 0.032, 0.039]:
		Kit.block(book, Vector3(-0.135, y, 0), Vector3(0.001, 0.0012, 0.401), paper_shadow)
		Kit.block(book, Vector3(0, y, -0.2034), Vector3(0.266, 0.0012, 0.001), paper_shadow)
	Kit.block(book, Vector3(0.137, 0.028, 0), Vector3(0.016, 0.052, 0.421), binding)
	var cover := print_surface(book, Vector3(-0.001, 0.054, 0), Vector2(0.279, 0.4185), BOOK_COVER)
	cover.rotation = Vector3(-PI / 2.0, PI, 0)
	if ribbon:
		Kit.belt(book, PackedVector3Array([
			Vector3(-0.08, 0.032, -0.199), Vector3(-0.08, 0.024, -0.223),
			Vector3(-0.074, 0.048, -0.247), Vector3(-0.070, 0.076, -0.268),
		]), 0.019, Kit.material("536952", true))

	return book

static func postcard(parent: Node3D) -> StaticBody3D:
	var card := Kit.item(parent, Vector3(2.20, 1.54, 5.857), "Postal de Paula", Vector3.ZERO, Vector3(0.23, 0.157, 0.024))
	card.rotation = Vector3(0, PI, -0.08)
	Kit.block(card, Vector3.ZERO, Vector3(0.220, 0.148, 0.006), Kit.material("d5bf9b"))
	print_surface(card, Vector3.BACK * 0.0035, Vector2(0.216, 0.144), POSTCARD)
	Kit.cylinder(card, Vector3(0, 0.067, 0.005), 0.006, 0.006, 0.009, Kit.material("a47e58")).rotation.x = PI / 2.0

	return card

static func wall_sketch(parent: Node3D, pos: Vector3, drawing: Texture2D, motif: int) -> Node3D:
	var sheet := Node3D.new()
	parent.add_child(sheet)
	sheet.position = pos
	sheet.rotation = Vector3(0, PI, 0.045 if motif < 0 else -0.055 + 0.019 * motif)
	var patch := QuadMesh.new()
	patch.size = Vector2(0.34, 0.31)
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://croquis_pared.gdshader")
	ink.set_shader_parameter("drawing", drawing)
	ink.set_shader_parameter("paper", preload("res://diario_papel.webp"))
	if motif >= 0:
		ink.set_shader_parameter("tile", Vector4((motif % 4) * 0.25, floorf(motif / 4.0) * 0.5, 0.25, 0.5))
	Kit.mesh_part(sheet, patch, Vector3.ZERO, ink).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.cylinder(sheet, Vector3(0, 0.142, 0.006), 0.006, 0.006, 0.010, Kit.material("8d7959")).rotation.x = PI / 2.0
	return sheet

static func exterior_equipment(parent: Node3D, flag_foot: Vector3, cylinder_foot: Vector3) -> ShaderMaterial:
	var flag_pole := Kit.item(parent, flag_foot, "", Vector3.UP * 1.68, Vector3(0.10, 3.36, 0.10))
	var steel := Kit.material("847f72", false, 0.58)
	Kit.cylinder(flag_pole, Vector3.UP * 1.65, 0.026, 0.041, 3.30, steel)
	Kit.cylinder(flag_pole, Vector3.UP * 0.09, 0.13, 0.15, 0.18, Kit.material("968b75"))
	var fabric := SurfaceTool.new()
	fabric.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 24:
		for column in 18:
			for vertex in [Vector2.ZERO, Vector2.DOWN, Vector2.RIGHT, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE]:
				var u: float = (column + vertex.x) / 18.0
				var v: float = (row + vertex.y) / 24.0
				var tone := Color("e4ded0") if row >= 8 and row < 16 else Color("73a6c3")
				if row >= 8 and row < 16 and Vector2((u - 0.49) * 0.48, (v - 0.5) * 0.59).length() < 0.043:
					tone = Color("c9994f")
				fabric.set_color(tone)
				fabric.set_uv(Vector2(u, v))
				fabric.set_normal(Vector3.FORWARD)
				fabric.add_vertex(Vector3(0.033 + u * 0.95, 3.02 - v * 0.83, 0))
	var weave := ShaderMaterial.new()
	weave.shader = preload("res://bandera_refugio.gdshader")
	var flag := Kit.mesh_part(flag_pole, fabric.commit(), Vector3.ZERO, weave)
	flag.name = "Bandera argentina"
	flag.extra_cull_margin = 0.6
	for height in [3.015, 2.418]:
		Kit.cylinder(flag_pole, Vector3.UP * height, 0.038, 0.038, 0.019, steel)
	var gold := Kit.material("c9994f")

	gas_connection(parent, cylinder_foot, steel, gold)

	var solar := Node3D.new()
	parent.add_child(solar)
	solar.position = Vector3(-2.65, ROOF_CENTER.y + 0.15 + (1.02 - ROOF_CENTER.z) * sin(ROOF_PITCH), 1.02)
	solar.rotation.x = -ROOF_PITCH
	for x in [-0.42, 0.42]:
		Kit.block(solar, Vector3(x, -0.091, 0), Vector3(0.06, 0.13, 0.61), steel)
	Kit.block(solar, Vector3.ZERO, Vector3(1.16, 0.076, 0.79), steel)
	var cell := Kit.material("334151", false, 0.53)
	for column in 5:
		for row in 4:
			Kit.block(solar, Vector3((column - 2) * 0.22, 0.044, (row - 1.5) * 0.177), Vector3(0.211, 0.016, 0.166), cell)
	return weave

static func gas_connection(parent: Node3D, foot: Vector3, steel: Material, brass: Material):
	var tank := Kit.item(parent, foot, "", Vector3.UP * 0.35, Vector3(0.37, 0.70, 0.37))
	tank.name = "Garrafa y conexión"
	var enamel := Kit.material("a58260", false, 0.72)
	var dark := Kit.material("59544c")
	Kit.block(tank, Vector3(0, 0.029, 0), Vector3(0.48, 0.064, 0.44), Kit.material("857766"))
	Kit.cylinder(tank, Vector3.UP * 0.084, 0.136, 0.143, 0.061, dark)
	Kit.shell(tank, [
		Vector4(0.11, 0.114, 0.114, 0), Vector4(0.151, 0.158, 0.158, 0),
		Vector4(0.24, 0.169, 0.169, 0), Vector4(0.518, 0.169, 0.169, 0),
		Vector4(0.571, 0.155, 0.155, 0), Vector4(0.622, 0.101, 0.101, 0),
		Vector4(0.636, 0.050, 0.050, 0), Vector4(0.637, 0.001, 0.001, 0),
	], enamel, 1.0, true)
	Kit.cylinder(tank, Vector3.UP * 0.352, 0.170, 0.170, 0.012, Kit.material("907057"))
	for x in [-0.090, 0.090]:
		Kit.block(tank, Vector3(x, 0.685, 0), Vector3(0.023, 0.109, 0.115), enamel)
	Kit.cord(tank, PackedVector3Array([
		Vector3(-0.09, 0.729, -0.056), Vector3(-0.064, 0.745, -0.073), Vector3(0.064, 0.745, -0.073),
		Vector3(0.097, 0.726, -0.050), Vector3(0.097, 0.726, 0.050), Vector3(0.065, 0.744, 0.073),
		Vector3(-0.063, 0.744, 0.073), Vector3(-0.09, 0.729, 0.056),
	]), 0.013, enamel)
	Kit.cylinder(tank, Vector3.UP * 0.658, 0.022, 0.026, 0.054, brass)
	Kit.cylinder(tank, Vector3.UP * 0.695, 0.040, 0.040, 0.016, Kit.material("8c5140"))
	Kit.cylinder(tank, Vector3(0.125, 0.661, 0.009), 0.051, 0.051, 0.025, steel)
	Kit.block(tank, Vector3(0.069, 0.661, 0.01), Vector3(0.064, 0.028, 0.028), brass)
	var entry := Vector3(-3.637, 0.503, 3.21)
	Kit.cord(parent, PackedVector3Array([
		foot + Vector3(0.163, 0.661, 0.013), foot + Vector3(0.227, 0.66, 0.04),
		foot + Vector3(0.298, 0.61, 0.12), entry + Vector3(-0.063, 0, -0.53),
		entry + Vector3(-0.056, 0, -0.098), entry + Vector3(-0.039, 0, -0.033), entry,
	]), 0.014, dark)
	for z in [2.80, 3.02, 3.18]:
		Kit.block(parent, Vector3(-3.676, entry.y, z), Vector3(0.066, 0.035, 0.019), steel)
	var sleeve := Kit.cylinder(parent, entry, 0.048, 0.048, 0.036, steel)
	sleeve.rotation.z = PI / 2.0
	var inner := Vector3(-3.38, entry.y, entry.z)
	Kit.cord(parent, PackedVector3Array([inner, inner + Vector3(0.16, 0, 0), Vector3(-3.213, 0.93, 3.17), Vector3(-3.181, 1.02, 3.17)]), 0.010, brass)

static func cutting(parent: Node3D) -> StaticBody3D:
	var clipping := Kit.item(parent, Vector3(3.165, 0.905, 2.505), "Recorte de astronomía", Vector3.UP * 0.014, Vector3(0.29, 0.030, 0.35))
	clipping.rotation.y = 0.18
	desk_paper(clipping, 0.27, CLIPPING_ART)
	var cell_wrap := Kit.material("9d8050", false, 0.55)
	var cell_cap := Kit.material("8d8b7d", false, 0.42)
	for i in 2:
		var cell := Kit.cylinder(parent, Vector3(3.22 + i * 0.039, 0.920, 2.23 - i * 0.028), 0.017, 0.017, 0.092, cell_wrap)
		cell.rotation = Vector3(PI / 2.0, 0.25 + i * 0.27, 0)
		for side in [-1.0, 1.0]:
			Kit.cylinder(cell, Vector3.UP * side * 0.043, 0.0174, 0.0174, 0.008, cell_cap)
	return clipping

static func kitchenette(parent: Node3D, doors: Dictionary):
	var cabinet := Kit.item(parent, Vector3(-3, 0, 3.6), "", Vector3(-0.035, 0.48, 0), Vector3(0.647, 0.95, 2.18))
	var timber := wood("746555")
	var panel := wood("8b745d")
	var iron := Kit.material("625c51", false, 0.57)
	var enamel := Kit.material("ada696", false, 0.72)
	Kit.block(cabinet, Vector3(-0.328, 0.49, 0), Vector3(0.064, 0.81, 2.18), timber)
	Kit.block(cabinet, Vector3(-0.036, 0.069, 0), Vector3(0.66, 0.11, 2.18), iron)
	Kit.block(cabinet, Vector3(-0.021, 0.153, 0), Vector3(0.68, 0.048, 2.18), panel)
	for z in [-1.066, -0.36, 0.36, 1.066]:
		Kit.block(cabinet, Vector3(-0.026, 0.55, z), Vector3(0.66, 0.80, 0.039), timber)
	for compartment in [["Gabinete de ollas", -0.72], ["Gabinete de tazas", 0.0], ["Gabinete de limpieza", 0.72]]:
		var label: String = compartment[0]
		var z: float = compartment[1]
		var pivot := Node3D.new()
		cabinet.add_child(pivot)
		pivot.position = Vector3(0.323, 0, z - 0.342)
		doors[label] = pivot
		var door := Kit.item(pivot, Vector3(0.022, 0.535, 0.342), label, Vector3.ZERO, Vector3(0.054, 0.711, 0.675))
		Kit.block(door, Vector3.ZERO, Vector3(0.054, 0.711, 0.675), panel)
		Kit.block(door, Vector3(0.029, 0, 0), Vector3(0.012, 0.575, 0.550), timber)
		Kit.block(door, Vector3(0.050, 0.246, 0.215), Vector3(0.041, 0.028, 0.126), iron)
		for y in [-0.24, 0.24]:
			Kit.block(door, Vector3(-0.020, y, -0.306), Vector3(0.041, 0.058, 0.053), iron)
	Kit.cylinder(cabinet, Vector3(-0.047, 0.251, -0.737), 0.135, 0.151, 0.154, iron)
	Kit.cylinder(cabinet, Vector3(-0.047, 0.335, -0.737), 0.141, 0.145, 0.024, enamel)
	Kit.cylinder(cabinet, Vector3(-0.047, 0.358, -0.737), 0.026, 0.021, 0.027, iron)
	Kit.block(cabinet, Vector3(-0.035, 0.484, 0), Vector3(0.53, 0.038, 0.64), panel)
	for z in [-0.123, 0.116]:
		mug(cabinet, Vector3(-0.017, 0.503, z))
	for y in [0.183, 0.204, 0.225]:
		Kit.cylinder(cabinet, Vector3(0.021, y, -0.01), 0.100, 0.121, 0.024, enamel)
	Kit.cylinder(cabinet, Vector3(0.045, 0.280, 0.77), 0.054, 0.050, 0.208, Kit.material("72806b"))
	Kit.cylinder(cabinet, Vector3(0.045, 0.400, 0.77), 0.023, 0.023, 0.037, enamel)
	Kit.block(cabinet, Vector3(0.069, 0.195, 0.543), Vector3(0.123, 0.036, 0.094), Kit.material("9e895f"))
	Kit.block(cabinet, Vector3(0, 0.968, -0.445), Vector3(0.82, 0.054, 1.36), enamel)
	Kit.block(cabinet, Vector3(0, 0.968, 0.962), Vector3(0.82, 0.054, 0.326), enamel)
	for x in [-0.335, 0.335]:
		Kit.block(cabinet, Vector3(x, 0.968, 0.522), Vector3(0.15, 0.054, 0.574), enamel)

	var sink := Node3D.new()
	cabinet.add_child(sink)
	sink.position = Vector3(0, 0.966, 0.524)
	var steel := Kit.material("82877f", false, 0.48)
	Kit.shell(sink, [
		Vector4(-0.065, 0.002, 0.002, 0), Vector4(-0.065, 0.234, 0.251, 0),
		Vector4(0.027, 0.269, 0.289, 0), Vector4(0.042, 0.273, 0.291, 0),
		Vector4(0.042, 0.246, 0.257, 0), Vector4(0.018, 0.238, 0.247, 0),
		Vector4(-0.056, 0.192, 0.211, 0), Vector4(-0.060, 0.001, 0.001, 0),
	], steel, 0.23)
	Kit.cylinder(sink, Vector3(0.003, -0.052, 0.019), 0.034, 0.034, 0.008, iron)
	Kit.cylinder(sink, Vector3(-0.324, 0.045, 0), 0.042, 0.040, 0.031, steel)
	Kit.cord(sink, PackedVector3Array([
		Vector3(-0.324, 0.051, 0), Vector3(-0.325, 0.264, 0), Vector3(-0.305, 0.317, 0),
		Vector3(-0.263, 0.338, 0), Vector3(-0.162, 0.339, 0), Vector3(-0.117, 0.312, 0), Vector3(-0.108, 0.266, 0),
	]), 0.016, steel)
	var stove := Kit.material("524f46")
	var griddle := Kit.material("3d3e38", false, 0.71)
	Kit.block(cabinet, Vector3(0, 1.018, -0.4), Vector3(0.64, 0.048, 0.70), stove)
	for z in [-0.603, -0.251]:
		Kit.cylinder(cabinet, Vector3(-0.02, 1.048, z), 0.112, 0.104, 0.024, griddle)
		for x in [-0.098, 0.058]:
			Kit.block(cabinet, Vector3(x, 1.061, z), Vector3(0.022, 0.025, 0.204), griddle)
	Kit.cylinder(cabinet, Vector3(-0.024, 1.093, -0.251), 0.079, 0.131, 0.036, Kit.material("42423a"))
	Kit.block(cabinet, Vector3(0.181, 1.097, -0.23), Vector3(0.21, 0.023, 0.031), iron).rotation.y = -0.12

static func refrigerator(parent: Node3D) -> Dictionary:
	var fridge := Kit.item(parent, Vector3(-2.96, 0, 1.65), "", Vector3.UP * 0.69, Vector3(0.52, 1.38, 0.67))
	fridge.name = "Heladera"
	var enamel := Kit.material("a6aa92", false, 0.66)
	var door := Kit.material("c3c5a8", false, 0.53)
	var liner := Kit.material("c2c1ad", false, 0.75)
	var seal := Kit.material("6d6e5d", false, 0.88)
	var steel := Kit.material("9e9988", false, 0.42)
	Kit.block(fridge, Vector3(-0.285, 0.72, 0), Vector3(0.11, 1.32, 0.64), enamel)
	for z in [-0.286, 0.286]:
		Kit.block(fridge, Vector3(-0.02, 0.72, z), Vector3(0.53, 1.32, 0.067), enamel)
	for y in [0.095, 1.37]:
		Kit.block(fridge, Vector3(-0.02, y, 0), Vector3(0.53, 0.075, 0.64), enamel)
	for y in [0.31, 0.57, 0.82]:
		Kit.block(fridge, Vector3(-0.025, y, 0), Vector3(0.46, 0.022, 0.55), liner)
		Kit.block(fridge, Vector3(0.204, y, 0), Vector3(0.021, 0.032, 0.55), steel)
	Kit.block(fridge, Vector3(-0.02, 1.069, 0), Vector3(0.51, 0.044, 0.58), liner)
	var bottle := Kit.material("6b8280", false, 0.31)
	Kit.cylinder(fridge, Vector3(-0.085, 0.415, 0.13), 0.046, 0.053, 0.20, bottle)
	Kit.cylinder(fridge, Vector3(-0.085, 0.527, 0.13), 0.024, 0.046, 0.026, bottle)
	Kit.cylinder(fridge, Vector3(-0.085, 0.548, 0.13), 0.023, 0.023, 0.020, steel)
	Kit.cylinder(fridge, Vector3(0.028, 0.63, -0.14), 0.047, 0.048, 0.10, Kit.material("9a8b60"))
	Kit.block(fridge, Vector3(0.015, 0.172, 0), Vector3(0.414, 0.075, 0.465), seal)
	Kit.block(fridge, Vector3(0.022, 0.214, 0), Vector3(0.42, 0.025, 0.474), liner)
	Kit.block(fridge, Vector3(0.217, 0.185, 0), Vector3(0.018, 0.044, 0.165), steel)
	Kit.block(fridge, Vector3(0.003, 1.099, -0.098), Vector3(0.33, 0.017, 0.22), steel)
	for x in [-0.098, -0.021, 0.056, 0.133]:
		Kit.block(fridge, Vector3(x, 1.118, -0.098), Vector3(0.009, 0.027, 0.205), liner)
	Kit.block(fridge, Vector3(-0.109, 1.15, 0.13), Vector3(0.153, 0.089, 0.115), Kit.material("b5b4a8", false, 0.84)).rotation.y = -0.12
	Kit.block(fridge, Vector3(0.084, 0.997, 0.174), Vector3(0.19, 0.037, 0.105), liner)
	var bulb := OmniLight3D.new()
	fridge.add_child(bulb)
	bulb.position = Vector3(0.201, 0.966, 0.168)
	bulb.omni_range = 0.75
	bulb.omni_attenuation = 1.25
	bulb.light_color = Color("fce0af")
	bulb.light_energy = 0.48
	bulb.visible = false

	var doors: Dictionary = {}
	for compartment in [["Heladera", 0.574, 0.964, 0.32], ["Freezer", 1.229, 0.281, -0.035]]:
		var tag: String = compartment[0]
		var center: float = compartment[1]
		var height: float = compartment[2]
		var hinge := Node3D.new()
		fridge.add_child(hinge)
		hinge.position = Vector3(0.261, 0.0, -0.32)
		doors[tag] = hinge
		var door_leaf := Kit.item(hinge, Vector3(0.022, center, 0.32), tag, Vector3.ZERO, Vector3(0.101, height, 0.64))
		Kit.block(door_leaf, Vector3(-0.04, 0, 0), Vector3(0.026, height - 0.030, 0.626), seal)
		var half := height * 0.5
		Kit.shell(door_leaf, [Vector4(-half, 0.001, 0.001, 0), Vector4(-half, 0.032, 0.307, 0),
			Vector4(-half + 0.017, 0.045, 0.318, 0), Vector4(half - 0.017, 0.045, 0.318, 0),
			Vector4(half, 0.032, 0.307, 0), Vector4(half, 0.001, 0.001, 0)], door, 0.21, true)
		for z in [0.059, 0.214]:
			Kit.block(door_leaf, Vector3(0.052, compartment[3], z), Vector3(0.054, 0.038, 0.029), steel)
		Kit.block(door_leaf, Vector3(0.079, compartment[3], 0.136), Vector3(0.019, 0.034, 0.195), steel)
		Kit.item(fridge, Vector3(0.247, center, 0), tag, Vector3.ZERO, Vector3(0.052, height - 0.043, 0.55)).collision_layer = 2
		if tag == "Heladera":
			hinge.set_meta("interior_light", bulb)
			for y in [-0.31, -0.014]:
				Kit.block(door_leaf, Vector3(-0.066, y, 0), Vector3(0.067, 0.035, 0.52), liner)
				Kit.block(door_leaf, Vector3(-0.097, y + 0.036, 0), Vector3(0.015, 0.070, 0.52), liner)
			Kit.block(door_leaf, Vector3(0.05, 0.32, -0.132), Vector3(0.014, 0.044, 0.103), steel)
	for z in [-0.24, 0.24]:
		Kit.block(fridge, Vector3(0.17, 0.037, z), Vector3(0.10, 0.074, 0.10), seal)
	for vent in 5:
		Kit.block(fridge, Vector3(0.255, 0.031 + vent * 0.009, 0.105), Vector3(0.006, 0.003, 0.188), seal)
	var motor := AudioStreamPlayer3D.new()
	motor.stream = refrigerator_hum()
	motor.volume_db = -29.0
	motor.unit_size = 1.10
	motor.max_distance = 5.6
	fridge.add_child(motor)
	motor.position.y = 0.43
	motor.play()
	return doors

static func privy(parent: Node3D, center: Vector3) -> Node3D:
	var shed := Node3D.new()
	shed.name = "Baño exterior"
	parent.add_child(shed)
	shed.position = center
	var boards := [wood("86735e"), wood("8d7963"), wood("796957")]
	var trim := wood("685c50")
	var deck := wood("9e856b", true)
	var tin := Kit.material("74786c", false, 0.67)
	var steel := Kit.material("514d45", false, 0.48)
	var rim := Kit.material("c5b9a0", false, 0.69)
	var dark := Kit.material("34332b")
	for side in [-1, 1]:
		var wall := Kit.item(shed, Vector3(side * 0.819, 1.124, 0), "", Vector3.ZERO, Vector3(0.083, 2.24, 1.78))
		for i in 10:
			Kit.block(wall, Vector3(0, 0, -0.804 + i * 0.179), Vector3(0.084, 2.24, 0.175), boards[(i + 2 * side + 10) % 3])
		for y in [-0.88, 0.65]:
			Kit.block(wall, Vector3(side * -0.052, y, 0), Vector3(0.055, 0.088, 1.79), trim)
	var back := Kit.item(shed, Vector3(0, 1.125, 0.875), "", Vector3.ZERO, Vector3(1.65, 2.25, 0.085))
	for i in 10:
		Kit.block(back, Vector3(-0.743 + i * 0.165, 0, 0), Vector3(0.162, 2.25, 0.086), boards[(2 * i) % 3])
	var floor := Kit.item(shed, Vector3(0, 0.012, 0), "", Vector3.ZERO, Vector3(1.63, 0.051, 1.80))
	for i in 10:
		Kit.block(floor, Vector3(0, 0, -0.804 + i * 0.179), Vector3(1.62, 0.051, 0.175), deck)
	for x in [-0.782, 0.782]:
		Kit.block(shed, Vector3(x, 1.13, -0.891), Vector3(0.095, 2.27, 0.115), trim)
	Kit.block(shed, Vector3(0, 2.173, -0.879), Vector3(1.54, 0.18, 0.081), trim)
	Kit.block(shed, Vector3(0, 2.178, -0.922), Vector3(0.31, 0.11, 0.013), dark)
	for y in [2.142, 2.178, 2.214]:
		Kit.block(shed, Vector3(0, y, -0.932), Vector3(0.309, 0.014, 0.034), tin).rotation.x = 0.3
	var roof := Node3D.new()
	shed.add_child(roof)
	roof.position.y = 2.291
	roof.rotation.x = 0.055
	Kit.block(roof, Vector3.ZERO, Vector3(1.89, 0.055, 2.09), tin)
	for i in 16:
		Kit.block(roof, Vector3(-0.895 + i * 0.119, 0.030, 0), Vector3(0.038, 0.018, 2.08), tin)
	Kit.cylinder(shed, Vector3(0.52, 2.38, 0.60), 0.053, 0.050, 0.37, steel)
	Kit.cylinder(shed, Vector3(0.52, 2.576, 0.60), 0.079, 0.065, 0.027, tin)

	var hinge := Node3D.new()
	shed.add_child(hinge)
	hinge.position = Vector3(-0.744, 0, -0.917)
	var door := Kit.item(hinge, Vector3(0.744, 1.06, 0), "Puerta del baño", Vector3.ZERO, Vector3(1.482, 2.047, 0.061))
	for i in 9:
		Kit.block(door, Vector3(-0.656 + i * 0.164, 0, 0), Vector3(0.161, 2.047, 0.061), boards[i % 3])
	for y in [-0.63, 0.67]:
		Kit.block(door, Vector3(0, y, 0.046), Vector3(1.44, 0.084, 0.043), trim)
		Kit.block(door, Vector3(-0.639, y, -0.039), Vector3(0.23, 0.059, 0.022), steel)
	brace(door, Vector3(-0.64, -0.58, 0.046), Vector3(0.64, 0.60, 0.046), 0.065, trim)
	Kit.block(door, Vector3(0.606, -0.045, -0.058), Vector3(0.184, 0.043, 0.070), steel)
	Kit.block(door, Vector3(0.61, -0.052, 0.064), Vector3(0.174, 0.031, 0.078), steel)

	var bench := Kit.item(shed, Vector3(0, 0.277, 0.53), "", Vector3.ZERO, Vector3(1.57, 0.494, 0.59))
	Kit.block(bench, Vector3(0, 0, -0.269), Vector3(1.57, 0.49, 0.052), trim)
	for x in [-0.542, 0.542]:
		Kit.block(bench, Vector3(x, 0.245, 0), Vector3(0.488, 0.051, 0.59), deck)
	for z in [-0.253, 0.253]:
		Kit.block(bench, Vector3(0, 0.245, z), Vector3(0.60, 0.051, 0.125), deck)
	Kit.cylinder(bench, Vector3(0, 0.18, 0), 0.205, 0.220, 0.009, dark)
	Kit.shell(bench, [
		Vector4(0.267, 0.242, 0.212, 0), Vector4(0.28, 0.250, 0.22, 0), Vector4(0.318, 0.239, 0.213, 0),
		Vector4(0.322, 0.179, 0.15, 0), Vector4(0.308, 0.164, 0.133, 0), Vector4(0.265, 0.164, 0.133, 0),
	], rim, 0.84, true)
	var roller := Vector3(0.739, 0.84, 0.36)
	Kit.cylinder(shed, roller, 0.071, 0.071, 0.12, rim).rotation.x = PI / 2.0
	Kit.cylinder(shed, roller + Vector3(0, 0, -0.061), 0.024, 0.024, 0.007, dark).rotation.x = PI / 2.0
	Kit.block(shed, roller + Vector3(-0.067, -0.047, 0), Vector3(0.008, 0.085, 0.112), rim).rotation.z = -0.14
	Kit.block(shed, Vector3(-0.524, 1.23, 0.73), Vector3(0.41, 0.037, 0.225), trim)
	Kit.cylinder(shed, Vector3(-0.53, 1.332, 0.70), 0.035, 0.033, 0.171, Kit.material("8b9a86"))
	Kit.cylinder(shed, Vector3(-0.53, 1.43, 0.70), 0.019, 0.019, 0.025, steel)
	return hinge

static func refrigerator_hum() -> AudioStreamWAV:
	const RATE := 11025
	const FRAMES := RATE * 2
	var samples := PackedByteArray()
	samples.resize(FRAMES * 2)
	for i in FRAMES:
		var t := float(i) / RATE
		var vibration := sin(TAU * 50.0 * t) * 0.42 + sin(TAU * 100.0 * t) * 0.31 + sin(TAU * 150.0 * t) * 0.09
		samples.encode_s16(i * 2, roundi(vibration * (0.76 + 0.21 * cos(PI * t)) * 16384.0))
	var tape := AudioStreamWAV.new()
	tape.format = AudioStreamWAV.FORMAT_16_BITS
	tape.mix_rate = RATE
	tape.loop_mode = AudioStreamWAV.LOOP_FORWARD
	tape.loop_end = FRAMES
	tape.data = samples
	return tape

static func pendant(parent: Node3D, pos: Vector3):
	var fixture := Node3D.new()
	parent.add_child(fixture)
	fixture.position = pos
	var olive := Kit.material("ad936b", false, 0.62)
	var porcelain := Kit.material("e8c995", false, 0.58)
	Kit.shell(fixture, [
		Vector4(-0.035, 0.254, 0.254, 0), Vector4(0.006, 0.245, 0.245, 0),
		Vector4(0.094, 0.178, 0.178, 0), Vector4(0.168, 0.083, 0.083, 0),
		Vector4(0.172, 0.028, 0.028, 0),
	], olive, 1.0)
	Kit.shell(fixture, [
		Vector4(0.158, 0.032, 0.032, 0), Vector4(0.148, 0.079, 0.079, 0),
		Vector4(0.081, 0.170, 0.170, 0), Vector4(-0.034, 0.243, 0.243, 0),
		Vector4(-0.039, 0.253, 0.253, 0),
	], porcelain, 1.0)
	var metal := Kit.material("4e473a")
	Kit.cylinder(fixture, Vector3.UP * 0.422, 0.007, 0.007, 0.50, metal)
	Kit.cylinder(fixture, Vector3.UP * 0.193, 0.033, 0.025, 0.047, metal)
	var bulb := StandardMaterial3D.new()
	bulb.albedo_color = Color("ffe4ad")
	bulb.emission_enabled = true
	bulb.emission = Color("ffcc79")
	bulb.emission_energy_multiplier = 0.43
	pad(fixture, Vector3.UP * 0.025, Vector3(0.094, 0.132, 0.094), bulb, 1.0)
