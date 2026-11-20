extends Control

const PAGE_SIZE := Vector2(820, 510)
const INK := Color("#41352f")
const PAPER_PATH := "res://diario_papel.webp"
const DRAWINGS_PATH := "res://diario_dibujos.webp"
const CREEK := 0
const LIGHTS := 1
const ROPE := 2
const DETOUR := 3
const WINCH := 4
const RIDGE := 5
const BRIDGE := 6
const ARCH := 7

var paper := TextureRect.new()
var drawing := TextureRect.new()
var heading := Label.new()
var body := Label.new()
var footer := Label.new()
var sheet := Control.new()
var drawings: Texture2D

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rect in [paper, drawing]:
		sheet.add_child(rect)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.size = PAGE_SIZE
	paper.texture = load(PAPER_PATH)
	drawing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drawing.position = Vector2(474, 104)
	drawing.size = Vector2(302, 318)
	drawings = load(DRAWINGS_PATH)
	var pen := SystemFont.new()
	pen.font_names = PackedStringArray(["Liberation Serif", "DejaVu Serif"])
	pen.font_italic = true
	for label in [heading, body, footer]:
		sheet.add_child(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", INK)
		label.add_theme_font_override("font", pen)
	heading.position = Vector2(62, 48)
	heading.add_theme_font_size_override("font_size", 34)
	body.position = Vector2(63, 115)
	body.add_theme_font_size_override("font_size", 25)
	body.add_theme_constant_override("line_spacing", 5)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.position = Vector2(63, 451)
	footer.add_theme_font_size_override("font_size", 20)
	resized.connect(fit_page)
	hide()

func fit_page():
	var factor := minf(size.x / (PAGE_SIZE.x + 42.0), size.y / (PAGE_SIZE.y + 40.0))
	sheet.scale = Vector2.ONE * factor
	sheet.position = (size - PAGE_SIZE * factor) * 0.5

func display(entry: Dictionary, index: int, total: int):
	var motif: int = entry.get("drawing", -1)
	var illustrated := motif >= 0 and is_instance_valid(drawings)
	drawing.visible = illustrated
	if illustrated:
		var tile := drawings.get_size() / Vector2(4, 2)
		var region := AtlasTexture.new()
		region.atlas = drawings
		region.region = Rect2(Vector2(motif % 4, floorf(motif / 4.0)) * tile, tile)
		region.filter_clip = true
		drawing.texture = region
	body.size = Vector2(382 if illustrated else 686, 0)
	heading.text = entry.title
	body.text = entry.text
	footer.text = "Tab · guardar"
	if total > 1:
		footer.text = "← / → · hojear (%d/%d)     " % [index + 1, total] + footer.text
	fit_page()
	show()
