extends Node3D

const Arrival = preload("res://llegada.gd")
const Museum = preload("res://museo.gd")
const Climate = preload("res://clima.gd")
const Alien = preload("res://hallazgos_sueno.gd")
const Trail = preload("res://travesia.gd")
const South = preload("res://quebrada_sur.gd")
const Creek = preload("res://cauce.gd")
const Cable = preload("res://camino_del_cable.gd")
const SkyGuide = preload("res://constelacion.gd")
const LastNight = preload("res://final_night.gd")
const Departure = preload("res://salida.gd")
const Coach = preload("res://omnibus.gd")
const ReturnTerrain = preload("res://regreso_noche.gd")
const CaveRunes = preload("res://piedra_cueva.gd")
const Saves = preload("res://partidas.gd")
const Mara = preload("res://charlas_mara.gd")
const Exploration = preload("res://exploracion.gd")
const Diary = preload("res://diario.gd")
const Refuge = preload("res://refugio.gd")
const INTRO_LOOK_AMOUNT := 0.14
const SUMMIT_NIGHT_SECONDS := 330.0
const SUMMIT_DUSK_SECONDS := 115.0
const RIDGE_NIGHT_SECONDS := 155.0
const QUARRY_NIGHT_SECONDS := 105.0
const SIGHTING_FOCUS_SECONDS := 0.4
const NIGHT_SCENE_VIEW := 200.0
const DREAM_SECONDS := 150.0
const WALK_SCORE := {
	2: ["calma1", "domestic"],
	7: ["domestic", "quietud"],
	25: ["domestic", "calma1"],
	27: ["domestic", "quietud"],
	32: ["calma2", "domestic"],
	36: ["quietud", "calma2"],
	40: ["noche", "quietud"],
	41: ["calma1", "domestic"],
}
const WALK_SCORE_DELAY := 5.0
const WALK_SCORE_GAP := 6.0
const CREEK_RETURN_SECONDS := 180.0
const ABRA_NIGHT_SECONDS := 44.0
const DAY40_SECONDS := 300.0
const WELCOME_REPLIES := ["Sí, te copio.", "Sí. Recién llego."]
const DAY2_SLEEP_REPLIES := ["Dormí de un tirón.", "Todavía me estoy acostumbrando al puesto."]
const DAY2_READY_REPLIES := ["Sí, estoy listo.", "Dale. Decime por dónde empiezo."]
const CREEK_REPORT_REPLIES := ["Medí cero centímetros.", "¿Viste la mica que hay en el cruce? Cambia toda la piedra si te agachás."]
const MAST_REPLIES := ["Sí, te copio. Se fue la estática.", "Te copio, aunque se te come el final de algunas palabras."]
const QUARRY_REPLIES := ["La chapa sigue quieta. Estoy al lado del bastidor.", "Te paso el rumbo que acabo de anotar. Lo marqué desde el malacate."]
const NIGHT_REPLIES := ["Se van al monte y las voy a seguir.", "Las dejo ir. Se van al monte. Me voy a acostar."]
const DREAM_ARCH_EXCHANGES := [
	[["Voz", "¿La ves?"], ["Hernán", "¿Cuál?"], ["Voz", "La que tarda más en aparecer. Quedate quieto un segundo."]],
	[["Hernán", "¿Me hablás por la radio?"], ["Voz", "Probá apagarla."], ["Hernán", "Ya está apagada."], ["Voz", "¿Me oís igual?"]],
	[["Hernán", "Veo dos discos. ¿Cuál tengo que mirar?"], ["Voz", "El huequito entre las cuatro estrellas."], ["Voz", "Como cuando tapábamos el farol en la vereda."]],
]
enum Sighting { ABRA, QUARRY, CROSSING, SHELTER }
const Natural = preload("res://naturaleza.gd")
const STATE = ["page", "stage", "keepsakes", "bedtime", "field_note", "crossing_note", "filo_report_reply", "quarry_reply", "fox_seen", "hiker_met", "route_reported", "observing", "pending_return", "heard", "radio_taken", "bag_left", "creek_note", "bed_pose", "bed_pitch", "gate_jumped", "map_read", "awaiting_call", "dream_count", "branch_found", "mapped_distance", "has_piece", "summit_mapped", "camp_read", "arrival_action", "intro_bridge_drawn", "second_sighting", "book_light_notes", "day7_dusk", "trail_replies", "crossing_response", "summit_echo_response", "night_investigation", "last_night", "night_home", "ending_at_door", "sky_memories", "compass_lost", "last_voice_reply", "found_collectibles", "nature_notes"]
var flashlight_out: = false
var camp_read: = false
var camp_reported := false
var camp_observations: Dictionary = {}
var summit_mapped: = false
var has_piece: = false
var dream_piece: Node3D
var dream_piece_height := 0.0
var dream_piece_phase := 0.0
var dream_world: Node3D
var paula_clipping_read := false
var trail_replies: Dictionary = {}
var mara_heard_paula := false
var trail_topic := ""
var trail_answer := 0
var trail_spacing_day := -1
var trail_walk_left := 0.0
var trail_quiet_left := 0.0
var ending_paragraphs: PackedStringArray = []
var ending_paragraph := 0
var ending_fade: Tween
var flag_raised := false
var door_side := 0
var door_crossed := false
var mate_call_left := 0.0
var mate_called := false
var mate_receiver: AudioStreamPlayer3D
var crossing_response: = -1
var summit_echo_response := -1
const CROSSING_NOTES = [
	"Al retroceder, oí mi propia voz. Mara también la oyó.",
	"Apagué la linterna. Vi una figura quieta del otro lado de la pasarela.",
	"Alumbré el cauce. Por un instante vi lo que parecía una mano agarrada al travesaño."
]
var night_investigation: = 0
var last_night := false
var day40_seconds_left := -1.0
var day40_interlude_done := false
var night_home := 0 # 1 al llegar, 2 después de hablar por radio.
var ending_at_door: = false
var packed_items: Array = []
var departure_destination := ""
var departure_path_open := false
var departure_briefed := false
var departure_call_wait := 1.5
var elvira_book_taken := false
var elvira_book: StaticBody3D
var departure_scene := ""
var mara_yard: Node3D
var cave: Node3D
var return_terrain: Node3D
var return_heading := Vector3.ZERO
var return_last_position := Vector3.ZERO
var return_walk_seconds := 0.0
var return_foot := LastNight.RETURN_START
var cave_static_seconds := 0.0
var cave_notebook_page := 0
var camp_notebook_page := 0
var valley_view_distance: float
var cave_checkpoint: = LastNight.ENTRY
var cave_notebooks_read: = false
var cave_exit_open: = false
var tunnel_call_step := 0
var crux_found: = false
var cave_outside := false
var cave_entry_clear := false
var cave_station_called := false
var cave_rope_cut := false
var cave_rope_reply_pending := false
var cave_rope_in_use := false
var compass_lost: = false
var spare_compass_taken := false
var fossil_sketched := false
var last_voice_reply: = -1
var sky_memories: Array = []
const CAVE_NOTEBOOK := [
	{"title": "14/10/1975", "text": "Puesto de observación · turno noche\n\n01.40. Cortó la niebla. Probamos el receptor hacia el abra. En la planilla dejamos tres columnas: hora, rumbo y respuesta.\n\nEl otro equipo salió con el trípode."},
	{"title": "09/11/1975", "text": "03.11. Dos luces al sudoeste. La de abajo cruzó la silueta de la sierra y volvió por el mismo lugar. No se oyó motor.\n\nEn la casilla de identificación, alguien escribió «U.F.O.» y encerró el rumbo en un círculo."},
	{"title": "17/02/1976", "text": "Repetimos la observación desde la cueva y desde el filo. Acordamos anotar las luces antes de hablar para no copiar el rumbo del otro.\n\n02.16. Los dos equipos apuntaron al mismo sector. El receptor dio dos golpes secos."},
	{"title": "21/09/1976", "text": "02.08. En el canal 3 se oyó «no cruces todavía». El segundo equipo tenía la radio apagada.\n\nLa última columna quedó en blanco."},
]
const CAMP_NOTEBOOK := [
	{"title": "Bitácora del campamento", "text": "Hora, rumbo y respuesta\n\n22.41. Luz abajo de la muesca. Camioneta en el camino.\n\n22.43. Otra luz arriba de la muesca.\n\nEn la última columna del segundo renglón hay una raya."},
	{"title": "La muesca", "text": "La flecha empieza junto a las pircas. Abajo, al lado del camino, alguien anotó «camioneta». La otra luz está marcada arriba de la muesca.",
		"sketch": preload("res://croquis_campamento.webp")},
]
const SKY_MEMORIES = {
	2: "Te quedás quieto. Tu papá decía que había que darle tiempo a los ojos. Contás hasta diez. Entre dos estrellas aparece otra, más débil.",
	7: "En la vereda tu papá te tapaba el farol con la mano. Primero te hacía buscar las dos del eje largo. La primera vez que marcaste el sur te pidió que le explicaras cómo, como si él también estuviera aprendiendo.",
	25: "Encontrás las dos del eje largo. Si las prolongás hacia el sur, la mirada te cae donde la ladera baja. Te sale decirle que ya la encontraste. Esperás un rato con la vista en el mismo lugar.",
	27: "Apoyás el pulgar en el canto del cuaderno. Tu papá se quedaba un rato en la vereda después de que vos entrabas. Dejaba la silla afuera hasta la mañana. Hoy entendés por qué a veces volvía a sacarla aunque estuviera nublado.",
	32: "Esta vez encontrás la cruz aunque la ladera te tape una parte del cielo. Marcás el sur entre dos piedras. Después guardás la brújula y te quedás un momento más."
}
var walk_score_day := 0
var walk_score_wait := WALK_SCORE_DELAY
var walk_score_turn := 0
var score = preload("res://banda_sonora.gd").new()
var book_view = preload("res://libro.gd").new()
var postcard_view = preload("res://postal.gd").new()
var held_desk_paper: StaticBody3D
var rain_strength := 0.0
var storm_return_seconds := 0.0
var mist_strength := 0.0
var rain_view := CPUParticles3D.new()
var rain_material := ShaderMaterial.new()
var underwater_view := ColorRect.new()
var immersion := 0.0
var branch_found: = false
var mapped_distance: = 0.0
var radio_hint: = Label.new()
var sighting: Sighting
var sighting_time := 0.0
var sighting_focus := 0.0
var sighting_resolving := false
var book_light_notes := false
var dream_count: = 0
var dream_seconds_left := DREAM_SECONDS
var dream_symbols_found := false
const DREAM_RUINS_SECONDS := 105.0
var dream_arch_visits: Array[int] = []
var dream_arch_lines: Array = []
var dream_pulse_wait := 0.0
var compass_out: = false
var ambience = preload("res://ambiente.gd").new()
var awaiting_call: = false
var slot: = 1
var paused_from: = ""
var gate_jumped: = false
var map_read: = false
var objective_seconds := 0.0
var intro_controls_seconds := 0.0
var intro_look_amount := 0.0
var intro_look_done := false
var intro_objectives_seen := false
var map = preload("res://plano.gd").new()
var map_goal_origin := Vector3.INF
var menu = preload("res://menu.gd").new()
var valley = preload("res://valley.gd").new()
var player = preload("res://player.gd").new()
var radio = preload("res://radio.gd").new()
var radio_panel = preload("res://radio_panel.gd").new()
var hands = preload("res://hands.gd").new()
var shade: = ColorRect.new()
var words: = Label.new()
var hint: = Label.new()
var cross: = Label.new()
var memories: Array = JSON.parse_string(FileAccess.get_file_as_string("res://prologo.json"))
var keepsakes: = {}
var choosing: = false
var overlay_choices = preload("res://choices.gd").new()
var recall = preload("res://recall.gd").new()
var second_sighting := false # Guardados anteriores usan esta clave para el avistamiento del abra.
var abra_told_mara := false
var day7_dusk: = false
var debug_run: = false
var arrival_action: = false
var intro_bridge_drawn := false
var intro_journal_seen := false
var radio_taken := false
var bag_left := false
const FIRST_CALL_DELAY := 5.0
const FIRST_CALL_INTERVAL := 6.3
var first_call_wait := 0.0
var first_call_repeat := 0.0
var first_call_caption := 0.0
var bedtime: = false
var creek_return_left := -1.0
var creek_evening_call := false
var field_note: = ""
var crossing_note := ""
var filo_report_reply := -1
var quarry_reply := -1
var journal_pages: Array[Dictionary] = []
var journal_view := Diary.new()
var journal_page := 0
var journal_section := Diary.Section.DIARY
var journal_from := ""
var collect_notice := ""
var collect_notice_seconds := 0.0
var found_collectibles: Dictionary = {}
var nature_notes: Dictionary = {}
var fox_seen: = false
var hiker_met: = false
var route_reported: = false
var bed_pose: = Transform3D.IDENTITY
var bed_pitch: = 0.0
var observing: = false
var pending_return: = false
var page: = 0
var mode: = "menu"
var stage: = -1
var heard: = false
var sequence: Array = []
var radio_answers: Array = []
var sentence_boundary := RegEx.create_from_string("(?<=[.!?…])\\s+")
var after: = ""
var target: = ""
var creek_note: = ""

func place(label: Label, rect: Rect2):
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.anchor_left = rect.position.x
	label.anchor_top = rect.position.y
	label.anchor_right = rect.end.x
	label.anchor_bottom = rect.end.y
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("outline_size", 4)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(valley)
	add_child(player)
	valley_view_distance = player.camera.far
	add_child(radio)
	add_child(score)
	add_child(ambience)
	player.footfall.connect(play_footfall)
	player.position = Vector3(valley.path_x(-26), 0.04, -26)
	player.rotation.y = PI
	setup_rain()
	var ui: = CanvasLayer.new()
	add_child(ui)
	ui.add_child(underwater_view)
	underwater_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	underwater_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var water_overlay := ShaderMaterial.new()
	water_overlay.shader = preload("res://bajo_agua.gdshader")
	underwater_view.material = water_overlay
	underwater_view.hide()
	ui.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color.BLACK
	ui.add_child(hands)
	ui.add_child(words)
	place(words, Rect2(0.1, 0.1, 0.8, 0.65))
	words.add_theme_font_size_override("font_size", 25)
	ui.add_child(hint)
	place(hint, Rect2(0.06, 0.82, 0.88, 0.15))
	hint.add_theme_font_size_override("font_size", 18)
	ui.add_child(overlay_choices)
	overlay_choices.anchor_left = 0.2
	overlay_choices.anchor_right = 0.8
	overlay_choices.anchor_top = 0.72
	overlay_choices.selected.connect(select_option)
	radio_panel.choices.selected.connect(select_option)
	recall.selected.connect(select_option)
	recall.continued.connect(next_memory)
	ui.add_child(recall)
	ui.add_child(radio_panel)
	ui.add_child(radio_hint)
	radio_hint.anchor_left = 0.045
	radio_hint.anchor_top = 0.88
	radio_hint.text = "R   ·   Mara"
	radio_hint.add_theme_font_size_override("font_size", 16)
	radio_hint.add_theme_color_override("font_color", Color("#e2d3b9"))
	radio_hint.add_theme_constant_override("outline_size", 3)
	radio_hint.hide()
	ui.add_child(cross)
	place(cross, Rect2(0.48, 0.48, 0.04, 0.04))
	cross.text = "·"
	cross.hide()
	shade.hide()
	var vista: = Camera3D.new()
	add_child(vista)
	vista.position = Vector3(11, 6, 10)
	vista.look_at(Vector3(-2, 2, -40))
	vista.current = true
	hands.mount_map(map)
	Arrival.build(valley)
	Arrival.build_fragments(valley)
	ui.add_child(book_view)
	ui.add_child(postcard_view)
	ui.add_child(journal_view)
	journal_view.section_requested.connect(toggle_journal_section)
	journal_view.nature_requested.connect(toggle_nature_section)
	ui.add_child(menu)
	menu.settings_changed.connect( func(volume, sensitivity):
		AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
		player.look_speed = 0.002 * sensitivity)
	menu.begin.connect(start_game)
	menu.debug_requested.connect(debug_scene)
	menu.resume_requested.connect(resume_play)
	menu.save_requested.connect( func():
		menu.pause_menu("Partida guardada" if save_game(false, paused_from) else "No se pudo guardar"))
	menu.load_requested.connect( func(n, auto):
		var data: Dictionary = Saves.read(n, auto)
		if data.is_empty(): return
		Saves.pending = data
		get_tree().reload_current_scene())
	if not Saves.pending.is_empty():
		var data = Saves.pending
		Saves.pending = {}
		restore.call_deferred(data)

func start_game(n: int):
	slot = n
	menu.hide()
	score.cue("prologo", -12.0, 2.6, true)
	player.camera.current = true
	approach(true)
	if save_game(true, "approach"):
		var manual = Saves.path(slot, false)
		if FileAccess.file_exists(manual): DirAccess.remove_absolute(manual)
	shade.color = Color.BLACK
	shade.show()
	var fade = create_tween()
	fade.tween_property(shade, "color:a", 0.0, 1.5)
	fade.tween_callback( func():
		if mode == "approach": shade.hide())

func approach(reset_position: bool = false):
	walk()
	mode = "approach"
	valley.restore_light(Arrival.DUSK[page], Arrival.DARK[page])
	Arrival.show_fragment(valley, page)
	var center: = Arrival.origin(page)
	if reset_position or player.position.distance_to(center) > 80:
		player.position = Arrival.spawn_point(page)
		player.rotation = Vector3(0, Arrival.spawn_heading(page), 0)
		player.camera.rotation = Vector3.ZERO
		player.velocity = Vector3.ZERO
		arrival_action = false
		objective_seconds = 0.0
		intro_controls_seconds = 0.0
		if page == 0:
			intro_look_amount = 0.0
			intro_look_done = false
			intro_objectives_seen = false
		if page == 6: flashlight_out = false
	if page == 0:
		set_arrival_bag_visible(not arrival_action)
		player.walking = arrival_action
		player.looking_only = not arrival_action
	player.intro_center = center
	player.intro_heading = Arrival.HEADINGS[page]
	hint.text = stop_control_hint() if page == 0 and not arrival_action else ""

func stop_control_hint() -> String:
	if intro_objectives_seen: return "E · recogé tu mochila"
	if intro_look_done: return "F1 · ver los objetivos"
	return "Mouse · mirar"

func use_arrival_item():
	if arrival_action or target != Arrival.ACTIONS[page] or page in [1, 2, 3, 4, 6, 7]: return
	if page == 0 and not intro_objectives_seen: return
	if page == 5:
		player.climb_rope(Arrival.rope_route(), Arrival.HEADINGS[page])
		return
	arrival_action = true
	if page == 0:
		set_arrival_bag_visible(false)
		player.walking = true
		player.looking_only = false
		intro_controls_seconds = 4.0
		hint.text = "WASD · moverte"
		save_game(true, "approach")
	else:
		hint.text = ""

func set_arrival_bag_visible(shown: bool):
	valley.arrival_bag.visible = shown
	valley.arrival_bag.collision_layer = 1 if shown else 0

