extends Control

signal begin(slot: int)
signal settings_changed(volume: float, sensitivity: float)

const COVER = preload("res://portada.webp")
var cover: = TextureRect.new()
var panel: = ScrollContainer.new()
var stack: = VBoxContainer.new()
var volume: = 75.0
var sensitivity: = 1.0
var showing_settings: = false
var showing_home := false

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.texture = COVER
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash: = TextureRect.new()
	var gradient: = Gradient.new()
	gradient.colors = PackedColorArray([Color("#152123f8"), Color("#17232ad9"), Color("#16222a00")])
	gradient.offsets = PackedFloat32Array([0, 0.3, 0.86])
	var texture: = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2.RIGHT
	wash.texture = texture
	wash.hide()
	add_child(wash)
	pause_wash = wash
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.anchor_left = 0.31
	panel.anchor_right = 0.69
	panel.anchor_top = 0.55
	panel.anchor_bottom = 0.96
	panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(stack)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 6)
	home()
	panel.modulate.a = 0
	panel.hide()
	var reveal: = create_tween()
	reveal.tween_interval(5.0)
	reveal.tween_callback(panel.show)
	reveal.tween_property(panel, "modulate:a", 1.0, 0.42)

func _input(event):
	if not showing_home or not panel.is_visible_in_tree(): return
	var focused := get_viewport().gui_get_focus_owner()
	if event is InputEventMouseMotion and is_instance_valid(focused) and focused.get_parent() == stack:
		focused.release_focus()
	elif event is InputEventKey and event.pressed and not event.echo and not focused and event.keycode in [KEY_TAB, KEY_UP, KEY_DOWN]:
		stack.get_child(0).grab_focus()
		get_viewport().set_input_as_handled()

func clear():
	showing_home = false
	for child in stack.get_children():
		stack.remove_child(child)
		child.queue_free()

func heading(text: String, size: int):
	var label: = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var serif: = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	label.add_theme_font_override("font", serif)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f6ead8"))
	stack.add_child(label)

func action(text: String, callback: Callable) -> Button:
	var button: = Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", Color("#f5e4d2"))
	button.add_theme_color_override("font_outline_color", Color("#191923"))
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_hover_color", Color("#ffd99e"))
	button.add_theme_color_override("font_focus_color", Color("#ffd99e"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	stack.add_child(button)
	button.pressed.connect(callback)
	return button

func home():
	clear()
	showing_home = true
	action("Nuevo juego", func(): slots(true))
	action("Cargar partida", func(): slots(false))
	action("Ajustes", settings)
	action("Salir", func(): get_tree().quit())
	action("Elegir escena", debug_login)

func slider(title: String, low: float, high: float, step: float, current: float, setter: Callable):
	var label: = Label.new()
	stack.add_child(label)
	label.text = title + "   " + str(current)
	var control: = HSlider.new()
	control.min_value = low
	control.max_value = high
	control.step = step
	control.value = current
	stack.add_child(control)
	control.value_changed.connect( func(v):
		setter.call(v)
		label.text = title + "   " + str(v)
		settings_changed.emit(volume, sensitivity))

func settings():
	showing_settings = true
	clear()
	heading("Ajustes", 52)
	slider("Volumen (%)", 0, 100, 5, volume, func(v): volume = v)
	slider("Sensibilidad del mouse", 0.5, 2, 0.1, sensitivity, func(v): sensitivity = v)
	action("Volver", close_settings).grab_focus()

func close_settings():
	showing_settings = false
	if in_game: pause_menu()
	else: home()

const Saves = preload("res://partidas.gd")
signal load_requested(slot: int, automatic: bool)
signal save_requested
signal resume_requested
var in_game: = false
var pause_wash: TextureRect
signal debug_requested(code: String)

func pause_menu(status: String = ""):
	in_game = true
	cover.hide()
	pause_wash.show()
	panel.show()
	panel.modulate.a = 1
	panel.anchor_top = 0.15
	clear()
	show()
	heading("Pausa", 54)
	if status: heading(status, 18)
	action("Seguir jugando", func(): resume_requested.emit())
	action("Guardar partida", func(): save_requested.emit())
	action("Cargar partida", func(): slots(false))
	action("Ajustes", settings)
	action("Menú principal", func(): get_tree().reload_current_scene())

func slots(new_game: bool):
	clear()
	heading("Nueva partida" if new_game else "Cargar partida", 42)
	var gap: = Control.new()
	gap.custom_minimum_size.y = 14
	stack.add_child(gap)
	for i in range(1, Saves.COUNT + 1):
		var auto_data = Saves.read(i, true)
		var manual = Saves.read(i, false)
		var prefix = "Ranura %d" % i
		if new_game:
			var taken = not auto_data.is_empty() or not manual.is_empty()
			action(prefix + (" · En uso" if taken else " · Libre"), func():
				if taken: confirm_new(i)
				else: begin.emit(i))
		else:
			for automatic in [false, true]:
				var data: Dictionary = auto_data if automatic else manual
				if data.is_empty(): continue
				action("%d · %s · %s" % [i, "Auto" if automatic else "Manual", data.title], func(): load_requested.emit(i, automatic))
			if manual.is_empty() and auto_data.is_empty(): action(prefix + " · Vacía", func(): pass).disabled = true
	action("Volver", func():
		if in_game: pause_menu()
		else: home())
	for child in stack.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func confirm_new(slot: int):
	clear()
	heading("Ranura %d" % slot, 42)
	heading("¿Reemplazar esta partida?", 22)
	action("Volver", func(): slots(true))
	action("Reemplazar y empezar", func(): begin.emit(slot))

func debug_login():
	clear()
	heading("Elegir escena", 34)
	var input: = LineEdit.new()
	input.secret = true
	input.placeholder_text = "Contraseña"
	stack.add_child(input)
	var submit: = func():
		if input.text == "6hw35g": debug_scenes()
		else:
			input.clear()
			input.placeholder_text = "Contraseña incorrecta"
			input.grab_focus()
	input.text_submitted.connect( func(_value): submit.call())
	action("Entrar", submit)
	action("Volver", home)
	input.grab_focus()

func debug_scenes():
	clear()
	for chapter in [["intro", "Prólogo · Ruta"], ["arrival", "Noche 1 · Puesto"], ["2", "Día 2 · El arroyo"], ["7", "Día 7 · Alcance"], ["sighting", "Día 7 · Avistamiento"], ["dream7", "Noche 7 · Primer sueño"], ["25", "Día 25 · La quebrada"], ["dream25", "Noche 25 · La pieza"], ["27", "Día 27 · La cantera"], ["32", "Día 32 · La cumbre"], ["camp", "Día 32 · Campamento"], ["36", "Día 36 · La pasarela"], ["ultima_noche", "Última noche · Luces"], ["cueva", "Última noche · Cueva"], ["dream36", "Última noche · Los arcos"], ["41", "Día 41 · Museo"]]:
		action(chapter[1], func(): debug_requested.emit(chapter[0]))
	action("Volver", home)
