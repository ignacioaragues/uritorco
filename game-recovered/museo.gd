extends RefCounted

const DISTANCE := 292.0
const SITE_OFFSET := 14.0
const LEGACY_SITE_OFFSET := 9.5
const HALF_WIDTH := 5.4
const HALF_DEPTH := 7.0
const HEIGHT := 2.85
const REPLICAS := ["Mortero y mano", "Tortero", "Vasija de cerámica"]
const STORIES := ["Bastón de Mando", "Vikingos en las sierras", "Luces sobre el cerro"]
const LABELS = {
	"Sala de las sierras": "Museo de sitio · Pueblos comechingones\n\nLas salas reúnen réplicas, ilustraciones y documentos. En la primera están los objetos y sus contextos arqueológicos. En la segunda están los relatos que circularon sobre el cerro.",
	"Pueblos comechingones": "Los documentos coloniales usaron el nombre comechingones para referirse a poblaciones de las Sierras Centrales. Sus modos de vida variaban según el lugar y la época. Hoy hay comunidades comechingonas en Córdoba que se reconocen como parte de esa historia.",
	"Vivir en las sierras": "En los sitios arqueológicos serranos aparecen instrumentos para moler, restos de plantas y fragmentos de vasijas. Un objeto encontrado junto al lugar donde se lo usó aporta más información que una pieza suelta. Las ilustraciones muestran usos posibles de las réplicas.",
	"Relatos del cerro": "Esta sala reúne testimonios, ilustraciones y reconstrucciones. Los relatos modernos también forman parte de la historia del cerro. Las fichas indican cuándo hay un testimonio y cuándo hay evidencia material.",
	"Memoria comechingona": "Durante la colonización se repartieron tierras y comunidades bajo el sistema de encomiendas. Algunos pueblos sostuvieron reclamos por sus tierras durante generaciones. Hoy las comunidades comechingonas conservan memorias familiares y lugares de importancia, y participan en las discusiones sobre cómo se cuida el patrimonio serrano.",
	"Mortero y mano": "Réplica · Molienda\n\nSe golpeaba o frotaba el material con una piedra de mano sobre una cavidad. Moler podía servir para preparar alimentos y también otros materiales. El desgaste y los residuos que quedan en la piedra ayudan a investigar qué se molió.",
	"Tortero": "Réplica · Hilado\n\nEl disco perforado se monta en un huso. Su peso sostiene el giro mientras se estira y se tuerce la fibra. En un hallazgo, la forma del disco y el contexto ayudan a reconocer la herramienta. El hilo rara vez se conserva.",
	"Vasija de cerámica": "Réplica · Alfarería\n\nUna forma de hacer una vasija es superponer rollos de arcilla, alisar las uniones y cocerla. El borde y el cuerpo ayudan a reconstruir su forma a partir de tiestos. Para conocer su uso también se examinan las huellas de calor y los residuos.",
	"Bastón de Mando": "Relato esotérico · Ilustración\n\nLa historia de un bastón oculto en el Uritorco circula en libros y testimonios del siglo XX. La pieza exhibida interpreta ese relato. Su procedencia arqueológica sigue sin establecerse.",
	"Vikingos en las sierras": "Hipótesis sin respaldo arqueológico · Ilustración\n\nAlgunos autores atribuyeron marcas serranas a viajeros nórdicos. Para sostener esa atribución harían falta materiales fechados y hallados en contexto. Una semejanza visual puede aparecer entre pueblos que nunca se encontraron.",
	"Luces sobre el cerro": "Archivo de testimonios · Ilustración\n\nLos relatos sobre luces en el Uritorco incluyen observaciones, fotografías y reconstrucciones. Registrar hora, rumbo y posición del observador permite comparar versiones y examinar posibles explicaciones.",
	"Maqueta del arco": "Maqueta del arco · Reconstrucción de un dibujo anónimo\n\nLa ficha lleva fecha del 12 de julio. El dibujo muestra dos pilares, un dintel torcido y un cuerpo suspendido en el hueco. El margen de la hoja está arrancado."
}