func _input(event: InputEvent):
	if mode == "elvira_book" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		advance_elvira_book()
		return
	if event is InputEventMouseMotion and mode == "approach" and page == 0 and not arrival_action and not intro_look_done and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		intro_look_amount += event.relative.length() * player.look_speed
		intro_look_done = intro_look_amount >= INTRO_LOOK_AMOUNT
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mode == "walk" and pack_item(target):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and radio_panel.visible and radio_panel.choices.visible:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			get_viewport().set_input_as_handled()
			radio_panel.choices.step_highlight(1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			radio_panel.choices.confirm_highlight()
		return
	if not event is InputEventKey: return
	if mode == "intro" and event.keycode == KEY_TAB and event.pressed and not event.echo:
		_unhandled_key_input(event)
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if mode == "book" and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: turn_book(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT: turn_book(-1)
		return
	if mode == "approach" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		use_arrival_item()

func fade_to_memory():
	mode = "approach_fade"
	cross.hide()
	hint.text = ""
	shade.z_index = 2
	var filter := shade.mouse_filter
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0, 0, 0, 0)
	shade.show()
	var fade := create_tween()
	fade.tween_property(shade, "color:a", 1.0, 1.35).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(func():
		shade.z_index = 0
		shade.mouse_filter = filter
		memory())

func memory(paragraph: int = 0):
	Arrival.show_fragment(valley, -1)
	hands.hide()
	hands.hold("")
	hands.show_map(false)
	compass_out = false
	mode = "intro"
	player.walking = false
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cross.hide()
	shade.color = Color.BLACK
	shade.show()
	words.text = ""
	hint.text = ""
	var entry: Dictionary = memories[page]
	if entry.get("show_response", false) and keepsakes.has(entry.key):
		choosing = false
		recall.present([keepsakes[entry.key]], [])
		return
	choosing = entry.has("options")
	var lines: Array = entry.lines.duplicate()
	recall.present(lines, entry.get("options", []), paragraph)

func next_memory():
	page += 1
	if page < memories.size():
		approach(true)
	else:
		player.intro_center = Vector3.ZERO
		player.position = Vector3( - 0.45, 0.1, -9)
		player.rotation.y = PI
		player.camera.rotation = Vector3.ZERO
		walk()
		hint.text = "E · abrir la puerta"

func calendar_day() -> int:
	if stage < 1: return 1
	if stage < 6: return 2
	if stage < 8: return 7
	if stage < 10: return 25
	if stage < 13: return 27
	if stage < 16: return 32
	if stage < 19: return 40 if last_night else 36
	return 41

func _physics_process(delta: float):
	if mode == "cave" and cave_outside and crux_found:
		advance_return_walk(delta, player.is_on_floor())
	if trail_walk_left <= 0.0 or trail_spacing_day != calendar_day() or mode not in ["walk", "map"]:
		return
	if not player.is_on_floor() or not player.climb_points.is_empty(): return
	var step: Vector3 = player.get_position_delta()
	trail_walk_left = maxf(0.0, trail_walk_left - Vector2(step.x, step.z).length())

func _process(delta):
	objective_seconds = maxf(0.0, objective_seconds - delta)
	intro_controls_seconds = maxf(0.0, intro_controls_seconds - delta)
	collect_notice_seconds = maxf(0.0, collect_notice_seconds - delta)
	var day: = calendar_day()
	if trail_spacing_day == day and mode in ["walk", "map"]:
		trail_quiet_left = maxf(0.0, trail_quiet_left - delta)
	var in_museum := Museum.under_roof(valley, player.position)
	if not in_museum and Museum.night_closed(valley) and valley.museum_hinge.get_meta("open", false):
		valley.swing_side_door(valley.museum_hinge)
	var in_refuge: bool = absf(player.position.x) < 3.45 and player.position.z > -0.35 and player.position.z < 5.9
	update_creek_return(delta)
	update_day40(delta)
	if stage == 19 and not departure_briefed and departure_call_wait > 0.0 and mode in ["walk", "map"]:
		departure_call_wait = maxf(0.0, departure_call_wait - delta)
		if departure_call_wait == 0.0:
			radio.incoming.play()
			objective_seconds = 4.5
	update_departure()
	valley.update_calendar(day)
	valley.route.set_detour_deadfall(day == 25)
	update_weather(day, delta, in_museum)
	update_water(delta)
	valley.shade_ridges()
	if mode not in ["mate_morning", "mate_radio"]:
		valley.update_desk_radio(radio_taken or (in_refuge and hands.pose == "radio"))
	if stage >= 1 and not flag_raised:
		flag_raised = true
		valley.set_flag(true)
	if stage >= 0 and mode in ["walk", "map", "mate_morning", "mate_radio"]:
		update_refuge_door()
	if mode in ["mate_morning", "mate_radio"]:
		update_mate_morning(delta, in_refuge)
	valley.set_desk_note(stage <= 0 and held_desk_paper != valley.desk_note)
	valley.update_spare_compass(stage == 19, spare_compass_taken)
	valley.update_shelter_details(day, trail_replies.get("piedras", -1) == 0, trail_replies.get("bajada", -1) == 1)
	if stage >= 0:
		if day >= 7 and intro_bridge_drawn: valley.hang_sketch(0, Diary.ARRIVAL_BRIDGE)
		if day >= 7 and not creek_note.is_empty(): valley.hang_sketch(1, Diary.WALL_ATLAS, Diary.CREEK)
		if day >= 25 and second_sighting: valley.hang_sketch(2, Diary.WALL_ATLAS, Diary.LIGHTS)
		if day >= 36 and camp_read: valley.hang_sketch(3, Diary.WALL_ATLAS, Diary.RIDGE)
	var darkness := float(valley.sky_mat.get_shader_parameter("nightfall"))
	var outside_world: bool = player.intro_center == Vector3.ZERO and (mode in ["walk", "map"] or (radio_panel.visible and player.walking))
	valley.nature.advance(delta, day, player.position, darkness, rain_strength, outside_world, nature_notes)
	if not nature_notes.is_empty() and in_refuge:
		valley.nature.next_day_sketches(valley, nature_notes, day)
	var hand_tone := Color.WHITE.lerp(Color("#727c8e") if not in_refuge else Color("#b4a392"), darkness)
	if is_instance_valid(cave) and not cave_outside: hand_tone = Color("#6c6b69") if flashlight_out else Color("#45444c")
	if hands.requested_pose == "piece" and mode in ["dream_arch_talk", "last_voice", "last_voice_answer", "waking"]:
		hand_tone.a *= 1.0 - shade.color.a
	hands.modulate = hand_tone
	var radio_active: bool = radio_panel.visible or radio.interference.playing
	score.radio_active = radio_active
	var near_cave: bool = is_instance_valid(cave) and player.position.distance_squared_to(ambience.cave_air.position) < 39.0 * 39.0
	ambience.mix_cave_air(delta, near_cave, radio_active)
	if mode in ["walk", "map"]: score_daily_walk(day, delta, in_museum)
	if mode == "sighting": update_sighting(delta)
	if mode == "cave":
		if cave_static_seconds > 0.0:
			cave_static_seconds = maxf(0.0, cave_static_seconds - delta)
			if cave_static_seconds == 0.0 and hands.requested_pose == "radio": hands.hold("")
		update_cave()
	elif is_instance_valid(cave) and radio_panel.visible and player.walking:
		update_cave(false)
	elif mode in ["mara_door", "departure_bus"]:
		update_night_target()
		if mode == "mara_door":
			hint.text = "E · golpear la puerta" if target == "Puerta de Mara" else ""
		else:
			hint.text = "E · abrir la puerta del ómnibus" if target == "Puerta del ómnibus" else ""
	update_flashlight()
	if mode == "dream" and (dream_variant() == 1 or (dream_variant() == 2 and dream_symbols_found)):
		dream_seconds_left = maxf(0.0, dream_seconds_left - delta)
		if dream_seconds_left == 0.0:
			finish_dream()
	if mode == "dream":
		hint.text = "????" if looking_at_dream_sky() else ""
		if is_instance_valid(dream_piece) and not has_piece:
			dream_piece_phase += delta
			dream_piece.position.y = dream_piece_height + sin(dream_piece_phase * 1.26) * 0.12
			dream_piece.get_node("Artefacto").rotation.y += delta * 0.38
			if near_dream_piece(): hint.text = "E · recoger el artefacto"
			elif objective_seconds > 0.0 and hint.text.is_empty(): hint.text = "Acercate al brillo."
		elif has_piece:
			if dream_variant() == 3:
				update_dream_arch(delta)
				if mode != "dream": return

		var find := aimed_collectible()
		if collect_notice_seconds > 0.0:
			hint.text = collect_notice
		elif Alien.FINDS.has(find):
			hint.text = "E · " + str(Alien.FINDS[find][1])
		elif dream_plate_in_sight():
			hint.text = "E · copiar los símbolos"
		elif hands.map_requested:
			hint.text = "M · guardar la hoja"
	radio_hint.visible = mode in ["walk", "map"] and radio_available()
	if radio_hint.visible:
		radio_hint.text = "R   ·   Charlá con Mara" if not at_departure_stop() and not night_patio_ready() and not mission_radio_available() else "R   ·   Mara"
	if mode in ["walk", "map"] and stage == 8 and not awaiting_call and crossing_note.is_empty():
		record_filo_route()
	if mode in ["walk", "map"] and stage >= 10 and not branch_found:
		if player.position.distance_to(valley.route.at(valley.route.trail(300), 300)) < 22:
			branch_found = true
	if mode in ["approach", "walk", "dream", "map", "sighting", "cave", "mara_door", "departure_bus"] or (radio_panel.visible and player.walking):
		var velocity: = Vector2(player.velocity.x, player.velocity.z).length() if player.is_on_floor() else 0.0
		var outdoors: bool = not in_museum and (player.position.z < 0 or absf(player.position.x) > 3.5)
		if hands.requested_pose == "compass":
			var look: Vector3 = -player.camera.global_basis.z
			hands.set_bearing(atan2(look.x, -look.z))
		hands.step(delta, velocity)
		if mode == "map" or (mode == "dream" and hands.map_requested):
			if mode == "map" and paused_from == "walk" and stage == 15:
				if player.position.distance_squared_to(map_goal_origin) > 6.25:
					refresh_map_goal()
			map.track(player.position)
		var daytime: bool = mode != "dream" and outdoors and rain_strength < 0.44 and float(valley.sky_mat.get_shader_parameter("nightfall")) < 0.5
		ambience.update_birds(delta, player.position, daytime and immersion < 0.05)
		if stage == 7 and day7_dusk and not second_sighting and mode in ["walk", "map"] and darkness > 0.71:
			show_sighting()
			return
	if mode in ["approach", "walk", "cave"] and not player.climb_points.is_empty():
		hint.text = ("S · bajar de espaldas" if player.rope_descending else "W · trepar con la cuerda") if player.rope_climbing else ""
		return

	if mode == "approach":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		var local: = Arrival.local_position(page, player.position)
		if page == 2: note_intro_bridge(local)
		if page == 1 and local.z < -10.43 and local.y > Arrival.surface_point(1, local).y + 0.29 and absf(local.x) < 1.70:
			arrival_action = true
		if page == 5 and not player.rope_climbing and local.y >= Arrival.LEDGE_TOP - 0.04 and local.z < -10.76:
			arrival_action = true
		var walked_out: bool = Arrival.left_fragment(local, page) and (page > 0 or arrival_action)
		if walked_out or ((arrival_action or page in [2, 3, 7]) and Arrival.reached_exit(page, local)):
			fade_to_memory()
			return
		if objective_seconds > 0.0:
			hint.text = intro_objective()
		elif page == 0 and not arrival_action:
			hint.text = stop_control_hint()
		elif page == 0 and intro_controls_seconds > 0.0:
			hint.text = "WASD · moverte"
		elif page == 3 and not intro_journal_seen:
			hint.text = "Tab · mirá el croquis del puente" if intro_bridge_drawn else "Tab · abrí el diario"
		elif page == 6 and not arrival_action:
			hint.text = "L · encendé la linterna"
		elif not arrival_action and page == 1 and local.z < -5.2:
			hint.text = "Espacio · saltar el tronco"
		elif not arrival_action and page in [2, 4]:
			hint.text = "B · probar la brújula" if page == 2 else "M · consultar el mapa"
		elif not arrival_action and not target.is_empty() and target == Arrival.ACTIONS[page]:
			hint.text = "E o clic · " + target
		else:
			hint.text = ""
	elif mode == "walk":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		if target == "Cortinas" and not in_refuge:
			target = ""
		if target == "Izar la bandera" and stage != 0:
			target = ""
		if stage == -1 and player.position.z < 0 and target == "":
			hint.text = "E · interactuar al mirar la puerta"
			return

		if stage == -1 and player.position.z > 0 and abs(player.position.x) < 3.4 and player.position.z < 5.9:
			if score.playing_cue == "prologo": score.silence(3.2)
			begin_refuge_night()
			return
		if stage == 0 and not heard and update_first_call(delta, in_refuge):
			return
		if collect_notice_seconds > 0.0:
			hint.text = collect_notice
			return
		if at_summit_finish():
			hint.text = "E · cerrar la travesía"
			return
		if objective_seconds > 0.0:
			hint.text = objective()
			return
		if target == "Cortinas":
			hint.text = curtain_hint()
			return
		var subject := aimed_nature()
		if not subject.is_empty():
			hint.text = "E · dibujar " + Natural.ENTRIES[subject][0].to_lower()
			return
		if stage == 0 and target == "Radio" and not radio_taken:
			hint.text = "E · levantar la radio"
			return
		if stage == 0 and heard and not bag_left and target in ["Cama", "Dejar la mochila"]:
			hint.text = "E · dejar la mochila al lado de la cama"
			return
		if not hit and ( - player.camera.global_basis.z).y > 0.12 and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6:
			var star := SkyGuide.identify(-player.camera.global_basis.z, valley.sky_chapter, day, valley.moon_direction, paula_clipping_read)
			if can_pause_under_sky():
				if watching_crux_tonight() and not looking_at_crux():
					hint.text = star if not star.is_empty() else "Buscá las dos estrellas del eje largo de la Cruz del Sur."
				else:
					hint.text = "E · ubicar el sur" if watching_crux_tonight() else "E · quedarte a mirar el cielo"
				return
			hint.text = star
		elif target in ["Puerta", "Puerta del baño", "Tranquera", "Puerta del museo", "Heladera", "Freezer", "Cajón izquierdo", "Cajón derecho", "Gabinete de ollas", "Gabinete de tazas", "Gabinete de limpieza"]:
			hint.text = "E"
		elif target == "Piedra de Mara" and not fossil_sketched:
			hint.text = "E · bocetar el fósil"
		elif stage >= 0 and hit and hit.has_meta("find_id"):
			hint.text = "E · recoger " + target.to_lower()
		elif stage >= 0 and target in ["", "Subir al escalón"] and not player.ledge_route().is_empty():
			hint.text = "E · trepar el saliente"
		else:
			hint.text = "Acercate al escalón" if target == "Subir al escalón" else ("E · " + target if target != "" else "")

func setup_rain():
	rain_view.emitting = false
	rain_view.local_coords = false
	rain_view.amount = 1550
	rain_view.lifetime = 1.45
	rain_view.lifetime_randomness = 0.18
	rain_view.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_view.emission_box_extents = Vector3(15.0, 3.0, 15.0)
	rain_view.visibility_aabb = AABB(Vector3(-19.0, -28.0, -19.0), Vector3(38.0, 34.0, 38.0))
	rain_view.direction = Vector3.DOWN
	rain_view.spread = 2.0
	rain_view.gravity = Vector3(0.0, -3.7, 0.0)
	rain_view.initial_velocity_min = 9.0
	rain_view.initial_velocity_max = 13.0
	rain_view.scale_amount_min = 0.72
	rain_view.scale_amount_max = 1.25
	rain_view.particle_flag_align_y = true
	rain_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drop := CylinderMesh.new()
	drop.top_radius = 0.010
	drop.bottom_radius = 0.0025
	drop.height = 0.31
	drop.radial_segments = 3
	drop.rings = 0
	rain_view.mesh = drop
	rain_material.shader = preload("res://lluvia.gdshader")
	rain_material.set_shader_parameter("museum_center", Museum.center(valley) + Vector3.UP * Museum.HEIGHT * 0.5)
	rain_material.set_shader_parameter("museum_half_extents", Vector3(Museum.HALF_WIDTH, Museum.HEIGHT * 0.5 + 0.10, Museum.HALF_DEPTH))
	rain_view.material_override = rain_material
	add_child(rain_view)

func update_weather(day: int, delta: float, in_museum: bool):
	var position: Vector3 = player.position
	if stage == 18 and mode in ["walk", "map"] and player.intro_center == Vector3.ZERO:
		storm_return_seconds = minf(Climate.STORM_CLEAR_SECONDS, storm_return_seconds + delta)
	var target_rain := Climate.rain(stage, position, storm_return_seconds)
	var target_mist := Climate.local_mist(day, position)
	if stage in [16, 17] and valley.weather_day != 36:
		rain_strength = target_rain
	rain_strength = move_toward(rain_strength, target_rain, delta * (0.095 if target_rain > rain_strength else 0.075))
	mist_strength = move_toward(mist_strength, target_mist, delta * 0.0013)
	valley.update_weather(day, rain_strength, mist_strength)
	var outside := position.z < -0.5 or absf(position.x) > 3.45 or position.z > 5.97
	var shows_world: bool = stage >= 0 and player.intro_center == Vector3.ZERO and (mode in ["walk", "map", "sighting", "mara_door", "message", "rest", "journal", "pause_menu"] or radio_panel.visible)
	var rain_active: bool = shows_world and rain_strength > 0.025
	rain_view.visible = rain_active
	rain_view.emitting = rain_active
	if rain_active:
		var wind := Climate.wind(day, position, rain_strength)
		var gust := 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.0019)
		rain_view.position = position + Vector3(0.0, 10.2, 0.0) + Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.30
		rain_view.direction = Vector3(wind * gust * 0.28, -1.0, 0.04 + wind * 0.12).normalized()
		rain_material.set_shader_parameter("intensity", rain_strength)
	ambience.weather(delta, rain_strength if shows_world else 0.0, shows_world and (not outside or in_museum), radio_panel.visible, day == 36)

func play_footfall(surface: StringName, impact: float):
	if mode not in ["approach", "walk", "map", "cave", "sighting", "dream", "mara_door", "departure_bus"]: return
	var foot: Vector3 = player.position
	if player.water_depth > 0.07:
		surface = &"water"
	elif player.intro_center == LastNight.CAVE and not cave_outside:
		surface = &"cave"
	elif surface == &"":
		surface = &"soil"
		if player.intro_center == Vector3.ZERO:
			if absf(foot.x) < 3.38 and foot.z > -0.32 and foot.z < 5.88 and foot.y < 0.15:
				surface = &"wood"
			elif rain_strength > 0.15 or stage in [16, 17, 18]:
				surface = &"mud"
	ambience.play_footstep(surface, impact)

func update_water(delta: float):
	var depth := 0.0
	var eye_depth := 0.0
	if stage < 0 and page == 2 and mode in ["approach", "map", "journal", "pause_menu"]:
		depth = Arrival.bridge_depth(player.position)
		eye_depth = Arrival.bridge_depth(player.camera.global_position)
	elif stage in [16, 17, 18] and is_instance_valid(valley.storm_water) and valley.storm_water.visible:
		depth = South.water_depth(player.position)
		eye_depth = South.water_depth(player.camera.global_position)
	player.water_depth = depth
	var target := smoothstep(0.007, 0.12, eye_depth)
	immersion = move_toward(immersion, target, delta * 7.5)
	underwater_view.visible = immersion > 0.002
	if underwater_view.visible: underwater_view.material.set_shader_parameter("submerged", immersion)

func record_filo_route():
	var route = valley.route
	var distance: float = route.ORIGIN_Z - player.position.z
	if distance >= 159.0 and distance <= 186.0 and absf(player.position.x - route.detour(distance)) < 6.0:
		crossing_note = "La vaguada rodea la laja y vuelve a la huella del filo."
	elif distance > 170.75 and distance < 174.5:
		var landing: Vector3 = route.surface_point(route.trail(170) - 0.64, 171.02)
		if player.position.distance_to(landing) < 4.0:
			crossing_note = "En la laja, el escalón de piedra se puede salvar con la cuerda."

func note_intro_bridge(local: Vector3):
	if intro_bridge_drawn or local.z > -15.1 or absf(local.x) > 2.2 or not player.is_on_floor(): return
	intro_bridge_drawn = true

func intro_objective() -> String:
	if page == 0:
		return "Seguí el camino de tierra al costado de la parada." if arrival_action else "Acercate a la parada y recogé la mochila."
	if page == 7 or arrival_action:
		return "Seguí la curva del sendero." if page >= 6 else "Caminá un poco más por la senda."
	return ["", "Espacio · saltá el tronco.", "Cruzá el puente. B · probá la brújula.", "Seguí la curva. Tab · mirá el croquis.", "M · consultá el mapa.", "E · agarrá la cuerda. Mantené W para trepar.", "L · encendé la linterna."][page]

func score_daily_walk(day: int, delta: float, in_museum: bool):
	if day != walk_score_day:
		walk_score_day = day
		walk_score_wait = WALK_SCORE_DELAY
		walk_score_turn = 0
	if awaiting_call or stage < 1 or in_museum or score.is_playing(): return
	var here: Vector3 = player.position
	if absf(here.x) < 12.0 and here.z > -15.0 and here.z < 12.0: return
	if walk_score_turn == 0 and (not player.is_on_floor() or Vector2(player.velocity.x, player.velocity.z).length_squared() < 0.36):
		return
	walk_score_wait -= delta
	if walk_score_wait > 0.0: return
	var themes: Array = WALK_SCORE[day]
	var dark := float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.65
	var sunset := float(valley.sky_mat.get_shader_parameter("dusk")) > 0.52
	var theme: String = "noche" if dark else ("quietud" if sunset else themes[walk_score_turn % themes.size()])
	score.cue(theme, -14.0, 3.0)
	walk_score_turn += 1
	walk_score_wait = WALK_SCORE_GAP

func at_summit_finish() -> bool:
	return stage == 15 and absf(player.position.x) < 9.0 and player.position.z > -11.0 and player.position.z < 7.0

func objective() -> String:
	if not player.climb_points.is_empty(): return "Buscás apoyo en la piedra."
	if stage == 0:
		if not radio_taken: return "Levantá la radio del escritorio."
		if not heard: return "Esperá a que Mara pruebe el canal."
		return "Acercate a la cama." if bag_left else "Dejá la mochila en el suelo, al lado de la cama."
	if awaiting_call: return "R · Escuchá a Mara en la radio."
	if stage == 5:
		if creek_return_left < 0.0 and not bedtime: return "R · Pasale a Mara la lectura del cauce."
		var at := Vector2(player.position.x, player.position.z)
		if absf(at.x) > 10.0 or at.y < -13.0 or at.y > 10.0: return "Volvé al puesto por la huella del poste."
		if not bedtime: return "Ya pasaste la lectura. Te queda un rato de luz."
	if stage == 9 and route_reported and player.position.z < -14.0:
		var distance: float = valley.route.ORIGIN_Z - player.position.z
		if distance > Museum.DISTANCE: return "Desandá la huella del filo hasta pasar el museo."
		if distance >= valley.route.LAJA_FORK: return "Bajá por la cuerda o rodeá la laja por la vaguada."
		return "Seguí la huella principal hasta el puesto."
	if stage == 12 and player.position.z < -20.0: return "Volvé junto al cable y seguí el sendero oeste hasta la tranquera."
	if stage == 18 and night_home == 1: return "R · Avisale a Mara que llegaste."
	if stage == 18 and not last_night and night_home == 0 and (player.position.z < -14.0 or player.position.z > 9.0 or absf(player.position.x) > 10.0):
		return "Volvé por las pircas. En el cruce podés volver por la loma o bajar al poste para tomar la huella del puesto."
	if stage == 15 and not (bedtime and player.position.z > -12.0):
		return "Volvé al puesto por las pircas del acceso."
	if night_patio_ready(): return "R · Llamá a Mara desde el patio del puesto."
	if bedtime: return "Cuando quieras terminar el día, acercate a la cama y tocá E."
	if pending_return: return "Volvé a pie al puesto y usá la radio junto a la entrada."
	if stage == 10: return "Tomá el sendero oeste al salir de la tranquera. Al encontrar el cable, seguilo hasta el malacate."
	if stage == 11: return "R · Consultá a Mara por el reflejo."
	if stage == 13:
		if not camp_read: return "Buscá a los turistas por el sendero del este. En el acceso, seguí las pircas."
		if not camp_reported: return "R · Avisale a Mara qué encontraste en el campamento."
		return "Seguí las pircas hasta el último hito del filo."
	if stage == 16:
		if player.position.x > -36.0 and player.position.z < 19.0:
			return "Salí por la tranquera. Pasá por la loma de las lajas y seguí la huella de la quebrada sur."
		return "Seguí las pircas aguas abajo hasta la pasarela."
	if stage == 17: return "R · Pasale la marca del agua a Mara."
	if stage == 18: return "Te queda la tarde libre. Podés dar una vuelta." if last_night and day40_seconds_left > 0.0 else "Volvé a dormir al puesto."
	if stage == 19:
		if not departure_briefed: return "R · Escuchá a Mara antes de empacar."
		if packed_items.size() < Departure.PACK_ITEMS.size():
			var missing := PackedStringArray()
			for i in Departure.PACK_NAMES.size():
				if not packed_items.has(i): missing.append(Departure.PACK_NAMES[i])
			return "Terminá de empacar: " + ", ".join(missing) + "."
		if not elvira_book_taken: return "Subí al museo. Elvira dejó un libro en el banco de adentro."
		if departure_destination == "mara": return "Al final de la bajada, tomá el camino vecinal a la izquierda."
		if departure_destination == "bus": return "Seguí bajando por la huella hasta la ruta."
		if departure_destination == "fork": return "En la bifurcación, a la izquierda está la casa de Mara y a la derecha, la parada." if can_visit_mara() else "Seguí bajando hasta la ruta."
		if at_departure_stop(): return "R · Llamá a Mara desde la bajada."
		return "Tomá la bajada a la ruta fuera de la tranquera."
	if stage == 14: return "R · Pasale a Mara lo que ves desde el filo del este."
	if stage == 8: return "Día 25 · Compará la subida con cuerda y la vuelta por la vaguada. Llegá al hito del filo."
	if stage == 9: return "R · Pasá el parte del filo." if not route_reported else "Volvé al puesto."
	if stage == -1: return "Abrí la puerta con E y entrá al puesto."
	if stage == 7:
		if observing: return "R · Probá la recepción con Mara desde la antena."
		if day7_dusk and not second_sighting: return "Quedate cerca del abra mientras cae la luz."
		return "Seguí la huella principal, pasá el museo y probá la recepción al pie de la antena."
	return ["Noche 1 · R · Contestar la radio", "Salí por la tranquera y tomá la bajada del cauce hasta el poste.", "R · Pasale a Mara la fecha", "Seguí la bajada del cauce.", "Seguí bajando hasta el lecho de piedras y buscá la regla.", "Volvé al puesto por la misma huella.", "Día 7 · Escuchá el parte de Mara.", "Pasá el museo de sitio y probá la recepción en el abra."][stage]

