extends Control

const PAGE_SIZE: = Vector2(450, 610)
const PAPER: = Color("#d9c6a0")
const INK: = Color("#483b34")
const GOLD: = Color("#bc9461")
var page: = 0
var inscribed: = false
var copied_crux := false
var bookmark: = false
var light_comparison := false
var cover: Texture2D
var signature: Texture2D
var crux_page: Texture2D
const ELVIRA_COVER = preload("res://museo/libro_comechingones.webp")
const ELVIRA_PAPER = preload("res://diario_papel.webp")
const ELVIRA_ENGRAVING = preload("res://museo/grabado_arco.webp")
var elvira := false
const HAND_COPY = preload("res://libro_crux_hernan.webp")
var serif: = SystemFont.new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	serif.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://libro_portada.webp"):
		cover = load("res://libro_portada.webp")
	if ResourceLoader.exists("res://libro_hernan.webp"):
		signature = load("res://libro_hernan.webp")
	if ResourceLoader.exists("res://libro_crux.webp"):
		crux_page = load("res://libro_crux.webp")
	resized.connect(queue_redraw)
	hide()

func open(has_name: bool, has_ribbon: bool, can_compare_lights: bool = false, has_hand_copy: bool = false):
	page = 0
	elvira = false
	inscribed = has_name
	copied_crux = has_hand_copy
	bookmark = has_ribbon
	light_comparison = can_compare_lights
	show()
	queue_redraw()

func open_elvira():
	page = 0
	elvira = true
	show()
	queue_redraw()

func turn(step: int):
	page = clampi(page + step, 0, 2 if elvira else (3 if light_comparison else 2))
	queue_redraw()

func title_at(value: String, y: float, font_size: int, tint: Color):
	draw_string(serif, Vector2(0, y), value, HORIZONTAL_ALIGNMENT_CENTER, PAGE_SIZE.x, font_size, tint)

func _draw():
	var scale_factor: = minf(size.x / 510.0, size.y / 740.0)
	if scale_factor <= 0.0: return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#131818ed"))
	var origin: = (size - PAGE_SIZE * scale_factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(Vector2(7, 10), PAGE_SIZE), Color("#0d0e0d"))
	if elvira:
		if page == 2:
			draw_elvira_text()
		else:
			var illustration: Texture2D = ELVIRA_COVER if page == 0 else ELVIRA_ENGRAVING
			var width := PAGE_SIZE.y * float(illustration.get_width()) / illustration.get_height()
			draw_texture_rect(illustration, Rect2((PAGE_SIZE.x - width) * 0.5, 0, width, PAGE_SIZE.y), false)
		var cues := ["E o clic · abrir   /   Esc · dejar", "← · tapa   /   E o clic · pasar página", "← · grabado   /   E o clic · guardar"]
		title_at(cues[page], 647, 21, Color("#ebdfc5"))
		return
	if page == 0:
		draw_cover()
	else:
		draw_rect(Rect2(Vector2.ZERO, PAGE_SIZE), PAPER)
		draw_rect(Rect2(9, 9, 432, 592), Color("#bba479"), false, 2)
		draw_rect(Rect2(10, 0, 6, 610), Color("#87735455"))
		if page == 1 and inscribed:
			draw_set_transform(origin + Vector2(65, 115) * scale_factor, -0.085, Vector2.ONE * scale_factor)
			if signature:
				var signature_width: = 126.0
				var signature_height: = signature_width * signature.get_height() / signature.get_width()
				draw_texture_rect(signature, Rect2(Vector2.ZERO, Vector2(signature_width, signature_height)), false, Color(1, 1, 1, 0.86))
		elif page == 1 and copied_crux:
			draw_set_transform(origin + Vector2(86, 125) * scale_factor, -0.105, Vector2.ONE * scale_factor)
			var sheet_size := Vector2(290.0, 290.0 * HAND_COPY.get_height() / HAND_COPY.get_width())
			draw_texture_rect(HAND_COPY, Rect2(Vector2(5.5, 8.0), sheet_size), false, Color(0.20, 0.13, 0.08, 0.34))
			draw_texture_rect(HAND_COPY, Rect2(Vector2.ZERO, sheet_size), false)
		elif page >= 2:
			draw_chart()
			if page == 3: draw_light_comparison(origin, scale_factor)
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	var turn_hint: String = ["→ o clic · abrir", "← · tapa     → o clic · Cruz del Sur", "← · guarda", "← · lámina"][page]
	if page == 2 and light_comparison: turn_hint += "     E · comparar el rumbo"
	title_at(turn_hint + "      Esc · guardar", 647, 21, Color("#ebdfc5"))

