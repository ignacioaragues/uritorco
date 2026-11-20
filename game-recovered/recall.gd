extends Control

signal selected(index: int)
var fade: Tween
var lines: Array
var options: Array
var paragraph: = 0
var complete: = false
var text: = Label.new()
var cue: = Label.new()
var choices = preload("res://choices.gd").new()

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(text)
	text.anchor_left = 0.19
	text.anchor_right = 0.81
	text.anchor_top = 0.25
	text.anchor_bottom = 0.53
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 25)
	text.add_theme_constant_override("line_spacing", 6)
	text.add_theme_color_override("font_color", Color("#ece6da"))
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cue)
	cue.anchor_left = 0.19
	cue.anchor_top = 0.62
	cue.text = "Clic para seguir"
	cue.add_theme_font_size_override("font_size", 16)
	cue.add_theme_color_override("font_color", Color("#b5a68f"))
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(choices)
	choices.anchor_left = 0.19
	choices.anchor_right = 0.81
	choices.anchor_top = 0.6
	choices.selected.connect( func(i): selected.emit(i))
	hide()

func present(passages: Array, captions: Array, start: int = 0):
	lines = passages
	options = captions
	paragraph = clampi(start, 0, lines.size() - 1)
	show()
	show_paragraph()

func show_paragraph():
	if fade: fade.kill()
	complete = false
	choices.hide()
	cue.hide()
	var passage: = str(lines[paragraph])
	var last: = passage.rfind(" ")
	text.text = passage.erase(last, 1).insert(last, " ") if last >= 0 else passage
	text.modulate.a = 0.0
	fade = create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property(text, "modulate:a", 1.0, 1.5)
	fade.tween_interval(2.4)
	fade.tween_callback(finish)

func finish():
	text.modulate.a = 1.0
	complete = true
	if paragraph == lines.size() - 1:
		choices.present(options.map( func(option): return option.label))
	else: cue.show()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		if complete and paragraph < lines.size() - 1:
			paragraph += 1
			show_paragraph()