func overlay(kind: String, caption: String, footer: Variant, prop: String = ""):
	overlay_choices.hide()
	mode = kind
	player.looking_only = false
	cross.hide()
	shade.show()
	if kind in ["talk", "choice", "report", "signal", "dusk", "reception"]:
		prop = "radio"
	var mobile := prop == "radio" and kind != "bench"
	player.walking = mobile
	player.looking_only = prop == "radio" and not mobile
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE if prop == "radio" else Control.MOUSE_FILTER_STOP
	if prop != "radio": hands.show_map(false)
	if not (hands.requested_pose == "piece" and kind in ["dream_arch_talk", "last_voice", "last_voice_answer", "waking"]) and not (kind == "talk" and after == "cave_rope"):
		hands.hold(prop)
	shade.color = Color(0.03, 0.045, 0.06, 0.07 if prop == "radio" else (0.48 if prop else 0.87))
	if prop == "radio":
		radio_panel.display(kind, caption, footer, kind == "choice" and stage == 0 and not heard)
		words.text = ""
		hint.text = ""
	else:
		radio_panel.hide()
		words.text = caption
		words.visible_ratio = 1
		hint.text = footer if footer is String else ""
		if footer is Array: overlay_choices.present(footer)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if prop == "radio" else Input.MOUSE_MODE_VISIBLE

func open_journal():
	journal_section = Diary.Section.DIARY
	journal_page = 0
	if page == 3 and journal_from == "approach": intro_journal_seen = true
	if journal_from in ["approach", "intro"]:
		recall.hide()
		journal_pages = [bridge_diary_entry() if intro_bridge_drawn or page > 2 else {
			"title": "Camino al puesto", "text": "Dejé una hoja libre para anotar lo que vaya viendo."}]
		show_journal_page()
		return
	journal_pages = []
	if intro_bridge_drawn or page > 2: journal_pages.append(bridge_diary_entry())
	add_diary_entries()
	add_field_notes()
	if journal_pages.is_empty():
		journal_pages.append({"title": "Cuaderno", "text": ""})
	journal_pages.reverse()
	show_journal_page()

func bridge_diary_entry() -> Dictionary:
	return {"title": "Camino al puesto", "text": "Las tablas cedían un poco al pisarlas. Del otro lado, la huella seguía entre los pastos.",
		"sketch": Diary.ARRIVAL_BRIDGE}

func diary_entry(title: String, text: String, drawing: int = -1):
	journal_pages.append({"title": title, "text": text, "drawing": drawing})

func add_diary_entries():
	if not creek_note.is_empty():
		diary_entry("2 de octubre · El cauce", creek_note, Diary.CREEK)
	if fossil_sketched:
		journal_pages.append({"title": "La piedra de Mara", "text": "Una ramita entre dos capas de piedra. Las nervaduras se ven al girarla debajo de la lámpara.", "sketch": preload("res://boceto_fosil.webp")})
	if second_sighting or stage >= 8:
		var entry := "Sobre el abra vi dos puntos. El segundo quedó un poco más alto. Por la radio alcancé a oír «…cruces…»."
		if book_light_notes: entry += "\n\nBusqué el rumbo en el libro de mi viejo. Dejé el croquis entre las páginas."
		diary_entry("7 de octubre · Dos luces", entry, Diary.LIGHTS)
	if stage >= 8 and (not crossing_note.is_empty() or stage >= 9):
		var via := "El rodeo de la vaguada empalma con la huella del filo." if "vaguada" in crossing_note else "El escalón de laja se puede pasar con la cuerda."
		var drawing := Diary.DETOUR if "vaguada" in crossing_note else Diary.ROPE
		if crossing_note.is_empty():
			via = "Desde el filo vi juntarse las dos huellas. La piedra del cartel queda más abajo."
			drawing = -1
		if filo_report_reply == 0: via += "\n\nLe pedí a Mara que les marque el rodeo a los que van con herramientas."
		elif filo_report_reply == 1: via += "\n\nLe dije a Mara que pasen de a uno por el escalón."
		diary_entry("25 de octubre · El filo", via, drawing)
	if quarry_reply >= 0 or stage >= 12:
		var entry := "Giré la chapa del malacate. La segunda luz apareció arriba del corte, con la chapa quieta."
		if quarry_reply == 1: entry += "\n\nAnoté la hora y el rumbo para compararlos desde otro punto."
		elif quarry_reply == 0: entry += "\n\nLe avisé a Mara. Entre el ruido se oyó «todavía»."
		diary_entry("27 de octubre · El malacate", entry, Diary.WINCH)
	if camp_read:
		var entry := "En el cuaderno del campamento quedaron dos apuntes. El de la camioneta a las 22.41. Dos minutos después, otra luz arriba de la muesca."
		if summit_echo_response >= 0: entry += "\n\nAl bajar oí «hasta el acceso». La voz se parecía a la mía."
		diary_entry("1 de noviembre · El filo del este", entry, Diary.RIDGE)
	if crossing_response >= 0:
		diary_entry("5 de noviembre · La pasarela", "El agua dejó pasto en el travesaño de abajo. Marqué la altura con carbón.\n\n" + CROSSING_NOTES[crossing_response], Diary.BRIDGE)
	if stage >= 19 and last_voice_reply >= 0:
		var entry := "Cerré las cortinas. Al abrir los ojos, vi un disco con anillos y otro más chico del otro lado del arco."
		if night_investigation == 3: entry = "En el claro hubo un destello. Después, el arco. Hay un pedazo que no puedo dibujar."
		elif night_investigation >= 2: entry = "Vi una raya de luz al sur. Me acuerdo de la puerta del puesto, pero no de todo lo que hay en el medio."
		entry += "\n\nPregunté si era mi viejo." if last_voice_reply == 1 else "\n\nPregunté quién era."
		entry += " La voz dijo: «Mirá una más»."
		diary_entry("10 de noviembre · El arco", entry, Diary.ARCH)

func add_field_notes():
	var notes := field_note.strip_edges().split(". ", false)
	var leaf := ""
	for index in notes.size():
		var note := notes[index] + ("." if index < notes.size() - 1 else "")
		if not leaf.is_empty() and leaf.length() + note.length() > 320:
			diary_entry("Cuaderno · Apuntes sueltos", leaf)
			leaf = ""
		leaf += ("" if leaf.is_empty() else "\n\n") + note
	if not leaf.is_empty(): diary_entry("Cuaderno · Apuntes sueltos", leaf)

func aimed_collectible() -> String:
	var hit = player.ray.get_collider()
	return str(hit.get_meta("find_id", "")) if hit else ""

func record_collectible(id: String):
	var in_dream := Alien.FINDS.has(id)
	var entry: Array = Alien.FINDS[id] if in_dream else Exploration.FINDS[id]
	if found_collectibles.has(id): return
	found_collectibles[id] = calendar_day()
	if id == Exploration.CAMP_BAND: remember_camp_observation("pulsera")
	remove_collected_objects()
	collect_notice = str(entry[1]) + " · C para ver Coleccionables"
	collect_notice_seconds = 4.0
	save_game(true, "dream" if in_dream else "walk")

func record_cave_runes():
	if found_collectibles.has(CaveRunes.ID): return
	found_collectibles[CaveRunes.ID] = calendar_day()
	collect_notice = "Signos copiados · C para ver Coleccionables"
	collect_notice_seconds = 4.0
	if debug_run: return
	# La última noche tiene un autoguardado en el puesto, antes de partir.
	var checkpoint := Saves.read(slot, true)
	if not checkpoint.is_empty() and checkpoint.state.get("stage") == 18:
		checkpoint.state["found_collectibles"] = found_collectibles.duplicate()
		Saves.write(slot, true, checkpoint)

func remove_collected_objects():
	for object in get_tree().get_nodes_in_group("field_finds"):
		if found_collectibles.has(object.get_meta("find_id")):
			object.hide()
			object.queue_free()

func toggle_journal_section():
	if journal_from in ["approach", "intro"]: return
	if journal_section == Diary.Section.COLLECTION:
		open_journal()
		return
	journal_section = Diary.Section.COLLECTION
	journal_page = 0
	var total := Exploration.FINDS.size() + Alien.FINDS.size() + 1
	var introduction := "%d de %d anotados.\n\nHallazgos del cerro y de los sueños." % [found_collectibles.size(), total]
	if not found_collectibles.is_empty():
		introduction += " Pasá la hoja para ver los dibujos y las notas."
	journal_pages = [{"title": "Coleccionables", "text": introduction}]
	var discoveries := found_collectibles.keys()
	discoveries.reverse()
	for id in discoveries:
		if id == CaveRunes.ID:
			journal_pages.append({"title": CaveRunes.TITLE, "text": "Última noche · Cueva\n\n" + CaveRunes.NOTE, "sketch": CaveRunes.sketch()})
			continue
		var dream := Alien.FINDS.has(id)
		var entry: Array = Alien.FINDS.get(id, []) if dream else Exploration.FINDS.get(id, [])
		if entry.is_empty(): continue
		var place := "Sueño %d" % entry[4] if dream else "Día %d" % found_collectibles[id]
		var note := {"title": entry[1], "text": place + " · " + entry[3], "drawing": entry[0], "dream": dream}
		if not dream and Exploration.SKETCHES.has(id): note["sketch"] = Exploration.SKETCHES[id]
		journal_pages.append(note)
	show_journal_page()

func aimed_nature() -> String:
	if stage <= 0 or stage >= 19 or not target.is_empty(): return ""
	return valley.nature.aimed(player.camera, player, nature_notes)

func record_nature(id: String):
	if nature_notes.has(id): return
	nature_notes[id] = calendar_day()
	collect_notice = Natural.ENTRIES[id][0] + " · Anotado en Flora y fauna (N)"
	collect_notice_seconds = 4.0
	hint.text = collect_notice
	save_game(true, "walk")

func toggle_nature_section():
	if journal_from in ["approach", "intro"]: return
	if journal_section == Diary.Section.NATURE:
		open_journal()
		return
	journal_section = Diary.Section.NATURE
	journal_page = 0
	var description := "Mirá un ejemplar y apretá E cuando aparezca «dibujar»."
	if not nature_notes.is_empty():
		description = "Dibujos y notas que fui tomando en las caminatas."
	description += "\n\nCerca del puesto, buscá flores amarillas y mirá las ramas bajas al tomar la huella del cauce. En la bajada hay cortaderas y se asoman animales entre las piedras."
	journal_pages = [{"title": "Flora y fauna", "text": description}]
	var observations := nature_notes.keys()
	observations.reverse()
	for id in observations:
		if not Natural.ENTRIES.has(id): continue
		var entry: Array = Natural.ENTRIES[id]
		journal_pages.append({"title": entry[0], "text": "Día %d\n\n%s" % [nature_notes[id], entry[1]],
			"sketch": load(Natural.SKETCHES[id])})
	show_journal_page()

func show_journal_page():
	overlay("journal", "", "")
	journal_view.display(journal_pages[journal_page], journal_page, journal_pages.size(), journal_section, journal_from not in ["approach", "intro"])

func walk():
	journal_view.hide()
	hands.show()
	player.set_physics_process(true)
	player.looking_only = false
	compass_out = false
	overlay_choices.hide()
	recall.hide()
	radio_panel.hide()
	hands.hold("radio" if stage == 0 and radio_taken and not heard else "")
	mode = "map" if hands.map_requested else "walk"
	words.text = ""
	shade.hide()
	cross.visible = mode == "walk"
	if mode == "map":
		hint.text = "M · guardar el mapa"
		refresh_map_goal()
		map.track(player.position)
	player.walking = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func conversation(lines: Array, next: String):
	if next != "last_call":
		trail_spacing_day = calendar_day()
		trail_walk_left = Mara.distance_between_calls(trail_spacing_day)
		trail_quiet_left = Mara.seconds_between_calls(trail_spacing_day)
	sequence = lines.duplicate()
	after = next
	speak()

func speak():
	radio.play()
	var cue := "Espacio · seguir   /   Esc · volver" if after == "last_call" else "Espacio · seguir"
	var line: Variant = sequence.pop_front()
	var speech := "Mara\n\n" + str(line)
	if line is Dictionary: speech = str(line.speaker) + "\n\n" + str(line.text)
	overlay("talk", speech, cue)
	if after == "night_patio" and sequence.is_empty(): place_last_night_lights()
	if line is Dictionary and line.speaker == "Hernán": hands.press_button()

func hernan(line: String) -> Dictionary:
	return {"speaker": "Hernán", "text": line}

func reply_sentences(line: String) -> PackedStringArray:
	return sentence_boundary.sub(line, "\n", true).split("\n", false)

func radio_choices(kind: String, caption: String, answers: Array):
	radio_answers = answers.duplicate()
	var previews: Array[String] = []
	for line: String in radio_answers:
		var sentences := reply_sentences(line)
		var lead := sentences[0]
		if sentences.size() > 1 and (lead.length() <= 7 or lead in ["Te copio.", "Ya estoy.", "Estoy bien."]):
			lead = sentences[1]
		previews.append(lead)
	overlay(kind, caption, previews, "radio")

func chosen_reply(index: int) -> Array:
	var lines: Array = []
	for sentence in reply_sentences(radio_answers[index]):
		lines.append(hernan(sentence))
	return lines

func radio_available() -> bool:
	if stage == 0 and not heard: return radio_taken and first_call_wait <= 0.0
	return at_departure_stop() or night_patio_ready() or mission_radio_available() or not available_trail_chat().is_empty()

func update_creek_return(delta: float):
	if stage != 5 or creek_return_left <= 0.0: return
	if mode not in ["walk", "map"] and not (player.walking and radio_panel.visible): return
	creek_return_left = maxf(0.0, creek_return_left - delta)
	var sunset_progress := 1.0 - creek_return_left / CREEK_RETURN_SECONDS
	valley.set_sun_phase(smoothstep(0.0, 0.77, sunset_progress), smoothstep(0.27, 1.0, sunset_progress))
	if creek_return_left == 0.0:
		bedtime = true
		objective_seconds = 4.0
		if mode in ["walk", "map"]: save_game(true, "walk")

func creek_evening_available() -> bool:
	var at: Vector3 = player.position
	return stage == 5 and bedtime and not creek_evening_call and absf(at.x) < 10.0 and at.z > -13.0 and at.z < 10.0

func at_departure_stop() -> bool:
	if stage != 19 or departure_scene != "" or not elvira_book_taken or departure_destination != "": return false
	var at: Vector3 = player.position
	return at.z >= 17.0 and at.z <= 69.0 and Departure.edge_distance(Vector2(at.x, at.z)) < 8.0

func night_patio_ready() -> bool:
	var at: Vector3 = player.position
	return stage == 18 and not last_night and bedtime and absf(at.x) < 8.5 and at.z > -11.5 and at.z < -1.15

func remember_camp_observation(item: String):
	if stage in [13, 14] and not camp_observations.has(item):
		camp_observations[item] = false
		save_game(true, "walk")

func next_camp_report() -> String:
	if stage not in [13, 14]: return ""
	if camp_read and not camp_reported: return "camp_report"
	for item: String in camp_observations:
		if not camp_observations[item]: return item
	return ""

func call_from_camp(topic: String):
	var lines: Array
	match topic:
		"camp_report":
			lines = [hernan("Llegué a la lona. No hay nadie acá. Hay botas marcadas en el barro y dejaron el trípode armado. En el cuaderno anotaron una camioneta y, dos minutos después, otra luz arriba de la muesca."),
				"Si dejaron el trípode, capaz subieron un poco más. Seguí las huellas hasta el hito del filo del este y fijate si los ves.",
				hernan("Esa segunda luz me deja pensando. Hace unos días vi una arriba del corte."),
				"Por acá pasan grupos enteros de noche. Desde abajo ni siquiera veo esa parte de la ladera. Avisame qué encontrás en el hito."]
		"trípode":
			lines = [hernan("Hay un trípode apuntando a la muesca. Se llevaron la cámara."),
				"Qué suerte. Una vez dejaron la cámara y se llevaron el trípode. Anduvimos una semana buscando al dueño."]
		"fogata":
			lines = [hernan("Dejaron una fogata. La ceniza está tibia todavía."),
				"Entonces anduvieron hace poco. Si seguís las pisadas, capaz los alcanzás."]
		"pulsera":
			lines = [hernan("Encontré una pulsera de papel. Dice «salida nocturna»."),
				"Mirá vos. Para imprimir pulseras les alcanza. Para pedir permiso, nunca."]
	conversation(lines, "camp:" + topic)

func mission_radio_available() -> bool:
	return (stage == 0 and not heard) or (stage == 19 and not departure_briefed) or awaiting_call or stage == 2 or (stage == 5 and creek_return_left < 0.0 and not bedtime) or creek_evening_available() or observing or (stage == 9 and not route_reported) or stage in [11, 14, 17] or not next_camp_report().is_empty() or (stage == 18 and night_home == 1)

func available_trail_chat() -> String:
	if mission_radio_available() or not player.climb_points.is_empty(): return ""
	if stage == 18 and last_night: return ""
	if trail_spacing_day == calendar_day() and (trail_walk_left > 0.0 or trail_quiet_left > 0.0) and not (stage == 19 and elvira_book_taken and not trail_replies.has("libro_elvira")): return ""
	if stage == 19 and (packed_items.size() < Departure.PACK_ITEMS.size() or not departure_destination.is_empty() or Museum.under_roof(valley, player.position)): return ""
	var topic := Mara.available(stage, player.position, bedtime, second_sighting, trail_replies, elvira_book_taken)
	if topic == "cable" and float(valley.sky_mat.get_shader_parameter("nightfall")) < 0.62: return ""
	return topic

func can_visit_mara() -> bool:
	return Mara.can_visit(trail_replies)

func start_trail_chat(topic: String):
	trail_topic = topic
	var opening := Mara.opening(topic, trail_replies, abra_told_mara, mara_heard_paula)
	var lines: Array = [hernan(opening)] if topic in Mara.HERNAN_STARTS else [opening]
	match topic:
		"piedras": lines.append("En el granito, difícil. Pero de una cantera más abajo tengo una piedra con la impresión de una planta. Está en el cajón.")
		"vaguada": lines.append("Suben las dos. Por la vaguada hay un tronco caído. Si lo pasás, te ahorrás la cuerda.")
		"sueno": lines.append("Ja. Te pegaron fuerte las historias de OVNIs. Eso es para los turistas. ¿Y después qué hiciste?")
		"duelo":
			lines.append(hernan("¿Qué cosa?"))
			lines.append("Perdón por preguntarte por qué viniste. Capaz te metí en un lugar del que no tenías ganas de hablar." if trail_replies.has("cielo") else "Nada del trabajo. Si hoy te hice muchas preguntas, decime. A veces a una le gana la curiosidad por radio.")
		"cable":
			lines.append_array(["Veo unas cuantas. ¿Cómo sabés cuáles son?", hernan("Estudié astronomía. La Cruz del Sur fue de las primeras que aprendí a encontrar."),
				"¿Astronomía, de verdad? Yo te pedí que me leyeras una regla. ¿Seguiste trabajando de eso?"])
		"pircas":
			lines.append_array([hernan("Supongo que nunca encontré el tiempo."), "¿Y alguna chica? ¿Alguien con quien te hayan dado ganas? Si querés contarme."])
		"regreso": lines.append("Desde el museo se ve todo el valle. ¿Sabés qué vas a hacer cuando llegues a casa?")
	if lines.size() > 1:
		conversation(lines, "trail_prompt")
	else:
		radio.play()
		show_trail_choices("Mara · " + opening)

func show_trail_choices(prompt: String):
	radio_choices("trail_chat", prompt, Mara.TOPICS[trail_topic][2])

func transmit():
	if not radio_available(): return
	radio_exchange()
	hands.press_button()

func begin_refuge_night():
	stage = 0
	first_call_wait = FIRST_CALL_DELAY
	first_call_repeat = 0.0
	first_call_caption = 0.0
	hint.text = ""
	valley.night(23.0)

func update_first_call(delta: float, inside: bool) -> bool:
	if not inside: return false
	if first_call_wait > 0.0:
		first_call_wait = maxf(0.0, first_call_wait - delta)
		if first_call_wait > 0.0: return false
	first_call_repeat -= delta
	if first_call_repeat <= 0.0:
		radio.incoming.play()
		first_call_repeat = FIRST_CALL_INTERVAL
		first_call_caption = 4.1
	first_call_caption = maxf(0.0, first_call_caption - delta)
	if radio_taken and first_call_caption < 3.28:
		welcome_mara()
		return true
	if first_call_caption > 0.0:
		hint.text = "Por la radio · ¿Me copiás?"
		if not radio_taken and target == "Radio": hint.text += "\nE · levantar la radio"
		return true
	return false

func take_arrival_radio():
	radio_taken = true
	valley.update_desk_radio(true)
	compass_out = false
	hands.hold("radio")
	hint.text = ""
	if first_call_wait <= 0.0: welcome_mara()

func put_down_arrival_bag():
	if stage != 0 or not heard or bag_left: return
	bag_left = true
	bedtime = true
	valley.leave_bag()
	valley.set_bag_drop(false)
	target = ""
	hint.text = ""
	save_game(true, "walk")

func welcome_mara():
	radio.incoming.stop()
	first_call_caption = 0.0
	conversation(["¿Me copiás? Soy Mara. Te hablo desde el puesto de abajo, pasando la curva del camino a Capilla."], "choice")

func start_day40():
	last_night = true
	bedtime = false
	day40_seconds_left = DAY40_SECONDS
	day40_interlude_done = false
	storm_return_seconds = Climate.STORM_CLEAR_SECONDS
	valley.morning()
	player.position = Vector3(1.24, 0.10, -4.4)
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	player.velocity = Vector3.ZERO
	save_game(true, "day40_card")
	show_day40_card()

func show_day40_card():
	day_card("Día 40 · El último día", "El arroyo bajó en los días siguientes. Mañana pasa el ómnibus. Salís un rato con la radio.", "Espacio · seguir")
	mode = "day40_card"

func start_day40_morning():
	var lines: Array = ["Último día ahí arriba, eh.", hernan("Sí. Me queda cerrar bien el puesto y preparar la mochila."),
		"Hoy no tengo ningún encargo para vos. Date una vuelta si tenés ganas. Disfrutá el día."]
	if Mara.closeness(trail_replies) >= 5:
		lines.append_array([hernan("Se va a sentir raro que no suene la radio."), "Sí. Igual te voy a dejar el canal abierto. Por si se nos quedó algo por decir."])
	conversation(lines, "day40_morning")

