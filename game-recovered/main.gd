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
const CaveRunes = preload("res://piedra_cueva.gd")
const Saves = preload("res://partidas.gd")
const Mara = preload("res://charlas_mara.gd")
const Exploration = preload("res://exploracion.gd")
const Diary = preload("res://diario.gd")
const SUMMIT_NIGHT_SECONDS := 40.0
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
	41: ["calma1", "domestic"],
}
const WALK_SCORE_DELAY := 5.0
const WALK_SCORE_GAP := 27.0
const DREAM_ARCH_EXCHANGES := [
	"—¿La ves?\n—¿Qué cosa?\n—La que tarda en aparecer. Quedate un segundo sin mover la cabeza.\n\nLa voz viene del otro lado de la piedra. Al fondo distinguís otro arco.",
	"—¿Me hablás por la radio?\n—Probá apagarla.\n\nTanteás la perilla. Ya está apagada.\n\n—¿Me oís igual?",
	"Del otro lado suenan dos golpes secos.\n\n—Hay dos lunas. ¿Cuál tengo que mirar?\n—El huequito entre las cuatro estrellas. Como en la vereda, cuando tapábamos el farol."
]
enum Sighting { ABRA, QUARRY, CROSSING, SHELTER, CAVE, CLEARING }
const STATE = ["page", "stage", "keepsakes", "bedtime", "field_note", "crossing_note", "filo_report_reply", "quarry_reply", "fox_seen", "hiker_met", "route_reported", "observing", "pending_return", "heard", "radio_taken", "bag_left", "read_note", "creek_note", "bed_pose", "bed_pitch", "gate_jumped", "map_read", "awaiting_call", "dream_count", "branch_found", "mapped_distance", "has_piece", "summit_mapped", "camp_read", "arrival_action", "intro_bridge_drawn", "second_sighting", "book_light_notes", "day7_dusk", "archive_read", "trail_replies", "crossing_response", "summit_echo_response", "night_investigation", "ending_at_door", "sky_memories", "compass_lost", "last_voice_reply", "found_collectibles"]
var flashlight_out: = false
var camp_read: = false
var summit_mapped: = false
var has_piece: = false
var dream_piece: Node3D
var dream_world: Node3D
var archive_read := false
var trail_replies: Dictionary = {}
var trail_topic := ""
var trail_answer := 0
var trail_spacing_day := -1
var trail_walk_left := 0.0
var ending_paragraphs: PackedStringArray = []
var ending_paragraph := 0
var ending_fade: Tween
var crossing_response: = -1
var summit_echo_response := -1
const CROSSING_NOTES = [
	"Al retroceder, la voz repitió mi indicativo. Mara también la oyó.", 
	"Apagué la linterna. Vi una figura quieta del otro lado de la pasarela.", 
	"Alumbré el cauce. Por un instante vi lo que parecía una mano agarrada al travesaño."
]
var night_investigation: = 0
var ending_at_door: = false
var cave_built: = false
var valley_view_distance: float
var cave_checkpoint: = LastNight.ENTRY
var cave_notebooks_read: = false
var cave_exit_open: = false
var follow_last_light: = false
var crux_found: = false
var cave_outside := false
var cave_station_called := false
var clearing_cued := false
var compass_lost: = false
var last_voice_reply: = -1
var sky_memories: Array = []
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
var rain_strength := 0.0
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
var dream_arches := 0
var compass_out: = false
var ambience = preload("res://ambiente.gd").new()
var awaiting_call: = false
var slot: = 1
var paused_from: = ""
var gate_jumped: = false
var map_read: = false
var objective_seconds := 0.0
var intro_controls_seconds := 0.0
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
var music = preload("res://intro_music.gd").new()
var overlay_choices = preload("res://choices.gd").new()
var recall = preload("res://recall.gd").new()
var second_sighting := false # Guardados anteriores usan esta clave para el avistamiento del abra.
var abra_told_mara := false
var day7_dusk: = false
var debug_run: = false
var arrival_action: = false
var intro_bridge_drawn := false
var radio_taken := false
var bag_left := false
var first_call_wait := 0.0
var first_call_caption := 0.0
var bedtime: = false
var field_note: = ""
var crossing_note := ""
var filo_report_reply := -1
var quarry_reply := -1
var journal_pages: Array[Dictionary] = []
var journal_view := Diary.new()
var journal_page := 0
var journal_collection := false
var journal_from := ""
var collect_notice := ""
var collect_notice_seconds := 0.0
var found_collectibles: Dictionary = {}
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
var read_note: = false
var sequence: Array = []
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
	add_child(music)
	add_child(score)
	add_child(ambience)
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
	music.begin()
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
	Arrival.show_fragment(valley, page)
	var center: = Arrival.origin(page)
	if reset_position or player.position.distance_to(center) > 80:
		player.position = Arrival.spawn_point(page)
		player.rotation = Vector3(0, Arrival.spawn_heading(page), 0)
		player.camera.rotation = Vector3.ZERO
		player.velocity = Vector3.ZERO
		arrival_action = false
		objective_seconds = 0.0
		intro_controls_seconds = 3.0
		if page == 6: flashlight_out = false
	if page == 0:
		set_arrival_bag_visible(not arrival_action)
		player.walking = arrival_action
		player.looking_only = not arrival_action
	player.intro_center = center
	player.intro_heading = Arrival.HEADINGS[page]
	hint.text = "Mouse · mirar     F1 · objetivos" if page == 0 and not arrival_action else ""

func use_arrival_item():
	if arrival_action or target != Arrival.ACTIONS[page] or page in [1, 2, 3, 4, 6, 7]: return
	if page == 5:
		player.climb_rope(Arrival.rope_route(), Arrival.HEADINGS[page])
		return
	arrival_action = true
	if page == 0:
		set_arrival_bag_visible(false)
		player.walking = true
		player.looking_only = false
		intro_controls_seconds = 4.0
	hint.text = ""

func set_arrival_bag_visible(shown: bool):
	valley.arrival_bag.visible = shown
	valley.arrival_bag.collision_layer = 1 if shown else 0

