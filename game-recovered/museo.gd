extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Stone = preload("res://piedra_serrana.gd")
const Refuge = preload("res://refugio.gd")
const DISTANCE := 292.0
const SITE_OFFSET := 14.0
const LEGACY_SITE_OFFSET := 9.5
const HALF_WIDTH := 5.4
const HALF_DEPTH := 7.0
const HEIGHT := 2.85
const ELVIRA_BOOK := "Libro de Elvira"
const ELVIRA_COVER = preload("res://museo/libro_comechingones.webp")
const REPLICAS := ["Mortero y mano", "Tortero", "Vasija de cerámica"]
const STORIES := ["Bastón de Mando", "Vikingos en las sierras", "Luces sobre el cerro"]
const REPLICA_CAPTIONS := ["Réplica · Molienda", "Réplica · Hilado", "Réplica · Alfarería"]
const STORY_CAPTIONS := ["Relato esotérico", "Hipótesis sin respaldo arqueológico", "Archivo de testimonios"]
const LABELS = {
	"Sala de objetos": "Objetos y técnicas de los pueblos comechingones.",
	"Museo del Uritorco": "Museo del Uritorco\n\nEl pasillo recorre la historia de los pueblos comechingones. A los lados quedan las salas de objetos y de relatos.",
	"Pueblos comechingones": "Los documentos coloniales usaron el nombre comechingones para referirse a poblaciones de las Sierras Centrales. Sus modos de vida variaban según el lugar y la época. Hoy hay comunidades comechingonas en Córdoba que se reconocen como parte de esa historia.",
	"Vivir en las sierras": "En los sitios arqueológicos serranos aparecen instrumentos para moler, restos de plantas y fragmentos de vasijas. Un objeto encontrado junto al lugar donde se lo usó aporta más información que una pieza suelta. Las ilustraciones muestran usos posibles de las réplicas.",
	"Sembrar en las sierras": "Antes de la conquista · Ilustración\n\nEn las Sierras Centrales se cultivaban maíz y zapallo. Según el lugar y la época, la siembra convivía con la caza y la recolección de frutos como el algarrobo. Los restos de plantas encontrados en los sitios ayudan a reconstruir qué se cultivaba y qué se juntaba.",
	"Tierra y encomienda": "Siglos XVI a XVIII · Recreación ilustrada\n\nCon la conquista española llegaron las encomiendas, que exigían trabajo o tributo a los pueblos indígenas. Hubo traslados y disputas por la tierra. En los expedientes coloniales quedaron reclamos de comunidades que defendían los lugares donde vivían y sembraban.",
	"Relatos del cerro": "La sala reúne testimonios y reconstrucciones sobre el Uritorco. Cada ficha identifica qué se muestra y de dónde viene la información.",
	"Memoria comechingona": "Comunidades de hoy · Ilustración\n\nEn la ciudad de Córdoba, la comunidad comechingona del Pueblo de La Toma reconstruye su historia con documentos y relatos de familia. La memoria del territorio también se transmite al recordar los nombres de los lugares y contar quiénes vivían allí.",
	"Mortero y mano": "Réplica · Molienda\n\nSe golpeaba o frotaba el material con una piedra de mano sobre una cavidad. Moler podía servir para preparar alimentos y también otros materiales. El desgaste y los residuos que quedan en la piedra ayudan a investigar qué se molió.",
	"Tortero": "Réplica · Hilado\n\nEl disco perforado se monta en un huso. Su peso sostiene el giro mientras se estira y se tuerce la fibra. En un hallazgo, la forma del disco y el contexto ayudan a reconocer la herramienta. El hilo rara vez se conserva.",
	"Vasija de cerámica": "Réplica · Alfarería\n\nUna forma de hacer una vasija es superponer rollos de arcilla, alisar las uniones y cocerla. El borde y el cuerpo ayudan a reconstruir su forma a partir de tiestos. Para conocer su uso también se examinan las huellas de calor y los residuos.",
	"Bastón de Mando": "Relato esotérico · Ilustración\n\nLa historia de un bastón oculto en el Uritorco circula en libros y testimonios del siglo XX. La pieza exhibida interpreta ese relato. Su procedencia arqueológica sigue sin establecerse.",
	"Vikingos en las sierras": "Hipótesis sin respaldo arqueológico · Ilustración\n\nAlgunos autores atribuyeron marcas serranas a viajeros nórdicos. Para sostener esa atribución harían falta materiales fechados y hallados en contexto. Una semejanza visual puede aparecer entre pueblos que nunca se encontraron.",
	"Luces sobre el cerro": "Archivo de testimonios · Ilustración\n\nLos relatos sobre luces en el Uritorco incluyen observaciones, fotografías y reconstrucciones. Registrar hora, rumbo y posición del observador permite comparar versiones y examinar posibles explicaciones.",
}

