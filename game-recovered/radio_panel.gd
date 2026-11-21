extends PanelContainer

var reveal: Tween
var speaker: = Label.new()
var line: = Label.new()
var options: = Label.new()
var choices = preload("res://choices.gd").new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.045
	anchor_top = 0.955
	anchor_right = 0.72
	anchor_bottom = 0.955
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style: = StyleBoxFlat.new()
	style.bg_color = Color("#182323ed")
	style.border_color = Color("#c3a271")
	style.border_width_left = 3
	style.content_margin_left = 21
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	var stack: = VBoxContainer.new()
	add_child(stack)
	stack.add_theme_constant_override("separation", 4)
	for label in [speaker, line, options]:
		stack.add_child(label)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	stack.add_child(choices)
	speaker.add_theme_color_override("font_color", Color("#e5c287"))
	speaker.add_theme_font_size_override("font_size", 17)
	line.add_theme_font_size_override("font_size", 23)
	options.add_theme_font_size_override("font_size", 17)
	options.add_theme_color_override("font_color", Color("#d5dcd3"))
	hide()

func display(kind: String, caption: String, footer: Variant, mobile := false):
	speaker.text = "RADIO"
	if reveal: reveal.kill()
	line.text = caption
	if kind == "talk":
		var parts := caption.split("\n\n", true, 1)
		speaker.text = parts[0].to_upper() + "   /   RADIO"
		line.text = parts[1]
	line.visible_characters = -1
	if kind == "talk":
		line.visible_characters = 0
		reveal = create_tween()
		reveal.tween_property(line, "visible_characters", line.text.length(), maxf(0.32, line.text.length() / 34.0))
		reveal.tween_callback(func(): line.visible_characters = -1)
	choices.present(footer if footer is Array else [], mobile)
	var show_cursor_help: bool = mobile and footer is Array
	options.visible = footer is String or show_cursor_help
	options.text = "Alt · cursor" if show_cursor_help else (footer if footer is String else "")
	show()
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
