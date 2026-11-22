extends Control

const FRONT: = preload("res://postal_munich.webp")
const TRAM: = preload("res://postal_paula.webp")
const TELESCOPE: = preload("res://postal_telescopio.webp")
const CARD_WIDTH: = 800.0
var printed: = SystemFont.new()
var verso: = false
var front_image: Texture2D = FRONT
var back_image: Texture2D = TRAM

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	printed.font_names = PackedStringArray(["Liberation Sans", "DejaVu Sans"])
	resized.connect(queue_redraw)
	hide()

func pick_up(telescope_chosen: bool):
	inspect(FRONT, TELESCOPE if telescope_chosen else TRAM)

func inspect(image: Texture2D, reverse: Texture2D = null):
	front_image = image
	back_image = reverse
	verso = false
	show()
	queue_redraw()

func flip():
	if not back_image: return
	verso = not verso
	queue_redraw()

func _draw():
	var card_size: = Vector2(CARD_WIDTH, CARD_WIDTH * front_image.get_height() / front_image.get_width())
	var scale_factor: = minf(size.x / (card_size.x + 88.0), size.y / (card_size.y + 125.0))
	if scale_factor <= 0.0: return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#151817ee"))
	var origin: = (size - card_size * scale_factor) * 0.5 - Vector2(0, 18) * scale_factor
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	var art := back_image if verso else front_image
	draw_texture_rect(art, Rect2(Vector2(8, 9), card_size), false, Color(0.07, 0.06, 0.04, 0.58))
	draw_texture_rect(art, Rect2(Vector2.ZERO, card_size), false)
	var instruction := "X · dar vuelta     E · volver a colgar" if back_image else "E · dejar en el escritorio"
	var font_size := roundi(clampf(22.0 / scale_factor, 22.0, 31.0))
	draw_string(printed, Vector2(0, card_size.y + 49.0), instruction, HORIZONTAL_ALIGNMENT_CENTER, CARD_WIDTH, font_size, Color("#e9ddc5"))