func _input(event: InputEvent):
	if mode == "intro" and event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo:
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
	player.walking = false
	player.looking_only = false
	player.set_physics_process(false)
	cross.hide()
	hint.text = ""
	shade.z_index = 2
	shade.color = Color.TRANSPARENT
	shade.show()
	var fade := create_tween()
	fade.tween_property(shade, "color:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(func():
		shade.z_index = 0
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
	choosing = entry.has("options")
	var lines: Array = entry.lines.duplicate()
	recall.present(lines, entry.get("options", []), paragraph)

func next_memory():
	page += 1
	if page < memories.size():
		valley.restore_light(Arrival.DUSK[page], Arrival.DARK[page])
		approach(true)
	else:
		music.close(1.25)
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
	if stage < 19: return 36
	return 41

func _physics_process(_delta: float):
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
	var in_museum := Museum.under_roof(valley, player.position)
	valley.update_calendar(day)
	update_weather(day, delta, in_museum)
	update_water(delta)
	valley.shade_ridges()
	var in_refuge: bool = absf(player.position.x) < 3.45 and player.position.z > -0.35 and player.position.z < 5.9
	valley.update_desk_radio(radio_taken or (in_refuge and hands.pose == "radio"))
	valley.set_desk_note(stage <= 0 and not read_note)
	valley.update_shelter_wall(day)
	if stage >= 0:
		if intro_bridge_drawn: valley.hang_sketch(0, Diary.ARRIVAL_BRIDGE)
		if not creek_note.is_empty(): valley.hang_sketch(1, Diary.WALL_ATLAS, Diary.CREEK)
		if second_sighting: valley.hang_sketch(2, Diary.WALL_ATLAS, Diary.LIGHTS)
		if camp_read: valley.hang_sketch(3, Diary.WALL_ATLAS, Diary.RIDGE)
	var darkness := float(valley.sky_mat.get_shader_parameter("nightfall"))
	var hand_tone := Color.WHITE.lerp(Color("#7d869e") if not in_refuge else Color("#b4a392"), darkness)
	if mode == "cave" and not cave_outside: hand_tone = Color("#6c6b69") if flashlight_out else Color("#45444c")
	hands.modulate = hand_tone
	score.radio_active = radio_panel.visible
	if mode in ["walk", "map"]: score_daily_walk(day, delta, in_museum)
	if mode == "sighting": update_sighting(delta)
	if mode == "cave":
		update_cave()
	elif mode == "mara_door":
		update_night_target()
		hint.text = "E · golpear la puerta" if target == "Puerta de Mara" else ("Seguí la huella que sale al este de la banquina." if objective_seconds > 0.0 else "")
	update_flashlight()
	if mode == "dream" and dream_variant() < 3:
		dream_seconds_left = maxf(0.0, dream_seconds_left - delta)
		if dream_seconds_left == 0.0:
			finish_dream()
	if mode == "dream":
		hint.text = "????" if looking_at_dream_sky() else ""
		match dream_variant():
			2:
				if has_piece:
					hands.set_piece_signal(0.22)
				elif is_instance_valid(dream_piece):
					dream_piece.rotate_y(delta * 0.42)
					if near_dream_piece(): hint.text = "E · recoger la pieza"
					elif hint.text.is_empty(): hint.text = "Una pieza brilla unos pasos más arriba."
			3:
				update_dream_arch()
				if mode != "dream": return
		var find := aimed_collectible()
		if collect_notice_seconds > 0.0:
			hint.text = collect_notice
		elif Alien.FINDS.has(find):
			hint.text = "E · " + str(Alien.FINDS[find][1])
		elif hands.map_requested:
			hint.text = "M · guardar la hoja"
	radio_hint.visible = mode in ["walk", "map"] and radio_available()
	if radio_hint.visible:
		radio_hint.text = "R   ·   Charlá con Mara" if not at_departure_stop() and not mission_radio_available() else "R   ·   Mara"
	if mode in ["walk", "map"] and stage == 8 and not awaiting_call and crossing_note.is_empty():
		record_filo_route()
	if mode in ["walk", "map"] and stage >= 10 and not branch_found:
		if player.position.distance_to(valley.route.at(valley.route.trail(300), 300)) < 22:
			branch_found = true
	if mode in ["approach", "walk", "dream", "map", "sighting", "cave", "mara_door"]:
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
		ambience.update(delta, player.position, velocity, daytime and immersion < 0.05, mode == "cave" and not cave_outside, player.water_depth)
		if stage == 7 and not second_sighting and mode in ["walk", "map"]:
			var here := Vector2(player.position.x, player.position.z)
			var overlook_distance := here.distance_to(Exploration.MOLLAR)
			if overlook_distance < 24.0 and valley.light_target.is_empty() and float(valley.sky_mat.get_shader_parameter("dusk")) < 0.01:
				valley.sunset(12.0)
			if overlook_distance < 5.4:
				day7_dusk = true
				show_sighting()
				return
		if stage == 7 and not second_sighting and mode in ["walk", "map"] and player.position.z < valley.route.ORIGIN_Z - 200:
			if not day7_dusk:
				day7_dusk = true
				valley.night(46)
				score.cue("quietud", 34, -17.0, 3.0)
			elif float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.71:
				show_sighting()
				return
	if mode in ["approach", "walk"] and not player.climb_points.is_empty():
		hint.text = ("W · bajar con la cuerda" if player.rope_descending else "W · trepar con la cuerda") if player.rope_climbing else ""
		return

	if mode == "approach":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		var local: = Arrival.local_position(page, player.position)
		if page == 2: note_intro_bridge(local)
		if page == 1 and local.z < -10.43 and local.y > 0.29 and absf(local.x) < 1.70:
			arrival_action = true
		if page == 5 and not player.rope_climbing and local.y >= 1.40 and local.z < -10.76:
			arrival_action = true
		var walked_out: bool = Arrival.left_fragment(local) and (page > 0 or arrival_action)
		if walked_out or ((arrival_action or page in [2, 7]) and Arrival.reached_exit(page, local)):
			fade_to_memory()
			return
		if objective_seconds > 0.0:
			hint.text = intro_objective()
		elif page == 0 and not arrival_action:
			hint.text = "Mouse · mirar     F1 · objetivos"
			if target == Arrival.ACTIONS[page]: hint.text += "\nE o clic · " + target
		elif page == 0 and intro_controls_seconds > 0.0:
			hint.text = "WASD · caminar"
		elif page == 6 and not arrival_action:
			hint.text = "L · encendé la linterna"
		elif not arrival_action and page == 1 and local.z < -5.2:
			hint.text = "Espacio · saltar el tronco"
		elif not arrival_action and page in [3, 4]:
			hint.text = "B · probar la brújula" if page == 3 else "M · consultar el mapa"
		elif not arrival_action and not target.is_empty() and target == Arrival.ACTIONS[page]:
			hint.text = "E o clic · " + target
		else:
			hint.text = ""
	elif mode == "walk":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		if stage == -1 and player.position.z < 0 and target == "":
			hint.text = "E · interactuar al mirar la puerta"
			return

		if stage == -1 and player.position.z > 0 and abs(player.position.x) < 3.4 and player.position.z < 5.9:
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
		if stage == 0 and target == "Radio" and not radio_taken:
			hint.text = "E · levantar la radio"
			return
		if stage == 0 and heard and not bag_left and target in ["Cama", "Dejar la mochila"]:
			hint.text = "E · dejar la mochila al lado de la cama"
			return
		if not hit and ( - player.camera.global_basis.z).y > 0.12 and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6:
			var star := SkyGuide.identify(-player.camera.global_basis.z, valley.sky_chapter, day)
			if can_pause_under_sky():
				if watching_crux_tonight() and not looking_at_crux():
					hint.text = star if not star.is_empty() else "Buscá las dos estrellas del eje largo de la Cruz del Sur."
				else:
					hint.text = "E · ubicar el sur" if watching_crux_tonight() else "E · quedarte a mirar el cielo"
				return
			hint.text = star
		elif stage >= 0 and hit and hit.has_meta("find_id"):
			hint.text = "E · recoger " + target.to_lower()
		elif stage >= 0 and target in ["", "Subir al escalón"] and not player.ledge_route().is_empty():
			hint.text = "E · trepar el saliente"
		else:
			hint.text = "Acercate al escalón" if target == "Subir al escalón" else ("E · " + target if target != "" else "")

func setup_rain():
	rain_view.emitting = false
	rain_view.amount = 920
	rain_view.lifetime = 1.45
	rain_view.lifetime_randomness = 0.18
	rain_view.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_view.emission_box_extents = Vector3(15.0, 2.4, 15.0)
	rain_view.visibility_aabb = AABB(Vector3(-19.0, -28.0, -19.0), Vector3(38.0, 34.0, 38.0))
	rain_view.direction = Vector3.DOWN
	rain_view.spread = 2.0
	rain_view.gravity = Vector3(0.0, -3.7, 0.0)
	rain_view.initial_velocity_min = 8.0
	rain_view.initial_velocity_max = 10.0
	rain_view.particle_flag_align_y = true
	rain_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drop := CylinderMesh.new()
	drop.top_radius = 0.004
	drop.bottom_radius = 0.009
	drop.height = 0.22
	drop.radial_segments = 3
	drop.rings = 0
	rain_view.mesh = drop
	rain_material.shader = preload("res://lluvia.gdshader")
	rain_view.material_override = rain_material
	add_child(rain_view)

func update_weather(day: int, delta: float, in_museum: bool):
	var position: Vector3 = player.position
	var target_rain := Climate.rain(stage, position)
	var target_mist := Climate.local_mist(day, position)
	if stage in [16, 17] and valley.weather_day != 36:
		rain_strength = maxf(rain_strength, 0.77)
	rain_strength = move_toward(rain_strength, target_rain, delta * (0.095 if target_rain > rain_strength else 0.075))
	mist_strength = move_toward(mist_strength, target_mist, delta * 0.0013)
	valley.update_weather(day, rain_strength, mist_strength)
	var outside := position.z < -0.5 or absf(position.x) > 3.45 or position.z > 5.97
	var shows_world: bool = mode in ["walk", "map", "sighting", "mara_door"] or radio_panel.visible
	var rain_active: bool = shows_world and rain_strength > 0.025
	rain_view.visible = rain_active
	rain_view.emitting = rain_active
	if rain_active:
		var wind := Climate.wind(day, position, rain_strength)
		rain_view.position = position + Vector3.UP * 8.8
		rain_view.direction = Vector3(wind * 0.12, -1.0, 0.07).normalized()
		rain_material.set_shader_parameter("intensity", rain_strength)
	ambience.weather(delta, rain_strength if shows_world else 0.0, shows_world and (not outside or in_museum), radio_panel.visible)

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
	return ["", "Espacio · saltá el tronco.", "Cruzá el puente y seguí la huella.", "B · probá la brújula.", "M · consultá el mapa.", "E · agarrá la cuerda. Mantené W para trepar.", "L · encendé la linterna."][page]

func score_daily_walk(day: int, delta: float, in_museum: bool):
	if day != walk_score_day:
		walk_score_day = day
		walk_score_wait = WALK_SCORE_DELAY
		walk_score_turn = 0
	if awaiting_call or stage < 1 or in_museum or score.is_playing(): return
	var here: Vector3 = player.position
	if absf(here.x) < 12.0 and here.z > -15.0 and here.z < 12.0: return
	if not player.is_on_floor() or Vector2(player.velocity.x, player.velocity.z).length_squared() < 0.36:
		return
	walk_score_wait -= delta
	if walk_score_wait > 0.0: return
	var themes: Array = WALK_SCORE[day]
	var dark := float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.65
	var theme: String = "noche" if dark else themes[walk_score_turn % themes.size()]
	var start := 28.0 if walk_score_turn > 0 and (dark or walk_score_turn >= themes.size()) else 0.0
	score.cue(theme, 92.0, -14.0, 3.0, start)
	walk_score_turn += 1
	walk_score_wait = WALK_SCORE_GAP

func at_summit_finish() -> bool:
	return stage == 15 and player.position.distance_to(valley.route.ascent_point(0.0)) < 3.2

func objective() -> String:
	if not player.climb_points.is_empty(): return "Buscás apoyo en la piedra."
	if stage == 0:
		if not radio_taken: return "Levantá la radio del escritorio."
		if not heard: return "Esperá a que Mara pruebe el canal."
		return "Acercate a la cama." if bag_left else "Dejá la mochila en el suelo, al lado de la cama."
	if awaiting_call: return "R · Escuchá a Mara en la radio."
	if stage == 5 and not bedtime: return "R · Pasale a Mara la lectura del cauce."
	if stage == 9 and route_reported and player.position.z < -14.0:
		var distance: float = valley.route.ORIGIN_Z - player.position.z
		if distance > Museum.DISTANCE: return "Desandá la huella del filo hasta pasar el museo."
		if distance >= valley.route.LAJA_FORK: return "Bajá por la cuerda o rodeá la laja por la vaguada."
		return "Seguí la huella principal hasta el refugio."
	if stage == 12 and player.position.z < -20.0: return "Volvé junto al cable y seguí el sendero oeste hasta la tranquera."
	if stage == 18 and (player.position.z < -14.0 or player.position.z > 9.0 or absf(player.position.x) > 10.0):
		return "Volvé por las pircas. En el cruce podés volver por la loma o bajar al poste para tomar la huella del refugio."
	if stage == 15 and not (bedtime and player.position.z > -12.0):
		return "Seguí las pircas de bajada hasta el banco del acceso para cerrar la travesía."
	if bedtime: return "Cuando quieras terminar el día, acercate a la cama y tocá E."
	if pending_return: return "Volvé a pie al refugio y usá la radio junto a la entrada."
	if stage == 10: return "Tomá el sendero oeste al salir de la tranquera. Al encontrar el cable, seguilo hasta el malacate."
	if stage == 11: return "R · Consultá a Mara por el reflejo."
	if stage == 13:
		if not summit_mapped: return "Salí por la tranquera y seguí el sendero del este hasta el inicio del ascenso."
		return "Seguí la senda del acceso y revisá el campamento antes de la cumbre." if not camp_read else "Seguí las pircas hasta la cumbre."
	if stage == 16:
		if player.position.x > -36.0 and player.position.z < 19.0:
			return "Salí por la tranquera. Pasá por la loma de las lajas y seguí la huella de la quebrada sur."
		return "Seguí las pircas aguas abajo hasta la pasarela."
	if stage == 17: return "R · Pasale la marca del agua a Mara."
	if stage == 18: return "Volvé a dormir al refugio."
	if stage == 19:
		if at_departure_stop(): return "R · Despedite de Mara desde la banquina."
		return "Andá a la curva del camino para despedirte de Mara. Podés pasar por el museo antes."
	if stage == 14: return "R · Pasale a Mara lo que ves desde la cumbre."
	if stage == 8: return "Día 25 · Pasá el museo y el abra para llegar al hito del filo."
	if stage == 9: return "R · Pasá el parte del filo." if not route_reported else "Volvé al refugio."
	if stage == -1: return "Abrí la puerta con E y entrá al refugio."
	if stage == 7 and not second_sighting and not day7_dusk: return "Salí por la tranquera y seguí la huella del este hasta el mirador del mollar."
	return ["Noche 1 · R · Contestar la radio", "Salí por la tranquera y tomá la bajada del cauce hasta el poste.", "R · Pasale a Mara la fecha", "Seguí la bajada del cauce.", "Seguí bajando hasta el lecho de piedras y buscá la regla.", "Volvé al refugio por la misma huella.", "Día 7 · Escuchá el parte de Mara.", "Pasá el museo de sitio y probá la recepción en el abra."][stage]

func overlay(kind: String, caption: String, footer: Variant, prop: String = ""):
	overlay_choices.hide()
	mode = kind
	player.looking_only = false
	player.walking = false
	cross.hide()
	shade.show()
	if kind in ["talk", "choice", "report", "signal", "dusk", "reception"]:
		prop = "radio"
	if prop != "radio": hands.show_map(false)
	hands.hold(prop)
	shade.color = Color(0.03, 0.045, 0.06, 0.07 if prop == "radio" else (0.48 if prop else 0.87))
	if prop == "radio":
		radio_panel.display(kind, caption, footer)
		words.text = ""
		hint.text = ""
	else:
		radio_panel.hide()
		words.text = caption
		words.visible_ratio = 1
		hint.text = footer if footer is String else ""
		if footer is Array: overlay_choices.present(footer)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func open_journal():
	journal_collection = false
	journal_page = 0
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
	if journal_from != "dream": journal_page = journal_pages.size() - 1
	show_journal_page()

func bridge_diary_entry() -> Dictionary:
	return {"title": "Camino al puesto", "text": "Las tablas cedían un poco al pisarlas. Del otro lado, la huella seguía entre los pastos.",
		"sketch": Diary.ARRIVAL_BRIDGE}

func diary_entry(title: String, text: String, drawing: int = -1):
	journal_pages.append({"title": title, "text": text, "drawing": drawing})

func add_diary_entries():
	if not creek_note.is_empty():
		diary_entry("2 de octubre · El cauce", creek_note, Diary.CREEK)
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
		if summit_echo_response >= 0: entry += "\n\nAl bajar oí «hasta el banco». La voz se parecía a la mía."
		diary_entry("1 de noviembre · La cumbre", entry, Diary.RIDGE)
	if crossing_response >= 0:
		diary_entry("5 de noviembre · La pasarela", "El agua dejó pasto en el travesaño de abajo. Marqué la altura con carbón.\n\n" + CROSSING_NOTES[crossing_response], Diary.BRIDGE)
	if stage >= 19 and last_voice_reply >= 0:
		var entry := "Cerré la cortina. Cuando abrí los ojos había dos lunas del otro lado del arco."
		if night_investigation == 3: entry = "En el claro hubo un destello. Después, el arco. Hay un pedazo que no puedo dibujar."
		elif night_investigation >= 2: entry = "Tomé la bajada al sur. El tramo hasta mi cama no me sale en el dibujo."
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
	# La última noche tiene un autoguardado en el refugio, antes de partir.
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
	if journal_collection:
		open_journal()
		return
	journal_collection = true
	journal_page = 0
	var total := Exploration.FINDS.size() + Alien.FINDS.size() + 1
	var introduction := "%d de %d anotados.\n\nHallazgos del cerro y de los sueños." % [found_collectibles.size(), total]
	if not found_collectibles.is_empty():
		introduction += " Pasá la hoja para ver los dibujos y las notas."
	journal_pages = [{"title": "Coleccionables", "text": introduction}]
	for listings in [Exploration.FINDS, Alien.FINDS]:
		var dream: bool = listings == Alien.FINDS
		for id in listings:
			if not found_collectibles.has(id): continue
			var entry: Array = listings[id]
			var place := "Sueño %d" % entry[4] if dream else "Día %d" % found_collectibles[id]
			journal_pages.append({"title": entry[1], "text": place + " · " + entry[3], "drawing": entry[0], "dream": dream})
	if found_collectibles.has(CaveRunes.ID):
		journal_pages.append({"title": CaveRunes.TITLE, "text": "Última noche · Cueva\n\n" + CaveRunes.NOTE, "sketch": CaveRunes.sketch()})
	show_journal_page()

func show_journal_page():
	overlay("journal", "", "")
	journal_view.display(journal_pages[journal_page], journal_page, journal_pages.size(), journal_collection, journal_from not in ["approach", "intro"])

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
	var replying: bool = mode in ["choice", "report", "reception", "field_report", "day2_reply", "departure_radio", "trail_chat"]
	if next != "last_call":
		trail_spacing_day = calendar_day()
		trail_walk_left = Mara.distance_between_calls(trail_spacing_day)
	sequence = lines.duplicate()
	after = next
	speak()
	if replying: hands.press_button()

func speak():
	radio.play()
	var cue := "Espacio · seguir   /   Esc · volver" if after == "last_call" else "Espacio · seguir"
	overlay("talk", "Mara\n\n" + str(sequence.pop_front()), cue)

func radio_available() -> bool:
	if stage == 0 and not heard: return radio_taken and first_call_wait <= 0.0
	return at_departure_stop() or mission_radio_available() or not available_trail_chat().is_empty()

func at_departure_stop() -> bool:
	return stage == 19 and LastNight.near_stop(player.position)

func mission_radio_available() -> bool:
	return (stage == 0 and not heard) or awaiting_call or stage == 2 or (stage == 5 and not bedtime) or observing or (stage == 9 and not route_reported) or stage in [11, 14, 17]

func available_trail_chat() -> String:
	if mission_radio_available() or not player.climb_points.is_empty(): return ""
	if trail_spacing_day == calendar_day() and trail_walk_left > 0.0: return ""
	return Mara.available(stage, player.position, bedtime, second_sighting, trail_replies)

func can_visit_mara() -> bool:
	return Mara.can_visit(trail_replies)

func start_trail_chat(topic: String):
	trail_topic = topic
	var chat: Array = Mara.TOPICS[topic]
	radio.play()
	var aside := ""
	match topic:
		"antena":
			if abra_told_mara: aside = "Guardá ese croquis del abra. Si vuelve a pasar, podemos comparar. "
		"cable":
			if quarry_reply >= 0: aside = "Mañana pregunto a qué hora se fue la última camioneta del corte. "
		"ventana":
			if crossing_response >= 0: aside = "Mañana voy a la pasarela con luz. Quiero probar el canal desde esa orilla. "
	overlay("trail_chat", "Mara · " + aside + chat[1], chat[2], "radio")

func transmit():
	if not radio_available(): return
	radio_exchange()
	hands.press_button()

func begin_refuge_night():
	stage = 0
	first_call_wait = 4.0
	first_call_caption = 0.0
	hint.text = ""
	valley.night(23.0)
	music.close(1.0)
	score.silence(0.8)

func update_first_call(delta: float, inside: bool) -> bool:
	if first_call_wait > 0.0 and inside:
		first_call_wait = maxf(0.0, first_call_wait - delta)
		if first_call_wait == 0.0:
			if radio_taken:
				welcome_mara()
				return true
			radio.play()
			first_call_caption = 3.7
	first_call_caption = maxf(0.0, first_call_caption - delta)
	if inside and first_call_caption > 0.0:
		hint.text = "Mara, por la radio · ¿Me copiás?"
		if target == "Radio": hint.text += "\nE · levantar la radio"
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
	first_call_caption = 0.0
	conversation(["¿Me copiás? Soy Mara. Estoy en el puesto de abajo, pasando la curva del camino a Capilla."], "choice")

func radio_exchange():
	if stage == 0 and not heard:
		welcome_mara()
		return
	var chat := available_trail_chat()
	if stage == 19:
		if not at_departure_stop():
			if not chat.is_empty(): start_trail_chat(chat)
		elif chat.is_empty():
			farewell_mara()
		else:
			trail_topic = chat
			radio.play()
			overlay("departure_radio", "Mara · Estoy acá. ¿Cómo va esa última mañana?", ["Charlar un rato.", "Despedirte antes del ómnibus.", "Guardar la radio."], "radio")
		return
	if not chat.is_empty():
		start_trail_chat(chat)
		return
	if awaiting_call:
		if stage == 1:
			radio.play()
			overlay("day2_reply", "Mara · Buen día. ¿Cómo dormiste?", ["Dormí de un tirón.", "Todavía me estoy acostumbrando al puesto."], "radio")
			return
		var brief: Array
		match stage:
			6: brief = ["Buen día. Ayer se cortó el enlace con el abra.", "¿Te llegás hasta la antena?", "Antes pasá por el mirador del mollar, al este. Desde ahí se ve bien el abra. Después seguí por el museo hasta la antena.", "Si se corta el canal, esperá un poco. Desde el puesto voy a seguir llamando."]
			16: brief = ["Acá abajo llovió toda la noche. ¿Te fijás hasta dónde subió el arroyo?", "Salí por la loma de las lajas y seguí las pircas al sur. Es el mismo cauce del poste, pero bastante más abajo.", "Fijate hasta dónde llegó el agua en la pasarela. La marca se lee desde la orilla por la que llegás."]
			13: brief = [
				"¿Te animás a subir hasta la cumbre?",
				"En el plano que tengo en el puesto, el cable y el corte parecen tocarse. Quiero ubicar el rumbo de esa luz.",
				"Tomá el sendero del este. La subida empieza en el banco.",
				"En la lona del campamento hay un cuaderno. Fijate desde dónde miraban antes de seguir al hito."
			]
			10:
				brief = ["Hay una chapa suelta en el malacate. A cierta hora devuelve el sol hacia el puesto."]
				if filo_report_reply == 0:
					brief.push_front("Le pasé a los de mantenimiento tu vuelta por la vaguada. Ya llegaron al cable.")
				elif filo_report_reply == 1:
					brief.push_front("Les avisé lo del escalón. Dejaron la carga abajo y subieron por turnos.")
				brief.append_array(["Salí por la tranquera y doblá a la izquierda. Seguí el cable viejo hasta la chapa.", "Cuando la gires, llamame. Desde abajo me llega el reflejo a la ventana del puesto."])
			8: brief = [
				"Se desmoronó un pedazo de la laja. Dejaron la cuerda, pero hay gente que mañana tiene que pasar con herramientas.",
				"Podés probar la cuerda o rodear por la vaguada, a la derecha del cartel. Las dos huellas se juntan.",
				"Pasá el museo y el abra hasta el hito del filo. Desde ahí se ve dónde se junta todo. Avisame qué camino les marco."
			]
		if stage == 8 and abra_told_mara:
			brief.insert(0, "Pregunté por tus destellos del abra. Me confirmaron que esa tarde bajó una camioneta. Desde acá se ve el camino un rato y después lo tapa el filo.")
		conversation(brief, "brief")
		return
	if stage == 17:
		var lines: Array = []
		if summit_echo_response == 0:
			lines.append("Lo del filo podía ser un rebote. Ese «no cruces» te entró antes de que yo prendiera la radio. Voy a preguntar quién más usa el canal.")
		match crossing_response:
			0: lines.append("Oí tu indicativo dos veces. Capaz se pisaron dos equipos. Anotá cómo sonaba la segunda voz.")
			1: lines.append("Con tu linterna apagada, el reflejo tuyo lo podemos tachar. De la figura, anotá desde qué orilla la viste. Mañana miro si hay algo a esa altura.")
			2: lines.append("Puede haber ramas trabadas bajo el puente. Dejá esa orilla libre. Mañana con luz veo qué arrastró el agua.")
		lines.append_array(["Ya tengo la marca. Si la loma se embarró, en el cruce podés cortar por el poste.", "¿Sabés qué hice mientras subía el agua? Puse dos tazas en la mesa.", "Siempre me sobra una."])
		conversation(lines, "crossing_home")
		return
	if stage == 14:
		var bearing := "En el plano me quedaban casi en la misma línea. Con lo que ves desde ahí puedo marcar el camino de la camioneta aparte."
		if quarry_reply == 1: bearing = "Puse en el plano el rumbo que me pasaste desde el malacate. Cae por detrás de la ladera. Marcá también dónde estabas parado."
		elif quarry_reply == 0: bearing = "La chapa me daba justo en la ventana. Con lo que ves desde la cumbre, el reflejo y la luz de arriba quedan en rumbos distintos."
		conversation([bearing, "El cuaderno tiene dos horas. Habría que averiguar si esa camioneta tuvo tiempo de aparecer del otro lado.", "Por hoy, con que llegues al banco del acceso alcanza."], "summit_home")
		return
	if stage == 11:
		conversation(["Ahí bajó el reflejo. La chapa devolvía el sol contra el puesto.", "Pará. Dejá la chapa como está."], "wait_flash")
		return
	if stage == 9 and not route_reported:
		var report: = crossing_note if crossing_note else "Desde arriba se distingue la vaguada."
		overlay("field_report", report + " Mañana suben con herramientas. ¿Qué les dejás marcado?", ["«Con carga, vayan por la vaguada».", "«En la laja hay que subir con la cuerda»."], "radio")
		return
	if (bedtime and (stage != 0 or heard)) or stage == -1 or stage >= 8:
		overlay("message", objective(), "Espacio · volver")
		return
	if observing:
		observing = false
		radio.play()
		overlay("reception", "Esperás a que se apague la estática. Queda el canal abierto.", ["Preguntarle cómo te copia.", "Decirle que te quedás un rato."])
		return
	match stage:
		1: overlay("message", "La radio está en silencio. Falta revisar el poste.", "Espacio · volver")
		2:
			stage = 4
			conversation(["Doce de julio. Repusieron el poste después de una crecida.", "Con la fecha puedo buscar el parte de ese día.", "Seguí bajando hasta el lecho de piedras. La regla está cerca de la curva. Pasame la lectura desde ahí."], "sighting_return")
		4: overlay("message", "Todavía falta medir el cauce. Llamá a Mara cuando tengas la lectura.", "Espacio · volver")
		5:
			radio.play()
			overlay("report", "Día 2 · Parte del cauce\n\nTenés la lectura anotada. Mara te espera en el canal.", ["Pasar la lectura.", "Contarle lo de la mica."])

		6, 7: overlay("message", "El parte es al anochecer. " + objective(), "Espacio · volver")

func farewell_mara():
	var reply := "¿Llegaste a la curva? El ómnibus pasa en un rato."
	if archive_read:
		reply = "¿Viste el dibujo? Lo encontraron con los papeles del poste. No sé de quién era."
	var close_enough := can_visit_mara()
	var farewell := "Gracias por hacerte cargo del puesto. Pasaron rápido estas semanas."
	if close_enough:
		farewell = "Al principio esperaba tu parte por el trabajo. Después empecé a dejar la radio prendida antes de que llamaras."
	if night_investigation > 0:
		farewell = "Había tanto ruido anoche que por un rato pensé que no ibas a volver a contestar. Hoy dejé la radio prendida desde temprano."
	var memory := ""
	if trail_replies.has("cielo"):
		memory = "Anoche busqué esa estrella en el patio de casa. Había nubes. Igual me quedé ahí un rato." if trail_replies["cielo"] == 1 else "Anoche salí a ver si abría el cielo. Me acordé de lo que me contaste de tu viejo."
	elif trail_replies.get("ventana", -1) == 0:
		memory = "La pava que puse anoche sigue en la hornalla. Cuando junté las tazas me quedó una limpia."
	elif trail_replies.get("sueno", -1) == 0:
		memory = "¿Te acordás de ese cielo que soñaste? Si te vuelve a pasar, guardá el dibujo. Algún día me lo mostrás."
	elif trail_replies.has("museo"):
		memory = "Llovió y pensé en las tardes que mi vieja me llevaba al museo. Hacía años que no se lo contaba a nadie." if trail_replies["museo"] == 0 else "Ayer enderecé la mesa. El cartel del museo quedó libre por si querés darle un último uso."
	elif trail_replies.get("cauce", -1) == 1:
		memory = "Ese primer día me pediste que te acompañara un rato. A mí también me hizo bien que hubiera alguien del otro lado."
	elif trail_replies.get("primera_noche", -1) == 0:
		memory = "Me acostumbré a dejar prendida la luz del puesto hasta que me avisabas que habías llegado."
	elif trail_replies.get("ultima_curva", -1) == 0:
		memory = "Si conseguís el asiento de la ventanilla, fijate en la última curva. A esta hora le da el sol a la ladera."
	var lines := [reply, farewell]
	if night_investigation > 0:
		lines.insert(1, "Anoche se me abrió el canal solo. Desde la ventana del puesto veía la curva vacía. A la segunda vez, ya ni me fijé si venía de la radio.")
	if not memory.is_empty(): lines.append(memory)
	if close_enough:
		lines.append("Si te queda tiempo, pasá por casa. De la curva sale una huella. La mía es la de la puerta de madera con el buzón al lado.")
		if trail_replies.has("bajada"):
			lines.append("Golpeá. Sigo sin arreglar el timbre." if trail_replies["bajada"] == 0 else "El día que bajaste de la cumbre hice durar dos platos toda la bajada. Hoy te guardo una taza.")
	else:
		lines.append("Mañana subo a revisar el refugio. Buen viaje.")
	lines.append("Bueno. Gracias por contestar.")
	conversation(lines, "last_call")

func show_map(variant: int = 0):
	map.found = found_collectibles
	var arrival := page if variant == 0 and paused_from == "approach" else -1
	var goal: Variant = null
	if variant == 0 and paused_from == "walk":
		goal = map_destination()
		map_goal_origin = player.position
	map.open_at(player.position, variant, arrival, goal)
	hands.show_map(true)
	update_flashlight()

func refresh_map_goal():
	map.objective_mark = map_destination()
	map_goal_origin = player.position

func update_flashlight():
	var active: bool = flashlight_out and (mode in ["walk", "approach", "map", "cave", "dream", "sighting"] or hands.requested_pose == "radio") and mode != "menu"
	player.flashlight.visible = active
	if active:
		var dark: float = valley.sky_mat.get_shader_parameter("nightfall")
		var air := 1.15 if mode == "cave" and not cave_outside else smoothstep(0.37, 0.96, dark)
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
	if mode == "journal":
		if advance or key in [KEY_ESCAPE, KEY_TAB]:
			close_journal()
		elif key == KEY_C:
			toggle_journal_section()
		elif key in [KEY_LEFT, KEY_RIGHT]:
			journal_page = clampi(journal_page + (1 if key == KEY_RIGHT else -1), 0, journal_pages.size() - 1)
			show_journal_page()
		return
	if mode in ["approach", "walk"] and not player.climb_points.is_empty() and key not in [KEY_ESCAPE, KEY_F1]:
		return
	if mode == "postcard":
		if key == KEY_X:
			postcard_view.flip()
		elif key == KEY_E:
			postcard_view.hide()
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
	if mode == "mate_morning":
		if key == KEY_E: switch_mate_to_radio()
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
	if key == KEY_E and mode == "approach":
		use_arrival_item()
		return
	if key == KEY_F1 and mode in ["walk", "approach", "cave", "mara_door"]:
		objective_seconds = 4.0
		intro_controls_seconds = 0.0
		return
	if key == KEY_L and mode in ["approach", "walk", "map", "cave", "dream", "sighting"]:
		flashlight_out = not flashlight_out
		if mode == "approach" and page == 6 and flashlight_out: arrival_action = true
		update_flashlight()
		return
	if key == KEY_B and mode in ["approach", "walk", "map", "cave"]:
		if compass_lost:
			hint.text = "La brújula quedó entre las piedras."
			return
		compass_out = not compass_out
		if mode == "approach" and page == 3 and compass_out: arrival_action = true
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
	if (mode in ["dream", "cave"] or (mode == "walk" and stage >= 0)) and key == KEY_C:
		journal_from = mode
		journal_collection = false
		toggle_journal_section()
		return
	if mode == "dream" and key == KEY_M:
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
		if key == KEY_E and not sighting_resolving and sighting_focus >= SIGHTING_FOCUS_SECONDS and looking_at_sighting():
			observe_lights()
	elif mode == "last_dream_prelude" and advance:
		mode = "sleeping"
		hint.text = ""
		reveal_dream(create_tween())
	elif mode == "dream_arch_talk" and advance:
		dream_arches += 1
		explore_dream()
		save_game(true, "dream")
	elif mode == "night_cut" and advance:
		enter_cave()
	elif mode == "cave":
		if key == KEY_E: inspect_cave()
		elif key == KEY_R: call_from_cave()
	elif mode == "cave_text" and advance:
		resume_cave()
	elif mode == "mara_door" and key == KEY_E and target == "Puerta de Mara":
		ending_at_door = true
		player.intro_center = Vector3.ZERO
		save_game(true, "end")
		show_ending()
	elif mode == "intro": return
	elif mode == "dream" and key == KEY_SPACE and player.is_on_floor():
		player.velocity.y = 4.6
	elif mode == "dream" and key == KEY_E:
		var find := aimed_collectible()
		if Alien.FINDS.has(find):
			record_collectible(find)
			return
		if dream_variant() == 2 and not has_piece and near_dream_piece():
			has_piece = true
			dream_piece.queue_free()
			hands.hold("piece")
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
				var find := aimed_collectible()
				if stage >= 0 and Exploration.FINDS.has(find):
					record_collectible(find)
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
					if stage == 19 and target == "Maqueta del arco":
						show_archive()
						return
					overlay("message", exhibits[target], "Espacio · cerrar")
					return
				if Cable.NOTES.has(target):
					overlay("message", Cable.NOTES[target], "Espacio · seguir")
					return
				match target:
					"Sendero del cauce":
						overlay("message", "La huella rodea la cerca y baja al cauce. El poste está a mitad de la bajada.", "Espacio · seguir")
					"Sendero oeste":
						overlay("message", "La huella del oeste une la tranquera del refugio con el cable de la cantera.", "Espacio · seguir")
					"Mirador del mollar":
						overlay("message", "La huella del este sube al mollar. Desde ahí podés bajar por la vuelta del sur hasta el cauce.", "Espacio · seguir")
					"Loma de las lajas":
						overlay("message", "Desde las lajas ves el techo del refugio. Del otro lado, una huella baja al sur, hacia la pasarela.", "Espacio · seguir")
					"Desvío de la quebrada":
						overlay("message", "La huella alta sigue el cauce aguas abajo hasta la pasarela. El ramal bajo vuelve por el poste a la tranquera.", "Espacio · seguir")
					"Tronco caído":
						overlay("message", "El arroyo dejó un tronco atravesado. Podés saltarlo con Espacio.", "Espacio · seguir")
					"Pasarela de la quebrada":
						if stage == 16 and not awaiting_call:
							stage = 17
							field_note += " El agua llegó al travesaño inferior de la pasarela."
							valley.sunset()
							score.cue("misterio", 33, -18.0)
							radio.play_knocks()
							var sound := "La radio da dos golpes secos." if summit_echo_response < 0 else "La radio repite los dos golpes de la cumbre."
							overlay("crossing_warning", "Marcás con carbón hasta dónde llegó el agua. " + sound + " Una voz que suena a Mara dice: «No cruces todavía».", "Espacio · escuchar", "radio")
							return
						overlay("message", "El agua dejó pasto enredado en el travesaño de abajo. Estirás el brazo y marcás la altura con un trozo de carbón.", "Espacio · guardar")
					"Calendario":
						var day: = calendar_day()
						var date: = "%d de octubre" % day if day <= 31 else "%d de noviembre" % (day - 31)
						overlay("message", "Calendario\n\n%s. Los días anteriores están tachados con lápiz rojo." % date if day > 1 else "Calendario\n\n%s. La hoja está recién dada vuelta." % date, "Espacio · volver")
					"Postal de Paula":
						overlay("postcard", "", "")
						postcard_view.pick_up("telescopio" in str(keepsakes.get("beca", "")))
					"Recorte de astronomía":
						overlay("message", "Un equipo de Heidelberg mide el giro de estrellas dobles. Reconocés a Paula en la foto antes de leer el epígrafe. Tiene los anteojos colgando del cuello con el mismo cordón colorado.", "Espacio · doblar el recorte")
					"Camino al acceso":
						overlay("message", "El sendero del este se aparta de la huella principal y llega al banco donde empieza la subida.", "Espacio · seguir")
					"Bajada al acceso":
						overlay("message", "El cartel señala la bajada por las pircas hasta el banco del acceso. El mapa te muestra el siguiente tramo.", "Espacio · seguir")
					"Acceso a la cumbre":
						if not awaiting_call: summit_mapped = true
						overlay("message", "Al pie del cerro hay un banco y un cartel gastado. Ajustás la mochila. La huella empieza acá y sube por la otra ladera, bajo las pircas.", "Espacio · empezar a subir")
					"Trípode vacío":
						overlay("message", "Alguien se llevó la cámara. El trípode quedó apuntando a una muesca de la ladera. Una pata tiene dos vueltas de cinta aisladora.", "Espacio · soltar")
					"Cuaderno del campamento":
						if not summit_mapped:
							overlay("message", "El croquis del cuaderno empieza en el acceso del este. Te falta ubicar ese punto para seguir las anotaciones.", "Espacio · volver")
							return
						if not camp_read:
							camp_read = true
							field_note += " Día 32 · El cuaderno del campamento registra una camioneta y, dos minutos después, otra luz arriba de la muesca."
						overlay("message", "Observación OVNI · Uritorco. En el croquis, una flecha indica desde dónde miraban.\n\n«22.41. Luz abajo de la muesca. Camioneta en el camino».\n«22.43. Otra luz arriba de la muesca».\n\nAl lado del segundo renglón hay tres columnas: hora, rumbo y respuesta. En la última, una raya.", "Espacio · guardar el rumbo")
					"Hito de la cumbre":
						if stage == 13 and not summit_mapped:
							overlay("message", "La senda de ascenso empieza en el acceso del cerro, abajo, del lado este.", "Espacio · volver")
							return
						if stage == 13 and not camp_read:
							overlay("message", "Desde acá distinguís la lona que dejaste abajo, junto a las pircas. Bajá a revisar el cuaderno del campamento para comparar los rumbos.", "Espacio · volver")
							return
						if stage == 13 and not awaiting_call:
							stage = 14
							summit_mapped = true
							field_note += " Desde la cumbre vi que el cable y la muesca de la segunda luz quedan separados por un pliegue del cerro."
							valley.sunset()
						var sketch := "Desde arriba ves terminar el cable antes del corte. Un pliegue entero de sierra lo separa de la muesca que dibujaron en el campamento."
						if quarry_reply == 1: sketch += " El rumbo que anotaste en el malacate cae detrás de ese pliegue."
						overlay("message", sketch + "\n\nAbrís el mapa sobre la piedra y marcás desde dónde miraste. El viento te levanta una esquina. La sujetás con el pulgar.", "Espacio · doblar el mapa")
					"Desvío de la cantera":
						branch_found = true
						overlay("message", "Una flecha gastada señala el cable. Copiás el ramal en el mapa.", "Espacio · guardar")
					"Chapa del malacate":
						if stage == 10 and not awaiting_call:
							stage = 11
							branch_found = true
							valley.quarry_plate.rotation.y += 0.9
							valley.sunset()
						overlay("message", "La chapa gira sobre un solo bulón. La orientás hacia el último sol y la sujetás contra el bastidor.", "Espacio · soltar la manija")
					"Paso de la laja":
						overlay("message", "La huella se corta en un escalón de granito. Del lado derecho baja otra huella hacia la vaguada. Las dos vuelven a juntarse arriba.", "Espacio · seguir")
					"Cuerda de la laja":
						var points: Array[Vector3] = valley.route.laja_rope_route()
						if player.position.z < valley.route.ORIGIN_Z - 170.2: points.reverse()
						player.climb_rope(points, 0.0)
					"Hito del filo":
						if stage == 8 and not awaiting_call:
							stage = 9
							field_note += " Día 25 · Hito del filo revisado."
							valley.sunset()
						overlay("message", "Desde el hito ves el pliegue entero de la quebrada. Recién acá se entiende la vuelta que da el sendero. Marcás el rodeo en el cuaderno.", "Espacio · guardar")
					"Bolso":
						if stage == 0:
							overlay("message", "Dejaste la mochila en el suelo. Mañana acomodás las cosas.", "Espacio · seguir")
						else:
							valley.unpack_book(book_has_ribbon())
							open_book()
					"Puerta": valley.toggle_door()
					"Puerta del baño": valley.swing_side_door(valley.privy_hinge)
					"Puerta del museo": valley.swing_side_door(valley.museum_hinge)
					"Puerta de Mara":
						overlay("message", "La puerta de madera tiene un buzón chico al lado del marco.", "Espacio · seguir")
					"Tranquera": valley.swing_side_door(valley.yard_hinge)
					"Dejar la mochila": put_down_arrival_bag()
					"Cama":
						if stage == 0 and heard and not bag_left: put_down_arrival_bag()
						elif bedtime: overlay("rest", "¿Querés acostarte y terminar la jornada?", ["Dormir", "Seguir despierto"])
						else: overlay("message", "Todavía te queda algo por hacer. " + objective(), "Espacio · levantarse")
					"Observar el Cielo": open_book()
					"Flora serrana", "Cuaderno de campo": overlay("message", target + "\n\nHay una hoja seca de molle entre las páginas.", "Espacio · cerrar")
					"Radio":
						if stage == 0 and not radio_taken: take_arrival_radio()
						else: transmit()
					"Nota":
						read_note = true
						valley.set_desk_note(false)
						overlay("message", "Turno de temporada. Canal 3 para comunicarte con el puesto de abajo. Las baterías de repuesto están en el cajón.", "Espacio · dejar la nota")
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
						if stage == 7 and not bedtime:
							if not second_sighting:
								show_sighting()
								return
							valley.night()
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
	elif key == KEY_ESCAPE and (mode in ["departure_radio", "trail_chat"] or (mode == "talk" and after == "last_call")):
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
		elif after == "crossing_home":
			stage = 18
			bedtime = true
			valley.night()
			walk()
		elif after == "summit_home":
			valley.night(SUMMIT_NIGHT_SECONDS)
			radio.play_knocks()
			overlay("summit_echo", "Soltás el botón. La radio da dos golpes secos. Después se oye «hasta el banco». La frase es de Mara. La voz suena como la tuya.", ["«¿Eso lo dijiste vos?»", "Guardás la radio y empezás a bajar."], "radio")
		elif after == "quarry_home":
			stage = 12
			bedtime = true
			field_note += " Día 27 · En el malacate vi una luz por encima del corte con la chapa quieta."
			if quarry_reply == 1: field_note += " Dejé anotados el rumbo y la hora junto al croquis."
			valley.night()
			walk()
		elif after == "last_call":
			show_departure_choice()
		elif after == "trail_chat_done":
			trail_replies[trail_topic] = trail_answer
			if trail_topic == "cauce":
				field_note += " Le dijiste a Mara que agradecías el silencio." if trail_answer == 0 else " Le pediste a Mara un poco de charla."
			trail_topic = ""
			walk()
			save_game(true, "walk")
		elif after == "sighting_return":
			walk()
			if stage == 7 and second_sighting: save_game(true, "walk")
		elif after == "brief" or after == "day2_confirm":
			awaiting_call = false
			if stage == 6: stage = 7
			walk()
		elif after == "filo":
			route_reported = true
			bedtime = true
			valley.night()
			walk()
		elif after in ["sleep", "reception_done"]:
			bedtime = true
			walk()
		elif after == "welcome_done":
			heard = true
			bedtime = bag_left
			valley.set_bag_drop(not bag_left)
			walk()
			save_game(true, "walk")
		elif after == "choice": overlay("choice", "Tenés el botón de la radio bajo el pulgar.", ["Sí, te copio.", "Sí. Recién llego."])
		else:
			stage = 0
			heard = true
			walk()
	elif mode == "bench" and advance:
		walk()
		observing = true
	elif mode == "departure_choice":
		if key == KEY_ESCAPE: walk()
		elif advance and not can_visit_mara(): select_option(0)
	elif mode == "end" and (advance or key == KEY_F2):
		if advance and ending_paragraph + 1 < ending_paragraphs.size():
			ending_paragraph += 1
			show_ending_paragraph()
		else:
			get_tree().reload_current_scene()
	elif mode in ["pause", "pause_approach", "dream_pause"] and key == KEY_F2:
		get_tree().reload_current_scene()

func select_option(index: int):
	if mode == "intro" and recall.complete and choosing:
		var entry: Dictionary = memories[page]
		keepsakes[entry.key] = entry.options[index].keepsake
		choosing = false
		next_memory()
	elif mode == "crossing_response":
		crossing_response = index
		field_note += " Día 36 · " + CROSSING_NOTES[index]
		if index != 0: flashlight_out = index == 2
		if index == 1: score.cue("cosmic", 28, -15.0, 1.5)
		overlay("message", CROSSING_NOTES[index] + "\n\nEl canal queda abierto. Mara te pide la marca del agua y quiere saber qué notaste en la orilla.", "Espacio · volver")
	elif mode == "summit_echo":
		summit_echo_response = index
		stage = 15
		bedtime = false
		field_note += " Día 32 · Dos golpes en la radio y una voz parecida a la mía."
		if index == 0:
			radio.play()
			overlay("message", "Mara · Recién te oigo. Capaz rebotó en el filo. Si se vuelve a abrir sola, pará un segundo antes de contestar.", "Espacio · bajar", "radio")
		else:
			walk()
		save_game(true, "walk")
	elif mode == "last_night_choice":
		if index == 0:
			night_investigation = 1
			score.cue("misterio", 22, -16.0)
			overlay("night_cut", "La luz se mete entre los molles. Salís. Después hay una zanja que no recordás haber cruzado. La radio te golpea contra el pecho.\n\n«¿Me escuchás? Buscá la piedra blanca. Voy a dejar el canal abierto». Suena a Mara.", "Espacio · seguir la voz")
		else:
			begin_dream(true)
	elif mode == "cave_exit_choice":
		follow_last_light = index == 0
		cave_exit_open = true
		compass_lost = true
		compass_out = false
		overlay("cave_text", "Buscás la brújula. En el bolsillo solo quedó el cordón cortado. Afuera hay un hueco de cielo entre los árboles. Tu papá te hacía buscar primero las dos estrellas del eje largo.", "Espacio · salir a cielo abierto")
	elif mode == "last_voice":
		last_voice_reply = index
		var answer: = "La voz tarda. «Mirá una más. Después nos vamos». Viene de atrás del arco, o de muy cerca de tu oído."
		if index == 1:
			answer = "La voz hace una pausa. «Mirá una más. Después nos vamos». En la vereda, tu papá decía algo parecido. Esta vez te quedás mirando hasta que se apaga sola."
		overlay("last_voice_answer", answer, "")
		var voice := create_tween()
		voice.tween_interval(maxf(6.0, answer.length() / 23.0))
		voice.tween_callback(finish_dream)
	elif mode == "departure_choice":
		if index == 0:
			ending_at_door = false
			save_game(true, "end")
			show_ending()
		elif index == 1 and can_visit_mara():
			approach_mara_door()
	elif mode == "day2_reply":
		var reply: = "Me alegro. Esa cama tiene sus años." if index == 0 else "A mí la primera noche me despertó hasta el viento."
		conversation([reply, "Hoy me hacen falta dos datos. Salí por la tranquera y tomá la huella que rodea la cerca hacia el sur.", "Fijate qué fecha tiene la chapa del poste en la bajada. Nos hablamos cuando la tengas."], "day2_confirm")
	elif mode == "departure_radio":
		match index:
			0: start_trail_chat(trail_topic)
			1: farewell_mara()
			2: walk()
	elif mode == "trail_chat":
		trail_answer = index
		conversation(Mara.TOPICS[trail_topic][3][index], "trail_chat_done")
	elif mode == "choice":
		var reply := "Te escucho claro. Va bien el canal." if index == 0 else "Bueno, acomodate tranquilo. Se oye el viento en el alero."
		conversation([reply, "Te dejo que te sigas acomodando. Podés dejar la mochila al lado de la cama. Mañana te llamo temprano."], "welcome_done")
	elif mode == "rest" and index == 1: walk()
	elif mode == "rest" and index == 0:
		if stage == 18:
			score.silence(2.5)
			save_game(true, "walk")
			bedtime = false
			bed_pose = Transform3D(Basis.IDENTITY, Vector3(1.37, 0.06, 4.55))
			bed_pitch = 0.0
			player.position = Vector3(1.24, 0.04, 1.82)
			player.velocity = Vector3.ZERO
			show_sighting(Sighting.SHELTER)
			return
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
		if stage in [7, 9]:
			begin_dream()
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
			conversation(["Desde mi ventana veo la curva hasta el primer poste. Pasó un rato sin que viera faros.", "Dos destellos pueden ser dos luces del camino. Si una quedó arriba del filo, marcame dónde estabas cuando la viste.", "En la antena probamos el canal. Lo de la voz puede ser alguien que entró en la misma frecuencia."], "sighting_return")
		else:
			field_note += " Guardé el rumbo para compararlo después."
			walk()
			save_game(true, "walk")
	elif mode == "quarry_sighting_response":
		quarry_reply = index
		var line := "Desde que paraste la chapa no me entra el reflejo. Si arriba siguió prendida, anotala aparte. Puede haber un foco de trabajo atrás del corte." if index == 0 else "Con ese rumbo ya puedo mirar el plano. Pasame también la hora. Quiero saber si todavía quedaba gente trabajando arriba."
		var lines := [line]
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
		var line := "Les marco la vuelta por abajo." if index == 0 else "Les aviso que en el escalón suban de a uno."
		conversation([line, "Van a mirar el malacate. Dicen que vieron algo brillar por ahí al cerrar el otro turno."], "filo")
	elif mode == "reception":
		var lines := ["Ahora sí. Te oigo clarito."] if index == 0 else ["Dale. Dejo la radio prendida."]
		if abra_told_mara: lines.append("Desde la antena tu voz entra limpia. Guardá la hora de los destellos. Puedo preguntar si había alguien del otro lado.")
		conversation(lines, "reception_done")
	elif mode == "report":
		if index == 0:
			creek_note += " Parte enviado."
			conversation(["Anotado.", "Cuando tengas el próximo parte, me encontrás acá."], "sleep")
		else:
			creek_note += " Le contaste a Mara lo que viste."
			conversation(["Mi viejo volvía de ahí con los bolsillos llenos de esas piedritas.", "Cuando lavábamos los pantalones, brillaba todo el patio."], "sleep")

func begin_dream(preserve_bed: bool = false, fade_from_black: bool = false):
	dream_seconds_left = DREAM_SECONDS
	dream_arches = 0
	score.cue("otromundo", 100, -14.0, 2.5)
	if not preserve_bed:
		bed_pose = player.transform
		bed_pitch = player.camera.rotation.x
	var first: = dream_count == 0
	var last := stage == 18
	dream_count += 1
	overlay("sleeping", "", "")
	shade.color = Color.BLACK if fade_from_black else Color.TRANSPARENT
	var fade: = create_tween()
	fade.tween_property(shade, "color:a", 1.0, 0.15 if fade_from_black else 1.8)
	fade.tween_callback( func():
		words.text = "Te dormís de costado. Por un momento te parece que seguís afuera." if first else "Te acostás con el pelo todavía húmedo. Cerrás los ojos. Esta vez reconocés la curva antes de verla."
		if night_investigation == 3:
			words.text = "El blanco se vuelve tela. Oís a tu papá pasar una hoja. Del otro lado del arco alguien gira la perilla de una radio. El papel y la estática hacen el mismo ruido."
		elif stage == 18:
			words.text = "Apoyás la radio en el piso. Contás los golpes del alero hasta perder la cuenta."
			if night_investigation > 0:
				words.text = "Agarrás la bajada. Después hay un tramo que no podés ubicar. En el sueño, la radio sigue abierta."
		valley.strange_sky(true)
		player.walking = false
		player.low_gravity = true
		position_on_planet()
		player.velocity = Vector3.ZERO
		player.rotation.y = 0.0
		player.camera.rotation.x = 0.4
		if last:
			mode = "last_dream_prelude"
			hint.text = "Espacio · entrar al sueño")
	if not last:
		fade.tween_interval(5.0)
		reveal_dream(fade)

func reveal_dream(fade: Tween):
	fade.tween_property(words, "modulate:a", 0.0, 1.0)
	fade.tween_property(shade, "color:a", 0.0, 2.0)
	fade.tween_callback( func():
		words.modulate.a = 1.0
		explore_dream())

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
	if dream_variant() == 2 and not has_piece and not is_instance_valid(dream_piece):
		var foot := LastNight.dream_point(2, 21.0)
		dream_piece = Alien.tesseract(dream_world)
		dream_piece.position = foot + Vector3.UP * 0.69
		dream_piece.rotation = Vector3(0.29, 0.70, 0.21)
	mode = "dream"
	if has_piece and dream_variant() in [2, 3]: hands.hold("piece")

func arch_bearing(arch: Vector3) -> float:
	var offset: Vector3 = arch - player.position
	var look: Vector3 = -player.camera.global_basis.z
	var direction := Vector2(offset.x, offset.z).normalized()
	var forward := Vector2(look.x, look.z).normalized()
	return smoothstep(0.22, 0.99, forward.dot(direction))

func looking_at_dream_sky() -> bool:
	return -player.camera.global_basis.z.y > 0.36

func near_dream_piece() -> bool:
	return is_instance_valid(dream_piece) and player.position.distance_to(dream_piece.global_position) < 3.0

func update_dream_arch():
	if dream_arches >= LastNight.DREAM_ARCH_DISTANCES.size():
		hands.set_piece_signal(0.0)
		return
	var arch := LastNight.dream_arch(dream_arches)
	var bearing := arch_bearing(arch) if has_piece else 0.0
	hands.set_piece_signal(bearing)
	if hint.text.is_empty():
		hint.text = "La pieza late más fuerte en esta dirección." if bearing > 0.6 else "Buscá el siguiente arco entre las paredes."
	if player.position.distance_to(arch) > 4.3: return
	if dream_arches < DREAM_ARCH_EXCHANGES.size():
		if dream_arches == 2: radio.play_knocks()
		overlay("dream_arch_talk", DREAM_ARCH_EXCHANGES[dream_arches], "Espacio · seguir")
	else:
		dream_arches += 1
		hear_last_voice()

func finish_dream():
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
			save_game(true, "walk")
			var waking: = "Abrís los ojos en tu cama. No sabés si volviste caminando. Buscás el cuaderno de la estación entre tus cosas. Solo está el tuyo.\n\n" if night_investigation > 0 else ""
			day_card("Día 41 · El dibujo", waking + "Intentás dibujar el arco en el reverso de un parte. Cuando enderezás el dintel, deja de parecerse al del sueño. Hoy termina tu relevo. Podés pasar por el museo antes de bajar a la curva. Mara te espera en la radio para despedirse.", "Espacio · levantarse")
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
	valley.morning()
	valley.dress_day36()
	save_game(true, "walk")
	day_card("Día 36 · Después de la lluvia", "En el banco del acceso guardás el mapa. Para cuando entrás al refugio, ya se escucha el agua en el techo.\n\nLa lluvia sigue varios días. Esta mañana hay barro en el escalón y el arroyo se oye desde la puerta.", "Espacio · levantarse")

func show_archive():
	archive_read = true
	var caption := "El dintel de la maqueta cae hacia el mismo lado que en tu sueño. Detrás del vidrio, el dibujo está al dorso de un parte de mantenimiento. Bajo el sello del 12 de julio, la fecha del poste, se lee: «Repuesto el poste del cauce. En la bajada vi dos luces. Dos golpes en el canal. Una voz pidió que esperara»."
	if night_investigation >= 2:
		caption += "\n\nEn la cueva usaban columnas para hora, rumbo y respuesta. En este parte también. La hoja está cortada justo donde empezaría la última columna."
	overlay("message", caption, "Espacio · seguir")

func book_has_ribbon() -> bool:
	return "cinta verde" in str(keepsakes.get("puesto", ""))

func open_book():
	overlay("book", "", "")
	var book_memory := str(keepsakes.get("libro", ""))
	book_view.open("imprenta grande" in book_memory, book_has_ribbon(), stage >= 8)

func turn_book(step: int):
	book_view.turn(step)
	if book_view.page == 3 and not book_light_notes:
		book_light_notes = true
		field_note += " Comparé en Observar el Cielo el rumbo de los destellos del abra. Dejé dos marcas en un papel entre las páginas."
		save_game(true, "walk")

func enter_cave():
	score.silence(1.5)
	if not cave_built:
		LastNight.build_cave(valley)
		cave_built = true
	valley.cave_darkness()
	player.camera.far = NIGHT_SCENE_VIEW
	cave_outside = false
	cave_station_called = false
	clearing_cued = false
	cave_checkpoint = LastNight.ENTRY
	radio.play()
	player.intro_center = LastNight.CAVE
	player.intro_heading = 0.0
	player.position = LastNight.CAVE + LastNight.ENTRY
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	player.velocity = Vector3.ZERO
	flashlight_out = false
	resume_cave()

func resume_cave():
	walk()
	mode = "cave"
	target = ""

func update_night_target():
	var hit = player.ray.get_collider()
	target = str(hit.get_meta("item", "")) if hit else ""

func update_cave():
	var local: Vector3 = player.position - LastNight.CAVE
	var outside := cave_exit_open and local.z < -38.0
	if outside != cave_outside:
		cave_outside = outside
		player.intro_center = LastNight.CAVE + (LastNight.RETURN_START if outside else Vector3.ZERO)
		if outside: valley.cave_moonlight()
		else: valley.cave_darkness()
	if outside:
		update_night_return(local)
		return
	if local.y < -1.2 or absf(local.x) > 5.2 or local.z > 0:
		player.position = LastNight.CAVE + cave_checkpoint
		player.velocity = Vector3.ZERO
		return
	if local.z < -22.4 and local.y > 0.55:
		cave_checkpoint = LastNight.CHECKPOINT
	elif cave_checkpoint == LastNight.ENTRY and local.z < LastNight.LIP.z and local.z > -10.4:
		cave_checkpoint = LastNight.LIP
	if local.z < -38.0 and not cave_exit_open:
		player.position.z = LastNight.CAVE.z - 37.9
	update_night_target()
	if target == CaveRunes.TITLE and not flashlight_out: target = ""
	if objective_seconds > 0.0:
		hint.text = "Revisá la estación y los cuadernos." if local.z < -22.0 else "Usá la linterna y saltá entre las tres piedras. R · Mara"
	elif collect_notice_seconds > 0.0:
		hint.text = collect_notice
	elif target == CaveRunes.TITLE:
		hint.text = "Signos copiados en el cuaderno" if found_collectibles.has(CaveRunes.ID) else "E · copiar los signos"
	elif not target.is_empty():
		hint.text = "E · " + target
	elif local.z > -22.0 and flashlight_out:
		hint.text = "Espacio · saltar entre las piedras     R · Mara"
	else:
		hint.text = "L · encender la linterna     R · llamar a Mara" if not flashlight_out else "L · linterna     R · Mara"

func update_night_return(local: Vector3):
	if local.y < -6.0:
		player.position = LastNight.CAVE + Vector3(0, 0.78, -40.0)
		player.velocity = Vector3.ZERO
		return
	if not crux_found:
		if local.z < -42.0: player.position.z = LastNight.CAVE.z - 41.9
		hint.text = "Buscá la Cruz del Sur entre las copas."
		if looking_at_crux():
			hint.text = "E · reconocer la Cruz del Sur"
		elif objective_seconds > 0.0:
			var sideways: float = crux_axis().dot(player.camera.global_basis.x)
			var direction := "izquierda" if sideways < 0.0 else "derecha"
			hint.text = "Buscá las dos estrellas del eje largo." if absf(sideways) < 0.18 else "Mirá arriba hacia la %s." % direction
		return
	var position := Vector2(local.x, local.z)
	var clearing_distance := position.distance_to(LastNight.CLEARING)
	if not clearing_cued and clearing_distance < 12.0:
		clearing_cued = true
		cue_clearing()
	if clearing_distance < 2.5:
		show_sighting(Sighting.CLEARING)
		return
	if position.distance_to(LastNight.RETURN) < 3.4:
		hint.text = "E · seguir la bajada"
	elif looking_at_crux():
		hint.text = "Cruz del Sur · sur"
	elif objective_seconds > 0.0 or absf(local.z - LastNight.FORK_Z) < 4.5:
		hint.text = "En la bifurcación, la bajada sigue al sur. El claro queda hacia el otro ramal."
	else:
		hint.text = ""

func call_from_cave():
	var local: Vector3 = player.position - LastNight.CAVE
	var line := "«Buscá los bordes claros. Hay tres piedras que sobresalen. Si resbalás, volvé a la repisa y tomá aire»."
	if cave_outside:
		line = "«Si estás afuera, buscá el sur. Voy a dejar el canal abierto»." if not crux_found else "«Ya no oigo el agua. Si se corta, seguí el rumbo. Yo te escucho»."
	elif local.z < -22.0:
		line = "«Escuchá el viento. Si me dejás de oír, seguí hasta donde veas cielo»."
		if not cave_station_called:
			cave_station_called = true
			hear_station_cut()
			return
	radio.play()
	overlay("cave_text", line, "Espacio · guardar la radio", "radio")

func hear_station_cut():
	radio.play()
	overlay("station_cut", "«¿Estás al lado mío?»", "", "radio")
	await get_tree().create_timer(0.95).timeout
	radio.play_interference()
	overlay("station_cut", "El canal se corta.", "", "radio")
	await get_tree().create_timer(0.7).timeout
	radio.play()
	overlay("cave_text", "La voz vuelve más baja. «Escuchá el viento. Por ahí tiene que estar la salida».", "Espacio · guardar la radio", "radio")

func inspect_cave():
	if cave_outside:
		if not crux_found and looking_at_crux():
			crux_found = true
			score.cue("cosmic", 48, -14.0, 2.3)
			var reading := "Encontrás las dos del eje largo. Lo prolongás hacia el sur, como te enseñó tu papá."
			if 25 in sky_memories or 32 in sky_memories:
				reading = "Hacés lo mismo que en la ladera. Primero las dos del eje largo. Después seguís la línea con la vista hasta el sur. Esta vez ni se te ocurre buscar la brújula."
			var trail := "Al pie de la ladera se juntan dos huellas. La que baja al refugio sigue al sur."
			if follow_last_light: trail += " Del otro lado de la bifurcación queda el claro."
			overlay("cave_text", reading + "\n\n" + trail, "Espacio · seguir el rumbo")
		elif crux_found:
			var local: Vector3 = player.position - LastNight.CAVE
			if Vector2(local.x, local.z).distance_to(LastNight.RETURN) < 3.4:
				start_final_dream(false)
		return
	match target:
		CaveRunes.TITLE:
			if flashlight_out: record_cave_runes()
		"Receptor":
			radio.play_knocks()
			overlay("cave_text", "Hay un receptor, un trípode y un cable que desaparece en una grieta. En el dial está marcada la frecuencia del refugio. Al girarlo oís dos golpes secos. La aguja se queda inmóvil.", "Espacio · soltar")
		"Cuadernos de observación":
			if not cave_notebooks_read: score.cue("misterio", 18, -22.0, 3.0)
			cave_notebooks_read = true
			night_investigation = 2
			var notebook := "14/10/1974 · «03.11. Dos destellos. El segundo bajó al claro».\n\n09/11/1978 · «Dos golpes. Una voz pidió que no cruzáramos todavía. La frecuencia del puesto estaba libre»."
			var entries := "Hay columnas de hora, rumbo y respuesta. En la última siempre hay una raya."
			if camp_read: entries = "Reconocés las columnas del cuaderno de la cumbre. Hora, rumbo y respuesta. La última también tiene una raya."
			overlay("cave_text", notebook + "\n\n" + entries, "Espacio · dejar los cuadernos")
		"Salida de la cueva":
			if cave_exit_open: return
			if not cave_notebooks_read:
				overlay("cave_text", "Entra aire frío. Atrás tuyo, la luz del receptor cae sobre unos cuadernos abiertos.", "Espacio · volver")
			else:
				player.position = LastNight.CAVE + Vector3(0, 0.72, -37.35)
				player.velocity = Vector3.ZERO
				show_sighting(Sighting.CAVE)

func cue_clearing():
	score.cue("tension", 14, -9.0, 0.35, 25.0)

func start_final_dream(blinded: bool):
	if blinded:
		cue_clearing()
		night_investigation = 3
		overlay("cave_flash", "", "")
		shade.color = Color(1, 1, 0.96, 0)
		var flash: = create_tween()
		flash.tween_property(shade, "color:a", 1.0, 0.14)
		flash.tween_callback(radio.play_interference)
		flash.tween_interval(0.22)
		flash.tween_property(shade, "color", Color.BLACK, 0.9)
		await flash.finished
	player.intro_center = Vector3.ZERO
	player.position = bed_pose.origin
	player.velocity = Vector3.ZERO
	flashlight_out = false
	begin_dream(true, blinded)

func show_departure_choice():
	var caption := "La radio queda en silencio. Desde la banquina ves el ómnibus doblar en la curva."
	if can_visit_mara():
		overlay("departure_choice", caption + " De la curva sale una huella hacia lo de Mara.", ["Subís al ómnibus.", "Tomás el sendero y vas a golpear la puerta de Mara."])
	else:
		overlay("departure_choice", caption, "Espacio · subir al ómnibus   /   Esc · volver")

func approach_mara_door():
	valley.open_mara_path()
	valley.morning()
	hands.show_map(false)
	player.intro_center = Vector3.ZERO
	player.intro_heading = 0.0
	player.velocity = Vector3.ZERO
	walk()
	mode = "mara_door"
	objective_seconds = 4.0

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
		score.cue("noche", 32, -17.0)
	overlay("message", SKY_MEMORIES[day], "Espacio · seguir")

func hear_last_voice():
	radio.play_interference()
	overlay("last_voice", "La voz vuelve del otro lado del arco. «¿Ya la encontraste?». Tu papá te hacía esa pregunta cuando miraban el cielo. Abrís la boca sin saber a quién le hablás.", ["«¿Quién es…?»", "«¿Papá…?»"])

func show_ending():
	score.silence(3.5)
	var memory_of_book := str(keepsakes.get("libro", "En la guarda sigue el dibujo que hiciste con tu papá."))
	ending_paragraphs = [
		"Subís al ómnibus. Desde el asiento ves la curva que baja al puesto. Antes de que desaparezca, abrís Observar el Cielo. " + memory_of_book,
		"La radio va apagada en tu mochila. Justo al doblar oís dos golpes secos."
	]
	if ending_at_door:
		ending_paragraphs = [
			"Golpeás dos veces. Dejás la mano apoyada en la madera. Del otro lado cruje una tabla.",
			"Te quedás en el escalón, con Observar el Cielo bajo el brazo. " + memory_of_book
		]
	var closing := "Cuando vuelvas a dar clase, querés llevar el libro. Pensás empezar por pedirles que dibujen lo primero que ven."
	if last_voice_reply == 1:
		closing = "Por un instante, al pensar en tu papá, oís la pregunta de siempre. Abrís la mano sobre las cuatro estrellas. Pensás llevar el libro cuando vuelvas a dar clase."
	ending_paragraphs.insert(2 if ending_at_door else 1, closing)
	ending_paragraph = 0
	show_ending_paragraph()

func show_ending_paragraph():
	var cue := "Espacio · seguir" if ending_paragraph + 1 < ending_paragraphs.size() else "Fin · Espacio para volver al menú"
	overlay("end", ending_paragraphs[ending_paragraph], cue)
	shade.color = Color.BLACK
	if ending_fade and ending_fade.is_valid(): ending_fade.kill()
	words.modulate.a = 0.0
	ending_fade = create_tween()
	ending_fade.tween_property(words, "modulate:a", 1.0, 0.85)

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
	state["abra_told_mara"] = abra_told_mara
	if trail_spacing_day == calendar_day() and trail_walk_left > 0.0:
		state["trail_walk_left"] = trail_walk_left
	if resume_mode == "dream":
		state["dream_seconds_left"] = dream_seconds_left
		state["dream_arches"] = dream_arches
	var title: String = "Llegada" if stage < 0 else ("Noche 1" if stage == 0 else ("Día 2" if stage < 6 else ("Día 7" if stage < 8 else "Día 25")))
	if stage >= 19: title = "Día 41"
	elif stage >= 16: title = "Día 36"
	elif stage >= 13: title = "Día 32"
	elif stage >= 10: title = "Día 27"
	var data = {"version": 1, "slot": slot, "title": title, "state": state, "mode": resume_mode, "pose": player.transform, "pitch": player.camera.rotation.x, "paragraph": recall.paragraph, "chapter": valley.sky_chapter, "museum_offset": Museum.SITE_OFFSET, "south_crossing": true, "stop_verge": true, "rain": rain_strength, "light_target": valley.light_target, "light_left": valley.remaining_light_transition(), "door": valley.door_open, "book": valley.book_unpacked, "night": valley.sky_mat.get_shader_parameter("nightfall"), "dusk": valley.sky_mat.get_shader_parameter("dusk"), "music": music.get_playback_position() if music.playing else 0.0}
	return Saves.write(slot, automatic, data)

func restore(data: Dictionary):
	score.silence(0.2)
	slot = data.slot
	for key in STATE:
		if data.state.has(key): set(key, data.state[key])
	abra_told_mara = bool(data.state.get("abra_told_mara", "Se lo conté a Mara." in str(data.state.get("field_note", ""))))
	found_collectibles = data.state.get("found_collectibles", {}).duplicate()
	remove_collected_objects()
	trail_replies = Mara.saved_replies(data.state)
	trail_spacing_day = calendar_day()
	trail_walk_left = clampf(float(data.state.get("trail_walk_left", 0.0)), 0.0, Mara.distance_between_calls(trail_spacing_day))
	if not data.state.has("filo_report_reply"):
		if "Recomendás la vaguada." in field_note: filo_report_reply = 0
		elif "Avisás del escalón." in field_note: filo_report_reply = 1
	if stage == 3: stage = 4
	if not data.state.has("archive_read"): archive_read = int(data.state.get("archive_entry", -1)) >= 0
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
	player.camera.rotation.x = data.pitch
	valley.configure_sky(data.chapter)
	valley.morning()
	if stage >= 10:
		valley.dress_day27()
		if stage >= 11: valley.quarry_plate.rotation.y = 0.9
	if stage >= 16: valley.dress_day36()
	if stage >= 13:
		valley.dress_day32()
		if camp_read: summit_mapped = true
	radio_taken = data.state.get("radio_taken", stage > 0 or (stage == 0 and heard))
	bag_left = data.state.get("bag_left", stage == 0 and heard)
	valley.set_desk_note(stage <= 0 and not read_note)
	valley.update_desk_radio(radio_taken)
	if stage >= 1:
		valley.unpack_book(book_has_ribbon())
	elif stage == 0:
		if bag_left: valley.leave_bag()
		bedtime = heard and bag_left
		valley.set_bag_drop(heard and not bag_left)
		if not heard: first_call_wait = 4.0
	if stage < 0:
		music.begin()
		music.seek(data.music)
	if data.door: valley.toggle_door()
	var dusk_value: Variant = data.get("dusk")
	var night_value: Variant = data.get("night")
	var saved_dusk := clampf(float(dusk_value) if dusk_value != null else 0.0, 0.0, 1.0)
	var saved_night := clampf(float(night_value) if night_value != null else 0.0, 0.0, 1.0)
	rain_strength = clampf(float(data.get("rain", Climate.rain(stage, player.position))), 0.0, 1.0)
	mist_strength = Climate.local_mist(calendar_day(), player.position)
	valley.restore_light(maxf(saved_dusk, saved_night), saved_night)
	var seconds := float(data.get("light_left", 0.0))
	if seconds > 0.01 and data.get("light_target") == "night":
		valley.night(seconds)
	elif seconds > 0.01 and data.get("light_target") == "dusk":
		valley.sunset(seconds)
	elif stage == 7 and day7_dusk and not second_sighting and saved_night < 1.0:
		valley.night(12.0)
	elif stage == 15 and saved_night < 1.0:
		valley.night(maxf(1.0, SUMMIT_NIGHT_SECONDS * (1.0 - saved_night)))

	match str(data.mode):
		"mate_morning":
			if stage == 13: show_mate_morning()
			else: start_day25()
		"first_dream_wake": show_first_dream_wake()
		"end": show_ending()
		"intro":
			player.intro_center = Arrival.origin(page)
			if player.position.distance_to(player.intro_center) > 80: player.position = player.intro_center
			memory(data.paragraph)
		"approach":
			var old_stop_spawn: bool = page == 0 and not arrival_action and not data.get("stop_verge", false)
			if not old_stop_spawn and player.position.distance_to(Arrival.origin(page)) <= 80.0:
				player.position = Arrival.safe_saved_position(page, player.position, arrival_action)
			approach(old_stop_spawn)
		"dream":
			dream_seconds_left = clampf(float(data.state.get("dream_seconds_left", DREAM_SECONDS)), 0.0, DREAM_SECONDS)
			dream_arches = clampi(int(data.state.get("dream_arches", 0)), 0, LastNight.DREAM_ARCH_DISTANCES.size())
			score.cue("otromundo", 100, -14.0, 2.5)
			player.low_gravity = true
			valley.strange_sky(true)
			explore_dream()
		_: walk()

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

func show_mate_morning():
	walk()
	mode = "mate_morning"
	score.cue("calma2", 27, -16.0)
	player.position = Vector3(1.14, 0.04, 2.42)
	player.velocity = Vector3.ZERO
	player.rotation.y = - PI / 2.0
	player.camera.position.y = 1.26
	player.camera.rotation.x = -0.12
	player.walking = false
	cross.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hands.hold("mate")
	words.text = "DÍA 32 · LA CUMBRE\n\nEl mate todavía está caliente. Llega el indicativo de Mara desde el puesto de abajo."
	hint.text = "E · dejar el mate"

func switch_mate_to_radio():
	mode = "mate_switch"
	var was_holding_mate: bool = hands.pose == "mate"
	hands.hold("")
	if was_holding_mate: await hands.movement.finished
	player.camera.position.y = 1.59
	walk()
	transmit()

func show_sighting(kind: Sighting = Sighting.ABRA):
	sighting = kind
	sighting_time = 0.0
	sighting_focus = 0.0
	sighting_resolving = false
	mode = "sighting"
	player.walking = kind in [Sighting.ABRA, Sighting.QUARRY, Sighting.CROSSING, Sighting.CLEARING]
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
			center = Vector3(42.0, 9.5, -4.0)
			place_sighting_light(valley.second_beacon, center + Vector3(5, 3.2, 10))
		Sighting.CAVE:
			center = LastNight.CAVE + Vector3(LastNight.CLEARING.x, 15.0, LastNight.CLEARING.y)
		Sighting.CLEARING:
			var point := LastNight.CLEARING + Vector2(0, -5.0)
			center = LastNight.CAVE + Vector3(point.x, LastNight.return_height(point.x, point.y) + 4.6, point.y)
	place_sighting_light(valley.beacon, center)
	update_sighting(0.0)

func place_sighting_light(light: Sprite3D, center: Vector3):
	light.position = center
	var distance: float = player.camera.global_position.distance_to(center)
	light.pixel_size = clampf(distance * 0.051, 1.2, 16.0) / 64.0
	light.show()

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
	if sighting == Sighting.CLEARING:
		var local: Vector3 = player.position - LastNight.CAVE
		if Vector2(local.x, local.z).distance_to(LastNight.CLEARING) > 6.0 or local.y < -6.0:
			valley.beacon.hide()
			resume_cave()
			return
	sighting_time += delta
	valley.beacon.modulate.a = 0.48 + 0.52 * pow(0.5 + 0.5 * sin(sighting_time * 3.3 + 0.8), 2.4)
	valley.second_beacon.modulate.a = 0.38 + 0.62 * pow(0.5 + 0.5 * sin(sighting_time * 3.3 - 1.15), 2.4)
	if looking_at_sighting():
		sighting_focus += delta
		var label := "?????" if sighting == Sighting.ABRA else "Luces extrañas"
		var verb := " · E · quedarte mirando" if sighting == Sighting.CLEARING else " · E · observar"
		hint.text = label + (verb if sighting_focus >= SIGHTING_FOCUS_SECONDS else "")
		return
	sighting_focus = 0.0
	var camera: Camera3D = player.camera
	var direction: Vector3 = (valley.beacon.global_position - camera.global_position).normalized()
	var sideways: float = direction.dot(camera.global_basis.x)
	if sighting == Sighting.SHELTER:
		hint.text = "Un reflejo barre la ventana. Mirá por el vidrio."
	elif absf(sideways) > 0.23 or direction.dot(-camera.global_basis.z) < 0.0:
		hint.text = "Mirá el cielo hacia la %s." % ("izquierda" if sideways < 0.0 else "derecha")
	else:
		if sighting == Sighting.CLEARING:
			hint.text = "Algo brilla por encima de los árboles."
		else:
			hint.text = "Mirá arriba, donde se abrió el cielo." if sighting == Sighting.CAVE else "Buscá el destello sobre la ladera."

func observe_lights():
	sighting_resolving = true
	hint.text = ""
	cross.hide()
	var fade := create_tween()
	if sighting == Sighting.CLEARING:
		player.walking = false
		fade.tween_property(valley.beacon, "modulate:a", 1.0, 0.85)
	else:
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
			score.cue("melancholy", 31, -15.0, 1.7)
			radio.play_interference()
			field_note += " Camino al abra vi dos destellos sobre la ladera. El segundo estaba más alto."
			overlay("sighting_response", "Un punto azul se apaga. El otro tarda un instante más. La radio se corta a mitad de una palabra: «…cruces…».", ["Le contás a Mara lo que viste y oíste.", "Anotás el rumbo para más tarde."])
		Sighting.QUARRY:
			score.cue("cosmic", 28, -16.0, 2.0)
			radio.play_interference()
			var caption := "La luz queda suspendida por encima del corte. La chapa sigue contra el bastidor."
			if book_light_notes: caption += " Te acordás de las dos marcas que dejaste en el libro. Desde acá el rumbo es otro."
			overlay("quarry_sighting_response", caption, ["Le decís a Mara que la chapa sigue quieta.", "Anotás el rumbo y se lo pasás."], "radio")
		Sighting.CROSSING:
			overlay("crossing_response", "La estática cede. «¿Ya llegaste? Recién prendo la radio». La luz titila por encima de la quebrada. Entre un destello y otro no se oye el agua.", ["Retrocedés con Mara en línea.", "Apagás la linterna y esperás.", "Alumbrás el cauce."], "radio")
		Sighting.SHELTER:
			overlay("last_night_choice", "Un punto queda quieto sobre los molles. El otro se pierde entre las ramas. Por la radio, Mara te pregunta si seguís despierto.", ["Salís y seguís las luces en el monte.", "Cerrás la cortina y te acostás."])
		Sighting.CAVE:
			overlay("cave_exit_choice", "La luz titila encima de un claro entre los árboles. Más abajo distinguís la huella de regreso.", ["Seguís el destello hasta el claro.", "Tomás la huella de regreso."])
		Sighting.CLEARING:
			start_final_dream(true)

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
	valley.toggle_door()
	stage = int({"arrival": 0, "2": 1, "sighting": 7, "7": 6, "dream7": 7, "25": 8, "dream25": 9, "27": 10, "32": 13, "camp": 13, "36": 16, "ultima_noche": 18, "cueva": 18, "dream36": 18, "41": 19}.get(code, 0))
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
		player.position = valley.route.at(valley.route.trail(292), 292) + Vector3.UP * 0.12
	awaiting_call = stage in [1, 6, 8, 10, 13, 16] and code != "camp"
	walk()
	if code.begins_with("dream"):
		dream_count = int({"dream7": 0, "dream25": 1, "dream36": 2}[code])
		has_piece = code == "dream36"
		begin_dream()
	elif code in ["ultima_noche", "cueva"]:
		bed_pose = Transform3D(Basis.IDENTITY, Vector3(1.37, 0.06, 4.55))
		bed_pitch = 0.0
		player.position = Vector3(1.24, 0.04, 1.82)
		valley.restore_light(1.0, 1.0)
		if code == "ultima_noche": show_sighting(Sighting.SHELTER)
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
	if stage == 15: return valley.route.summit_return_marker(player.position)
	if (bedtime or awaiting_call) and stage != 19: return Vector3.ZERO
	var route = valley.route
	match stage:
		1, 2: return Creek.post()
		4: return Creek.marker()
		5: return Vector3.ZERO
		7: return Exploration.ground(Exploration.MOLLAR, route) if not second_sighting and not day7_dusk else route.at(route.trail(420), 420)
		8: return route.at(route.trail(922), 922)
		10: return route.quarry_point(1.0)
		13:
			if not summit_mapped: return route.ascent_point(0)
			return route.summit_point(1) if camp_read else route.camp_point()
		16: return South.mark_position()
		19: return LastNight.STOP
	return null