func draw_elvira_text():
	draw_texture_rect(ELVIRA_PAPER, Rect2(Vector2.ZERO, PAGE_SIZE), false)
	title_at("Pasos de piedra", 92, 31, INK)
	var paragraphs := [
		"El grabado de la página anterior muestra dos piedras altas y una laja tendida sobre ellas. En la sierra se ven pasos parecidos. Algunos parecen obra humana; en otros cuesta distinguir lo puesto a mano de lo que dejó la erosión.",
		"Se ha sugerido que señalaban un paso entre quebradas. Otros lectores ven un umbral ceremonial o un marco desde el que mirar alguna estrella. El dibujo carece de orientación y el sitio quedó sin registrar.",
		"En las historias de la zona vuelve una idea: una misma piedra puede marcar el camino para unos y su final para otros. Es difícil saber quién la contó primero.",
	]
	var y := 143.0
	for paragraph in paragraphs:
		var layout := TextParagraph.new()
		layout.width = 352.0
		layout.add_string(paragraph, serif, 21)
		layout.draw(get_canvas_item(), Vector2(49.0, y), INK)
		y += layout.get_size().y + 24.0
	title_at("48", 568, 18, INK)

func draw_cover():
	if cover:
		draw_texture_rect(cover, Rect2(Vector2.ZERO, PAGE_SIZE), false)
		return
	draw_rect(Rect2(Vector2.ZERO, PAGE_SIZE), Color("#19272f"))
	draw_rect(Rect2(8, 8, 434, 594), GOLD, false, 4)
	draw_rect(Rect2(20, 36, 410, 93), Color("#d4bf94"))
	title_at("OBSERVAR EL CIELO", 95, 35, Color("#624538"))
	var rng: = RandomNumberGenerator.new()
	rng.seed = 30
	for i in range(200):
		draw_circle(Vector2(rng.randf_range(22, 428), rng.randf_range(150, 580)), rng.randf_range(0.45, 2.0), Color("#bac3b4"), true, -1.0, true)
	draw_circle(Vector2(130, 260), 71, Color("#9b7356"), true, -1.0, true)
	for offset in [-35.0, -11.0, 19.0, 40.0]:
		var width: = sqrt(71.0 * 71.0 - offset * offset)
		draw_line(Vector2(132 - width, 260 + offset), Vector2(128 + width, 261 + offset), Color("#b8946d"), 6, true)
	draw_circle(Vector2(265, 406), 83, Color("#c29b60"), true, -1.0, true)
	for i in range(4):
		var ring: = PackedVector2Array()
		for step in range(61):
			var angle: = PI * step / 60.0
			ring.append(Vector2(265, 404) + Vector2(cos(angle) * (149 + i * 5), sin(angle) * (26 + i * 2)).rotated(-0.29))
		draw_polyline(ring, Color("#d9cba8"), 2, true)

func draw_chart():
	if crux_page:
		draw_texture_rect(crux_page, Rect2(Vector2.ZERO, PAGE_SIZE), false)
	if bookmark:
		draw_colored_polygon(PackedVector2Array([Vector2(405, 0), Vector2(425, 0), Vector2(429, 136), Vector2(418, 127), Vector2(409, 138)]), Color("#536952"))

func draw_light_comparison(origin: Vector2, scale_factor: float):
	draw_set_transform(origin + Vector2(36, 263) * scale_factor, -0.055, Vector2.ONE * scale_factor)
	draw_rect(Rect2(4, 6, 378, 263), Color("#43352b70"))
	draw_rect(Rect2(0, 0, 378, 263), Color("#e7d8b0"))
	for y in range(53, 250, 28):
		draw_line(Vector2(18, y), Vector2(356, y), Color("#6d8b951f"), 1.0, true)
	draw_string(serif, Vector2(24, 40), "7 de octubre · Sobre el abra", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)
	draw_polyline(PackedVector2Array([Vector2(28, 134), Vector2(113, 104), Vector2(152, 118), Vector2(224, 88), Vector2(346, 139)]), INK, 2.0, true)
	draw_circle(Vector2(194, 86), 2.6, INK, true, -1.0, true)
	draw_circle(Vector2(237, 67), 2.6, INK, true, -1.0, true)
	draw_string(serif, Vector2(24, 178), "El segundo quedó un poco más alto.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_string(serif, Vector2(24, 206), "La lámina no coincide con el dibujo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_string(serif, Vector2(24, 234), "Si vuelven, anotar la hora.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
