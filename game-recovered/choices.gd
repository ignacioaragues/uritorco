extends VBoxContainer

signal selected(index: int)

func _ready():
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func present(captions: Array):
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for index in captions.size():
		var button: = Button.new()
		button.text = captions[index]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 19)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style: = StyleBoxFlat.new()
			style.bg_color = Color("#201c17") if state != "normal" else Color("#100f0d")
			style.border_color = Color("#edc387") if state != "normal" else Color("#79674d")
			style.border_width_left = 2
			style.content_margin_left = 14
			style.content_margin_right = 14
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", Color("#e1d6c3"))
		button.add_theme_color_override("font_hover_color", Color("#ffe4b7"))
		button.pressed.connect( func(): selected.emit(index))
		add_child(button)
	visible = not captions.is_empty()
