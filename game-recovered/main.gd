extends Node3D

const Arrival = preload("res://llegada.gd")
const Museum = preload("res://museo.gd")
const Creek = preload("res://cauce.gd")
const SkyGuide = preload("res://constelacion.gd")
const LastNight = preload("res://final_night.gd")
const Saves = preload("res://partidas.gd")
const Mara = preload("res://charlas_mara.gd")
const Diary = preload("res://diario.gd")
const SUMMIT_NIGHT_SECONDS := 40.0
const SIGHTING_FOCUS_SECONDS := 0.4
const NIGHT_SCENE_VIEW := 200.0
enum Sighting { ABRA, QUARRY, CROSSING, SHELTER, CAVE, CLEARING }
const STATE = ["page", "stage", "keepsakes", "bedtime", "field_note", "crossing_note", "filo_report_reply", "quarry_reply", "fox_seen", "hiker_met", "route_reported", "observing", "pending_return", "heard", "read_note", "creek_note", "bed_pose", "bed_pitch", "gate_jumped", "map_read", "awaiting_call", "dream_count", "branch_found", "mapped_distance", "has_piece", "summit_mapped", "camp_read", "arrival_action", "second_sighting", "book_light_notes", "day7_dusk", "archive_read", "trail_replies", "crossing_response", "summit_echo_response", "night_investigation", "ending_at_door", "sky_memories", "compass_lost", "last_voice_reply", "scored_walks"]
var flashlight_out: = false
var camp_read: = false
var summit_mapped: = false
var has_piece: = false
var dream_piece: MeshInstance3D
var dream_world: Node3D
var archive_read := false
var trail_replies: Dictionary = {}
var trail_topic := ""
var trail_answer := 0
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
var scored_walks: Array = []
var score = preload("res://banda_sonora.gd").new()
var book_view = preload("res://libro.gd").new()
var postcard_view = preload("res://postal.gd").new()
var rain_view: = ColorRect.new()
var branch_found: = false
var mapped_distance: = 0.0
var radio_hint: = Label.new()
var sighting: Sighting
var sighting_time := 0.0
var sighting_focus := 0.0
var sighting_resolving := false
var book_light_notes := false
var dream_count: = 0
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
var day7_dusk: = false
var debug_run: = false
var arrival_action: = false
var bedtime: = false
var field_note: = ""
var crossing_note := ""
var filo_report_reply := -1
var quarry_reply := -1
var journal_pages: Array[Dictionary] = []
var journal_view := Diary.new()
var journal_page := 0
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
	var ui: = CanvasLayer.new()
	add_child(ui)
	ui.add_child(rain_view)
	rain_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rain: = ShaderMaterial.new()
	rain.shader = preload("res://lluvia.gdshader")
	rain_view.material = rain
	rain_view.hide()
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
		player.position = center + Vector3.UP * 0.12
		player.rotation = Vector3(0, Arrival.HEADINGS[page], 0)
		player.camera.rotation = Vector3.ZERO
		player.velocity = Vector3.ZERO
		arrival_action = false
		objective_seconds = 0.0
		intro_controls_seconds = 3.0
		if page == 6: flashlight_out = false
	if page == 0: set_arrival_bag_visible( not arrival_action)
	player.intro_center = center
	player.intro_heading = Arrival.HEADINGS[page]
	hint.text = "WASD · caminar     Mouse · mirar" if page == 0 else ""

func use_arrival_item():
	if arrival_action or target != Arrival.ACTIONS[page] or page in [1, 3, 4, 6, 7]: return
	if page == 5:
		player.climb_rope(Arrival.rope_route(), Arrival.HEADINGS[page])
		return
	arrival_action = true
	if page == 0: set_arrival_bag_visible(false)
	hint.text = ""

func set_arrival_bag_visible(shown: bool):
	valley.arrival_bag.visible = shown
	valley.arrival_bag.get_child(0).collision_layer = 1 if shown else 0