func update_day40(delta: float):
	if stage != 18 or not last_night or night_investigation != 0 or night_home != 0: return
	if mode not in ["walk", "map"] or not player.climb_points.is_empty(): return
	day40_seconds_left = maxf(0.0, day40_seconds_left - delta)
	var elapsed := DAY40_SECONDS - day40_seconds_left
	valley.set_sun_phase(smoothstep(184.0, 270.0, elapsed), smoothstep(226.0, DAY40_SECONDS, elapsed))
	if day40_seconds_left == 0.0:
		start_patio_call()
	elif day40_seconds_left <= 150.0 and not day40_interlude_done:
		start_day40_interlude()

func start_day40_interlude():
	var lines: Array
	if mara_heard_paula:
		lines = ["Che, me quedé pensando. ¿Supiste algo más de Paula?", hernan("Desde la última vez, nada."),
			"¿Te vas con ganas de saber cómo está?"]
	else:
		lines = ["Che, te iba a preguntar una cosa. ¿Qué vas a extrañar de acá?"]
	conversation(lines, "day40_interlude")

func start_patio_call():
	save_game(true, "walk")
	bed_pose = Transform3D(Basis.IDENTITY, Vector3(1.37, 0.06, 4.55))
	bed_pitch = 0.0
	bedtime = false
	var lines: Array = ["¿Me copiás? Te quería avisar lo del ómnibus de mañana.",
		hernan("¿Lo espero abajo en la ruta, después de la bajada?"),
		"Sí. Parate donde el chofer te vea desde antes de doblar."]
	lines.append("Avisame por el tres cuando salgas a la bajada. Voy a estar en el puesto de abajo.")
	lines.append("Pará. ¿Vos también ves esas dos luces por encima del monte?")
	conversation(lines, "night_patio")

func radio_exchange():
	if stage == 0 and not heard:
		welcome_mara()
		return
	if creek_evening_available():
		conversation([hernan("Che, se me pasó rapidísimo el día."),
			"Sí. A veces pasa muy rápido.",
			hernan("Cuando volví pensé que todavía iba a tener tiempo de desarmar todo."),
			"Dejalo para mañana. El primer parte ya está. Buenas noches, Hernán."], "creek_evening")
		return
	if stage == 18 and night_home == 1:
		conversation([
			hernan("Ya estoy en el puesto. Llegué bien."),
			"¿Estás en la puerta? Te oigo claro ahora. Estuve esperando que volvieras a llamar.",
			{"speaker": "Hernán", "text": "En el túnel dijiste que te había llegado mi voz de nuevo. ¿Qué escuchaste?"},
			"Tu «¿me copiás?». Volvió igualito unos segundos después de que soltaras el botón. Pensé que habías insistido.",
			{"speaker": "Hernán", "text": "Yo lo dije una sola vez."},
			"Capaz rebotó en algún equipo. Mañana lo hablamos. Ahora entrá en calor, Hernán."
		], "night_home")
		return
	var chat := available_trail_chat()
	if night_patio_ready() and chat.is_empty():
		start_day40()
		return
	if stage == 19:
		if not departure_briefed:
			departure_morning()
		elif at_departure_stop():
			farewell_mara()
		elif not chat.is_empty():
			start_trail_chat(chat)
		return
	if not chat.is_empty():
		start_trail_chat(chat)
		return
	if awaiting_call:
		if stage == 1:
			radio.play()
			radio_choices("day2_reply", "Mara · Buen día. ¿Cómo dormiste?", DAY2_SLEEP_REPLIES)
			return
		var brief: Array
		match stage:
			6: brief = ["Ayer se perdió el enlace con el abra. ¿Te llegás hasta la antena?", hernan("Dale. ¿Por dónde tengo mejor vista del abra?"),
				"Seguí la huella principal que sube desde la tranquera. El mástil está pasando el museo.",
				"Si perdés el canal, esperá unos segundos. Desde el puesto de abajo voy a seguir llamando."]
			16: brief = ["Acá abajo llovió toda la noche. Necesito saber hasta dónde subió el arroyo.",
				hernan("Antes de que salga, ¿sabés si hay alguien más andando por ahí? Con este ruido no distingo nada afuera."),
				"De los nuestros, nadie. Es el mismo cauce de la regla, más abajo. Pasá la loma de las lajas y seguí las pircas al sur, hasta la pasarela.",
				"Leé la marca desde esta orilla. Si el agua tapó la huella, te das vuelta."]
			13: brief = [
				"Me avisaron que anoche se metió un grupo de turistas sin permiso. Capaz el otro día viste las linternas de un grupo como ése. Nos pasa todas las semanas.",
				hernan("¿Querés que vaya a ver si queda alguien?"),
				"Sí. Tomá el sendero del este. Seguí las pircas desde el cartel de acceso.",
				"Buscá a los turistas. Suelen parar a descansar en los claros. Si encontrás alguna señal de ellos, llamame."
			]
			10:
				brief = ["Buen día, Hernán."]
				if filo_report_reply == 0:
					brief.append("Les marqué el rodeo a los de mantenimiento. Ya llegaron al cable por ahí.")
				elif filo_report_reply == 1:
					brief.append("Les avisé lo del escalón. Dejaron la carga abajo y subieron por turnos.")
				brief.append_array(["Tengo otro encargo para vos.", "Hay una chapa suelta en el malacate. A cierta hora devuelve el sol hacia el puesto.",
					hernan("Te copio. ¿Querés que la gire para probar el reflejo?"),
					"Salí por la tranquera y doblá a la izquierda. Seguí el cable viejo hasta la chapa.", hernan("Cuando la gire te aviso. Si la ves desde ahí, probamos si se apaga."),
					"Sí, con este sol me da justo en la ventana. Es buen momento para probar."])
			8: brief = [
				"Mañana sube gente de mantenimiento con herramientas. Quieren saber por dónde pasar con carga sin tener que trepar.",
				hernan("¿Les averiguo si pueden evitar el escalón de la laja?"),
				"Eso. En el cartel se abre un rodeo a la derecha. También sube, pero da la vuelta al escalón, donde está la cuerda.",
				"Elegí por dónde subir. Las dos huellas se juntan más arriba. Pasá el museo y el abra hasta el hito del filo. Desde ahí pasame tu recomendación."
			]
		if stage == 8 and abra_told_mara:
			brief.append("De paso, pregunté por tus destellos del abra. Esa tarde bajó una camioneta. Desde acá se ve el camino un rato y después lo tapa el filo.")
		conversation(brief, "brief")
		return
	var camp_report := next_camp_report()
	if not camp_report.is_empty():
		call_from_camp(camp_report)
		return
	if stage == 17:
		var lines: Array = []
		if summit_echo_response == 0:
			lines.append("Lo de la bajada del filo podía ser un rebote.")
		match crossing_response:
			0: lines.append_array([hernan("Marqué el travesaño de abajo. Cuando retrocedí oí mi propia voz."), "Yo también lo oí. Capaz se pisaron dos equipos."])
			1: lines.append_array([hernan("El agua llegó al travesaño de abajo. Apagué mi linterna y del otro lado seguía habiendo una figura."), "Entonces tu reflejo lo podemos tachar. ¿Te acordás desde qué orilla la viste? Marcala cuando estés a resguardo."])
			2: lines.append_array([hernan("Marqué el travesaño de abajo. Cuando alumbré había algo agarrado del borde, como una mano."), "Puede haber ramas trabadas. Con esta lluvia cuesta ver."])
		lines.append_array(["Ya tengo la marca. Si la loma se embarró, volvé por el poste.", "Cuando estés cerca de la tranquera podemos probar el canal otra vez."])
		conversation(lines, "crossing_home")
		return
	if stage == 14:
		var bearing := "Pudo ser una linterna. Desde un sendero bastante más abajo también parecen flotar."
		if quarry_reply == 1: bearing = "Marqué el rumbo que me diste. Atrás de la ladera hay gente caminando casi todas las noches. Una linterna de frente engaña a cualquiera."
		conversation([hernan("Llegué al hito del filo del este. Las huellas siguen por la otra ladera. Desde acá se ve un pliegue entero entre ese sendero y la muesca. La luz me sigue dejando dudas."),
			bearing, "Me acaban de avisar que el grupo se juntó abajo. Pegá la vuelta por el acceso y seguí hasta el puesto."], "summit_home")
		return
	if stage == 11:
		conversation([hernan("Giré la chapa. ¿Te sigue dando en la ventana?"), "Se apagó justo ahora. Dejala así un segundo."], "wait_flash")
		return
	if stage == 9 and not route_reported:
		conversation([hernan("Llegué al hito. Desde acá veo dónde se juntan las dos huellas."),
			"¿Cuál les marco a los que vienen con herramientas?"], "filo_prompt")
		return
	if (bedtime and (stage != 0 or heard)) or stage == -1 or stage >= 8:
		overlay("message", objective(), "Espacio · volver")
		return
	if observing:
		observing = false
		radio.play()
		conversation([hernan("Estoy al pie del mástil. ¿Me copiás?"), "Ahora sí te oigo. ¿Cómo me escuchás vos desde ahí?"], "reception_prompt")
		return
	match stage:
		1: overlay("message", "La radio está en silencio. Falta revisar el poste.", "Espacio · volver")
		2:
			stage = 4
			conversation([hernan("¿Mara? Lo encontré. Acá abajo de la pintura dice doce de julio."), "Lo repusieron después de una crecida. Con esa fecha puedo buscar el parte viejo.",
				"Seguí hasta el lecho de piedras. La regla está cerca de la curva. Pasame la lectura desde ahí."], "sighting_return")
		4: overlay("message", "Todavía falta medir el cauce. Llamá a Mara cuando tengas la lectura.", "Espacio · volver")
		5:
			radio.play()
			conversation([hernan("Mara, llegué a la regla. ¿Me copiás?"), "Sí. ¿Qué viste ahí abajo?"], "creek_report_prompt")

		6, 7: overlay("message", "El parte es al anochecer. " + objective(), "Espacio · volver")

func departure_morning():
	radio.incoming.stop()
	var lines: Array = ["Buen día, Hernán. ¿Ya empezaste a juntar tus cosas?"]
	if night_investigation > 0:
		lines.append(hernan("Recién me levanté. Quería hablar de lo de anoche. En la cueva había alguien anotando las mismas luces que vimos nosotros."))
	elif night_investigation < 0:
		lines.append(hernan("Todavía no. Me quedé pensando en esas luces que vimos anoche."))
	else:
		lines.append(hernan("Todavía no. Me cuesta creer que ya me toque bajar."))
	if can_visit_mara():
		lines.append("Yo también me quedé pensando. Terminá de empacar y hablamos cuando estés bajando.")
	else:
		lines.append("En ese cerro siempre pasa algo raro. Te quedás unos días y empezás a oír historias de todos lados.")
	lines.append_array(["Antes de bajar, pasá por el museo. Elvira te dejó un libro en el banco de adentro.",
		hernan("Bueno. Paso a buscarlo cuando tenga todo listo.")])
	conversation(lines, "departure_morning_done")

func farewell_mara():
	var reply := "Te escucho. Todavía tenés tiempo de sobra para alcanzar el ómnibus."
	var close_enough := can_visit_mara()
	var lines := [hernan("Ya estoy bajando a la ruta. Te quería avisar antes de irme.")]
	lines.append(reply)
	if night_investigation > 0:
		lines.append_array([hernan("Antes de subir, ¿podemos hablar de las luces? Necesito saber que vos también viste las dos."),
			"Las vi. Después que se taparon dejé el equipo en el tres hasta que aclaró. A ratos volvió la estática. Tu voz, ninguna vez más."])
	elif night_investigation < 0:
		lines.append_array([hernan("Me quedé pensando en las luces. ¿Volviste a verlas después de que guardé la radio?"),
			"Me quedé mirando un rato desde la ventana. Las dos primeras las vi. Después, en la curva, nada."])
	var memory := Mara.farewell_memory(trail_replies)
	if not memory.is_empty(): lines.append(memory)
	if close_enough:
		lines.append_array([hernan("Se me va a hacer raro guardar la radio."),
			"A mí me va a costar dejar de buscar el canal tres.",
			"Si querés pasar por casa antes de irte, más abajo empieza una huella a mano izquierda. Es la puerta de madera con el buzón. Golpeá, que desde el fondo cuesta oír."])
	else:
		lines.append_array(["Gracias por hacerte cargo del puesto estas semanas. Mañana subo a revisar lo que queda.",
			hernan("Gracias por acompañarme desde abajo."), "Buen viaje, Hernán."])
	conversation(lines, "last_call")

func show_map(variant: int = 0):
	var arrival := page if variant == 0 and paused_from == "approach" else -1
	var goal: Variant = null
	if variant == 0 and paused_from == "walk":
		goal = map_destination()
		map_goal_origin = player.position
	var sheet := -1
	if stage in [1, 2, 4, 5]: sheet = 0
	elif stage in [6, 7]: sheet = map.ABRA_ZONE
	elif stage in [8, 9]: sheet = map.FILO_ZONE
	elif stage in [10, 11, 12]: sheet = map.QUARRY_ZONE
	elif stage in [13, 14, 15]: sheet = map.SUMMIT_ZONE
	elif stage in [16, 17, 18]: sheet = map.CREEK_ZONE
	elif stage == 19: sheet = map.DEPARTURE_ZONE
	map.camp_known = camp_read
	map.tourist_search = stage == 13 and not awaiting_call and not camp_read
	map.open_at(player.position, variant, arrival, goal, sheet, stage == 19 and elvira_book_taken)
	map.queue_redraw()
	hands.show_map(true)
	update_flashlight()

func refresh_map_goal():
	map.objective_mark = map_destination()
	map_goal_origin = player.position

func update_flashlight():
	var in_cave_scene := is_instance_valid(cave)
	var active: bool = flashlight_out and (mode in ["walk", "approach", "map", "dream", "sighting"] or in_cave_scene or hands.requested_pose == "radio") and mode != "menu"
	player.flashlight.visible = active
	if active:
		var dark: float = valley.sky_mat.get_shader_parameter("nightfall")
		var air := 1.15 if in_cave_scene and not cave_outside else smoothstep(0.37, 0.96, dark)
		player.flashlight_haze.set_shader_parameter("density", air)

