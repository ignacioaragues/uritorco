extends Control

const FRONT: = preload("res://postal_munich.webp")
const TRAM: = preload("res://postal_paula.webp")
const TELESCOPE: = preload("res://postal_telescopio.webp")
const CARD_WIDTH: = 800.0
var printed: = SystemFont.new()
var verso: = false
var message_side: = TRAM

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	printed.font_names = PackedStringArray(["Liberation Sans", "DejaVu Sans"])
	resized.connect(queue_redraw)
	hide()

func pick_up(telescope_chosen: bool):
	message_side = TELESCOPE if telescope_chosen else TRAM
	verso = false
	show()
	queue_redraw()

func flip():
	verso = not verso
	queue_redraw()

func _draw():
	var card_size: = Vector2(CARD_WIDTH, CARD_WIDTH * FRONT.get_height() / FRONT.get_width())
	var scale_factor: = minf(size.x / (card_size.x + 88.0), size.y / (card_size.y + 125.0))
	if scale_factor <= 0.0: return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#151817ee"))
	var origin: = (size - card_size * scale_factor) * 0.5 - Vector2(0, 18) * scale_factor
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(Vector2(8, 9), card_size), Color("#0e1010"))
	draw_texture_rect(message_side if verso else FRONT, Rect2(Vector2.ZERO, card_size), false)
	draw_string(printed, Vector2(0, card_size.y + 47.0), "X · dar vuelta     E · volver a colgar", HORIZONTAL_ALIGNMENT_CENTER, CARD_WIDTH, 22, Color("#e9ddc5"))