func _unhandled_input(event):
	if mode == "book" and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: turn_book(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT: turn_book(-1)
		return
	if mode == "approach" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		use_arrival_item()

func memory(paragraph: int = 0):
	Arrival.show_fragment(valley, -1)
	hands.hold("")
	compass_out = false
	mode = "intro"
	player.walking = false
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
	valley.arrival_light(clampf(float(page) / (memories.size() - 1), 0, 1))
	if page < memories.size(): approach(true)
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
	if stage < 19: return 36
	return 41

func _process(delta):
	objective_seconds = maxf(0.0, objective_seconds - delta)
	intro_controls_seconds = maxf(0.0, intro_controls_seconds - delta)
	var day: = calendar_day()
	valley.update_calendar(day)
	valley.update_weather(day)
	valley.update_shelter_wall(day)
	if mode == "walk": score_daily_walk(day)
	var rain_visible: bool = stage >= 16 and stage <= 17 and mode in ["walk", "map", "sighting"] and (player.position.z < -0.5 or absf(player.position.x) > 3.4)
	if rain_visible != rain_view.visible:
		rain_view.visible = rain_visible
		rain_view.material.set_shader_parameter("intensity", 0.62 if rain_visible else 0.0)
	if mode == "sighting": update_sighting(delta)
	if mode == "cave":
		update_cave()
	elif mode == "mara_door":
		update_night_target()
		hint.text = "E · golpear la puerta" if target == "Puerta de Mara" else ("Seguí la huella que sale al este de la parada." if objective_seconds > 0.0 else "")
	update_flashlight()
	if mode == "dream":
		hint.text = "????" if looking_at_dream_sky() else ""
		match dream_variant():
			1:
				if looking_at_dream_sky(): hint.text = "???? · E"
			2:
				if has_piece:
					hands.queue_redraw()
					hint.text = "E · volver a tocar la pieza"
				elif is_instance_valid(dream_piece):
					dream_piece.rotate_y(delta * 0.42)
					if near_dream_piece(): hint.text = "E · recoger la pieza"
					elif hint.text.is_empty(): hint.text = "Una pieza brilla unos pasos más arriba."
			3:
				if near_last_arch(): hint.text = "E · tocar el último arco"
				elif hint.text.is_empty(): hint.text = "Seguí los arcos hacia la luz."
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
		var outdoors: bool = player.position.z < 0 or absf(player.position.x) > 3.5
		hands.step(delta, velocity)
		if mode == "map":
			map.location = player.position
			map.queue_redraw()
		var daytime: bool = mode != "dream" and outdoors and float(valley.sky_mat.get_shader_parameter("nightfall")) < 0.5
		ambience.update(delta, velocity, daytime, mode == "cave" and not cave_outside)
		if hands.pose == "compass":
			var look: Vector3 = - player.camera.global_basis.z
			hands.heading = atan2(look.x, look.z)
			hands.queue_redraw()
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
		if page == 1 and local.z < -10.43 and local.y > 0.29 and absf(local.x) < 1.70:
			arrival_action = true
		if page == 5 and not player.rope_climbing and local.y >= 1.40 and local.z < -10.76:
			arrival_action = true
		if (arrival_action or page == 7) and Arrival.reached_exit(page, local):
			memory()
			return
		if objective_seconds > 0.0:
			hint.text = intro_objective()
		elif page == 0 and intro_controls_seconds > 0.0:
			hint.text = "WASD · caminar     Mouse · mirar"
		elif page == 6 and not arrival_action:
			hint.text = "L · encender la linterna"
		elif not arrival_action and page == 1 and local.z < -5.2:
			hint.text = "Espacio · saltar el tronco"
		elif not arrival_action and page in [3, 4]:
			hint.text = "B · probar la brújula" if page == 3 else "M · consultar el mapa"
		elif not arrival_action and page != 7 and target == Arrival.ACTIONS[page]:
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
			stage = 0
			music.close()
			score.cue("noche", 29, -18.0, 4.0)
			valley.leave_bag()
			welcome_mara()
			return
		if at_summit_finish():
			hint.text = "E · cerrar la travesía"
			return
		if objective_seconds > 0.0:
			hint.text = objective()
			return
		if not hit and ( - player.camera.global_basis.z).y > 0.12 and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6:
			var star: = SkyGuide.identify( - player.camera.global_basis.z, valley.sky_chapter)
			if can_pause_under_sky():
				if watching_crux_tonight() and not looking_at_crux():
					hint.text = "Buscá las dos estrellas del eje largo de la Cruz del Sur."
				else:
					hint.text = "E · ubicar el sur" if watching_crux_tonight() else "E · quedarte a mirar el cielo"
				return
			hint.text = star
		elif stage >= 0 and target in ["", "Subir al escalón"] and not player.ledge_route().is_empty():
			hint.text = "E · trepar el saliente"
		else:
			hint.text = "Acercate al escalón" if target == "Subir al escalón" else ("E · " + target if target != "" else "")

func record_filo_route():
	var route = valley.route
	var distance: float = route.ORIGIN_Z - player.position.z
	if distance >= 159.0 and distance <= 186.0 and absf(player.position.x - route.detour(distance)) < 6.0:
		crossing_note = "La vaguada rodea la laja y vuelve a la huella del filo."
	elif distance > 170.75 and distance < 174.5:
		var landing: Vector3 = route.surface_point(route.trail(170) - 0.64, 171.02)
		if player.position.distance_to(landing) < 4.0:
			crossing_note = "En la laja, el escalón de piedra se puede salvar con la cuerda."

func intro_objective() -> String:
	if page == 0:
		return "Seguí el camino de tierra al costado de la parada." if arrival_action else "Acercate a la parada y recogé la mochila."
	if page == 7 or arrival_action:
		return "Seguí la curva del sendero." if page >= 6 else "Caminá un poco más por la senda."
	return ["", "Espacio · saltá el tronco.", "E · agarrate del pasamanos.", "B · probá la brújula.", "M · consultá el mapa.", "E · agarrá la cuerda. Mantené W para trepar.", "L · encendé la linterna."][page]

func score_daily_walk(day: int):
	if awaiting_call or day in scored_walks: return
	if (Creek.trail_distance(Vector2(player.position.x, player.position.z)) > 5.0 if day == 2 else player.position.z > -20.0): return
	if float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.3: return
	if stage == 1:
		scored_walks.append(day)
		score.cue("calma1", 46, -16.0)
	elif stage in [7, 8]:
		scored_walks.append(day)
		score.cue("domestic", 52, -16.0)

func at_summit_finish() -> bool:
	return stage == 15 and player.position.distance_to(valley.route.ascent_point(0.0)) < 3.2

func objective() -> String:
	if awaiting_call: return "R · Escuchá a Mara en la radio."
	if not player.climb_points.is_empty(): return "Buscás apoyo en la piedra."
	if stage == 0: return "Primera noche · Acercate a la cama." if heard else "R · Contestale a Mara."
	if stage == 5 and not bedtime: return "R · Pasale a Mara la lectura del cauce."
	if stage == 9 and route_reported and player.position.z < -14.0:
		var distance: float = valley.route.ORIGIN_Z - player.position.z
		if distance > Museum.DISTANCE: return "Desandá la huella del filo hasta pasar el museo."
		if distance >= valley.route.LAJA_FORK: return "Bajá por la cuerda o rodeá la laja por la vaguada."
		return "Seguí la huella principal hasta el refugio."
	if stage == 12 and player.position.z < -20.0: return "Volvé junto al cable y seguí el sendero oeste hasta la tranquera."
	if stage == 18 and player.position.z < -14.0: return "Volvé por las pircas al cable. De ahí, tomá el sendero oeste hacia el refugio."
	if stage == 15 and not (bedtime and player.position.z > -12.0):
		return "Seguí las pircas de bajada hasta el banco del acceso para cerrar la travesía."
	if bedtime: return "Cuando quieras terminar el día, acercate a la cama y tocá E."
	if pending_return: return "Volvé a pie al refugio y usá la radio junto a la entrada."
	if stage == 10: return "Tomá el sendero oeste al salir de la tranquera. Al encontrar el cable, seguilo hasta el malacate."
	if stage == 11: return "R · Consultá a Mara por el reflejo."
	if stage == 13:
		if not summit_mapped: return "Salí por la tranquera y seguí el sendero del este hasta el inicio del ascenso."
		return "Seguí la senda del acceso y revisá el campamento antes de la cumbre." if not camp_read else "Seguí las pircas hasta la cumbre."
	if stage == 16: return "Seguí los mojones de la quebrada oeste hasta la pasarela."
	if stage == 17: return "R · Pasale la marca del agua a Mara."
	if stage == 18: return "Volvé a dormir al refugio."
	if stage == 19:
		if at_departure_stop(): return "R · Despedite de Mara en la parada."
		return "Andá a la parada para despedirte de Mara. Podés pasar por el museo antes."
	if stage == 14: return "R · Pasale a Mara lo que ves desde la cumbre."
	if stage == 8: return "Día 25 · Pasá el museo y el abra para llegar al hito del filo."
	if stage == 9: return "R · Pasá el parte del filo." if not route_reported else "Volvé al refugio."
	if stage == -1: return "Abrí la puerta con E y entrá al refugio."
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
	journal_page = 0
	var current := objective()
	if stage >= 2: current += "\n\nPoste del cauce · 12 de julio."
	elif read_note: current += "\n\nRevisar la fecha del poste."
	var keepsake := str(keepsakes.get("despedida", ""))
	if not keepsake.is_empty(): current += "\n\n" + keepsake
	journal_pages = [{"title": "Cuaderno · Encargo", "text": current}]
	add_diary_entries()
	add_field_notes()
	show_journal_page()

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

func show_journal_page():
	overlay("journal", "", "")
	journal_view.display(journal_pages[journal_page], journal_page, journal_pages.size())

func walk():
	journal_view.hide()
	player.looking_only = false
	compass_out = false
	overlay_choices.hide()
	recall.hide()
	radio_panel.hide()
	hands.hold("")
	mode = "map" if hands.map_requested else "walk"
	words.text = ""
	shade.hide()
	cross.visible = mode == "walk"
	if mode == "map":
		hint.text = "M · guardar el mapa"
		map.objective_mark = map_destination()
	player.walking = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func conversation(lines: Array, next: String):
	var replying: bool = mode in ["choice", "report", "reception", "field_report", "day2_reply", "departure_radio", "trail_chat"]
	sequence = lines.duplicate()
	after = next
	speak()
	if replying: hands.press_button()

func speak():
	radio.play()
	var cue := "Espacio · seguir   /   Esc · volver" if after == "last_call" else "Espacio · seguir"
	overlay("talk", "Mara\n\n" + str(sequence.pop_front()), cue)

func radio_available() -> bool:
	return at_departure_stop() or mission_radio_available() or not available_trail_chat().is_empty()

func at_departure_stop() -> bool:
	return stage == 19 and LastNight.near_stop(player.position)

func mission_radio_available() -> bool:
	return (stage == 0 and not heard) or awaiting_call or stage == 2 or (stage == 5 and not bedtime) or observing or (stage == 9 and not route_reported) or stage in [11, 14, 17]

func available_trail_chat() -> String:
	if mission_radio_available() or not player.climb_points.is_empty(): return ""
	return Mara.available(stage, player.position, bedtime, second_sighting, trail_replies)

func can_visit_mara() -> bool:
	return Mara.can_visit(trail_replies)

func start_trail_chat(topic: String):
	trail_topic = topic
	var chat: Array = Mara.TOPICS[topic]
	radio.play()
	overlay("trail_chat", "Mara · " + chat[1], chat[2], "radio")

func transmit():
	if not radio_available(): return
	radio_exchange()
	hands.press_button()

func welcome_mara():
	conversation(["¿Llegaste bien? Soy Mara, del puesto de abajo.", "Dejá la mochila donde puedas. Esta noche no hay nada que medir.", "Mañana te llamo temprano. Antes de dormir probá que cierre bien la puerta."], "choice")

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
			overlay("departure_radio", "Mara · Estoy acá. ¿Cómo va esa última mañana?", ["Charlar un rato.", "Despedirte antes del colectivo.", "Guardar la radio."], "radio")
		return
	if not chat.is_empty():
		start_trail_chat(chat)
		return
	if awaiting_call:
		var brief: Array
		match stage:
			1: brief = ["Buen día. ¿Descansaste algo?", "Hoy me hacen falta dos datos.", "Salí por la tranquera y seguí el cartel del cauce. La huella da la vuelta por atrás.", "Fijate qué fecha tiene la chapa del poste en la bajada."]
			6: brief = ["Buen día. Ayer perdimos una llamada del puesto de arriba.", "¿Te llegás hasta la antena del abra?", "Pasá el museo y llamame desde la antena.", "Mi puesto queda antes de la parada. Es el de la puerta de madera. Si un día se corta del todo, buscame ahí."]
			16: brief = ["¿Viste cómo creció el arroyo?", "Tomá el sendero oeste desde el refugio. En el cable buscá las pircas de la quebrada.", "Probá la pasarela alta. Decime hasta dónde llegó el agua."]
			13: brief = [
				"¿Te animás a subir hasta la cumbre?",
				"Desde mi patio, el cable y el corte parecen tocarse. Quiero ver dónde queda esa luz en el mapa.",
				"Tomá el sendero del este. La subida empieza en el banco.",
				"En la lona del campamento hay un cuaderno. Fijate desde dónde miraban antes de seguir al hito."
			]
			10:
				brief = ["Hay una chapa suelta en el malacate. A cierta hora devuelve el sol hacia el puesto."]
				if filo_report_reply == 0:
					brief.push_front("Le pasé a los de mantenimiento tu vuelta por la vaguada. Ya llegaron al cable.")
				elif filo_report_reply == 1:
					brief.push_front("Les avisé lo del escalón. Dejaron la carga abajo y subieron por turnos.")
				brief.append_array(["Salí por la tranquera y doblá a la izquierda. Seguí el cable viejo hasta la chapa.", "Cuando la gires, llamame. Desde acá puedo ver si cambia el reflejo."])
			8: brief = [
				"Se desmoronó un pedazo de la laja. Dejaron la cuerda, pero hay gente que mañana tiene que pasar con herramientas.",
				"Podés probar la cuerda o rodear por la vaguada, a la derecha del cartel. Las dos huellas se juntan.",
				"Pasá el museo y el abra hasta el hito del filo. Desde ahí se ve dónde se junta todo. Avisame qué camino les marco."
			]
		conversation(brief, "brief")
		return
	if stage == 17:
		var reply := "Bien. Mañana llevo pintura para marcarlo."
		if summit_echo_response == 0:
			reply = "Lo de arriba podía ser un rebote. Esto lo escuchaste antes de que yo prendiera la radio."
		elif crossing_response == 0:
			reply = "Oí tu indicativo dos veces. Entre una y otra soltaste el botón."
		elif crossing_response == 1:
			reply = "Avisame cuando prendas la linterna. Desde acá solo veo la lluvia."
		elif crossing_response == 2:
			reply = "Dejá libre la pasarela. Si había algo en el agua, desde la orilla tampoco lo vas a ver bien."
		conversation([reply, "Ya tengo la marca. Volvé por las pircas al cable.", "¿Sabés qué hice mientras subía el agua? Puse dos tazas en la mesa.", "Siempre me sobra una."], "crossing_home")
		return
	if stage == 14:
		var bearing := "Entonces el camino de la camioneta y la muesca quedan a distinta altura."
		if quarry_reply == 1: bearing = "El rumbo que anotaste en el malacate cae por detrás de la ladera. Marcá también desde dónde lo viste."
		conversation([bearing, "Desde acá solo veo una raya. Me gusta que me cuentes qué hay del otro lado.", "Por hoy, con que llegues al banco del acceso alcanza."], "summit_home")
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
	var reply := "¿Ya tenés la llave? El colectivo pasa en un rato."
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
		memory = "Anoche busqué la estrella de la pileta. Había nubes. Igual me quedé ahí un rato." if trail_replies["cielo"] == 1 else "Anoche salí a ver si abría el cielo. Me acordé de lo que me contaste de tu viejo."
	elif trail_replies.get("ventana", -1) == 0:
		memory = "La pava que puse anoche sigue en la hornalla. Cuando junté las tazas me quedó una limpia."
	elif trail_replies.get("sueno", -1) == 0:
		memory = "¿Te acordás de ese cielo que soñaste? Si te vuelve a pasar, guardá el dibujo. Algún día me lo mostrás."
	elif trail_replies.has("museo"):
		memory = "Llovió y pensé en las tardes que mi vieja me llevaba al museo. Hacía años que no se lo contaba a nadie." if trail_replies["museo"] == 0 else "Ayer enderecé la mesa. El cartel del museo quedó libre por si querés darle un último uso."
	elif trail_replies.get("cauce", -1) == 1:
		memory = "Ese primer día me pediste que te acompañara un rato. A mí también me hizo bien que hubiera alguien del otro lado."
	elif trail_replies.get("primera_noche", -1) == 0:
		memory = "Me acostumbré a ver la luz del refugio cuando cierro la cortina. Hoy voy a extrañar verla prendida."
	elif trail_replies.get("ultima_curva", -1) == 0:
		memory = "Si conseguís el asiento de la ventanilla, fijate en la última curva. A esta hora le da el sol a la ladera."
	var departure := "Dejame la llave en el buzón cuando pases. Buen viaje."
	if close_enough:
		departure = "Si te queda tiempo antes del colectivo, ya sabés cuál es mi puerta."
		if trail_replies.has("bajada"):
			departure = "Mejor traeme la llave en persona, si te da el tiempo. Golpeá. Todavía me sobran dos tornillos." if trail_replies["bajada"] == 0 else "El día que bajaste de la cumbre hice durar dos platos toda la bajada. Hoy, si querés pasar, te guardo una taza."
	var lines := [reply, farewell]
	if not memory.is_empty(): lines.append(memory)
	lines.append_array([departure, "Bueno. Gracias por contestar."])
	conversation(lines, "last_call")

func update_flashlight():
	var active: bool = flashlight_out and (mode in ["walk", "approach", "map", "cave", "dream", "sighting"] or hands.requested_pose == "radio") and mode != "menu"
	player.flashlight.visible = active

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.keycode
	var advance = key in [KEY_SPACE, KEY_ENTER]
	if mode == "journal":
		if advance or key in [KEY_ESCAPE, KEY_TAB]:
			walk()
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
		if key == KEY_E or advance:
			field_note += " Noche 7 · Al despertar todavía me acordaba de esas estrellas. Intenté dibujarlas antes de prender la luz."
			start_day25()
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
	if key == KEY_M and mode in ["approach", "walk"]:
		if mode == "approach" and page == 4: arrival_action = true
		paused_from = mode
		mode = "map"
		cross.hide()
		hint.text = "M · guardar el mapa"
		hands.show_map(true)
		map.location = player.position
		map.objective_mark = map_destination() if paused_from == "walk" else null
		map.queue_redraw()
		map.show()
		update_flashlight()
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
		player.velocity.y = 5.7
		return
	if mode == "sighting":
		if key == KEY_E and not sighting_resolving and sighting_focus >= SIGHTING_FOCUS_SECONDS and looking_at_sighting():
			observe_lights()
	elif mode == "last_dream_prelude" and advance:
		mode = "sleeping"
		hint.text = ""
		reveal_dream(create_tween())
	elif mode == "last_voice_answer" and advance:
		finish_dream()
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
		match dream_variant():
			1:
				if looking_at_dream_sky(): finish_dream()
			2:
				if has_piece:
					finish_dream()
				elif near_dream_piece():
					has_piece = true
					dream_piece.queue_free()
					hands.hold("piece")
			3:
				if near_last_arch(): hear_last_voice()
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
				match target:
					"Sendero del cauce":
						overlay("message", "La huella rodea la cerca y baja al cauce. El poste está a mitad de la bajada.", "Espacio · seguir")
					"Sendero oeste":
						overlay("message", "La huella del oeste une la tranquera del refugio con el cable de la cantera.", "Espacio · seguir")
					"Desvío del cauce":
						overlay("message", "La senda de la izquierda sube al mirador y vuelve a bajar al cauce. La de enfrente va directo a la regla.", "Espacio · seguir")
					"Mirador del cauce":
						overlay("message", "Desde arriba distinguís el fondo de piedra y la marca de la última crecida. La huella baja por la otra orilla.", "Espacio · seguir")
					"Desvío de la quebrada":
						overlay("message", "Las pircas siguen la ladera oeste. Alcanzás a ver lo que queda de una pasarela más arriba.", "Espacio · seguir")
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
					"Guante izquierdo":
						overlay("message", "Colgás del clavo el guante izquierdo. Fue el que te tocó la primera noche que saliste a mirar el cielo con Paula. Cuando lo das vuelta, todavía se ve la costura que ella arregló con hilo claro.", "Espacio · dejarlo colgado")
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
							valley.unpack_book()
							open_book()
					"Puerta": valley.toggle_door()
					"Puerta del baño": valley.swing_side_door(valley.privy_hinge)
					"Puerta del museo": valley.swing_side_door(valley.museum_hinge)
					"Puerta de Mara":
						overlay("message", "La puerta de madera tiene un buzón chico al lado del marco.", "Espacio · seguir")
					"Tranquera": valley.swing_side_door(valley.yard_hinge)
					"Cama":
						if bedtime: overlay("rest", "¿Querés acostarte y terminar la jornada?", ["Dormir", "Seguir despierto"])
						else: overlay("message", "Todavía te queda algo por hacer. " + objective(), "Espacio · levantarse")
					"Observar el Cielo": open_book()
					"Flora serrana", "Cuaderno de campo": overlay("message", target + "\n\nHay una hoja seca de molle entre las páginas.", "Espacio · cerrar")
					"Radio": transmit()
					"Nota":
						read_note = true
						overlay("message", "Turno de temporada. Canal 3 para comunicarte con el puesto de abajo. Las baterías de repuesto están en el cajón.", "Espacio · dejar la nota")
					"Regla del cauce":
						if stage == 4:
							stage = 5
							creek_note = "Día 2 · Cauce seco. Mica en la piedra del cruce."
						overlay("message", "Cero centímetros. Cuando te agachás, una escama de mica devuelve el sol. Desde arriba la misma piedra parece gris.", "Espacio · levantarse")
					"Banco": overlay("message", "La madera está lisa donde se sienta la gente.", "Espacio · volver")
					"Parada":
						if at_departure_stop(): transmit()
						else: overlay("message", "El poste marca la curva donde para el colectivo.", "Espacio · volver")
					"Puesto de abajo":
						overlay("message", "La huella llega hasta el puesto del otro lado de la curva.", "Espacio · volver")
					"Antena del abra":
						if stage == 7 and not bedtime:
							if not second_sighting:
								show_sighting()
								return
							valley.night()
							overlay("bench", "Al pie de la antena se alcanza a ver el techo del puesto de abajo. Extendés la antena y esperás a que aclare el canal.", "Espacio · escuchar", "radio")
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
			score.silence(0.8)
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
			score.silence(0.6)
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
		elif after == "brief" and stage == 1:
			overlay("day2_reply", "Mara espera con el canal abierto.", ["Dormí de un tirón.", "Todavía me estoy acostumbrando al puesto."], "radio")
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
			bedtime = true
			walk()
			save_game(true, "walk")
		elif after == "choice": overlay("choice", "Tenés el botón de la radio bajo el pulgar.", ["Costó abrir la puerta.", "Todo en orden."])
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
		overlay("message", CROSSING_NOTES[index] + "\n\nEl canal queda abierto. Desde el puesto, Mara te pide la marca del agua.", "Espacio · volver")
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
		overlay("last_voice_answer", answer, "Espacio · cerrar los ojos")
	elif mode == "departure_choice":
		if index == 0:
			ending_at_door = false
			save_game(true, "end")
			show_ending()
		elif index == 1 and can_visit_mara():
			approach_mara_door()
	elif mode == "day2_reply":
		var reply: = "Me alegro. Esa cama tiene sus años." if index == 0 else "A mí la primera noche me despertó hasta el viento."
		conversation([reply, "Nos hablamos cuando tengas la lectura."], "day2_confirm")
	elif mode == "departure_radio":
		match index:
			0: start_trail_chat(trail_topic)
			1: farewell_mara()
			2: walk()
	elif mode == "trail_chat":
		trail_answer = index
		conversation(Mara.TOPICS[trail_topic][3][index], "trail_chat_done")
	elif mode == "choice":
		conversation(["Para cerrar tenés que levantar un poquito la hoja. Me olvidé de avisarte.", "Que descanses. Mañana hablamos."] if index == 0 else ["Bueno. Si te despertás y no reconocés el ruido, suele ser el viento en el alero.", "Que descanses. Mañana hablamos."], "welcome_done")
	elif mode == "rest" and index == 1: walk()
	elif mode == "rest" and index == 0:
		if stage == 18:
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
		if stage == 0 and not valley.book_unpacked: valley.unpack_book()
		bedtime = false
		if stage in [7, 9]:
			begin_dream()
		else:
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
		if index == 0:
			field_note += " Se lo conté a Mara."
			conversation(["¿Celeste? Qué fino el cerro, ahora hace juego con el cielo.", "Guardá el rumbo. Cuando llegues a la antena probamos el canal."], "sighting_return")
		else:
			field_note += " Guardé el rumbo para compararlo después."
			walk()
	elif mode == "quarry_sighting_response":
		quarry_reply = index
		var line := "Entonces lo que vi en la chapa era una cosa sola. Esa otra quedó arriba del corte." if index == 0 else "Guardá también la hora. Desde la cumbre vamos a poder comparar mejor el rumbo."
		conversation([line, "Entre el ruido oí «todavía». Pensé que habías hablado vos.", "¿Seguís ahí? Me quedo hasta que llegues."], "quarry_home")
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
		conversation(["Ahora sí. Te oigo clarito."] if index == 0 else ["Dale. Dejo la radio prendida."], "reception_done")
	elif mode == "report":
		if index == 0:
			creek_note += " Parte enviado."
			conversation(["Anotado.", "Cuando tengas el próximo parte, me encontrás acá."], "sleep")
		else:
			creek_note += " Le contaste a Mara lo que viste."
			conversation(["Mi viejo volvía de ahí con los bolsillos llenos de esas piedritas.", "Cuando lavábamos los pantalones, brillaba todo el patio."], "sleep")

func begin_dream(preserve_bed: bool = false, fade_from_black: bool = false):
	score.cue("otromundo", 63, -14.0, 2.5)
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
			hint.text = "Espacio · abrir los ojos")
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

