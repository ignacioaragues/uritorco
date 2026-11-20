extends Control

const PAGE_SIZE: = Vector2(450, 610)
const PAPER: = Color("#d9c6a0")
const INK: = Color("#483b34")
const GOLD: = Color("#bc9461")
var page: = 0
var inscribed: = false
var bookmark: = false
var cover: Texture2D
var signature: Texture2D
var crux_page: Texture2D
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

func open(has_name: bool, has_ribbon: bool):
	page = 0
	inscribed = has_name
	bookmark = has_ribbon
	show()
	queue_redraw()

func turn(step: int):
	page = clampi(page + step, 0, 2)
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
		elif page == 2:
			draw_chart()
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	var turn_hint: = ["→ o clic · abrir", "← · tapa     → o clic · Cruz del Sur", "← · guarda"][page] as String
	title_at(turn_hint + "      Esc · guardar", 647, 21, Color("#ebdfc5"))

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