static func center(valley, offset: float = SITE_OFFSET) -> Vector3:
	var route = valley.route
	var x: float = route.trail(DISTANCE) + offset
	var floor_height: float = route.at(x, DISTANCE).y
	for dx in [-HALF_WIDTH, 0.0, HALF_WIDTH]:
		for dz in [-HALF_DEPTH, 0.0, HALF_DEPTH]:
			floor_height = maxf(floor_height, route.at(x + dx, DISTANCE + dz).y)
	return Vector3(x, floor_height + 0.23, route.ORIGIN_Z - DISTANCE)

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
	valley.box(c - Vector3.UP * foundation * 0.5, Vector3(width, foundation, depth), "9d8f76", true)
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
		valley.timber(valley.box(c + Vector3(0, 2.49, z), Vector3(2.76, 0.16, 0.24), "89765e", true))
	for z in [-4.7, 0.0, 4.7]:
		var lamp := OmniLight3D.new()
		valley.add_child(lamp)
		lamp.position = c + Vector3(0, 2.55, z)
		lamp.light_color = Color("#fff0d6")
		lamp.omni_range = 8.0
		lamp.light_energy = 0.73
		valley.box(c + Vector3(0, 2.68, z), Vector3(0.48, 0.08, 0.32), "dcc9a4")
	plaque(valley, c + Vector3(0, 2.32, -1.66), "Pueblos comechingones", 0.0, 2.55)
	plaque(valley, c + Vector3(0, 2.49, 1.646), "Relatos del cerro", PI, 2.55)
	plaque(valley, c + Vector3(2.94, 1.47, 1.925), "Memoria comechingona", 0.0, 2.35)
	plaque(valley, c + Vector3(-3.19, 1.47, -1.66), "Vivir en las sierras", 0.0, 2.1)
	valley.box(c + Vector3(3.65, 0.44, -0.76), Vector3(2.3, 0.14, 0.49), "846b50", true, "Banco")
	for x in [2.7, 4.58]:
		valley.box(c + Vector3(x, 0.23, -0.76), Vector3(0.16, 0.46, 0.42), "6d5d51", true)
	for i in 3:
		var x := (i - 1) * 3.30
		vitrine(valley, c + Vector3(x, 0, -4.37), i)
		display_panel(valley, c + Vector3(x, 1.67, -6.85), REPLICAS[i], "comechingones", i, 0.0)
		display_panel(valley, c + Vector3(x, 1.67, 6.85), STORIES[i], "relatos", i, PI)

static func wall(valley, at: Vector3, size_m: Vector3):
	valley.plaster(valley.box(at, size_m, "baaa90", true))

static func build_entrance(valley, c: Vector3):
	var front := c + Vector3(-HALF_WIDTH, 0, 0)
	var route = valley.route
	var start: Vector3 = route.at(route.trail(DISTANCE) + 1.8, DISTANCE)
	var end := front + Vector3(0.12, 0.0, 0)
	start.y -= 0.12
	var span := end - start
	var ramp: MeshInstance3D = valley.box(start.lerp(end, 0.5) - Vector3.UP * 0.09, Vector3(span.length(), 0.18, 2.38), "a38e71", true)
	ramp.rotation.z = atan2(span.y, span.x)
	valley.museum_hinge = Node3D.new()
	valley.add_child(valley.museum_hinge)
	valley.museum_hinge.position = front + Vector3(0, 0, -0.88)
	var leaf: MeshInstance3D = valley.box(front + Vector3(0, 1.14, 0), Vector3(0.12, 2.28, 1.76), "887050", true, "Puerta del museo")
	valley.timber(leaf)
	leaf.reparent(valley.museum_hinge)
	var handle: MeshInstance3D = valley.box(front + Vector3(-0.09, 1.07, 0.64), Vector3(0.13, 0.08, 0.12), "a69a7b")
	handle.reparent(valley.museum_hinge)
	plaque(valley, front + Vector3(-0.14, 2.62, 0), "Sala de las sierras", -PI / 2.0, 2.6)