static func center(valley, offset: float = SITE_OFFSET) -> Vector3:
	var route = valley.route
	var x: float = route.trail(DISTANCE) + offset
	var floor_height: float = route.at(x, DISTANCE).y
	for dx in [-HALF_WIDTH, 0.0, HALF_WIDTH]:
		for dz in [-HALF_DEPTH, 0.0, HALF_DEPTH]:
			floor_height = maxf(floor_height, route.at(x + dx, DISTANCE + dz).y)
	return Vector3(x, floor_height + 0.23, route.ORIGIN_Z - DISTANCE)

static func night_closed(valley) -> bool:
	return float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.68

static func under_roof(valley, at: Vector3) -> bool:
	var center_z: float = valley.route.ORIGIN_Z - DISTANCE
	if absf(at.z - center_z) > HALF_DEPTH - 0.12: return false
	var local := at - center(valley)
	return absf(local.x) < HALF_WIDTH - 0.10 and local.y >= -0.16 and local.y < HEIGHT

static func restore_legacy_position(valley, position: Vector3) -> Vector3:
	var previous := center(valley, LEGACY_SITE_OFFSET)
	var local := position - previous
	if absf(local.x) <= HALF_WIDTH and absf(local.z) <= HALF_DEPTH and local.y >= -0.3 and local.y <= HEIGHT:
		return position + center(valley) - previous
	return position

static func build(valley):
	var c := center(valley)
	var width := HALF_WIDTH * 2.0
	var depth := HALF_DEPTH * 2.0
	var lowest := c.y
	for dx in [-HALF_WIDTH, 0.0, HALF_WIDTH]:
		for dz in [-HALF_DEPTH, 0.0, HALF_DEPTH]:
			lowest = minf(lowest, valley.route.at(c.x + dx, DISTANCE + dz).y)
	var foundation := c.y - lowest + 0.23
	var floor: MeshInstance3D = valley.box(c - Vector3.UP * foundation * 0.5, Vector3(width, foundation, depth), "9d8f76", true)
	floor.get_child(0).set_meta("footstep", &"stone")
	floor.material_override = Stone.paint("77716a")
	floor.name = "Base de piedra del museo"
	for side in [-1, 1]:
		wall(valley, c + Vector3(0, HEIGHT * 0.5, side * HALF_DEPTH), Vector3(width, HEIGHT, 0.22))
		wall(valley, c + Vector3(-HALF_WIDTH, HEIGHT * 0.5, side * 3.95), Vector3(0.23, HEIGHT, 6.1))
		var roof: MeshInstance3D = valley.box(c + Vector3(side * 2.76, 3.22, 0), Vector3(5.86, 0.19, 14.65), "74675d")
		roof.rotation.z = -side * 0.115
	valley.box(c + Vector3.UP * 2.89, Vector3(10.65, 0.10, 13.94), "ad9c84")
	wall(valley, c + Vector3(HALF_WIDTH, HEIGHT * 0.5, 0), Vector3(0.23, HEIGHT, depth))
	wall(valley, c + Vector3(-HALF_WIDTH, 2.61, 0), Vector3(0.24, 0.48, 2.1))
	build_entrance(valley, c)
	for z in [-1.8, 1.8]:
		for x in [-3.38, 3.38]:
			wall(valley, c + Vector3(x, HEIGHT * 0.5, z), Vector3(4.04, HEIGHT, 0.18))
		for x in [-1.33, 1.33]:
			valley.timber(valley.box(c + Vector3(x, 1.21, z), Vector3(0.12, 2.42, 0.24), "89765e", true))
		valley.timber(valley.box(c + Vector3(0, 2.49, z), Vector3(2.76, 0.16, 0.24), "89765e", true), true)
	for z in [-4.7, 0.0, 4.7]:
		var lamp := OmniLight3D.new()
		valley.add_child(lamp)
		lamp.position = c + Vector3(0, 2.55, z)
		lamp.light_color = Color("#fff0d6")
		lamp.omni_range = 8.0
		lamp.light_energy = 0.73
		valley.box(c + Vector3(0, 2.68, z), Vector3(0.48, 0.08, 0.32), "dcc9a4")
	plaque(valley, c + Vector3(0, 2.32, -1.66), "Sala de objetos", 0.0, 2.15)
	plaque(valley, c + Vector3(0, 2.49, 1.646), "Relatos del cerro", PI, 2.55)
	plaque(valley, c + Vector3(-3.56, 2.48, -1.66), "Pueblos comechingones", 0.0, 2.82)
	display_panel(valley, c + Vector3(-4.32, 1.40, -1.653), "Sembrar en las sierras", "historia", 0, 0.0, "Vida cotidiana antes de la conquista")
	display_panel(valley, c + Vector3(-2.86, 1.40, -1.653), "Tierra y encomienda", "historia", 1, 0.0, "Trabajo, tributo y territorio")
	display_panel(valley, c + Vector3(-1.88, 1.40, -1.653), "Memoria comechingona", "historia", 2, 0.0, "Pueblo de La Toma · Córdoba")
	valley.timber(valley.box(c + Vector3(3.65, 0.44, -0.76), Vector3(2.3, 0.14, 0.49), "846b50", true, "Banco"), true)
	for x in [2.7, 4.58]:
		valley.timber(valley.box(c + Vector3(x, 0.23, -0.76), Vector3(0.16, 0.46, 0.42), "6d5d51", true))
	for i in 3:
		var x := (i - 1) * 3.30
		vitrine(valley, c + Vector3(x, 0, -4.37), i)
		display_panel(valley, c + Vector3(x, 1.67, -6.85), REPLICAS[i], "comechingones", i, 0.0, REPLICA_CAPTIONS[i])
		display_panel(valley, c + Vector3(x, 1.67, 6.85), STORIES[i], "relatos", i, PI, STORY_CAPTIONS[i])

