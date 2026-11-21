extends RefCounted

const Kit = preload("res://equipo_campo.gd")
const Stone = preload("res://piedra_serrana.gd")
const ID := "piedra_runas"
const TITLE := "Piedra con runas"
const NOTE := "Copié las marcas de una piedra en un recodo de la galería. Algunas parecen runas. En dos surcos había polvo claro. A saber cuánto tiempo llevaba ahí."
const OUTLINE := [
	Vector2(-0.45, -0.13), Vector2(-0.32, -0.26), Vector2(0.12, -0.25),
	Vector2(0.40, -0.18), Vector2(0.45, 0.06), Vector2(0.31, 0.22),
	Vector2(-0.11, 0.26), Vector2(-0.40, 0.16),
]
const STROKES := [
	[Vector2(-0.29, 0.12), Vector2(-0.28, -0.12), Vector2(-0.17, -0.055), Vector2(-0.28, 0.012), Vector2(-0.16, 0.11)],
	[Vector2(-0.03, 0.10), Vector2(0.005, -0.10)],
	[Vector2(-0.09, -0.046), Vector2(0.047, 0.048)],
	[Vector2(0.08, -0.070), Vector2(-0.06, 0.045)],
	[Vector2(0.17, 0.11), Vector2(0.17, -0.093), Vector2(0.288, 0.002), Vector2(0.19, 0.065)],
	[Vector2(0.30, -0.126), Vector2(0.34, -0.063)],
]
const FACE_HEIGHT := 0.153

static var drawing: ImageTexture

static func build(parent: Node3D, foot: Vector3):
	var stone := Kit.item(parent, foot, TITLE, Vector3.UP * 0.069, Vector3(0.99, 0.19, 0.60))
	stone.rotation.y = -0.22
	var surface := Stone.surface()
	for index in OUTLINE.size():
		var a: Vector2 = OUTLINE[index]
		var b: Vector2 = OUTLINE[(index + 1) % OUTLINE.size()]
		var top_a := on_stone(a, FACE_HEIGHT)
		var top_b := on_stone(b, FACE_HEIGHT)
		var base_a := on_stone(a * 1.08, 0.0)
		var base_b := on_stone(b * 1.08, 0.0)
		Stone.triangle(surface, base_a, base_b, top_a, Color.WHITE)
		Stone.triangle(surface, base_b, top_b, top_a, Color.WHITE)
		Stone.triangle(surface, Vector3.UP * FACE_HEIGHT, top_a, top_b, Color.WHITE)
	surface.generate_normals()
	Kit.mesh_part(stone, surface.commit(), Vector3.ZERO, Stone.paint("766b5d"))
	var groove := StandardMaterial3D.new()
	groove.albedo_color = Color("#463d35")
	groove.roughness = 0.96
	for stroke in STROKES:
		for index in range(stroke.size() - 1):
			var from := on_stone(stroke[index], FACE_HEIGHT + 0.001)
			var to := on_stone(stroke[index + 1], FACE_HEIGHT + 0.001)
			var cut := Kit.block(stone, from.lerp(to, 0.5), Vector3(0.010, 0.002, from.distance_to(to)), groove)
			var direction := to - from
			cut.rotation.y = atan2(direction.x, direction.z)
			cut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func on_stone(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x, height, point.y)

static func sketch() -> Texture2D:
	if is_instance_valid(drawing): return drawing
	var outline := sketch_points(OUTLINE)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="360" height="280" viewBox="0 0 360 280">'
	svg += '<g fill="none" stroke="#645e54" stroke-linejoin="round" stroke-linecap="round">'
	svg += '<polygon points="%s" transform="translate(2 15)" fill="#d4d0c8" stroke-width="2.2"/>' % outline
	svg += '<polygon points="%s" fill="#eee9de" stroke-width="2.5"/>' % outline
	svg += '<path d="M56 99l12 -20m-6 25l12 -21m227 104l10 -18m-16 22l10 -17m-45 35l15 -17m-21 20l14 -17M108 200l13 -14m-4 18l11 -13" opacity=".65" stroke-width="1.5"/>'
	for stroke in STROKES:
		svg += '<polyline points="%s" stroke="#49453d" stroke-width="3.3"/>' % sketch_points(stroke)
	svg += '</g></svg>'
	var image := Image.new()
	if image.load_svg_from_string(svg) == OK:
		drawing = ImageTexture.create_from_image(image)
	return drawing

static func sketch_points(points: Array) -> String:
	var pairs := PackedStringArray()
	for point in points:
		var pixel := Vector2(180, 123) + Vector2(point) * Vector2(294, 310)
		pairs.append("%.1f,%.1f" % [pixel.x, pixel.y])
	return " ".join(pairs)