func position_on_planet():
	ensure_dream_world()
	player.intro_center = LastNight.PLANET
	player.intro_heading = 0.0
	player.position = LastNight.dream_point(dream_variant(), 0.0) + Vector3.UP * 0.16
	player.rotation.y = 0.0

func explore_dream():
	ensure_dream_world()
	if player.position.distance_to(LastNight.PLANET) > 100.0:
		position_on_planet()
	player.intro_center = LastNight.PLANET
	player.intro_heading = 0.0
	player.camera.far = NIGHT_SCENE_VIEW
	walk()
	if dream_variant() == 2 and not has_piece and not is_instance_valid(dream_piece):
		var foot := LastNight.dream_point(2, 21.0)
		dream_piece = valley.box(foot + Vector3.UP * 0.8, Vector3(0.27, 0.27, 0.27), "9eaaad")
		dream_piece.rotation = Vector3(0.45, 0.7, 0.3)
		(dream_piece.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dream_piece.reparent(dream_world)
	mode = "dream"
	if has_piece and dream_variant() == 2: hands.hold("piece")

func looking_at_dream_sky() -> bool:
	return -player.camera.global_basis.z.y > 0.36

func near_dream_piece() -> bool:
	return is_instance_valid(dream_piece) and player.position.distance_to(dream_piece.position) < 3.0

func near_last_arch() -> bool:
	return player.position.distance_to(LastNight.final_arch()) < 3.2

func finish_dream():
	score.silence(2.2)
	overlay("waking", "", "")
	shade.color = Color(0, 0, 0, 0)
	var fade: = create_tween()
	fade.tween_property(shade, "color:a", 1.0, 1.2)
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
			day_card("Día 41 · El dibujo", waking + "Intentás dibujar el arco en el reverso de un parte. Cuando enderezás el dintel, deja de parecerse al del sueño. Hoy termina tu relevo. Podés pasar por el museo antes de ir a la parada. Mara te espera en la radio para despedirse.", "Espacio · levantarse")
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

func start_day36():
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

func open_book():
	overlay("book", "", "")
	var book_memory: = str(keepsakes.get("libro", ""))
	var travel_memory: = str(keepsakes.get("puesto", ""))
	book_view.open("imprenta grande" in book_memory, "cinta verde" in travel_memory, stage >= 8)

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
	if objective_seconds > 0.0:
		hint.text = "Revisá la estación y los cuadernos." if local.z < -22.0 else "Usá la linterna y saltá entre las tres piedras. R · Mara"
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
	var caption := "La radio queda en silencio. Desde la parada ves el colectivo doblar en la curva."
	if can_visit_mara():
		overlay("departure_choice", caption + " Un poco antes sale el sendero al puesto de abajo.", ["Subís al colectivo.", "Tomás el sendero y vas a golpear la puerta de Mara."])
	else:
		overlay("departure_choice", caption, "Espacio · subir al colectivo   /   Esc · volver")

func approach_mara_door():
	valley.morning()
	hands.show_map(false)
	player.intro_center = Vector3.ZERO
	player.intro_heading = 0.0
	player.velocity = Vector3.ZERO
	walk()
	mode = "mara_door"
	objective_seconds = 4.0

func crux_axis() -> Vector3:
	var sidereal: float = SkyGuide.NIGHTS[valley.sky_chapter][0]
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
	overlay("last_voice", "Del otro lado del arco el cielo tiene dos lunas. Oís una voz: «¿Ya la encontraste?». La radio está apagada. Te acordás de esa pregunta, pero no del todo de la voz.", ["«¿Quién es…?»", "«¿Papá…?»"])

func show_ending():
	var memory_of_book := str(keepsakes.get("libro", "En la guarda sigue el dibujo que hiciste con tu papá."))
	ending_paragraphs = [
		"Subís al colectivo. Desde el asiento ves la curva que baja al puesto. Antes de que desaparezca, abrís Observar el Cielo. " + memory_of_book,
		"La radio va apagada en tu mochila. Justo al doblar oís dos golpes secos."
	]
	if ending_at_door:
		ending_paragraphs = [
			"Golpeás dos veces. Guardás la llave en el bolsillo para tener la mano libre. Del otro lado cruje una tabla.",
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
	var title: String = "Llegada" if stage < 0 else ("Noche 1" if stage == 0 else ("Día 2" if stage < 6 else ("Día 7" if stage < 8 else "Día 25")))
	if stage >= 19: title = "Día 41"
	elif stage >= 16: title = "Día 36"
	elif stage >= 13: title = "Día 32"
	elif stage >= 10: title = "Día 27"
	var data = {"version": 1, "slot": slot, "title": title, "state": state, "mode": resume_mode, "pose": player.transform, "pitch": player.camera.rotation.x, "paragraph": recall.paragraph, "chapter": valley.sky_chapter, "museum_offset": Museum.SITE_OFFSET, "door": valley.door_open, "book": valley.book_unpacked, "night": valley.sky_mat.get_shader_parameter("nightfall"), "dusk": valley.sky_mat.get_shader_parameter("dusk"), "music": music.get_playback_position() if music.playing else 0.0}
	return Saves.write(slot, automatic, data)

func restore(data: Dictionary):
	score.silence(0.2)
	slot = data.slot
	for key in STATE:
		if data.state.has(key): set(key, data.state[key])
	trail_replies = Mara.saved_replies(data.state)
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
	if stage >= 1:
		valley.unpack_book()
	elif stage == 0:
		valley.leave_bag()
		bedtime = heard
	if stage < 0:
		music.begin()
		music.seek(data.music)
	if data.door: valley.toggle_door()
	if float(data.get("dusk", 0.0) if data.dusk != null else 0.0) > 0.3: valley.sunset()
	var saved_night: = clampf(float(data.night) if data.get("night") != null else 0.0, 0.0, 1.0)
	if stage == 7 and day7_dusk and not second_sighting:
		valley.sky_mat.set_shader_parameter("nightfall", saved_night)
		valley.night(12)
	elif stage == 15:
		valley.sky_mat.set_shader_parameter("nightfall", saved_night)
		valley.night(maxf(1.0, SUMMIT_NIGHT_SECONDS * (1.0 - saved_night)))
	elif saved_night > 0.0:
		valley.arrival_light(saved_night)
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
			if player.position.distance_to(Arrival.origin(page)) <= 80.0:
				player.position = Arrival.safe_saved_position(page, player.position, arrival_action)
			approach()
		"dream":
			score.cue("otromundo", 63, -14.0, 2.5)
			player.low_gravity = true
			valley.strange_sky(true)
			explore_dream()
		_: walk()

func start_day25():
	stage = 8
	awaiting_call = true
	valley.configure_sky(3)
	valley.morning()
	save_game(true, "walk")
	day_card("Día 25 · La quebrada larga", "Hace días que usás el cuaderno para anotar las lecturas. Esta mañana lo abrís por la hoja donde dibujaste las estrellas del sueño. La dejás marcada. Sobre el escritorio está el libro de tu viejo. Todavía podés comparar el rumbo de los destellos del abra. Hoy Mara te espera en la radio.", "Espacio · levantarse")

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
			center = valley.route.crossing_point(1.0) + Vector3(-12, 24, -46)
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
			overlay("sighting_response", "Un punto azul se apaga. El otro tarda un instante más. La radio se corta a mitad de una palabra: «…cruces…».", ["Le preguntás a Mara si los vio.", "Anotás el rumbo para más tarde."])
		Sighting.QUARRY:
			score.cue("cosmic", 28, -16.0, 2.0)
			radio.play_interference()
			var caption := "La luz queda suspendida por encima del corte. La chapa sigue contra el bastidor."
			if book_light_notes: caption += " Te acordás de las dos marcas que dejaste en el libro. Desde acá el rumbo es otro."
			overlay("quarry_sighting_response", caption, ["Le decís a Mara que la chapa sigue quieta.", "Anotás el rumbo antes de contestar."], "radio")
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
	stage = int({"arrival": 0, "2": 1, "sighting": 7, "7": 6, "dream7": 7, "25": 8, "dream25": 9, "27": 10, "32": 13, "camp": 13, "36": 16, "dream36": 18, "41": 19}.get(code, 0))
	heard = stage > 0
	if stage > 0: valley.unpack_book()
	else: valley.leave_bag()
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
		begin_dream()
	elif code == "sighting":
		player.position = valley.route.at(valley.route.trail(228), 228) + Vector3.UP * 0.12
		player.rotation.y = 0.0
		valley.arrival_light(1.0)
		show_sighting()
	elif stage == 0:
		bedtime = false
		valley.arrival_light(1.0)
		welcome_mara()

func map_destination() -> Variant:
	if stage < 0: return Vector3.ZERO
	if stage == 15: return valley.route.summit_return_marker(player.position)
	if (bedtime or awaiting_call) and stage != 19: return Vector3.ZERO
	var route = valley.route
	match stage:
		1, 2: return Creek.post()
		4: return Creek.marker()
		5: return Vector3.ZERO
		7: return route.at(route.trail(420), 420)
		8: return route.at(route.trail(922), 922)
		10: return route.quarry_point(1.0)
		13:
			if not summit_mapped: return route.ascent_point(0)
			return route.summit_point(1) if camp_read else route.camp_point()
		16: return route.crossing_point(1)
		19: return LastNight.STOP
	return null