static func build_elvira_book(valley: Node3D) -> StaticBody3D:
	var at := center(valley) + Vector3(3.43, 0.54, -0.77)
	var book := Kit.item(valley, at, ELVIRA_BOOK, Vector3.ZERO, Vector3(0.25, 0.07, 0.37))
	book.rotation.y = -0.16
	Kit.block(book, Vector3.ZERO, Vector3(0.23, 0.038, 0.34), Kit.material("c2a775"))
	Kit.block(book, Vector3(0, -0.025, 0), Vector3(0.247, 0.012, 0.36), Kit.material("654a2f"))
	Refuge.print_surface(book, Vector3(0, 0.021, 0), Vector2(0.247, 0.36), ELVIRA_COVER).rotation.x = -PI * 0.5
	return book

static func wall(valley, at: Vector3, size_m: Vector3):
	var surface: MeshInstance3D = valley.box(at, size_m, "b9aa94", true)
	surface.material_override = Stone.paint("c1a37d")
	surface.name = "Muro de arenisca del museo"

static func build_entrance(valley, c: Vector3):
	var front := c + Vector3(-HALF_WIDTH, 0, 0)
	var route = valley.route
	var start: Vector3 = route.at(route.trail(DISTANCE) + 1.8, DISTANCE)
	var end := front + Vector3(0.12, 0.0, 0)
	start.y -= 0.12
	var span := end - start
	var ramp: MeshInstance3D = valley.box(start.lerp(end, 0.5) - Vector3.UP * 0.09, Vector3(span.length(), 0.18, 2.38), "a38e71", true)
	ramp.get_child(0).set_meta("footstep", &"stone")
	ramp.rotation.z = atan2(span.y, span.x)
	ramp.material_override = Stone.paint("9d8c75")
	ramp.name = "Pasarela de piedra del museo"
	valley.museum_hinge = Node3D.new()
	valley.add_child(valley.museum_hinge)
	valley.museum_hinge.position = front + Vector3(0, 0, -0.88)
	var leaf: MeshInstance3D = valley.box(front + Vector3(0, 1.14, 0), Vector3(0.12, 2.28, 1.76), "887050", true, "Puerta del museo")
	var oak := Refuge.wood("887050")
	oak.set_shader_parameter("side_grain", true)
	oak.set_shader_parameter("grain_strength", 0.29)
	leaf.material_override = oak
	var jamb := Refuge.wood("746048")
	jamb.set_shader_parameter("side_grain", true)
	for z in [-0.91, 0.91]:
		var frame: MeshInstance3D = valley.box(front + Vector3(-0.02, 1.13, z), Vector3(0.17, 2.26, 0.10), "746048")
		frame.material_override = jamb
	var lintel: MeshInstance3D = valley.box(front + Vector3(-0.03, 2.32, 0), Vector3(0.19, 0.14, 1.94), "746048")
	var lintel_wood := Refuge.wood("746048", true)
	lintel_wood.set_shader_parameter("side_grain", true)
	lintel.material_override = lintel_wood
	leaf.reparent(valley.museum_hinge)
	var handle: MeshInstance3D = valley.box(front + Vector3(-0.09, 1.07, 0.64), Vector3(0.13, 0.08, 0.12), "a69a7b")
	handle.reparent(valley.museum_hinge)
	plaque(valley, front + Vector3(-0.14, 2.62, 0), "Museo del Uritorco", -PI / 2.0, 2.85)