func close_journal():
	journal_view.hide()
	var source := journal_from
	journal_from = ""
	match source:
		"approach": approach()
		"intro":
			mode = "intro"
			shade.color = Color.BLACK
			recall.show()
		"dream": explore_dream()
		"cave": resume_cave()
		_: walk()

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.keycode
	var advance = key in [KEY_SPACE, KEY_ENTER]
	if mode == "cave_notebook":
		if key in [KEY_ESCAPE, KEY_TAB, KEY_E] or (advance and cave_notebook_page == CAVE_NOTEBOOK.size() - 1):
			resume_cave()
		elif key in [KEY_LEFT, KEY_RIGHT] or advance:
			cave_notebook_page = clampi(cave_notebook_page + (-1 if key == KEY_LEFT else 1), 0, CAVE_NOTEBOOK.size() - 1)
			show_cave_notebook()
		return
	if mode == "camp_notebook":
		if advance or key in [KEY_ESCAPE, KEY_TAB, KEY_E]:
			walk()
		elif key in [KEY_LEFT, KEY_RIGHT]:
			camp_notebook_page = clampi(camp_notebook_page + (1 if key == KEY_RIGHT else -1), 0, CAMP_NOTEBOOK.size() - 1)
			show_camp_notebook()
		return
	if mode == "journal":
		if advance or key in [KEY_ESCAPE, KEY_TAB]:
			close_journal()
		elif key == KEY_C:
			toggle_journal_section()
		elif key == KEY_N:
			toggle_nature_section()
		elif key in [KEY_LEFT, KEY_RIGHT]:
			journal_page = clampi(journal_page + (1 if key == KEY_RIGHT else -1), 0, journal_pages.size() - 1)
			show_journal_page()
		return
	if mode in ["approach", "walk", "cave"] and not player.climb_points.is_empty() and key not in [KEY_ESCAPE, KEY_F1]:
		return
	if mode in ["postcard", "desk_paper"]:
		if key == KEY_X and mode == "postcard":
			postcard_view.flip()
		elif key == KEY_E:
			if is_instance_valid(held_desk_paper):
				held_desk_paper.visible = true
				held_desk_paper.collision_layer = 1
				held_desk_paper = null
			postcard_view.hide()
			walk()
		return
	if mode == "elvira_book":
		if advance or key in [KEY_E, KEY_RIGHT]:
			advance_elvira_book()
		elif key == KEY_LEFT:
			book_view.turn(-1)
		elif key == KEY_ESCAPE and book_view.page == 0:
			book_view.hide()
			walk()
		return
	if mode == "book":
		if key == KEY_ESCAPE:
			book_view.hide()
			walk()
		elif key == KEY_LEFT: turn_book(-1)
		elif key == KEY_RIGHT or advance: turn_book(1)
		elif key == KEY_E and book_view.page == 2 and book_view.light_comparison: turn_book(1)
		return
	if mode in ["mate_morning", "mate_radio"]:
		if key == KEY_E:
			var hit = player.ray.get_collider()
			var item: String = hit.get_meta("item", "") if hit else ""
			if item == "Puerta":
				operate_refuge_door()
			elif mode == "mate_morning" and in_refuge_room():
				hands.hold("")
				mode = "mate_radio"
				save_game(true, "mate_radio")
			elif mode == "mate_radio" and item == "Radio" and mate_called:
				take_mate_radio()
		return
	if mode == "first_dream_wake":
		if words.modulate.a >= 1.0 and (key == KEY_E or advance):
			field_note += " Noche 7 · Al despertar todavía me acordaba de esas estrellas. Intenté dibujarlas antes de prender la luz."
			start_day25()
		return
	if mode == "day25_card":
		if advance and words.modulate.a >= 1.0:
			walk()
			shade.show()
			var fade := create_tween()
			fade.tween_property(shade, "color:a", 0.0, 1.25).set_trans(Tween.TRANS_SINE)
			fade.tween_callback(func():
				if mode == "walk": shade.hide())
		return
	if key == KEY_ESCAPE and mode in ["intro", "approach", "walk", "dream"]:
		paused_from = mode
		mode = "pause_menu"
		recall.hide()
		player.walking = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		menu.pause_menu()
		return
	if mode == "pause_menu" and key == KEY_ESCAPE:
		if menu.showing_settings: menu.close_settings()
		else: resume_play()
		return
	if mode == "approach" and page == 0 and not arrival_action:
		if key == KEY_F1 and intro_look_done:
			intro_objectives_seen = true
			hint.text = stop_control_hint()
		elif key == KEY_E:
			use_arrival_item()
		return
	if key == KEY_E and mode == "approach":
		use_arrival_item()
		return
	if key == KEY_F1 and mode in ["walk", "approach", "cave", "mara_door"]:
		objective_seconds = 4.0
		intro_controls_seconds = 0.0
		return
	if key == KEY_F1 and mode == "dream" and dream_variant() == 3:
		objective_seconds = 4.0
		return
	if key == KEY_L and (mode in ["approach", "walk", "map", "cave", "dream", "sighting"] or (radio_panel.visible and player.walking)):
		flashlight_out = not flashlight_out
		if mode == "approach" and page == 6 and flashlight_out: arrival_action = true
		update_flashlight()
		return
	if key == KEY_B and mode in ["approach", "walk", "map", "cave"]:
		if compass_lost:
			collect_notice = "Hernán · La brújula… La perdí en la cueva."
			collect_notice_seconds = 3.6
			hint.text = collect_notice
			return
		compass_out = not compass_out
		if mode == "approach" and page == 2 and compass_out: arrival_action = true
		hands.hold("compass" if compass_out else "")
		return
	if key == KEY_TAB and (mode in ["approach", "intro"] or (mode == "map" and paused_from == "approach")):
		journal_from = "approach" if mode == "map" else mode
		if journal_from == "approach" and page == 2:
			note_intro_bridge(Arrival.local_position(page, player.position))
		open_journal()
		return
	if mode in ["dream", "cave"] and key == KEY_TAB:
		journal_from = mode
		open_journal()
		return
	if (mode in ["dream", "cave"] or (mode == "walk" and stage >= 0)) and key in [KEY_C, KEY_N]:
		journal_from = mode
		journal_section = Diary.Section.DIARY
		if key == KEY_C: toggle_journal_section()
		else: toggle_nature_section()
		return
	if mode == "dream" and key == KEY_B:
		if dream_variant() == 3 and has_piece:
			hands.hold("" if hands.requested_pose == "piece" else "piece")
		return
	if mode == "dream" and key == KEY_M:
		if not dream_can_open_sheet(): return
		if hands.map_requested: hands.show_map(false)
		else: show_map(dream_variant())
		return
	if key == KEY_M and mode in ["approach", "walk"]:
		if mode == "approach" and page == 4: arrival_action = true
		paused_from = mode
		mode = "map"
		cross.hide()
		hint.text = "M · guardar el mapa"
		show_map()
		return
	if mode == "map" and key in [KEY_M, KEY_ESCAPE]:
		hands.show_map(false)
		mode = paused_from
		cross.show()
		hint.text = ""
		return
	if mode == "map" and key == KEY_R and paused_from == "walk" and radio_available():
		compass_out = false
		transmit()
		return
	if key == KEY_SPACE and mode in ["walk", "approach", "cave"] and player.is_on_floor():
		player.velocity.y = lerpf(5.7, 3.1, smoothstep(0.03, 1.60, player.water_depth))
		return
	if mode == "sighting":
		if key == KEY_E and not sighting_resolving:
			if sighting == Sighting.SHELTER and valley.curtain_hits.has(player.ray.get_collider()):
				valley.set_curtains(not valley.curtains_open)
			elif sighting_focus >= SIGHTING_FOCUS_SECONDS and looking_at_sighting():
				observe_lights()
	elif mode == "last_dream_prelude" and advance:
		mode = "sleeping"
		hint.text = ""
		reveal_dream(create_tween())
	elif mode == "dream_arch_talk" and advance:
		if radio_panel.line.visible_ratio < 1.0:
			radio_panel.reveal.kill()
			radio_panel.line.visible_characters = -1
		elif dream_arch_lines.is_empty():
			radio_panel.hide()
			explore_dream()
			save_game(true, "dream")
		else:
			show_dream_arch_line()
	elif mode == "day40_card" and advance:
		start_day40_morning()
	elif mode == "night_cut" and advance:
		enter_cave()
	elif mode == "cave":
		if key == KEY_E: inspect_cave()
		elif key == KEY_R: call_from_cave()
	elif mode == "cave_text" and advance:
		resume_cave()
	elif mode == "departure_bus" and key == KEY_E and target == "Puerta del ómnibus":
		finish_at_door(false)
	elif mode == "mara_door" and key == KEY_E and target == "Puerta de Mara":
		finish_at_door(true)
	elif mode == "intro": return
	elif mode == "dream" and key == KEY_SPACE and player.is_on_floor():
		player.velocity.y = 4.6
	elif mode == "dream" and key == KEY_E:
		if dream_plate_in_sight():
			dream_symbols_found = true
			dream_seconds_left = DREAM_RUINS_SECONDS
			collect_notice = "Copiaste los símbolos · M para ver la hoja"
			collect_notice_seconds = 5.0
			save_game(true, "dream")
			return
		var find := aimed_collectible()
		if Alien.FINDS.has(find):
			record_collectible(find)
			return
		if not has_piece and near_dream_piece():
			has_piece = true
			dream_piece.queue_free()
			dream_piece = null
			hands.hold("piece")
			ambience.play_piece_pulse(0.5)
			save_game(true, "dream")
	elif mode == "dream" and key == KEY_ESCAPE:
		overlay("dream_pause", "Pausa", "Esc · volver   /   F2 · menú principal")
	elif mode == "dream_pause" and (advance or key == KEY_ESCAPE):
		explore_dream()
	elif mode == "approach" and key == KEY_ESCAPE:
		overlay("pause_approach", "Pausa", "Espacio · volver   /   F2 · menú principal")
	elif mode == "pause_approach" and (advance or key == KEY_ESCAPE):
		walk()
		mode = "approach"
		hint.text = "WASD · Seguí la huella hacia la casa. Mouse · mirar"
	elif mode in ["arrival", "message", "pause"] and (advance or key in [KEY_ESCAPE, KEY_TAB]):
		walk()
	elif mode == "walk":
		if not player.climb_points.is_empty() and key != KEY_ESCAPE: return
		match key:
			KEY_ESCAPE: overlay("pause", "Pausa", "Espacio · volver   /   F2 · menú principal")
			KEY_TAB: open_journal()
			KEY_R: transmit()
			KEY_E:
				if pack_item(target): return
				if target == Museum.ELVIRA_BOOK and not elvira_book_taken:
					overlay("elvira_book", "", "")
					book_view.open_elvira()
					return
				var find := aimed_collectible()
				if stage >= 0 and Exploration.FINDS.has(find):
					record_collectible(find)
					return
				var subject := aimed_nature()
				if not subject.is_empty():
					record_nature(subject)
					return
				if at_summit_finish():
					start_day36()
					return
				if can_watch_sky():
					watch_sky()
					return
				if stage >= 0 and target in ["", "Subir al escalón"] and player.climb_ledge():
					compass_out = false
					hands.hold("")
					return
				var exhibits = Museum.LABELS
				if exhibits.has(target):
					overlay("message", exhibits[target], "Espacio · cerrar")
					return
				if Cable.NOTES.has(target):
					overlay("message", Cable.NOTES[target], "Espacio · seguir")
					return
				match target:
					"Tronco caído":
						overlay("message", "El arroyo dejó un tronco atravesado. Podés saltarlo con Espacio.", "Espacio · seguir")
					"Pasarela de la quebrada":
						if stage == 16 and not awaiting_call:
							stage = 17
							field_note += " El agua llegó al travesaño inferior de la pasarela."
							valley.sunset(Climate.STORM_RETURN_DUSK)
							score.cue("misterio", -18.0)
							radio.play_knocks()
							var sound := "La radio da dos golpes secos." if summit_echo_response < 0 else "La radio repite los dos golpes del filo."
							overlay("crossing_warning", "Marcás con carbón hasta dónde llegó el agua. " + sound + " Una voz que suena a Mara dice: «No cruces todavía».", "Espacio · escuchar", "radio")
							return
						overlay("message", "El agua dejó pasto enredado en el travesaño de abajo. Estirás el brazo y marcás la altura con un trozo de carbón.", "Espacio · guardar")
					"Heladera", "Freezer": valley.swing_side_door(valley.fridge_doors[target])
					"Gabinete de ollas", "Gabinete de tazas", "Gabinete de limpieza":
						valley.swing_side_door(valley.cabinet_doors[target])
					"Cajón izquierdo", "Cajón derecho":
						valley.move_fitting(valley.desk_drawers[target], "position:z", -0.30)
					"Brújula de repuesto":
						if stage == 19 and not spare_compass_taken and valley.spare_compass.collision_layer == 2:
							spare_compass_taken = true
							compass_lost = false
							valley.update_spare_compass(true, true)
							collect_notice = "Brújula de repuesto · B para usarla"
							collect_notice_seconds = 4.0
							save_game(true, "walk")
					"Calendario":
						var day: = calendar_day()
						var date: = "%d de octubre" % day if day <= 31 else "%d de noviembre" % (day - 31)
						overlay("message", "Calendario\n\n%s. Los días anteriores están tachados con lápiz rojo." % date if day > 1 else "Calendario\n\n%s. La hoja está recién dada vuelta." % date, "Espacio · volver")
					"Postal de Paula":
						overlay("postcard", "", "")
						postcard_view.pick_up("telescopio" in str(keepsakes.get("beca", "")))
					"Recorte de astronomía":
						if not paula_clipping_read:
							paula_clipping_read = true
							valley.sky_mat.set_shader_parameter("paula_star_visible", true)
							save_game(true, "walk")
						open_desk_paper(valley.desk_clipping, Refuge.CLIPPING_ART)
					"Trípode vacío":
						remember_camp_observation("trípode")
						overlay("message", "Alguien se llevó la cámara. El trípode quedó apuntando a una muesca de la ladera. Una pata tiene dos vueltas de cinta aisladora.", "Espacio · soltar")
					"Fogata apagada":
						remember_camp_observation("fogata")
						overlay("message", "Las ramas se deshacen al rozarlas. Debajo de las piedras queda ceniza tibia.", "Espacio · volver")
					"Cuaderno del campamento":
						if stage == 13 and not awaiting_call: summit_mapped = true
						if not camp_read:
							camp_read = true
							field_note += " Día 32 · El cuaderno del campamento registra una camioneta y, dos minutos después, otra luz arriba de la muesca."
							save_game(true, "walk")
						camp_notebook_page = 0
						show_camp_notebook()
					"Hito del filo oriental":
						if stage == 13 and not camp_read:
							overlay("message", "Desde acá distinguís la lona que dejaste abajo, junto a las pircas. Bajá a revisar el cuaderno del campamento para comparar los rumbos.", "Espacio · volver")
							return
						if stage == 13 and not camp_reported:
							overlay("message", "R · Avisale a Mara del campamento antes de seguir.", "Espacio · volver")
							return
						if stage == 13 and not awaiting_call:
							stage = 14
							summit_mapped = true
							field_note += " Desde el filo del este vi que el cable y la muesca de la segunda luz quedan separados por un pliegue del cerro."
							valley.sunset(SUMMIT_DUSK_SECONDS)
						var sketch := "Desde arriba ves terminar el cable antes del corte. Un pliegue entero de sierra lo separa de la muesca que dibujaron en el campamento."
						if quarry_reply == 1: sketch += " El rumbo que anotaste en el malacate cae detrás de ese pliegue."
						overlay("message", sketch + "\n\nAbrís el mapa sobre la piedra y marcás desde dónde miraste. El viento te levanta una esquina. La sujetás con el pulgar.", "Espacio · doblar el mapa")
					"Chapa del malacate":
						if stage == 10 and not awaiting_call:
							stage = 11
							branch_found = true
							valley.quarry_plate.rotation.y += 0.9
							valley.sunset(33.0)
						overlay("message", "La chapa gira sobre un solo bulón. La orientás hacia el último sol y la sujetás contra el bastidor.", "Espacio · soltar la manija")
					"Cuerda de la laja":
						var points: Array[Vector3] = valley.route.laja_rope_route()
						if player.position.z < valley.route.ORIGIN_Z - 170.2: points.reverse()
						player.climb_rope(points, 0.0)
					"Hito del filo":
						if stage == 8 and not awaiting_call:
							stage = 9
							field_note += " Día 25 · Hito del filo revisado."
							valley.sunset(46.0)
						overlay("message", "Desde el hito ves el pliegue entero de la quebrada. Recién acá se entiende la vuelta que da el sendero. Marcás el rodeo en el cuaderno.", "Espacio · guardar")
					"Bolso":
						if stage == 0:
							overlay("message", "Dejaste la mochila en el suelo. Mañana acomodás las cosas.", "Espacio · seguir")
						else:
							valley.unpack_book(book_has_ribbon())
							open_book()
					"Puerta":
						if stage == 19 and packed_items.size() < Departure.PACK_ITEMS.size():
							objective_seconds = 5.0
							return
						var arriving: bool = stage == -1 and not valley.door_open
						operate_refuge_door()
						if arriving and score.playing_cue == "prologo": score.silence(3.2)
					"Izar la bandera":
						if stage == 0 and not flag_raised:
							flag_raised = true
							valley.set_flag(true, true)
							save_game(true, "walk")
					"Cortinas": valley.set_curtains(not valley.curtains_open)
					"Puerta del baño": valley.swing_side_door(valley.privy_hinge)
					"Puerta del museo":
						if Museum.night_closed(valley) and not Museum.under_roof(valley, player.position):
							overlay("message", "El museo ya cerró.", "Espacio · volver")
						else: valley.swing_side_door(valley.museum_hinge)
					"Puerta de Mara":
						overlay("message", "La puerta de madera tiene un buzón chico al lado del marco.", "Espacio · seguir")
					"Tranquera": valley.swing_side_door(valley.yard_hinge)
					"Dejar la mochila": put_down_arrival_bag()
					"Cama":
						if stage == 0 and heard and not bag_left: put_down_arrival_bag()
						elif stage == 18 and night_investigation == 0 and night_home == 0 and bedtime: overlay("message", "Mara quedó en escucharte desde el patio. Salí y llamala por radio.", "Espacio · seguir")
						elif bedtime: overlay("rest", "¿Querés acostarte y terminar la jornada?", ["Dormir", "Seguir despierto"])
						else: overlay("message", "Todavía te queda algo por hacer. " + objective(), "Espacio · levantarse")
					"Observar el Cielo": open_book()
					"Flora serrana", "Cuaderno de campo": overlay("message", target + "\n\nHay una hoja seca de molle entre las páginas.", "Espacio · cerrar")
					"Radio":
						if stage == 0 and not radio_taken: take_arrival_radio()
						else: transmit()
					"Nota":
						open_desk_paper(valley.desk_note, Refuge.NOTE_ART)
					"Piedra de Mara":
						if not fossil_sketched:
							fossil_sketched = true
							collect_notice = "Fósil dibujado · Tab para ver el cuaderno"
							collect_notice_seconds = 4.0
							save_game(true, "walk")
						else:
							overlay("message", "La piedra se abrió por la mitad y la ramita quedó marcada en una de las caras. Mara la envolvió con las pilas.", "Espacio · dejarla en el escritorio")
					"Botella de Mara":
						overlay("message", "Levantás una punta del papel de diario. El sello del tinto está intacto. Entre los dobleces reconocés la letra de Mara. «Para cuando entregues la llave. M.»", "Espacio · dejarla en la repisa")
					"Regla del cauce":
						if stage == 4:
							stage = 5
							creek_note = "Día 2 · Cauce seco. Mica en la piedra del cruce."
						var depth_cm := roundi(South.water_depth(Creek.marker()) * 100.0) if valley.storm_water and valley.storm_water.visible else 0
						var reading := "%d centímetros. El agua cubre las primeras marcas de la regla." % depth_cm if depth_cm > 0 else "Cero centímetros. Cuando te agachás, una escama de mica devuelve el sol. Desde arriba la misma piedra parece gris."
						overlay("message", reading, "Espacio · levantarse")
					"Banco": overlay("message", "La madera está lisa donde se sienta la gente.", "Espacio · volver")
					"Puesto de abajo":
						overlay("message", "La huella llega hasta el puesto del otro lado de la curva.", "Espacio · volver")
					"Antena del abra":
						if stage == 7 and not day7_dusk and not bedtime:
							overlay("bench", "Extendés la antena al pie del mástil. Mara dijo que iba a seguir llamando desde el puesto de abajo. Te quedás quieto hasta que aclare el canal.", "Espacio · escuchar", "radio")
						else:
							overlay("message", "El viento hace vibrar el tensor.", "Espacio · levantarse")
					"Poste":
						if stage == 1 and not awaiting_call:
							stage = 2
						overlay("message", "Debajo de la pintura nueva se lee todavía una fecha: 12 de julio.", "Espacio · volver")
	elif mode == "crossing_warning" and advance:
		radio.play_interference()
		show_sighting(Sighting.CROSSING)
	elif key == KEY_ESCAPE and (mode == "trail_chat" or (mode == "talk" and after == "last_call")):
		walk()
	elif mode == "talk" and advance:
		if radio_panel.line.visible_ratio < 1.0:
			radio_panel.reveal.kill()
			radio_panel.line.visible_ratio = 1.0
			return
		if not sequence.is_empty(): speak()
		elif after == "wait_flash":
			mode = "listen_quarry"
			radio_panel.hide()
			await get_tree().create_timer(2.2).timeout
			show_sighting(Sighting.QUARRY)
		elif after == "night_patio":
			show_sighting(Sighting.SHELTER)
		elif after == "day40_morning" or after == "day40_interlude_done":
			walk()
			save_game(true, "walk")
		elif after == "day40_interlude":
			var prompt := "Mara · ¿Te vas con ganas de saber cómo está?" if mara_heard_paula else "Mara · ¿Qué vas a extrañar de acá?"
			var frank := "Sí, quiero saber cómo está. Y voy a extrañar esperar a que abras el canal." if mara_heard_paula else "Voy a extrañar esperar a que abras el canal."
			var reserved := "Sí, pero tendrá que ser cuando vuelva." if mara_heard_paula else "Salir de noche y que de golpe se vea todo el cielo."
			radio_choices("day40_reply", prompt, [frank, reserved])
		elif after.begins_with("camp:"):
			var item := after.get_slice(":", 1)
			if item == "camp_report": camp_reported = true
			else: camp_observations[item] = true
			walk()
			save_game(true, "walk")
		elif after == "filo_prompt":
			radio_choices("field_report", "Mara · ¿Cuál les marco a los que vienen con herramientas?", ["Con carga, vayan por la vaguada.", "En la laja hay que subir con la cuerda."])
		elif after == "reception_prompt":
			radio_choices("reception", "Mara · ¿Cómo me escuchás vos desde ahí?", MAST_REPLIES)
		elif after == "quarry_prompt":
			radio_choices("quarry_sighting_response", "Mara · ¿Desde dónde estás viendo esa otra luz?", QUARRY_REPLIES)
		elif after == "crossing_home":
			stage = 18
			storm_return_seconds = 0.0
			bedtime = true
			valley.return_night(Climate.STORM_RETURN_NIGHT, Climate.STORM_RETURN_DUSK)
			walk()
		elif after == "summit_home":
			valley.return_night(SUMMIT_NIGHT_SECONDS, SUMMIT_DUSK_SECONDS)
			radio.play_knocks()
			radio_choices("summit_echo", "Soltás el botón. La radio da dos golpes secos. Después se oye «hasta el acceso». La frase es de Mara. La voz suena como la tuya.", ["¿Vos acabás de repetir «hasta el acceso»?", "Guardás la radio y empezás a bajar."])
		elif after == "summit_echo_done":
			walk()
			save_game(true, "walk")
		elif after == "quarry_home":
			stage = 12
			bedtime = true
			field_note += " Día 27 · En el malacate vi una luz por encima del corte con la chapa quieta."
			if quarry_reply == 1: field_note += " Dejé anotados el rumbo y la hora junto al croquis."
			valley.return_night(QUARRY_NIGHT_SECONDS, 35.0)
			walk()
			save_game(true, "walk")
		elif after == "last_call":
			choose_departure("fork")
		elif after == "departure_morning_done":
			departure_briefed = true
			walk()
			objective_seconds = 5.0
			save_game(true, "walk")
		elif after in ["cave_intro", "cave_rope", "cave_tunnel"]:
			resume_cave()
		elif after == "cave_plate":
			radio_choices("cave_entry", "Hay aire frío del otro lado de la boca.", ["Voy a asomarme. Te aviso enseguida.", "Voy a entrar. Si se corta, quedate en el canal."])
		elif after == "cave_entry":
			cave_entry_clear = true
			resume_cave()
		elif after == "cave_station":
			cave_exit_open = true
			resume_cave()
		elif after == "night_follow":
			day_card("La última noche", "Seguís las luces entre los molles. Se pierden atrás de un paredón. Cuando encontrás dónde pasar, ves una abertura en la piedra.", "Espacio · seguir")
			mode = "night_cut"
		elif after == "night_stay":
			bedtime = true
			field_note += " Día 40 · Vi dos luces meterse en el monte. Le dije a Mara que las iba a dejar ir."
			walk()
			save_game(true, "walk")
		elif after == "night_home":
			night_home = 2
			bedtime = true
			walk()
			save_game(true, "walk")
		elif after == "creek_report":
			creek_return_left = CREEK_RETURN_SECONDS
			walk()
			save_game(true, "walk")
		elif after == "creek_report_prompt":
			radio_choices("report", "Mara · ¿Qué viste ahí abajo?", CREEK_REPORT_REPLIES)
		elif after == "creek_evening":
			creek_evening_call = true
			walk()
			save_game(true, "walk")
		elif after == "trail_chat_done":
			trail_replies[trail_topic] = trail_answer
			if trail_topic == "pircas": mara_heard_paula = trail_answer == 0
			if trail_topic == "cauce":
				field_note += " Día 7 · Le dije a Mara que me venía bien un rato de silencio." if trail_answer == 0 else " Día 7 · Le pedí a Mara que se quedara en el canal hasta el cruce."
			trail_topic = ""
			walk()
			save_game(true, "walk")
		elif after == "trail_prompt":
			show_trail_choices("Mara · " + radio_panel.line.text)
		elif after == "sighting_return":
			walk()
			if stage == 7 and second_sighting: save_game(true, "walk")
		elif after == "day2_readiness":
			radio_choices("day2_ready", "Mara · ¿Estás listo para empezar a trabajar?", DAY2_READY_REPLIES)
		elif after == "brief" or after == "day2_confirm":
			awaiting_call = false
			if stage == 6: stage = 7
			walk()
		elif after == "filo":
			route_reported = true
			bedtime = true
			valley.return_night(RIDGE_NIGHT_SECONDS, 52.0)
			walk()
			save_game(true, "walk")
		elif after == "reception_done":
			day7_dusk = true
			bedtime = second_sighting
			if not second_sighting: valley.night(ABRA_NIGHT_SECONDS, 32.0)
			walk()
			save_game(true, "walk")
		elif after in ["sleep", "abra_done"]:
			bedtime = true
			walk()
			if after == "abra_done": save_game(true, "walk")
		elif after == "welcome_done":
			heard = true
			bedtime = bag_left
			valley.set_bag_drop(not bag_left)
			walk()
			save_game(true, "walk")
		elif after == "choice": radio_choices("choice", "Tenés el botón de la radio bajo el pulgar.", WELCOME_REPLIES)
		else:
			stage = 0
			heard = true
			walk()
	elif mode == "bench" and advance:
		walk()
		observing = true
	elif mode == "end" and (advance or key == KEY_F2):
		if advance and ending_paragraph + 1 < ending_paragraphs.size():
			ending_paragraph += 1
			show_ending_paragraph()
		elif key == KEY_F2:
			get_tree().reload_current_scene()
	elif mode in ["pause", "pause_approach", "dream_pause"] and key == KEY_F2:
		get_tree().reload_current_scene()