static func vitrine(valley, c: Vector3, index: int):
	var title: String = REPLICAS[index]
	valley.box(c + Vector3.UP * 0.37, Vector3(1.95, 0.74, 1.08), "74624e", true, title)
	valley.box(c + Vector3.UP * 0.75, Vector3(1.86, 0.035, 0.99), "afa18b")
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
			valley.stone(base + Vector3(-0.17, 0.05, 0.05), Vector3(0.83, 0.20, 0.60), "797166")
			var rim := TorusMesh.new()
			rim.inner_radius = 0.13
			rim.outer_radius = 0.31
			valley.prop(rim, base + Vector3(-0.17, 0.10, 0.05), "8b8172")
			var hand: MeshInstance3D = valley.stone(base + Vector3(0.38, 0.08, 0.06), Vector3(0.36, 0.15, 0.18), "a79b8b")
			hand.rotation.y = -0.40
		1:
			var spindle: MeshInstance3D = valley.box(base + Vector3(0, 0.15, 0), Vector3(0.021, 0.36, 0.027), "88674b")
			spindle.rotation.z = -0.16
			var whorl := TorusMesh.new()
			whorl.inner_radius = 0.023
			whorl.outer_radius = 0.135
			valley.prop(whorl, base + Vector3(0, 0.115, 0), "b18059")
			valley.stone(base + Vector3(0.34, 0.065, 0.11), Vector3(0.34, 0.13, 0.23), "d7c5a0")
		2:
			var pot := ceramic_body()
			valley.prop(pot, base, "b17a55")
			var sherd: MeshInstance3D = valley.box(base + Vector3(0.49, 0.055, 0.15), Vector3(0.2, 0.05, 0.17), "a26547")
			sherd.rotation = Vector3(0.18, 0.58, -0.25)

static func ceramic_body() -> ArrayMesh:
	const PROFILE := [Vector2(0.16, 0.0), Vector2(0.27, 0.08), Vector2(0.30, 0.22), Vector2(0.24, 0.34), Vector2(0.17, 0.41), Vector2(0.19, 0.46), Vector2(0.15, 0.46), Vector2(0.13, 0.39)]
	const SIDES := 24
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in PROFILE:
		for side in SIDES:
			var angle := TAU * side / SIDES
			surface.add_vertex(Vector3(edge.x * cos(angle), edge.y, edge.x * sin(angle)))
	for row in range(PROFILE.size() - 1):
		for side in SIDES:
			var a := row * SIDES + side
			var b := row * SIDES + (side + 1) % SIDES
			for index in [a, a + SIDES, b, b, a + SIDES, b + SIDES]:
				surface.add_index(index)
	surface.generate_normals()
	return surface.commit()

static func dress_archive(valley):
	var c := center(valley)
	var base := c + Vector3(0, 0.83, 3.85)
	valley.box(base - Vector3.UP * 0.42, Vector3(1.75, 0.83, 1.12), "71614c", true, "Maqueta del arco")
	preload("res://estructuras.gd").arch(valley, base, 0.31)
	plaque(valley, base + Vector3(0, -0.14, -0.58), "Maqueta del arco", PI, 1.55)

static func display_panel(valley, center_pos: Vector3, title: String, group: String, index: int, angle: float):
	var frame: MeshInstance3D = valley.box(center_pos, Vector3(0.94, 1.42, 0.055), "766650", true, title)
	frame.rotation.y = angle
	var art_path := "res://museo/" + group + ".webp"
	if ResourceLoader.exists(art_path):
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
		image.pixel_size = 1.33 / atlas.get_height()
		image.shaded = false
	plaque(valley, center_pos + Vector3(0, -0.81, 0), title, angle, 1.95)

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