static func vitrine(valley, c: Vector3, index: int):
	var title: String = REPLICAS[index]
	var plinth: MeshInstance3D = valley.box(c + Vector3.UP * 0.37, Vector3(1.95, 0.74, 1.08), "74624e", true, title)
	plinth.material_override = Refuge.wood("74624e", true)
	var liner: MeshInstance3D = valley.box(c + Vector3.UP * 0.75, Vector3(1.86, 0.035, 0.99), "afa18b")
	liner.material_override = Refuge.cloth("8e8066", "b2a38a", 0.38)
	for x in [-0.945, 0.945]:
		valley.timber(valley.box(c + Vector3(x, 0.773, 0), Vector3(0.047, 0.027, 1.064), "7c6349"))
	for z in [-0.513, 0.513]:
		valley.timber(valley.box(c + Vector3(0, 0.774, z), Vector3(1.89, 0.032, 0.041), "8c7656"), true)
	var cabinet: MeshInstance3D = valley.box(c + Vector3.UP * 1.03, Vector3(1.94, 0.56, 1.06), "a7bdb4", true, title)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.64, 0.78, 0.75, 0.13)
	glass.roughness = 0.36
	cabinet.material_override = glass
	cabinet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x in [-0.96, 0.96]:
		for z in [-0.52, 0.52]:
			valley.box(c + Vector3(x, 1.031, z), Vector3(0.025, 0.56, 0.025), "514d40")
	plaque(valley, c + Vector3(0, 0.57, 0.55), title, 0.0, 1.78)
	var base := c + Vector3.UP * 0.77
	match index:
		0:
			var mortar := shaped_vessel([
				Vector2(0.29, 0), Vector2(0.40, 0.035), Vector2(0.43, 0.16), Vector2(0.40, 0.195),
				Vector2(0.27, 0.19), Vector2(0.24, 0.145), Vector2(0.12, 0.048), Vector2(0.0, 0.04)
			], 0.73, 0.11, Color("#8d8473"))
			valley.prop(mortar, base + Vector3(-0.21, 0, 0.05), "8d8473").material_override = Stone.paint()
			var faces := Stone.surface()
			var rng := RandomNumberGenerator.new()
			rng.seed = 292
			Stone.fragment(faces, base + Vector3(0.40, 0, 0.065), Vector3(0.36, 0.125, 0.17), -0.42, rng)
			Stone.finish(valley, faces, "Mano de la vitrina")
		1:
			var spindle: MeshInstance3D = valley.box(base + Vector3(0, 0.15, 0), Vector3(0.021, 0.36, 0.027), "88674b")
			spindle.rotation.z = -0.16
			valley.timber(spindle)
			var whorl := TorusMesh.new()
			whorl.inner_radius = 0.023
			whorl.outer_radius = 0.135
			valley.prop(whorl, base + Vector3(0, 0.115, 0), "b18059").material_override = Stone.paint("987453")
			var spool := PackedVector3Array()
			for turn in 52:
				var angle := turn * 0.51
				spool.append(spindle.position + Vector3(0.028 * cos(angle), 0.074 + 0.0011 * turn, 0.031 * sin(angle)))
			Kit.cord(valley, spool, 0.0031, Refuge.cloth("b9a88c", "8e7c60", 0.58))
			valley.stone(base + Vector3(0.34, 0.065, 0.11), Vector3(0.34, 0.13, 0.23), "d7c5a0")
		2:
			var pot := shaped_vessel([
				Vector2(0.16, 0), Vector2(0.27, 0.08), Vector2(0.30, 0.20), Vector2(0.291, 0.26),
				Vector2(0.26, 0.32), Vector2(0.20, 0.37), Vector2(0.17, 0.41), Vector2(0.19, 0.46),
				Vector2(0.15, 0.46), Vector2(0.13, 0.39), Vector2(0.18, 0.31), Vector2(0.017, 0.08)
			], 0.96, 0.038, Color("#b67d57"), true)
			valley.prop(pot, base, "b67d57").material_override = Stone.paint()
			var edges := Stone.surface()
			var chip := PackedVector3Array([Vector3(-0.10, 0.027, -0.055), Vector3(-0.036, 0.039, -0.096),
				Vector3(0.085, 0.06, -0.067), Vector3(0.108, 0.052, 0.021), Vector3(0.039, 0.037, 0.085),
				Vector3(-0.061, 0.025, 0.040)])
			for i in range(1, chip.size() - 1):
				Stone.triangle(edges, chip[0], chip[i], chip[i + 1], Color("#a26b4c").lightened(0.025 * i))
			var sherd := Stone.finish(valley, edges, "Tiesto de la vitrina")
			sherd.position = base + Vector3(0.49, 0, 0.15)