func select_option(index: int):
	if mode == "intro" and recall.complete and choosing:
		var entry: Dictionary = memories[page]
		keepsakes[entry.key] = entry.options[index].keepsake
		if entry.get("show_response", false):
			memory()
		else:
			choosing = false
			next_memory()
	elif mode == "crossing_response":
		crossing_response = index
		field_note += " Día 36 · " + CROSSING_NOTES[index]
		if index != 0: flashlight_out = index == 2
		if index == 1:
			score.cue("cosmic", -15.0, 1.5)
			walk()
			mode = "crossing_glimpse"
			update_flashlight()
			var figure := South.glimpse(valley)
			player.glance_toward(figure.global_position + Vector3.UP * 1.28)
			await get_tree().create_timer(3.6).timeout
			figure.queue_free()
			if mode != "crossing_glimpse": return
		overlay("message", CROSSING_NOTES[index] + "\n\nEl canal queda abierto. Mara te pide la marca del agua y quiere saber qué notaste en la orilla.", "Espacio · volver")
	elif mode == "summit_echo":
		summit_echo_response = index
		stage = 15
		bedtime = false
		field_note += " Día 32 · Dos golpes en la radio y una voz parecida a la mía."
		if index == 0:
			conversation(chosen_reply(index) + [
				"Lo dije antes. Ahora estaba esperando tu respuesta. Si lo volvés a oír, fijate si entra antes o después de que sueltes el botón."], "summit_echo_done")
		else:
			walk()
			save_game(true, "walk")
	elif mode == "day40_reply":
		day40_interlude_done = true
		var reply := "Yo también. A veces ya tenía el dedo en el botón antes de escucharte llegar." if Mara.closeness(trail_replies) >= 5 else "Bueno. Todavía te queda una noche para llamarme si te desvelás."
		if index == 1: reply = "Te entiendo. Tomate tu tiempo." if mara_heard_paula else "Ojalá te toque una noche despejada, entonces."
		conversation(chosen_reply(index) + [reply], "day40_interlude_done")
	elif mode == "last_night_choice":
		if index == 0:
			night_investigation = 1
			conversation(chosen_reply(index) + [
				"Esperá. Llevá la linterna. Si dejás de ver el puesto, llamame."
			], "night_follow")
		else:
			night_investigation = -1
			conversation(chosen_reply(index) + [
				"Está bien. Dejá las cosas cerca de la puerta para mañana. Te escucho desde la bajada."
			], "night_stay")
	elif mode == "cave_entry":
		conversation(chosen_reply(index) + ["Voy a quedarme acá con la radio prendida."], "cave_entry")
	elif mode == "last_voice":
		last_voice_reply = index
		show_dream_voice("last_voice_answer", "Hernán", "¿Papá…?" if index == 1 else "¿Quién es…?", "")
		var voice := create_tween()
		voice.tween_interval(1.65 if index == 1 else 1.15)
		voice.tween_callback(func():
			show_dream_voice("last_voice_answer", "Voz", "Mirá una más. Después nos vamos.", ""))
		voice.tween_interval(5.8)
		voice.tween_callback(finish_dream)
	elif mode == "day2_reply":
		var reply := "Menos mal. Esa cama tiene sus años." if index == 0 else "Es normal. El monte en realidad es más ruidoso que la ciudad, ¿viste?"
		conversation(chosen_reply(index) + [reply, "¿Estás listo para empezar a trabajar?"], "day2_readiness")
	elif mode == "day2_ready":
		conversation(chosen_reply(index) + ["Hoy me hacen falta dos datos. Salí por la tranquera y tomá la huella que rodea la cerca hacia el sur.",
			"Fijate qué fecha tiene la chapa del poste en la bajada. Nos hablamos cuando la tengas."], "day2_confirm")
	elif mode == "trail_chat":
		trail_answer = index
		var chat: Array = Mara.TOPICS[trail_topic]
		var replies := chosen_reply(index)
		replies.append_array(chat[3][index])
		if trail_topic == "duelo" and index == 0:
			if trail_replies.get("cielo", -1) == 0:
				replies.append_array(["¿Lo extrañás mucho?", hernan("A veces estoy por contarle algo. Me acuerdo justo cuando ya abrí la boca.")])
			replies.append("Mi mamá murió hace unos años. Todavía saco dos tazas si pongo la pava medio dormida. Después guardo una.")
		if trail_topic == "ventana" and crossing_response == 0:
			replies.append("Si se repite tu voz, dejá pasar un segundo antes de responder. Quiero saber cuánto tarda en volver.")
		conversation(replies, "trail_chat_done")
	elif mode == "choice":
		conversation(chosen_reply(index) + ["Ahí te escucho. Mañana te voy a pedir un par de datos del cauce. Desde afuera la señal llega un poco mejor.",
			"Te dejo que te sigas acomodando. Después descansá. Mañana te llamo temprano."], "welcome_done")
	elif mode == "rest" and index == 1: walk()
	elif mode == "rest" and index == 0:
		if stage == 15:
			start_day36()
			return
		if stage == 12:
			stage = 13
			bedtime = false
			awaiting_call = true
			valley.morning()
			valley.dress_day32()
			show_mate_morning()
			save_game(true, "mate_morning")
			return
		if stage == 0 and not valley.book_unpacked: valley.unpack_book(book_has_ribbon())
		bedtime = false
		if stage == 18 and night_investigation < 0:
			bed_pose = player.transform
			bed_pitch = player.camera.rotation.x
			valley.set_curtains(false)
			flashlight_out = false
			finish_dream(false)
		elif stage in [7, 9, 18]:
			begin_dream(stage == 18)
		else:
			score.silence(2.5)
			valley.morning()
			if stage == 0:
				valley.configure_sky(1)
				stage = 1
				awaiting_call = true
				save_game(true, "walk")
				day_card("Día 2 · La regla", "Desde el puesto de abajo llega un llamado corto. La radio está prendida.", "Espacio · levantarse")
			else:
				stage = 6
				valley.configure_sky(2)
				awaiting_call = true
				save_game(true, "walk")
				day_card("Día 7 · Alcance", "Llevás una semana en el puesto. Reconocés el doble clic de Mara antes de que empiece a hablar.", "Espacio · levantarse")
	elif mode == "sighting_response":
		abra_told_mara = index == 0
		if abra_told_mara:
			field_note += " Se lo conté a Mara."
			conversation(chosen_reply(index) + [
				"Desde mi ventana veo la curva hasta el primer poste. Por ahí no pasó nadie mientras hablábamos.",
				"Si una luz quedó arriba del filo, marcame desde dónde la viste. Avisame si vuelve a cortarse el canal en la bajada."], "abra_done")
		else:
			field_note += " Guardé el rumbo para compararlo después."
			bedtime = true
			walk()
			save_game(true, "walk")
	elif mode == "quarry_sighting_response":
		quarry_reply = index
		var reply := "Anotala aparte entonces. Puede haber un foco de trabajo atrás del corte." if index == 0 else "Con ese rumbo la luz cae detrás del corte. Guardá también la hora."
		var lines := chosen_reply(index)
		lines.append(reply)
		if abra_told_mara: lines.append("La otra vez eran dos destellos. Guardá los dos rumbos. Desde abajo se te mezcla todo en la misma ladera.")
		lines.append_array(["Entre el ruido oí «todavía». Pensé que habías hablado vos.", "¿Seguís ahí? Me quedo hasta que llegues."])
		conversation(lines, "quarry_home")
	elif mode == "fox":
		valley.route.release_fox(index == 0)
		field_note += " Lo ves bajar al cauce." if index == 0 else " Le dejás libre el paso."
		walk()
	elif mode == "field_report":
		filo_report_reply = index
		field_note += " Marqué la vuelta por la vaguada para los de mantenimiento." if index == 0 else " Avisé que en la laja hay que usar la cuerda."
		var line := "Les marco el rodeo." if index == 0 else "Les aviso que en el escalón suban de a uno."
		conversation(chosen_reply(index) + [line, "Van a mirar el malacate. Dicen que algo brilló por ahí al cerrar el otro turno."], "filo")
	elif mode == "reception":
		var lines := chosen_reply(index)
		lines.append("Perfecto. Entonces el mástil está haciendo su trabajo." if index == 0 else "Ese es el canal que más se corta. Dejo la radio prendida.")
		if abra_told_mara: lines.append("Desde la antena tu voz entra limpia. Guardá la hora de los destellos. Puedo preguntar si había alguien del otro lado.")
		conversation(lines, "reception_done")
	elif mode == "report":
		var lines := chosen_reply(index)
		creek_note += " Parte enviado."
		if index == 1:
			creek_note += " Le contaste a Mara lo de la mica."
			lines.append_array([
				"A esa hora se ve bien. Si mañana vuelven las nubes, vas a tener que buscarla de nuevo. ¿Qué te dio la regla?",
				hernan("Cero centímetros."), hernan("Está seco."),
			])
		lines.append("Anotado. Bastante trabajo por hoy. Podés terminar de acomodarte y dar un paseo si querés.")
		conversation(lines, "creek_report")

func begin_dream(preserve_bed: bool = false):
	dream_seconds_left = DREAM_SECONDS
	dream_symbols_found = false
	has_piece = false
	dream_arch_visits.clear()
	dream_pulse_wait = 0.0
	var last := stage == 18
	score.cue("otromundo", -14.0, 2.5, true)
	if not preserve_bed:
		bed_pose = player.transform
		bed_pitch = player.camera.rotation.x
	var first: = dream_count == 0
	dream_count += 1
	overlay("sleeping", "", "")
	shade.color = Color(0, 0, 0, 0)
	var fade: = create_tween()
	fade.tween_property(shade, "color:a", 1.0, 1.8)
	fade.tween_callback( func():
		words.text = "Te dormís de costado. Por un momento te parece que seguís afuera." if first else "Te acostás con el pelo todavía húmedo. Cerrás los ojos. Esta vez reconocés la curva antes de verla."
		if night_investigation == 3:
			words.text = "El blanco se vuelve tela. Oís a tu papá pasar una hoja. Del otro lado del arco alguien gira la perilla de una radio. El papel y la estática hacen el mismo ruido."
		elif stage == 18:
			words.text = "Apoyás la radio en el piso. Todavía caen gotas del alero. Las contás hasta perder la cuenta."
			if night_home == 2:
				words.text = "Dejás la radio en el piso. Durante un rato mirás el techo, todavía con las botas puestas."
			elif night_investigation > 0:
				words.text = "Agarrás la bajada. Después hay un tramo que no podés ubicar. En el sueño, la radio sigue abierta."
		valley.strange_sky(dream_variant())
		player.walking = false
		player.low_gravity = true
		position_on_planet()
		player.velocity = Vector3.ZERO
		player.rotation.y = PI if first else 0.0
		player.camera.rotation.x = 0.14 if first else 0.4
		if last:
			mode = "last_dream_prelude"
			hint.text = "Espacio · entrar al sueño")
	if not last:
		fade.tween_interval(5.0)
		reveal_dream(fade)

func reveal_dream(fade: Tween):
	fade.tween_property(words, "modulate:a", 0.0, 1.0)
	if dream_variant() == 1:
		var top := ColorRect.new()
		var bottom := ColorRect.new()
		for lid in [top, bottom]:
			lid.color = Color.BLACK
			lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lid.hide()
			shade.get_parent().add_child(lid)
		fade.tween_callback(func():
			top.show()
			bottom.show()
			shade.color.a = 0.0)
		var eyelids := func(aperture: float):
			top.set_anchor_and_offset(SIDE_BOTTOM, aperture, 0.0)
			bottom.set_anchor_and_offset(SIDE_TOP, 1.0 - aperture, 0.0)
		top.set_anchor(SIDE_RIGHT, 1.0)
		bottom.set_anchor(SIDE_RIGHT, 1.0)
		bottom.set_anchor(SIDE_BOTTOM, 1.0)
		eyelids.call(0.51)
		fade.tween_method(eyelids, 0.51, 0.06, 0.49)
		fade.tween_method(eyelids, 0.06, 0.45, 0.16)
		fade.tween_method(eyelids, 0.45, 0.0, 0.39)
		fade.tween_callback(func():
			top.queue_free()
			bottom.queue_free())
	else:
		fade.tween_property(shade, "color:a", 0.0, 2.0)
	fade.tween_callback( func():
		words.modulate.a = 1.0
		explore_dream()
		if dream_variant() == 3: objective_seconds = 4.0)

func dream_variant() -> int:
	if stage == 18: return 3
	return 1 if dream_count <= 1 else 2

func ensure_dream_world():
	if not is_instance_valid(dream_world):
		dream_world = LastNight.build_planet(valley, dream_variant())
		remove_collected_objects()

func position_on_planet():
	ensure_dream_world()
	player.intro_center = LastNight.PLANET
	player.dream_bounds = LastNight.DREAM_BOUNDS
	player.intro_heading = 0.0
	player.position = LastNight.dream_point(dream_variant(), 0.0) + Vector3.UP * 0.16
	player.rotation.y = 0.0

func explore_dream():
	ensure_dream_world()
	var local: Vector3 = player.position - LastNight.PLANET
	if absf(local.y) > 70.0 or not LastNight.DREAM_BOUNDS.grow(2.0).has_point(Vector2(local.x, local.z)):
		position_on_planet()
	player.intro_center = LastNight.PLANET
	player.dream_bounds = LastNight.DREAM_BOUNDS
	player.intro_heading = 0.0
	player.camera.far = NIGHT_SCENE_VIEW
	hands.show_map(false)
	walk()
	if dream_variant() == 3 and not has_piece and not is_instance_valid(dream_piece):
		var foot := LastNight.dream_surface(dream_variant(), Vector2(0.32, -5.3))
		dream_piece = Node3D.new()
		dream_world.add_child(dream_piece)
		dream_piece.position = foot + Vector3.UP * 1.38
		dream_piece_height = dream_piece.position.y
		dream_piece_phase = 0.0
		Alien.artifact(dream_piece).rotation = Vector3(0.25, 0.62, 0.22)
		Alien.artifact_glow(dream_piece)
	mode = "dream"
	if has_piece and dream_variant() == 3: hands.hold("piece")

func dream_can_open_sheet() -> bool:
	return (dream_variant() == 2 and dream_symbols_found) or (dream_variant() == 3 and has_piece)

func dream_plate_in_sight() -> bool:
	if dream_variant() != 2 or dream_symbols_found: return false
	var hit = player.ray.get_collider()
	return hit != null and hit.get_meta("item", "") == LastNight.DREAM_PLATE

func arch_bearing(arch: Vector3) -> float:
	var offset: Vector3 = arch - player.position
	var look: Vector3 = -player.camera.global_basis.z
	var direction := Vector2(offset.x, offset.z).normalized()
	var forward := Vector2(look.x, look.z).normalized()
	return smoothstep(0.29, 0.99, forward.dot(direction)) * (1.0 - smoothstep(0.42, 0.78, absf(look.y)))

func looking_at_dream_sky() -> bool:
	return -player.camera.global_basis.z.y > 0.36

func near_dream_piece() -> bool:
	if not is_instance_valid(dream_piece): return false
	var center := dream_piece.global_position
	var eye: Vector3 = player.camera.global_position
	var offset := center - eye
	return offset.length_squared() < 8.41 and offset.normalized().dot(-player.camera.global_basis.z) > 0.96 and player.raycast_surface(eye, center).is_empty()

func update_dream_arch(delta: float):
	var nearest := -1
	var distance := INF
	for i in LastNight.DREAM_ARCH_SITES.size():
		if i in dream_arch_visits: continue
		var away: float = player.position.distance_to(LastNight.dream_arch(i))
		if away < distance:
			nearest = i
			distance = away
	if nearest == -1: return
	if distance < 4.3:
		var exchange := dream_arch_visits.size()
		dream_arch_visits.append(nearest)
		hands.set_piece_signal(0.0)
		dream_pulse_wait = 3.0
		if exchange < DREAM_ARCH_EXCHANGES.size():
			if exchange == 2: radio.play_knocks()
			dream_arch_lines = DREAM_ARCH_EXCHANGES[exchange].duplicate()
			show_dream_arch_line()
		else:
			hear_last_voice()
		return
	var bearing := arch_bearing(LastNight.dream_arch(nearest))
	var proximity := 1.0 - smoothstep(4.3, 85.0, distance)
	var signal_strength := smoothstep(0.30, 0.86, bearing) * lerpf(0.56, 1.0, proximity)
	hands.set_piece_signal(signal_strength)
	dream_pulse_wait = maxf(0.0, dream_pulse_wait - delta)
	if bearing > 0.72 and dream_pulse_wait == 0.0:
		ambience.play_piece_pulse(signal_strength)
		dream_pulse_wait = 6.8

func show_dream_arch_line():
	var voice: Array = dream_arch_lines.pop_front()
	show_dream_voice("dream_arch_talk", voice[0], voice[1], "Espacio · seguir")

func show_dream_voice(kind: String, speaker: String, text: String, footer: Variant):
	overlay(kind, "", "")
	shade.hide()
	shade.color.a = 0.0
	player.walking = true
	radio_panel.display("dream_voice", speaker + "\n\n" + text, footer)

func restore_dream_arches(state: Dictionary):
	dream_arch_visits.clear()
	var count := LastNight.DREAM_ARCH_SITES.size()
	if state.has("dream_arch_visits"):
		for index in state.dream_arch_visits:
			if index is int and index >= 0 and index < count and index not in dream_arch_visits:
				dream_arch_visits.append(index)
	else:
		for index in clampi(int(state.get("dream_arches", 0)), 0, count - 1):
			dream_arch_visits.append(index)
	if dream_arch_visits.size() == count: dream_arch_visits.pop_back()
	dream_pulse_wait = 0.0