static func shaped_vessel(profile: Array, depth_ratio: float, irregularity: float, tint: Color, painted := false) -> ArrayMesh:
	const SIDES := 40
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in profile.size():
		var edge: Vector2 = profile[row]
		for side in SIDES:
			var angle := TAU * side / SIDES
			var radius := edge.x * (1.0 + irregularity * (0.62 * cos(angle * 3.0) + 0.38 * sin(angle * 7.0)))
			var rise := edge.y + irregularity * 0.15 * sin(angle * 5.0) * smoothstep(0, 0.11, edge.y)
			var tone := tint.lightened(0.035 * sin(angle * 7.0 + row * 1.2))
			if painted and row in [3, 4, 5]:
				var stroke := float(side % 8) / 8.0
				var zig := absf(stroke * 2.0 - 1.0)
				var dye := maxf(0.12 if row == 3 or row == 5 else 0.0, 1.0 - absf(zig - 0.5 * (row - 3)) * 3.3)
				tone = tone.lerp(Color("#62402f"), dye * 0.79)
			surface.set_color(tone)
			surface.add_vertex(Vector3(radius * cos(angle), rise, radius * sin(angle) * depth_ratio))
	for row in range(profile.size() - 1):
		for side in SIDES:
			var a := row * SIDES + side
			var b := row * SIDES + (side + 1) % SIDES
			for index in [a, a + SIDES, b, b, a + SIDES, b + SIDES]:
				surface.add_index(index)
	surface.generate_normals()
	return surface.commit()

static func display_panel(valley, center_pos: Vector3, title: String, group: String, index: int, angle: float, caption: String):
	var art_path := "res://museo/" + group + ".webp"
	if not ResourceLoader.exists(art_path):
		plaque(valley, center_pos, title, angle, 1.95)
		return
	var frame: MeshInstance3D = valley.box(center_pos, Vector3(0.82, 1.58, 0.055), "766650", true, title)
	frame.rotation.y = angle
	var atlas: Texture2D = load(art_path)
	var artwork := AtlasTexture.new()
	artwork.atlas = atlas
	var width := atlas.get_width() / 3.0
	artwork.region = Rect2(width * index, 0, width, atlas.get_height())
	artwork.filter_clip = true
	var image := Sprite3D.new()
	frame.add_child(image)
	image.texture = artwork
	image.position.z = 0.033
	image.pixel_size = 1.50 / atlas.get_height()
	image.shaded = false
	image.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	poster_text(frame, title, 0.637, 0.064)
	poster_text(frame, caption, -0.647, 0.047)

static func poster_text(frame: Node3D, caption: String, y: float, height: float):
	var print_label := Label3D.new()
	print_label.text = caption
	print_label.font_size = 48
	print_label.outline_size = 0
	print_label.render_priority = 1
	print_label.modulate = Color("#3d3024")
	var pixels := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, print_label.font_size).x
	print_label.pixel_size = minf(height / print_label.font_size, 0.65 / maxf(1.0, pixels))
	frame.add_child(print_label)
	print_label.position = Vector3(0.0, y, 0.042)

static func plaque(valley, at: Vector3, title: String, angle: float, width: float):
	var panel: MeshInstance3D = valley.box(at, Vector3(width, 0.21, 0.047), "534737", true, title)
	panel.rotation.y = angle
	lettering(valley, at + Vector3(sin(angle), 0.0, cos(angle)) * 0.028, title, angle, 28)

static func lettering(valley, at: Vector3, title: String, angle: float, font_size: int):
	var label := Label3D.new()
	valley.add_child(label)
	label.position = at
	label.rotation.y = angle
	label.text = title
	label.font_size = font_size
	label.pixel_size = 0.0026
	label.outline_size = 0
	label.modulate = Color("#f3e4ca")