func finish_dream(had_dream := true):
	score.silence(2.2)
	overlay("waking", "", "")
	shade.color = Color(0, 0, 0, 0)
	var fade: = create_tween()
	fade.tween_property(shade, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	fade.tween_interval(0.46)
	fade.tween_callback( func():
		player.low_gravity = false
		player.intro_center = Vector3.ZERO
		player.camera.far = valley_view_distance
		player.transform = bed_pose
		player.camera.rotation.x = bed_pitch
		player.velocity = Vector3.ZERO
		valley.sky_mat.set_shader_parameter("other_world", 0.0)
		if is_instance_valid(dream_world): dream_world.queue_free()
		dream_world = null
		dream_piece = null
		if stage == 18:
			valley.morning()
			stage = 19
			bedtime = false
			awaiting_call = false
			departure_briefed = false
			departure_call_wait = 1.5
			elvira_book_taken = false
			packed_items.clear()
			departure_destination = ""
			if valley.door_open: valley.toggle_door()
			valley.update_packing(packed_items, true)
			save_game(true, "walk")
			var departure := "La mochila está abierta al pie de la cama."
			if had_dream:
				var waking := "Abrís los ojos en tu cama. Sobre la mesa, la radio sigue en el canal de anoche. Buscás entre tus cosas. El único cuaderno que encontrás es el tuyo.\n\n"
				day_card("Día 41 · El dibujo", waking + "Intentás dibujar el arco en el reverso de un parte. Cuando enderezás el dintel, deja de parecerse al del sueño. " + departure, "Espacio · levantarse")
			else:
				day_card("Día 41 · La partida", "Amanece. Hay tierra seca en los cordones de las botas. Afuera, entre los molles, empieza a dar el sol.\n\n" + departure, "Espacio · levantarse")
		elif stage == 7:
			show_first_dream_wake()
			save_game(true, "first_dream_wake")
		elif dream_count == 1:

			bedtime = true
			overlay("message", "Abrís los ojos en la cama. Afuera todavía está oscuro. La sábana se te enredó en un tobillo.", "Espacio · incorporarte")
		else:
			valley.morning()
			stage = 10
			awaiting_call = true
			valley.dress_day27()
			save_game(true, "walk")
			day_card("Día 27 · La cantera", "Abrís los ojos. El libro de tu viejo está abierto en el piso, al lado de la cama. En el margen de Saturno hay dos círculos a lápiz. Pasás el pulgar por el más chico. Junto al despertador anotaste el próximo turno de radio. Por un segundo te parece que es la hora de llevar a tu viejo al hospital.", "Espacio · levantarse"))

func show_first_dream_wake():
	overlay("first_dream_wake", "Abrís los ojos. Afuera sigue oscuro. Tardás un rato en reconocer el techo. Al mover las piernas, te sorprende el peso de la sábana. Buscás el cuaderno a tientas.", "E · anotar lo que recordás")
	shade.color = Color.BLACK
	fade_in_caption()

func fade_in_caption():
	words.modulate.a = 0.0
	hint.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(words, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	fade.parallel().tween_property(hint, "modulate:a", 1.0, 0.8).set_delay(0.15)

func start_day36():
	score.silence(3.0)
	stage = 16
	bedtime = false
	awaiting_call = true
	player.position = Vector3(1.37, 0.06, 4.55)
	player.rotation.y = 0.0
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	storm_return_seconds = 0.0
	rain_strength = Climate.rain(stage, player.position)
	valley.morning()
	valley.dress_day36()
	save_game(true, "walk")
	day_card("Día 36 · La crecida", "Guardás el mapa al regresar al puesto. Ya se escucha el agua en el techo.\n\nLa lluvia sigue varios días. Esta mañana hay barro en el escalón y el agua del alero golpea contra la tierra.", "Espacio · levantarse")

func book_has_ribbon() -> bool:
	return "cinta verde" in str(keepsakes.get("puesto", ""))

func open_book():
	overlay("book", "", "")
	var book_memory := str(keepsakes.get("libro", ""))
	book_view.open("imprenta grande" in book_memory, book_has_ribbon(), stage >= 8, book_memory.begins_with("La copiás a lápiz"))

func open_desk_paper(paper: StaticBody3D, art: Texture2D):
	held_desk_paper = paper
	paper.visible = false
	paper.collision_layer = 0
	overlay("desk_paper", "", "")
	postcard_view.inspect(art)

func turn_book(step: int):
	book_view.turn(step)
	if book_view.page == 3 and not book_light_notes:
		book_light_notes = true
		field_note += " Comparé en Observar el Cielo el rumbo de los destellos del abra. Dejé dos marcas en un papel entre las páginas."
		save_game(true, "walk")

func enter_cave():
	hands.show_map(false)
	if not is_instance_valid(cave):
		cave = LastNight.build_cave(valley)
		return_terrain = ReturnTerrain.new()
		cave.add_child(return_terrain)
		return_terrain.position.z = LastNight.EXIT_Z
	valley.begin_cave_light()
	valley.cave_light(1.0)
	ambience.cave_air.position = LastNight.cave_point(Vector3(0.0, -2.0, -30.0))
	player.camera.far = NIGHT_SCENE_VIEW
	cave_outside = false
	cave_entry_clear = false
	cave_station_called = false
	cave_rope_cut = false
	cave_rope_reply_pending = false
	cave_rope_in_use = false
	cave_notebooks_read = false
	cave_exit_open = false
	tunnel_call_step = 0
	crux_found = false
	return_walk_seconds = 0.0
	compass_lost = false
	night_home = 0
	cave_checkpoint = LastNight.ENTRY
	return_foot = LastNight.RETURN_START
	cave_static_seconds = 0.0
	player.intro_center = LastNight.CAVE
	player.scene_bounds = LastNight.BOUNDS
	player.intro_heading = LastNight.HEADING
	player.position = LastNight.cave_point(LastNight.ENTRY)
	player.rotation.y = LastNight.HEADING
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	flashlight_out = false
	resume_cave()
	conversation([
		{"speaker": "Hernán", "text": "Mara, las perdí. Hay una abertura en la piedra."},
		"No conozco esa ladera. Si vas a acercarte, alumbrá el suelo y avisame."
	], "cave_intro")

func resume_cave():
	walk()
	mode = "cave"
	target = ""

func update_night_target():
	var hit = player.ray.get_collider()
	target = str(hit.get_meta("item", "")) if hit else ""

func update_cave(allow_call: bool = true):
	var local: Vector3 = LastNight.cave_local(player.position)
	if cave_rope_in_use and not cave_rope_cut and local.y <= LastNight.ROPE_BREAK_Y:
		cave_rope_cut = true
		player.drop_from_rope()
		LastNight.cut_descent(cave)
		ambience.play_rope_snap(LastNight.cave_point(Vector3(0, LastNight.ROPE_BREAK_Y, LastNight.DROP_Z)))
	if cave_rope_in_use and not player.rope_climbing:
		player.remove_collision_exception_with(cave.get_node("BordeDelPozo"))
		cave_rope_in_use = false
	if local.y < LastNight.LOWER_FLOOR - 4.0:
		player.position = LastNight.cave_point(return_foot if cave_outside else cave_checkpoint)
		player.velocity = Vector3.ZERO
		return
	if cave_exit_open and tunnel_call_step < 2 and local.z < LastNight.EXIT_Z + 0.85:
		local.z = LastNight.EXIT_Z + 0.85
		player.position = LastNight.cave_point(local)
		player.velocity.z = 0.0
	if cave_exit_open and local.z < LastNight.EXIT_Z + 21.0:
		return_terrain.follow(local - Vector3(0, 0, LastNight.EXIT_Z))
	if cave_exit_open and local.z < LastNight.EXIT_Z:
		if not cave_outside:
			score.cue("cosmic", -14.0, 4.2, true)
			cave_outside = true
			compass_lost = true
			compass_out = false
			if allow_call: hands.hold("")
			player.scene_bounds = Rect2()
		valley.cave_light(0.50)
		if allow_call: update_night_return(local)
		return
	if cave_outside:
		# El paredón deja volver por la boca del túnel.
		if absf(local.x) > 2.65:
			local.z = LastNight.EXIT_Z - 0.5
			player.position = LastNight.cave_point(local)
			player.velocity.z = 0.0
			return
		cave_outside = false
		var bounds := LastNight.BOUNDS
		if absf(local.x) < bounds.size.x * 0.5: player.scene_bounds = bounds
	if not cave_entry_clear and local.z < LastNight.ENTRY_LIMIT_Z:
		local.z = LastNight.ENTRY_LIMIT_Z
		player.position = LastNight.cave_point(local)
		player.velocity.z = 0.0
	var mouth_light := smoothstep(-12.4, 3.0, local.z)
	var exit_light := 0.50 * (1.0 - smoothstep(0.0, 14.0, local.z - LastNight.EXIT_Z))
	valley.cave_light(maxf(mouth_light, exit_light))
	if local.z < LastNight.MOUTH_Z and not compass_lost and (score.playing_cue != "misterio" or not score.is_playing()):
		score.cue("misterio", -19.0, 4.0, true)
	if allow_call and cave_rope_cut and cave_checkpoint != LastNight.CHECKPOINT and player.is_on_floor() and local.y < -5.0:
		cave_checkpoint = LastNight.CHECKPOINT
		cave_rope_reply_pending = true
		conversation(["¿Hernán? Oí un golpe. ¿Estás bien?"], "cave_rope")
		return
	if local.z < LastNight.TUNNEL_Z and not cave_exit_open:
		local.z = LastNight.TUNNEL_Z
		player.position = LastNight.cave_point(local)
		player.velocity.z = 0.0
	if not allow_call: return
	if cave_exit_open and tunnel_call_step < 2:
		var threshold := -95.0 if tunnel_call_step == 0 else -126.0
		if local.z < threshold:
			tunnel_call_step += 1
			radio.play_interference()
			if tunnel_call_step == 1:
				conversation([
					{"speaker": "Hernán", "text": "El cable sigue por el túnel. ¿Me copiás?"},
					"Te copio por partes. Seguí hablándome si podés."
				], "cave_tunnel")
			else:
				conversation(["Me volvió a entrar tu «¿me copiás?». ¿Apretaste de nuevo? Hernán, si me escuchás…"], "cave_tunnel")
			return
	update_night_target()
	if target == CaveRunes.TITLE and not flashlight_out: target = ""
	if collect_notice_seconds > 0.0:
		hint.text = collect_notice
	elif target == CaveRunes.TITLE:
		hint.text = "Signos copiados en el cuaderno" if found_collectibles.has(CaveRunes.ID) else "E · copiar los signos"
	elif cave_rope_reply_pending:
		hint.text = "R · contestarle a Mara"
	elif not target.is_empty():
		hint.text = "E · leer la chapa" if target == LastNight.ENTRY_PLATE else "E · " + target
	elif not cave_entry_clear and local.z < 5.7:
		hint.text = "Hay una chapa atornillada junto a la boca."
	elif local.z < LastNight.TUNNEL_Z + 3.0 and not cave_exit_open:
		hint.text = "R · Contale a Mara lo de los cuadernos" if cave_notebooks_read else "Revisá el cuaderno en la mesa."
	elif objective_seconds > 0.0:
		if cave_exit_open: hint.text = "Seguí el cable por el túnel."
		elif cave_notebooks_read: hint.text = "R · Contale a Mara lo que encontraste."
		elif local.y < -5.0: hint.text = "Buscá los cuadernos de la estación."
		elif local.z < -5.0: hint.text = "Buscá el anclaje de la cuerda junto al borde."
		else: hint.text = "L · linterna"
	else:
		hint.text = "L · encender la linterna" if not flashlight_out else ""

func update_night_return(local: Vector3):
	if player.is_on_floor():
		return_foot = local + Vector3.UP * 0.03
	target = ""
	hint.text = collect_notice if collect_notice_seconds > 0.0 else ""
	if not crux_found:
		if hint.text.is_empty() and can_recognize_crux(): hint.text = "Cruz del Sur · E · reconocer"

func advance_return_walk(delta: float, grounded: bool):
	var step: Vector3 = (player.position - return_last_position).slide(Vector3.UP)
	return_last_position = player.position
	if grounded and delta > 0.0 and step.length() > delta * 0.6 and step.normalized().dot(return_heading) > 0.78:
		return_walk_seconds += delta
	if return_walk_seconds >= 30.0: reach_refuge()

func can_recognize_crux() -> bool:
	if not looking_at_crux(): return false
	var eye: Vector3 = player.camera.global_position
	return player.raycast_surface(eye, eye + crux_axis() * NIGHT_SCENE_VIEW).is_empty()

func recognize_crux():
	crux_found = true
	var sidereal := SkyGuide.sidereal_at(valley.sky_chapter, calendar_day())
	var pole := SkyGuide.pole_from_crux(sidereal)
	return_heading = Vector3(pole.x, 0.0, pole.z).normalized()
	return_last_position = player.position
	valley.sky_mat.set_shader_parameter("crux_pole", pole)
	var trace := create_tween().set_trans(Tween.TRANS_SINE)
	trace.tween_method(func(progress: float): valley.sky_mat.set_shader_parameter("crux_trace", progress), 0.0, 1.0, 1.9)

func reach_refuge():
	overlay("cave_home", "", "")
	player.walking = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shade.color = Color(0, 0, 0, 0)
	var fade := create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property(shade, "color:a", 1.0, 3.6)
	await fade.finished
	player.walking = false
	valley.sky_mat.set_shader_parameter("crux_trace", 0.0)
	cave.queue_free()
	cave = null
	return_terrain = null
	cave_outside = false
	player.intro_center = Vector3.ZERO
	player.intro_heading = 0.0
	player.scene_bounds = player.DEFAULT_SCENE_BOUNDS
	player.camera.far = valley_view_distance
	player.position = Vector3(-0.48, 0.08, -1.78)
	player.rotation.y = PI
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	flashlight_out = false
	valley.end_cave_light()
	collect_notice_seconds = 0.0
	night_home = 1
	bedtime = false
	save_game(true, "walk")
	var reveal := create_tween().set_trans(Tween.TRANS_SINE)
	reveal.tween_property(shade, "color:a", 0.0, 2.25)
	await reveal.finished
	walk()

func call_from_cave():
	if cave_rope_reply_pending:
		cave_rope_reply_pending = false
		conversation([hernan("Estoy bien. Se cortó la cuerda y caí al fondo. Por acá ya no puedo subir."),
			"Quedate un segundo donde caíste. Cuando estés firme, alumbrá alrededor. Decime si ves por dónde sigue."], "cave_rope")
		return
	var local: Vector3 = LastNight.cave_local(player.position)
	if cave_outside or tunnel_call_step == 2:
		hands.hold("radio")
		hands.press_button()
		radio.play_interference()
		cave_static_seconds = 1.5
		return
	var line := "Mara · Te copio. Andá con cuidado y avisame si cambia algo."
	if local.z > LastNight.MOUTH_Z and not cave_entry_clear:
		line = "Mara · No alcanzo a ver la abertura desde acá. ¿Hay algo en la entrada que te diga qué es?"
	elif local.y < -5.0:
		line = "Mara · Te escucho. ¿Encontraste por dónde seguir?"
		if cave_notebooks_read and not cave_station_called and local.z < -58.0:
			cave_station_called = true
			conversation([
				{"speaker": "Hernán", "text": "Hay un receptor de radio y cuadernos de los años 70. Anotaban las luces. El dial está marcado en el tres, como el nuestro."},
				"¿Nuestro canal? Fijate si del receptor sale un cable. Si entra en otra galería, puede llevarte hacia afuera.",
				{"speaker": "Hernán", "text": "Sí. Va pegado a la pared del fondo. Voy por ahí."},
				"Dejá prendida la radio. Si perdés la señal, buscá por dónde corre el aire."
			], "cave_station")
			hands.press_button()
			return
		if cave_station_called: line = "Mara · Te sigo copiando. ¿Todavía ves el cable?"
	radio.play()
	overlay("cave_text", line, "Espacio · guardar la radio", "radio")

func inspect_cave():
	if cave_outside:
		if not crux_found and can_recognize_crux(): recognize_crux()
		return
	match target:
		LastNight.ENTRY_PLATE:
			if cave_entry_clear: return
			conversation([
				{"speaker": "Hernán", "text": "Hay una chapa vieja al lado de la entrada. Dice «Sector 08»."},
				"¿Sector 08? Nunca oí ese nombre. Yo esperaría hasta mañana. No sabemos qué hay ahí."
			], "cave_plate")
		CaveRunes.TITLE:
			if flashlight_out: record_cave_runes()
		"Cuerda de descenso":
			cave_rope_in_use = true
			player.add_collision_exception_with(cave.get_node("BordeDelPozo"))
			player.climb_rope(LastNight.descent_route(), LastNight.HEADING + PI)
		"Receptor":
			radio.play_knocks()
			overlay("cave_text", "En el dial está marcada la frecuencia del puesto. Lo girás y oís dos golpes secos. La aguja se queda inmóvil.", "Espacio · soltar")
		"Cuaderno de observación":
			cave_notebook_page = 0
			show_cave_notebook()

func show_cave_notebook():
	if cave_notebook_page >= 1:
		cave_notebooks_read = true
		night_investigation = 2
	overlay("cave_notebook", "", "")
	journal_view.display(CAVE_NOTEBOOK[cave_notebook_page], cave_notebook_page, CAVE_NOTEBOOK.size(), Diary.Section.DIARY, false)

func show_camp_notebook():
	overlay("camp_notebook", "", "")
	journal_view.display(CAMP_NOTEBOOK[camp_notebook_page], camp_notebook_page, CAMP_NOTEBOOK.size(), Diary.Section.DIARY, false, "Tab · dejar")

func pack_item(label: String) -> bool:
	if stage != 19 or packed_items.size() == Departure.PACK_ITEMS.size(): return false
	var index := Departure.PACK_ITEMS.find(label)
	if index < 0 or packed_items.has(index): return false
	if not departure_briefed:
		objective_seconds = 4.0
		return true
	packed_items.append(index)
	update_departure()
	collect_notice = "Mochila lista. Elvira te dejó un libro en el museo." if packed_items.size() == Departure.PACK_ITEMS.size() else "Guardaste " + Departure.PACK_NAMES[index] + "."
	collect_notice_seconds = 3.0
	save_game(true, "walk")
	return true

func advance_elvira_book():
	if book_view.page < 2:
		book_view.turn(1)
		return
	book_view.hide()
	elvira_book_taken = true
	elvira_book.queue_free()
	elvira_book = null
	walk()
	update_departure()
	objective_seconds = 5.0
	save_game(true, "walk")

func update_departure():
	if stage != 19 or mode not in ["walk", "map"]: return
	var packed := packed_items.size() == Departure.PACK_ITEMS.size()
	if not packed and valley.wall_sketches.is_empty(): valley.hang_sketch(0, Diary.ARRIVAL_BRIDGE)
	valley.update_packing(packed_items, true)
	if packed and departure_briefed and not elvira_book_taken and not is_instance_valid(elvira_book):
		elvira_book = Museum.build_elvira_book(valley)
	if elvira_book_taken and not departure_path_open:
		Departure.open(valley)
		departure_path_open = true
	if departure_destination in ["fork", "bus"] and Departure.near(player.position, Departure.MARA_END, 3.75):
		departure_destination = "mara" if can_visit_mara() and departure_destination == "fork" else "bus"
		finish_departure_walk()
	elif departure_destination in ["fork", "bus"] and Departure.near(player.position, Departure.END, 3.75):
		departure_destination = "bus"
		finish_departure_walk()
	elif departure_destination == "mara" and Departure.near(player.position, Departure.MARA_END, 3.75):
		finish_departure_walk()

func choose_departure(destination: String):
	departure_destination = destination
	walk()
	if mode == "map": refresh_map_goal()
	objective_seconds = 6.0
	save_game(true, "walk")

func finish_departure_walk():
	overlay("departure_fade", "", "")
	shade.color = Color(0, 0, 0, 0)
	var fade := create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property(shade, "color:a", 1.0, 2.0)
	await fade.finished
	place_departure_scene(departure_destination)
	save_game(true, mode)
	shade.show()
	var reveal := create_tween().set_trans(Tween.TRANS_SINE)
	reveal.tween_property(shade, "color:a", 0.0, 1.35)
	await reveal.finished
	shade.hide()

func place_departure_scene(destination: String):
	walk()
	player.velocity = Vector3.ZERO
	player.intro_heading = 0.0
	target = ""
	var is_mara := destination == "mara"
	Arrival.show_fragment(valley, -1 if is_mara else 0)
	if is_instance_valid(mara_yard):
		mara_yard.visible = is_mara
		mara_yard.process_mode = Node.PROCESS_MODE_INHERIT if is_mara else Node.PROCESS_MODE_DISABLED
	if is_mara:
		if not is_instance_valid(mara_yard): mara_yard = Departure.mara(valley)
		Departure.isolate(mara_yard)
		player.intro_center = mara_yard.position
		player.scene_bounds = Departure.MARA_BOUNDS
		player.position = mara_yard.to_global(Departure.MARA_START)
		player.rotation.y = 0.22
		mode = "mara_door"
	else:
		var roadside: Node3D = valley.arrival_fragments[0]
		set_arrival_bag_visible(false)
		player.position = Departure.bus(roadside)
		Departure.isolate(roadside)
		player.intro_center = roadside.position
		player.scene_bounds = Departure.BUS_BOUNDS
		player.rotation.y = 1.94
		mode = "departure_bus"
	player.camera.cull_mask = Departure.SCENE_LAYER
	player.camera.rotation = Vector3.ZERO
	departure_scene = destination

func finish_at_door(at_mara: bool):
	mode = "departure_door"
	player.walking = false
	player.looking_only = true
	cross.hide()
	hint.text = ""
	if at_mara:
		var hinge := mara_yard.get_node("Bisagra de la puerta de Mara") as Node3D
		var knocks := AudioStreamPlayer3D.new()
		knocks.stream = radio.knocks.stream
		knocks.max_distance = 8.0
		knocks.volume_db = 1.5
		hinge.add_child(knocks)
		knocks.position = Vector3(0.76, 1.19, 0.06)
		knocks.finished.connect(knocks.queue_free)
		knocks.play()
		await get_tree().create_timer(0.82).timeout
		var door := create_tween().set_trans(Tween.TRANS_SINE)
		door.tween_property(hinge, "rotation:y", deg_to_rad(12.0), 1.06)
		await get_tree().create_timer(0.61).timeout
	else:
		var roadside: Node3D = valley.arrival_fragments[0]
		await Coach.open_door(roadside.get_node("Ómnibus")).finished
		await get_tree().create_timer(0.92).timeout
	shade.color = Color(0, 0, 0, 0)
	shade.show()
	var fade := create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property(shade, "color:a", 1.0, 1.15)
	await fade.finished
	ending_at_door = at_mara
	save_game(true, "end")
	show_ending()

func crux_axis() -> Vector3:
	var sidereal := SkyGuide.sidereal_at(valley.sky_chapter, calendar_day())
	return (SkyGuide.direction(SkyGuide.STARS[0], sidereal) + SkyGuide.direction(SkyGuide.STARS[2], sidereal)).normalized()

func looking_at_crux() -> bool:
	return (-player.camera.global_basis.z).dot(crux_axis()) > cos(deg_to_rad(11.0))

func can_pause_under_sky() -> bool:
	var outdoors: bool = player.position.z < -0.5 or absf(player.position.x) > 3.6
	var day := calendar_day()
	return outdoors and target.is_empty() and SKY_MEMORIES.has(day) and not day in sky_memories and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6 and (-player.camera.global_basis.z).y > 0.32

func watching_crux_tonight() -> bool:
	return calendar_day() in [25, 32]

func can_watch_sky() -> bool:
	return can_pause_under_sky() and (not watching_crux_tonight() or looking_at_crux())

func watch_sky():
	var day := calendar_day()
	sky_memories.append(day)
	flashlight_out = false
	if not score.is_playing():
		score.cue("noche", -17.0)
	overlay("message", SKY_MEMORIES[day], "Espacio · seguir")

func hear_last_voice():
	radio.play_interference()
	show_dream_voice("last_voice", "Voz", "¿Ya la encontraste?", ["«¿Quién es…?»", "«¿Papá…?»"])

func show_ending():
	var memory_of_book := str(keepsakes.get("libro", "El lomo cruje como la primera noche en que lo abriste."))
	ending_paragraphs = [
		"Subís al ómnibus. Desde el asiento ves la curva que baja al puesto. Antes de que desaparezca, abrís Observar el Cielo. " + memory_of_book,
		"La radio va apagada en tu mochila. Justo al doblar oís dos golpes secos."
	]
	if ending_at_door:
		ending_paragraphs = [
			"Del otro lado cruje una tabla. La puerta se entorna. Bajás la mano.",
			"Te quedás en el escalón. Por primera vez, vas a hablarle sin buscar el botón de la radio."
		]
	else:
		var closing := "Cuando vuelvas a dar clase, querés llevar el libro. Pensás empezar por pedirles que dibujen lo primero que ven."
		if last_voice_reply == 1:
			closing = "Por un instante, al pensar en tu papá, oís la pregunta de siempre. Abrís la mano sobre las cuatro estrellas. Pensás llevar el libro cuando vuelvas a dar clase."
		ending_paragraphs.insert(1, closing)
	ending_paragraph = 0
	show_ending_paragraph()

func show_ending_paragraph():
	var last := ending_paragraph + 1 == ending_paragraphs.size()
	overlay("end", ending_paragraphs[ending_paragraph], "" if last else "Espacio · seguir")
	shade.color = Color.BLACK
	if ending_fade and ending_fade.is_valid(): ending_fade.kill()
	words.modulate.a = 0.0
	ending_fade = create_tween()
	ending_fade.tween_property(words, "modulate:a", 1.0, 0.85)
	if last:
		ending_fade.tween_interval(maxf(5.2, words.text.length() / 16.0))
		ending_fade.tween_property(words, "modulate:a", 0.0, 1.30)
		ending_fade.tween_callback(show_credits)

func show_credits():
	mode = "credits"
	ending_fade = create_tween()
	for card in ["FIN", "Un juego de Ignacio Aragües", "URITORCO"]:
		ending_fade.tween_interval(0.45)
		ending_fade.tween_callback(func(): words.text = card)
		ending_fade.tween_property(words, "modulate:a", 1.0, 1.25)
		ending_fade.tween_interval(2.8 if card == "FIN" else 4.0)
		ending_fade.tween_property(words, "modulate:a", 0.0, 1.30)
	ending_fade.tween_callback(func(): get_tree().reload_current_scene())

func resume_play():
	menu.hide()
	match paused_from:
		"intro": memory(recall.paragraph)
		"approach": approach()
		"dream": explore_dream()
		_: walk()

func save_game(automatic: bool, resume_mode: String) -> bool:
	if debug_run: return false
	var state: Dictionary = {}
	for key in STATE: state[key] = get(key)
	if stage < 0 and page == 0:
		state["intro_look_done"] = intro_look_done
		state["intro_objectives_seen"] = intro_objectives_seen
	state["abra_told_mara"] = abra_told_mara
	state["mara_heard_paula"] = mara_heard_paula
	state["paula_clipping_read"] = paula_clipping_read
	state["flag_raised"] = flag_raised
	if resume_mode in ["mate_morning", "mate_radio"]: state["mate_outdoors"] = true
	if stage == 19:
		state["packed_items"] = packed_items.duplicate()
		state["departure_destination"] = departure_destination
		state["departure_briefed"] = departure_briefed
		state["elvira_book_taken"] = elvira_book_taken
	if spare_compass_taken: state["spare_compass_taken"] = true
	if fossil_sketched: state["fossil_sketched"] = true
	if stage in [13, 14]:
		state["camp_reported"] = camp_reported
		state["camp_observations"] = camp_observations.duplicate()
	if stage == 5:
		state["creek_return_left"] = creek_return_left
		state["creek_evening_call"] = creek_evening_call
	if stage == 7: state["abra_sequence"] = true
	if stage == 18:
		state["storm_return_seconds"] = storm_return_seconds
		if last_night:
			state["day40_seconds_left"] = day40_seconds_left
			state["day40_interlude_done"] = day40_interlude_done
	if trail_spacing_day == calendar_day():
		if trail_walk_left > 0.0: state["trail_walk_left"] = trail_walk_left
		if trail_quiet_left > 0.0: state["trail_quiet_left"] = trail_quiet_left
	if resume_mode == "dream":
		state["dream_seconds_left"] = dream_seconds_left
		state["dream_symbols_found"] = dream_symbols_found
		state["dream_arch_visits"] = dream_arch_visits.duplicate()
	var title: String = "Llegada" if stage < 0 else ("Noche 1" if stage == 0 else ("Día 2" if stage < 6 else ("Día 7" if stage < 8 else "Día 25")))
	if stage >= 19: title = "Día 41"
	elif stage >= 16: title = "Día 40" if last_night else "Día 36"
	elif stage >= 13: title = "Día 32"
	elif stage >= 10: title = "Día 27"
	var data = {"version": 1, "slot": slot, "title": title, "state": state, "mode": resume_mode, "pose": player.transform, "pitch": player.camera.rotation.x, "paragraph": recall.paragraph, "chapter": valley.sky_chapter, "museum_offset": Museum.SITE_OFFSET, "south_crossing": true, "stop_verge": Arrival.STOP_LAYOUT, "rain": rain_strength, "light_target": valley.light_target, "light_left": valley.remaining_light_transition(), "door": valley.door_open, "book": valley.book_unpacked, "night": valley.sky_mat.get_shader_parameter("nightfall"), "dusk": valley.sky_mat.get_shader_parameter("dusk"), "music": score.position_of("prologo")}
	data["curtains_open"] = valley.curtains_open
	data["dusk_left"] = valley.remaining_dusk_transition()
	data["nightfall_delay"] = valley.remaining_nightfall_delay()
	return Saves.write(slot, automatic, data)

func restore(data: Dictionary):
	score.silence(0.2)
	slot = data.slot
	for key in STATE:
		if data.state.has(key): set(key, data.state[key])
	flag_raised = bool(data.state.get("flag_raised", stage >= 1))
	valley.set_flag(flag_raised)
	spare_compass_taken = bool(data.state.get("spare_compass_taken", false))
	fossil_sketched = bool(data.state.get("fossil_sketched", false))
	packed_items = data.state.get("packed_items", []).duplicate()
	departure_destination = str(data.state.get("departure_destination", ""))
	if stage == 19 and not data.state.has("packed_items") and not Departure.near(data.pose.origin, Vector3.ZERO, 10.0):
		packed_items = [0, 1, 2, 3]
	if stage == 19:
		var past_museum: bool = not departure_destination.is_empty() or data.pose.origin.z > 17.0
		departure_briefed = bool(data.state.get("departure_briefed", past_museum))
		elvira_book_taken = bool(data.state.get("elvira_book_taken", past_museum))
		bedtime = false
		awaiting_call = false
	valley.update_spare_compass(stage == 19, spare_compass_taken)
	day40_seconds_left = clampf(float(data.state.get("day40_seconds_left", 0.0 if last_night else -1.0)), -1.0, DAY40_SECONDS)
	day40_interlude_done = bool(data.state.get("day40_interlude_done", false))
	abra_told_mara = bool(data.state.get("abra_told_mara", "Se lo conté a Mara." in str(data.state.get("field_note", ""))))
	mara_heard_paula = bool(data.state.get("mara_heard_paula", false))
	paula_clipping_read = bool(data.state.get("paula_clipping_read", false))
	valley.sky_mat.set_shader_parameter("paula_star_visible", paula_clipping_read)
	camp_reported = bool(data.state.get("camp_reported", camp_read))
	camp_observations = data.state.get("camp_observations", {}).duplicate()
	creek_return_left = clampf(float(data.state.get("creek_return_left", -1.0)), -1.0, CREEK_RETURN_SECONDS)
	creek_evening_call = bool(data.state.get("creek_evening_call", false))
	found_collectibles = data.state.get("found_collectibles", {}).duplicate()
	nature_notes = data.state.get("nature_notes", {}).duplicate()
	remove_collected_objects()
	trail_replies = Mara.saved_replies(data.state)
	trail_spacing_day = calendar_day()
	trail_walk_left = clampf(float(data.state.get("trail_walk_left", 0.0)), 0.0, Mara.distance_between_calls(trail_spacing_day))
	trail_quiet_left = clampf(float(data.state.get("trail_quiet_left", 0.0)), 0.0, Mara.seconds_between_calls(trail_spacing_day))
	if not data.state.has("filo_report_reply"):
		if "Recomendás la vaguada." in field_note: filo_report_reply = 0
		elif "Avisás del escalón." in field_note: filo_report_reply = 1
	if stage == 3: stage = 4
	menu.hide()
	player.camera.current = true
	player.transform = data.pose
	if not data.has("museum_offset"):
		player.position = Museum.restore_legacy_position(valley, player.position)
	if stage in [16, 17, 18] and not data.get("south_crossing", false):
		player.position = restore_crossing_position(player.position)
	var north_distance: float = valley.route.ORIGIN_Z - player.position.z
	if stage >= 0 and absf(north_distance - 96.0) < 8.8:
		var ground: Vector3 = valley.route.surface_point(player.position.x, north_distance)
		player.position.y = maxf(player.position.y, ground.y + 0.048)
	if stage >= 0 and data.mode == "walk" and Creek.access_relief(player.position.x, player.position.z) > 0.01:
		var ground := Creek.surface_point(player.position)
		if player.position.y < ground.y - 0.035: player.position.y = ground.y + 0.048
	player.camera.rotation.x = data.pitch
	valley.configure_sky(data.chapter)
	valley.morning()
	if stage >= 10:
		valley.dress_day27()
		if stage >= 11: valley.quarry_plate.rotation.y = 0.9
	if stage >= 16: valley.dress_day36()
	if stage >= 13:
		valley.dress_day32()
		remove_collected_objects()
		if camp_read: summit_mapped = true
	radio_taken = data.state.get("radio_taken", stage > 0 or (stage == 0 and heard))
	bag_left = data.state.get("bag_left", stage == 0 and heard)
	intro_look_done = bool(data.state.get("intro_look_done", false))
	intro_objectives_seen = bool(data.state.get("intro_objectives_seen", false))
	valley.set_desk_note(stage <= 0)
	valley.update_desk_radio(radio_taken)
	if stage >= 1:
		valley.unpack_book(book_has_ribbon())
	elif stage == 0:
		if bag_left: valley.leave_bag()
		bedtime = heard and bag_left
		valley.set_bag_drop(heard and not bag_left)
		if not heard: first_call_wait = FIRST_CALL_DELAY
	if stage < 0:
		score.cue("prologo", -12.0, 2.6, true)
		score.seek_to(float(data.get("music", 0.0)))
	if data.door: operate_refuge_door()
	valley.set_curtains(bool(data.get("curtains_open", true)), false)
	var dusk_value: Variant = data.get("dusk")
	var night_value: Variant = data.get("night")
	var saved_dusk := clampf(float(dusk_value) if dusk_value != null else 0.0, 0.0, 1.0)
	var saved_night := clampf(float(night_value) if night_value != null else 0.0, 0.0, 1.0)
	var legacy_abra: bool = stage == 7 and not data.state.get("abra_sequence", false) and not second_sighting
	if legacy_abra:
		day7_dusk = false
		saved_dusk = 0.0
		saved_night = 0.0
	var old_storm_return := Climate.STORM_CLEAR_SECONDS if stage == 18 else 0.0
	storm_return_seconds = clampf(float(data.state.get("storm_return_seconds", old_storm_return)), 0.0, Climate.STORM_CLEAR_SECONDS)
	rain_strength = clampf(float(data.get("rain", Climate.rain(stage, player.position, storm_return_seconds))), 0.0, 1.0)
	mist_strength = Climate.local_mist(calendar_day(), player.position)
	valley.restore_light(maxf(saved_dusk, saved_night), saved_night)
	var seconds := 0.0 if legacy_abra else float(data.get("light_left", 0.0))
	if seconds > 0.01 and data.get("light_target") == "night":
		# Los guardados anteriores tenían 30 segundos entre el fin del ocaso y la noche cerrada.
		var old_dusk := maxf(0.1, seconds - 30.0) if stage == 18 else 14.0
		var dusk_left := maxf(0.1, float(data.get("dusk_left", old_dusk)))
		valley.night(seconds, dusk_left, float(data.get("nightfall_delay", 0.0)))
	elif seconds > 0.01 and data.get("light_target") == "dusk":
		valley.sunset(seconds)
	elif stage == 7 and day7_dusk and not second_sighting and saved_night < 1.0:
		valley.night(ABRA_NIGHT_SECONDS * (1.0 - saved_night), 28.0)
	elif stage == 15 and saved_night < 1.0:
		valley.night(maxf(1.0, SUMMIT_NIGHT_SECONDS * (1.0 - saved_night)))

	match str(data.mode):
		"day40_card": show_day40_card()
		"mara_door": place_departure_scene("mara")
		"departure_bus": place_departure_scene("bus")
		"mate_morning", "mate_radio":
			if stage == 13:
				var initial: bool = absf(player.position.x) < 3.35 and player.position.z > 0.0 and not data.state.has("mate_outdoors")
				if initial: show_mate_morning()
				else: show_mate_morning(data.mode, player.position)
			else: start_day25()
		"first_dream_wake": show_first_dream_wake()
		"end": show_ending()
		"intro":
			player.intro_center = Arrival.origin(page)
			if player.position.distance_to(player.intro_center) > 80: player.position = player.intro_center
			memory(data.paragraph)
		"approach":
			var old_stop_spawn: bool = page == 0 and not arrival_action and int(data.get("stop_verge", 0)) < Arrival.STOP_LAYOUT
			if not old_stop_spawn and player.position.distance_to(Arrival.origin(page)) <= 80.0:
				player.position = Arrival.safe_saved_position(page, player.position, arrival_action)
			approach(old_stop_spawn)
		"dream":
			dream_symbols_found = bool(data.state.get("dream_symbols_found", false))
			if dream_variant() < 3: has_piece = false
			dream_seconds_left = clampf(float(data.state.get("dream_seconds_left", DREAM_SECONDS)), 0.0, DREAM_SECONDS)
			restore_dream_arches(data.state)
			score.cue("otromundo", -14.0, 2.5, true)
			player.low_gravity = true
			valley.strange_sky(dream_variant())
			explore_dream()
			recover_saved_dream_position()
		_: walk()

func recover_saved_dream_position():
	await get_tree().physics_frame
	if mode != "dream" or player.capsule_has_room(player.position + Vector3.UP * 0.08): return
	var variant := dream_variant()
	var local := Vector2(player.position.x - LastNight.PLANET.x, player.position.z - LastNight.PLANET.z)
	for radius: float in [0.85, 1.7, 3.4, 6.8]:
		for direction in 8:
			var candidate := local + Vector2.RIGHT.rotated(TAU * direction / 8.0) * radius
			if not LastNight.DREAM_BOUNDS.has_point(candidate): continue
			var foot := LastNight.dream_surface(variant, candidate) + Vector3.UP * 0.1
			if player.capsule_has_room(foot):
				player.position = foot
				player.velocity = Vector3.ZERO
				return
	player.position = LastNight.dream_point(variant, clampf(-local.y, 0.0, 135.0)) + Vector3.UP * 0.16
	player.velocity = Vector3.ZERO

func restore_crossing_position(position: Vector3) -> Vector3:
	var here := Vector2(position.x, position.z)
	var last := Vector2.ZERO
	var nearest := 34.0 * 34.0
	var progress := -1.0
	for i in 65:
		var old := Trail.legacy_crossing_point(i / 64.0)
		var point := Vector2(old.x, old.z)
		if i > 0:
			var projection := Geometry2D.get_closest_point_to_segment(here, last, point)
			var distance := projection.distance_squared_to(here)
			if distance < nearest:
				nearest = distance
				progress = (i - 1 + last.distance_to(projection) / last.distance_to(point)) / 64.0
		last = point
	if progress < 0.0: return position
	if stage == 16 and progress < 0.97:
		var path := Creek.crossing_point(progress)
		var side := South.forward(progress).cross(Vector3.UP) * 3.4
		return South.ground(path + side) + Vector3.UP * 0.12
	return South.ground(Creek.crossing_point(1.0) + Vector3(0, 0, -2.0)) + Vector3.UP * 0.12

func start_day25():
	mode = "day25_transition"
	hint.text = ""
	var fade := create_tween()
	fade.tween_property(words, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	fade.tween_interval(0.35)
	await fade.finished
	stage = 8
	awaiting_call = true
	valley.configure_sky(3)
	valley.morning()
	save_game(true, "walk")
	day_card("Día 25 · La quebrada larga", "Hace días que usás el cuaderno para anotar las lecturas. Esta mañana lo abrís por la hoja donde dibujaste las estrellas del sueño. La dejás marcada. Sobre el escritorio está el libro de tu viejo. Todavía podés comparar el rumbo de los destellos del abra. Hoy Mara te espera en la radio.", "Espacio · levantarse")
	mode = "day25_card"
	fade_in_caption()

func in_refuge_room() -> bool:
	var at: Vector3 = player.position
	return absf(at.x) < 3.35 and at.z > 0.02 and at.z < 5.85

func operate_refuge_door():
	valley.toggle_door()
	if valley.door_open:
		door_side = 1 if player.position.z > valley.hinge.position.z else -1
		door_crossed = false

func update_refuge_door():
	if not valley.door_open or door_side == 0: return
	var at: Vector3 = player.position
	var threshold: float = valley.hinge.position.z
	var side := 1 if at.z > threshold else -1
	if side != door_side and absf(at.x + 0.51) < 0.82: door_crossed = true
	if not door_crossed: return
	var cleared_outside := side < 0 and at.z < threshold - 0.8
	var cleared_inside := side > 0 and (at.z > threshold + 2.80 or absf(at.x) > 1.5)
	if cleared_outside or cleared_inside:
		valley.toggle_door()
		if not valley.door_open:
			door_crossed = false
			door_side = 0

func show_mate_morning(resume := "", pos := Vector3.ZERO):
	walk()
	mode = "mate_morning" if resume.is_empty() else resume
	score.cue("calma2", -16.0)
	if resume.is_empty():
		player.position = Vector3(1.68, 0.03, -3.22)
		player.rotation.y = 2.13
		player.camera.rotation.x = -0.08
	else:
		player.position = pos
	player.velocity = Vector3.ZERO
	radio_taken = false
	valley.update_desk_radio(false)
	if not is_instance_valid(mate_receiver):
		mate_receiver = AudioStreamPlayer3D.new()
		valley.desk_radio.add_child(mate_receiver)
		mate_receiver.stream = radio.incoming.stream
		mate_receiver.max_distance = 21.0
		mate_receiver.volume_db = -4.0
	mate_called = false
	mate_call_left = 7.0 if mode == "mate_morning" else 1.0
	if mode == "mate_morning": hands.hold("mate")

func update_mate_morning(delta: float, inside: bool):
	mate_call_left -= delta
	if mate_call_left <= 0.0:
		mate_receiver.play()
		mate_called = true
		mate_call_left = 10.0
	var hit = player.ray.get_collider()
	var item: String = hit.get_meta("item", "") if hit else ""
	if item == "Puerta":
		hint.text = "E · abrir o cerrar"
	elif mode == "mate_radio":
		hint.text = "E · levantar la radio" if item == "Radio" and mate_called else "La radio está sobre el escritorio."
	elif inside:
		hint.text = "E · dejar el mate"
	else:
		hint.text = "La radio suena adentro del puesto." if mate_receiver.playing else ""

func take_mate_radio():
	mate_receiver.stop()
	radio_taken = true
	valley.update_desk_radio(true)
	walk()
	transmit()

func show_sighting(kind: Sighting = Sighting.ABRA):
	sighting = kind
	sighting_time = 0.0
	sighting_focus = 0.0
	sighting_resolving = false
	mode = "sighting"
	player.walking = true
	player.looking_only = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hands.show_map(false)
	hands.hold("")
	compass_out = false
	cross.show()
	overlay_choices.hide()
	radio_panel.hide()
	shade.hide()
	words.text = ""
	var center: Vector3
	match kind:
		Sighting.ABRA:
			center = valley.route.at(valley.route.trail(448) + 34.0, 448) + Vector3.UP * 60.0
			place_sighting_light(valley.second_beacon, center + Vector3(8, 12, -11))
			if float(valley.sky_mat.get_shader_parameter("nightfall")) < 0.71: valley.night(5.0)
		Sighting.QUARRY:
			center = valley.route.quarry_point(1.0) + Vector3(-12, 29, -54)
		Sighting.CROSSING:
			center = Creek.crossing_point(1.0) + Vector3(-33, 26, 24)
		Sighting.SHELTER:
			if not valley.beacon.visible or not valley.second_beacon.visible: place_last_night_lights()
	if kind != Sighting.SHELTER: place_sighting_light(valley.beacon, center)
	update_sighting(0.0)

func place_last_night_lights():
	var at: Vector3 = player.position
	var horizontal := Vector2(at.x, at.z)
	var center := Vector3(48.0, 25.0, -26.0)
	if horizontal.length() >= 24.0:
		var sector := horizontal.snapped(Vector2(120, 120))
		center = Vector3(sector.x + 94.0, maxf(at.y + 74.0, 86.0), sector.y - 92.0)
	place_sighting_light(valley.beacon, center)
	place_sighting_light(valley.second_beacon, center + Vector3(5, 3.2, 10))

func place_sighting_light(light: Sprite3D, center: Vector3):
	light.position = center
	var distance: float = player.camera.global_position.distance_to(center)
	light.pixel_size = clampf(distance * 0.051, 1.2, 16.0) / 64.0
	light.modulate.a = 1.0
	light.show()

func curtain_hint() -> String:
	return "E · cerrar las cortinas" if valley.curtains_open else "E · abrir las cortinas"

func looking_at_sighting() -> bool:
	var camera: Camera3D = player.camera
	var eye: Vector3 = camera.global_position
	for light in [valley.beacon, valley.second_beacon]:
		if not light.visible: continue
		var point: Vector3 = light.global_position
		if (point - eye).normalized().dot(-camera.global_basis.z) < 0.989: continue
		if not camera.is_position_in_frustum(point): continue
		var ray := PhysicsRayQueryParameters3D.create(eye, point, 3, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return true
	return false

func update_sighting(delta: float):
	if sighting_resolving: return
	sighting_time += delta
	valley.beacon.modulate.a = 0.48 + 0.52 * pow(0.5 + 0.5 * sin(sighting_time * 3.3 + 0.8), 2.4)
	valley.second_beacon.modulate.a = 0.38 + 0.62 * pow(0.5 + 0.5 * sin(sighting_time * 3.3 - 1.15), 2.4)
	if looking_at_sighting():
		sighting_focus += delta
		var label := "?????" if sighting == Sighting.ABRA else "Luces extrañas"
		hint.text = label + (" · E · observar" if sighting_focus >= SIGHTING_FOCUS_SECONDS else "")
		return
	sighting_focus = 0.0
	var camera: Camera3D = player.camera
	var direction: Vector3 = (valley.beacon.global_position - camera.global_position).normalized()
	var sideways: float = direction.dot(camera.global_basis.x)
	if sighting == Sighting.SHELTER and absf(sideways) <= 0.23 and direction.dot(-camera.global_basis.z) > 0.0:
		hint.text = "Buscá un lugar despejado y mirá arriba."
	elif absf(sideways) > 0.23 or direction.dot(-camera.global_basis.z) < 0.0:
		hint.text = "Mirá el cielo hacia la %s." % ("izquierda" if sideways < 0.0 else "derecha")
	else:
		hint.text = "Buscá el destello sobre la ladera."

func observe_lights():
	sighting_resolving = true
	hint.text = ""
	cross.hide()
	var fade := create_tween()
	fade.tween_property(valley.beacon, "modulate:a", 0.0, 0.45)
	if valley.second_beacon.visible:
		fade.parallel().tween_property(valley.second_beacon, "modulate:a", 0.0, 0.5).set_delay(0.35)
	fade.tween_interval(0.28)
	await fade.finished
	valley.beacon.hide()
	valley.second_beacon.hide()
	match sighting:
		Sighting.ABRA:
			second_sighting = true
			score.cue("melancholy", -15.0, 1.7)
			radio.play_interference()
			field_note += " Sobre el abra vi dos destellos. El segundo estaba más alto."
			radio_choices("sighting_response", "Un punto azul se apaga. El otro tarda un instante más. La radio se corta a mitad de una palabra: «…cruces…».",
				["Vi dos destellos. Uno quedó por encima de la ladera. Y en el canal se cortó una voz, como si dijera «cruces».", "Anotás el rumbo para más tarde."])
		Sighting.QUARRY:
			score.cue("cosmic", -16.0, 2.0)
			radio.play_interference()
			var observation := "La chapa que giré sigue quieta. Ahora veo una luz más arriba, separada del sendero. ¿Vos la ves?"
			if book_light_notes: observation = "La chapa sigue quieta. Esta luz está más arriba y cae en otro rumbo que los destellos que marqué en el libro. ¿Vos la ves?"
			conversation([hernan(observation), "El reflejo de la chapa se apagó en mi ventana. Lo de arriba me lo tapa la ladera. ¿Desde dónde estás viendo esa otra luz?"], "quarry_prompt")
		Sighting.CROSSING:
			overlay("crossing_response", "La estática cede. «¿Ya llegaste? Recién prendo la radio». La luz titila por encima de la quebrada. Entre un destello y otro no se oye el agua.", ["Retrocedés con Mara en línea.", "Apagás la linterna y esperás.", "Alumbrás el cauce."], "radio")
		Sighting.SHELTER:
			radio.play()
			radio_choices("last_night_choice", "Mara · Desde acá ya se me taparon. ¿Para dónde fueron?", NIGHT_REPLIES)

func day_card(title: String, caption: String, cue: String):
	overlay("message", title.to_upper() + "\n\n" + caption, cue)
	shade.color = Color.BLACK

func debug_scene(code: String):
	debug_run = true
	if code == "intro":
		start_game(1)
		return
	menu.hide()
	player.camera.make_current()
	player.position = Vector3( - 0.45, 0.1, 1.2)
	player.rotation.y = PI
	if code != "41_pack": valley.toggle_door()
	stage = int({"arrival": 0, "2": 1, "sighting": 7, "7": 6, "dream7": 7, "25": 8, "dream25": 9, "27": 10, "32": 13, "camp": 13, "36": 16, "40": 18, "ultima_noche": 18, "cueva": 18, "dream36": 18, "41": 19, "41_pack": 19, "41_close": 19}.get(code, 0))
	storm_return_seconds = Climate.STORM_CLEAR_SECONDS if stage == 18 else 0.0
	heard = stage > 0
	if stage > 0:
		valley.unpack_book(book_has_ribbon())
		radio_taken = true
	if stage >= 10: valley.dress_day27()
	if stage >= 13: valley.dress_day32()
	if stage >= 16: valley.dress_day36()
	if code == "camp":
		player.position = valley.route.camp_point() + Vector3(0, 0.2, 1.6)
		summit_mapped = true
	if stage == 19:
		match code:
			"41":
				departure_briefed = true
				packed_items = [0, 1, 2, 3]
				player.position = valley.route.at(valley.route.trail(292), 292) + Vector3.UP * 0.12
			"41_pack":
				if valley.door_open: valley.toggle_door()
				player.position = Vector3(1.25, 0.06, 4.12)
				valley.hang_sketch(0, Diary.ARRIVAL_BRIDGE)
				valley.hang_sketch(1, Diary.WALL_ATLAS, Diary.CREEK)
			"41_close":
				departure_briefed = true
				elvira_book_taken = true
				packed_items = [0, 1, 2, 3]
				for topic in Mara.TOPICS: trail_replies[topic] = Mara.TOPICS[topic][0]
				mara_heard_paula = true
				player.position = valley.route.terrain_point(Vector3(22.8, 0.0, 11.0)) + Vector3.UP * 0.10
				player.rotation.y = PI
				night_investigation = 2
		objective_seconds = 6.0
	awaiting_call = stage in [1, 6, 8, 10, 13, 16] and code != "camp"
	walk()
	if code.begins_with("dream"):
		dream_count = int({"dream7": 0, "dream25": 1, "dream36": 2}[code])
		has_piece = false
		begin_dream()
	elif code == "32":
		show_mate_morning()
	elif code == "40":
		start_day40()
	elif code in ["ultima_noche", "cueva"]:
		bed_pose = Transform3D(Basis.IDENTITY, Vector3(1.37, 0.06, 4.55))
		bed_pitch = 0.0
		player.position = Vector3(1.24, 0.04, 1.82)
		valley.restore_light(1.0, 1.0)
		last_night = true
		if code == "ultima_noche":
			player.position = Vector3(1.24, 0.04, -4.4)
			day40_seconds_left = 0.0
			day40_interlude_done = true
			storm_return_seconds = Climate.STORM_CLEAR_SECONDS
			start_patio_call()
		else: enter_cave()
	elif code == "sighting":
		player.position = valley.route.at(valley.route.trail(228), 228) + Vector3.UP * 0.12
		player.rotation.y = 0.0
		valley.arrival_light(1.0)
		show_sighting()
	elif stage == 0:
		bedtime = false
		valley.arrival_light(1.0)
		begin_refuge_night()

func map_destination() -> Variant:
	if stage < 0: return Vector3.ZERO
	if stage == 15: return Vector3.ZERO
	if (bedtime or awaiting_call) and stage != 19: return Vector3.ZERO
	var route = valley.route
	match stage:
		1, 2: return Creek.post()
		4: return Creek.marker()
		5: return Vector3.ZERO
		7: return route.at(route.trail(420) + 1.6, 420)
		8: return route.at(route.trail(route.CREST) - 1.50, route.CREST)
		10: return route.quarry_point(1.0)
		13:
			return route.summit_point(1) if camp_reported else null
		16: return South.mark_position()
		19:
			if not departure_briefed or packed_items.size() < Departure.PACK_ITEMS.size(): return Vector3.ZERO
			if not elvira_book_taken: return Museum.center(valley)
			if departure_destination.is_empty(): return Departure.RADIO_STOP
			return Departure.FORK if departure_destination == "fork" else Departure.trail_end(departure_destination)
	return null
