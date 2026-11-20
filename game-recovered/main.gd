extends Node3D

const Arrival = preload("res://llegada.gd")
const Creek = preload("res://cauce.gd")
const SkyGuide = preload("res://constelacion.gd")
const LastNight = preload("res://final_night.gd")
const Saves = preload("res://partidas.gd")
const STATE = ["page", "stage", "keepsakes", "bedtime", "field_note", "crossing_note", "fox_seen", "hiker_met", "route_reported", "observing", "pending_return", "heard", "read_note", "creek_note", "bed_pose", "bed_pitch", "gate_jumped", "map_read", "awaiting_call", "dream_count", "branch_found", "mapped_distance", "has_piece", "summit_mapped", "camp_read", "arrival_action", "second_sighting", "day7_dusk", "trail_check_in", "asked_mara_to_stay", "archive_entry", "crossing_response", "night_investigation", "ending_at_door", "sky_memories", "compass_lost", "last_voice_reply", "scored_walks"]
var flashlight_out: = false
var camp_read: = false
var summit_mapped: = false
var has_piece: = false
var dream_piece: MeshInstance3D
var dream_world: Node3D
var archive_entry: = -1
var crossing_response: = -1
const CROSSING_NOTES = [
	"Al retroceder, la voz repitió mi indicativo. Mara también la oyó.", 
	"Apagué la linterna. Vi una figura quieta del otro lado de la pasarela.", 
	"Alumbré el cauce. Por un instante vi lo que parecía una mano agarrada al travesaño."
]
var night_investigation: = 0
var ending_at_door: = false
var cave_built: = false
var door_built: = false
var cave_checkpoint: = LastNight.ENTRY
var cave_notebooks_read: = false
var cave_exit_open: = false
var follow_last_light: = false
var crux_found: = false
var compass_lost: = false
var last_voice_reply: = -1
var sky_memories: Array = []
var scored_walks: Array = []
var score = preload("res://banda_sonora.gd").new()
var trail_check_in: = false
var asked_mara_to_stay: = false
var book_view = preload("res://libro.gd").new()
var postcard_view = preload("res://postal.gd").new()
var rain_view: = ColorRect.new()
var branch_found: = false
var mapped_distance: = 0.0
var radio_hint: = Label.new()
var sighting_waiting := false
var dream_count: = 0
var compass_out: = false
var ambience = preload("res://ambiente.gd").new()
var awaiting_call: = false
var slot: = 1
var paused_from: = ""
var gate_jumped: = false
var map_read: = false
var show_objective: = false
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
var second_sighting: = false
var day7_dusk: = false
var debug_run: = false
var arrival_action: = false
var bedtime: = false
var field_note: = ""
var crossing_note: = ""
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
	var center: = Arrival.origin(page)
	if reset_position or player.position.distance_to(center) > 80:
		player.position = center + Vector3.UP * 0.12
		player.rotation = Vector3(0, Arrival.HEADINGS[page], 0)
		player.camera.rotation = Vector3.ZERO
		player.velocity = Vector3.ZERO
		arrival_action = false
	if page == 0: set_arrival_bag_visible( not arrival_action)
	player.intro_center = center
	player.intro_heading = Arrival.HEADINGS[page]
	hint.text = "WASD · caminar     Mouse · mirar" if page == 0 else ""

func use_arrival_item():
	if arrival_action or target != Arrival.ACTIONS[page] or page in [1, 3, 4]: return
	if page == 5:
		player.climb_to(Arrival.world_position(page, Vector3(0, 1.39, -11.5)))
		return
	arrival_action = true
	if page == 0: set_arrival_bag_visible(false)
	hint.text = ""

func set_arrival_bag_visible(shown: bool):
	valley.arrival_bag.visible = shown
	valley.arrival_bag.get_child(0).collision_layer = 1 if shown else 0

func _unhandled_input(event):
	if mode == "book" and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: book_view.turn(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT: book_view.turn(-1)
		return
	if mode == "approach" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		use_arrival_item()

func memory(paragraph: int = 0):
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
	var day: = calendar_day()
	valley.update_calendar(day)
	valley.update_weather(day)
	valley.update_shelter_wall(day)
	if mode == "walk": score_daily_walk(day)
	var rain_visible: bool = stage >= 16 and stage <= 17 and mode in ["walk", "map"] and (player.position.z < -0.5 or absf(player.position.x) > 3.4)
	if rain_visible != rain_view.visible:
		rain_view.visible = rain_visible
		rain_view.material.set_shader_parameter("intensity", 0.62 if rain_visible else 0.0)
	if mode == "sighting" and sighting_waiting: update_sighting()
	if mode == "cave":
		update_cave()
	elif mode == "mara_door":
		if player.position.y < LastNight.DOOR.y - 0.5:
			player.position = LastNight.DOOR + Vector3.UP * 0.08
			player.velocity = Vector3.ZERO
		update_night_target()
		hint.text = "E · golpear la puerta" if target == "Puerta de Mara" else ""
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
	if mode in ["walk", "map"] and stage >= 10 and not branch_found:
		if player.position.distance_to(valley.route.at(valley.route.trail(300), 300)) < 22:
			branch_found = true
	if mode in ["approach", "walk", "dream", "map"]:
		var velocity: = Vector2(player.velocity.x, player.velocity.z).length() if player.is_on_floor() else 0.0
		var outdoors: bool = player.position.z < 0 or absf(player.position.x) > 3.5
		hands.step(delta, velocity)
		if mode == "map":
			map.location = player.position
			map.queue_redraw()
		ambience.update(delta, velocity, mode != "dream" and outdoors and float(valley.sky_mat.get_shader_parameter("nightfall")) < 0.5)
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

	if mode == "approach":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		var local: = Arrival.local_position(page, player.position)
		if page == 1 and local.z < -10.3 and local.y > 0.35 and absf(local.x) < 1.65:
			arrival_action = true
		if page == 5 and local.y >= 1.36 and local.z < -10.5:
			arrival_action = true
		if arrival_action and local.z < -17:
			memory()
		elif not arrival_action and page == 1:
			hint.text = "Espacio · saltar el tronco"
		elif not arrival_action and page in [3, 4]:
			hint.text = "B · probar la brújula" if page == 3 else "M · consultar el mapa"
		elif not arrival_action and target == Arrival.ACTIONS[page]:
			hint.text = "E o clic · " + target
		else:
			hint.text = "WASD · caminar     Mouse · mirar" if page == 0 and not arrival_action else ""
	elif mode == "walk":
		var hit = player.ray.get_collider()
		target = str(hit.get_meta("item", "")) if hit else ""
		if stage == -1 and player.position.z < 0 and target == "":
			hint.text = "E · interactuar al mirar la puerta"
			return

		if not awaiting_call and stage == 8 and crossing_note.is_empty() and player.position.z < -247 and player.position.z > -268:
			crossing_note = "Subiste por la vaguada." if player.position.x > valley.route.trail(170) + 16 else "Subiste por la laja."
		if stage == -1 and player.position.z > 0 and abs(player.position.x) < 3.4 and player.position.z < 5.9:
			stage = 0
			music.close()
			score.cue("noche", 29, -18.0, 4.0)
			bedtime = true
			valley.leave_bag()
			save_game(true, "walk")
			hint.text = ""
			return
		if not hit and ( - player.camera.global_basis.z).y > 0.12 and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6:
			var star: = SkyGuide.identify( - player.camera.global_basis.z, valley.sky_chapter)
			if can_watch_sky():
				hint.text = "E · quedarte a mirar el cielo"
				return
			hint.text = star + ("   /   R · Parte" if observing and show_objective else "")
		else:
			hint.text = "E · " + target if target != "" else (objective() if show_objective else "")

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

func objective() -> String:
	if awaiting_call: return "R · Escuchá a Mara en la radio."
	if not player.climb_points.is_empty(): return "Buscás apoyo en la piedra."
	if stage == 0: return "Primera noche · Dejá la mochila y acercate a la cama."
	if stage == 5 and not bedtime: return "R · Pasale a Mara la lectura del cauce."
	if stage == 12 and player.position.z < -20.0: return "Volvé junto al cable y seguí el sendero oeste hasta la tranquera."
	if bedtime: return "Cuando quieras terminar el día, acercate a la cama y tocá E."
	if pending_return: return "Volvé a pie al refugio y usá la radio junto a la entrada."
	if stage == 10: return "Tomá el sendero oeste al salir de la tranquera. Al encontrar el cable, seguilo hasta el malacate."
	if stage == 11: return "R · Consultá a Mara por el reflejo."
	if stage == 13:
		if not summit_mapped: return "Bajá al acceso del cerro por el camino del este."
		return "Seguí la senda del acceso y revisá el campamento antes de la cumbre." if not camp_read else "Seguí las pircas hasta la cumbre."
	if stage == 16: return "Seguí los mojones de la quebrada oeste hasta la pasarela."
	if stage == 17: return "R · Pasale la marca del agua a Mara."
	if stage == 18: return "Volvé a dormir al refugio."
	if stage == 19:
		return "Leé la ficha de la maqueta en el museo." if archive_entry < 0 else "R · Avisale a Mara que dejaste el parte."
	if stage == 14: return "R · Pasale a Mara lo que ves desde la cumbre."
	if stage == 15: return "Bajá por la senda del acceso y volvé al refugio."
	if stage == 8: return "Día 25 · Seguí la senda que continúa detrás del mirador hasta el hito del filo."
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

func walk():
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
	var replying: bool = mode in ["choice", "report", "reception", "field_report", "day2_reply", "trail_check_in"]
	sequence = lines.duplicate()
	after = next
	speak()
	if replying: hands.press_button()

func speak():
	radio.play()
	overlay("talk", "Mara\n\n" + str(sequence.pop_front()), "Espacio · seguir")

func radio_available() -> bool:
	return awaiting_call or (stage == 19 and archive_entry >= 0) or can_check_in() or stage == 2 or (stage == 5 and not bedtime) or observing or (stage == 9 and not route_reported) or stage in [11, 14, 17]

func can_check_in() -> bool:
	return stage == 4 and not trail_check_in and player.position.z > 30.0 and Creek.trail_distance(Vector2(player.position.x, player.position.z)) < 14.0

func transmit():
	if not radio_available(): return
	radio_exchange()
	hands.press_button()

func radio_exchange():
	if stage == 19 and archive_entry >= 0:
		var reply: = "Así está bien. El rumbo y la hora ya son bastante." if archive_entry == 0 else "Si pusiste que lo soñaste, dejalo. El que lea va a saber de dónde salió."
		var farewell: = "Al principio esperaba tu parte por el trabajo. Después empecé a dejar la radio prendida antes de que llamaras."
		if night_investigation > 0:
			farewell = "Había tanto ruido anoche que por un rato pensé que no ibas a volver a contestar. Hoy dejé la radio prendida desde temprano."
		var goodbye: = "Ese primer día me pediste que te acompañara un rato. A mí también me hizo bien que hubiera alguien del otro lado." if asked_mara_to_stay else "Al próximo relevo le voy a decir dónde dejaste tus notas. A vos te quería decir otra cosa."
		conversation([reply, farewell, goodbye, "Si te queda tiempo antes del colectivo, ya sabés cuál es mi puerta.", "Bueno. Gracias por contestar."], "last_call")
		return
	if can_check_in():
		overlay("trail_check_in", "Mara · ¿Cómo te está tratando el camino?", ["Se agradece el silencio.", "Me vendría bien un poco de charla."], "radio")
		return
	if awaiting_call:
		var brief: Array
		match stage:
			1: brief = ["Buen día. ¿Descansaste algo?", "Hoy me hacen falta dos datos.", "Salí por la tranquera y seguí el cartel del cauce. La huella da la vuelta por atrás.", "Fijate qué fecha tiene la chapa del poste en la bajada."]
			6: brief = ["Buen día. Ayer perdimos una llamada del puesto de arriba.", "¿Te llegás hasta la antena del abra?", "Pasá el museo y llamame desde la antena.", "Mi puesto queda antes de la parada. Es el de la puerta de madera. Si un día se corta del todo, buscame ahí."]
			16: brief = ["¿Viste cómo creció el arroyo?", "Tomá el sendero oeste desde el refugio. En el cable buscá las pircas de la quebrada.", "Probá la pasarela alta. Decime hasta dónde llegó el agua."]
			13: brief = ["¿Te animás a subir hasta la cumbre?", "Desde mi patio, el cable y el corte parecen tocarse.", "Salí hacia el este y bajá al acceso del cerro. De ahí arranca la subida."]
			10: brief = ["¿Tenés el mapa a mano?", "Después de la tranquera, doblá a la izquierda. Esa huella te lleva al cable viejo.", "Seguilo hasta el malacate. Desde mi patio se ve ese corte."]
			8: brief = ["Anoche se cortó el paso de la laja.", "Llegá hasta el hito del filo.", "Avisame si se puede volver por abajo."]
		conversation(brief, "brief")
		return
	if stage == 17:
		conversation(["Bien. Mañana llevo pintura para marcarlo.", "¿Sabés qué hice mientras subía el agua? Puse dos tazas en la mesa.", "Siempre me sobra una."], "crossing_home")
		return
	if stage == 14:
		conversation(["Entonces la cantera queda del otro lado.", "Anotá desde dónde la estás mirando.", "Desde acá solo veo una raya. Me gusta que me cuentes qué hay del otro lado.", "Voy a dejar la pava puesta hasta que bajes."], "summit_home")
		return
	if stage == 11:
		conversation(["Ahí la vi.", "Pará. Dejá la chapa como está."], "wait_flash")
		return
	if stage == 9 and not route_reported:
		var report: = crossing_note if crossing_note else "Desde arriba se distingue la vaguada."
		overlay("field_report", report + " Hay gente que va a salir temprano mañana. Elegís qué dejar en el parte.", ["Señalar el rodeo.", "Describir el escalón de roca."], "radio")
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
		0: conversation(["¿Llegaste bien?", "Soy Mara, del puesto de abajo.", "Tengo un rato antes de que hierva el agua."], "choice")
		1: overlay("message", "La radio está en silencio. Falta revisar el poste.", "Espacio · volver")
		2:
			stage = 4
			conversation(["Doce de julio. Repusieron el poste después de una crecida.", "Con la fecha puedo buscar el parte de ese día.", "Seguí bajando hasta el lecho de piedras. La regla está cerca de la curva. Pasame la lectura desde ahí."], "sighting_return")
		4: overlay("message", "Todavía falta medir el cauce. Llamá a Mara cuando tengas la lectura.", "Espacio · volver")
		5:
			radio.play()
			overlay("report", "Día 2 · Parte del cauce\n\nTenés la lectura anotada. Mara te espera en el canal.", ["Pasar la lectura.", "Contarle lo de la mica."])

		6, 7: overlay("message", "El parte es al anochecer. " + objective(), "Espacio · volver")

func update_flashlight():
	var active: bool = flashlight_out and (mode in ["walk", "approach", "map", "cave", "dream"] or hands.requested_pose == "radio") and mode != "menu"
	player.flashlight.visible = active

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.keycode
	var advance = key in [KEY_SPACE, KEY_ENTER]
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
		elif key == KEY_LEFT: book_view.turn(-1)
		elif key == KEY_RIGHT or advance: book_view.turn(1)
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
	if key == KEY_F1 and mode == "walk":
		show_objective = not show_objective
		return
	if key == KEY_L and mode in ["approach", "walk", "map", "cave", "dream"]:
		flashlight_out = not flashlight_out
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
	if mode == "last_voice_answer" and advance:
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
	elif mode in ["arrival", "message", "journal", "pause"] and (advance or key in [KEY_ESCAPE, KEY_TAB]):
		walk()
	elif mode == "walk":
		if not player.climb_points.is_empty() and key != KEY_ESCAPE: return
		match key:
			KEY_ESCAPE: overlay("pause", "Pausa", "Espacio · volver   /   F2 · menú principal")
			KEY_TAB: overlay("journal", "Cuaderno\n\nBajada del refugio → poste → regla del cauce\nLaderas → laja o vaguada → museo → abra → filo\n\n" + objective() + ("\nNota: revisar la fecha del poste." if read_note else "") + ("\nPoste: 12 de julio." if stage >= 2 else "") + ("\n" + creek_note if creek_note else "") + "\n" + str(keepsakes.get("despedida", "")) + ("\n" + field_note if field_note else ""), "Tab · guardar")
			KEY_R: transmit()
			KEY_E:
				if can_watch_sky():
					watch_sky()
					return
				var exhibits = preload("res://museo.gd").LABELS
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
					"Subir al escalón":
						var rock: Vector3 = valley.route.crossing_point(0.72)
						var landing: = rock + Vector3(0, 1.54, - 0.7)
						player.climb_to(landing)
					"Pasarela de la quebrada":
						if stage == 16 and not awaiting_call:
							stage = 17
							field_note += " El agua llegó al travesaño inferior de la pasarela."
							valley.sunset()
							score.cue("misterio", 33, -18.0)
							radio.play_interference()
							overlay("crossing_warning", "Marcás con carbón hasta dónde llegó el agua. La radio se abre sola. Una voz que suena a Mara dice: «No cruces todavía».", "Espacio · escuchar", "radio")
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
						overlay("message", "El sendero del puesto sigue por el filo. La subida a la cumbre empieza en el acceso del lado este, al pie de la ladera.", "Espacio · seguir")
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
							field_note += " En el campamento de observadores anotaron dos destellos junto a una muesca. El primero coincide con el paso de una camioneta. El segundo queda sin identificar."
						overlay("message", "Observación OVNI · Uritorco. La tinta se corrió en los bordes. Debajo de un dibujo del cerro leés: «22.41. Luz abajo de la muesca. Camioneta en el camino». En el renglón siguiente: «22.43. Otra luz arriba de la muesca». La columna de identificación está vacía.", "Espacio · guardar el rumbo")
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
							field_note += " Cumbre: la cantera y la ladera del segundo destello quedan separadas por un pliegue del cerro."
							valley.sunset()
						overlay("message", "Desde arriba ves el cable terminar antes del corte. Entre los dos hay un pliegue entero de sierra. Ubicás la muesca del cuaderno: queda más arriba que el camino. Abrís el mapa sobre la piedra y marcás los rumbos. El viento te levanta una esquina. La sujetás con el pulgar.", "Espacio · doblar el mapa")
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
					"Trepar la laja", "Bajar la laja":
						var d: = 172.5 if target == "Trepar la laja" else 167.5
						player.climb_to(valley.route.at(valley.route.trail(170) - 0.6, d) + Vector3.UP * 0.08)
					"Hito del filo":
						if stage == 8 and not awaiting_call:
							stage = 9
							field_note += " Día 25 · Hito del filo revisado."
							valley.sunset()
						overlay("message", "Desde el hito ves el pliegue entero de la quebrada. Recién acá se entiende la vuelta que da el sendero. Marcás el rodeo en el cuaderno.", "Espacio · guardar")
					"Bolso":
						valley.unpack_book()
						open_book()
					"Puerta": valley.toggle_door()
					"Puerta del baño": valley.swing_side_door(valley.privy_hinge)
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
		overlay("crossing_response", "Mara entra entre dos golpes de estática. «¿Ya llegaste? Recién prendo la radio». Una luz sube desde el fondo del cauce. Cuando te quedás quieto, se detiene.", ["Retrocedés con Mara en línea.", "Apagás la linterna y esperás.", "Alumbrás el cauce."], "radio")
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
			score.cue("melancholy", 30, -17.0, 1.5)
			radio.play_interference()
			conversation(["Acaba de prenderse otra vez y la chapa está quieta.", "Entre el ruido oí «todavía». Pensé que habías hablado vos.", "¿Seguís ahí? Me quedo hasta que llegues."], "quarry_home")
		elif after == "crossing_home":
			stage = 18
			bedtime = true
			valley.night()
			walk()
		elif after == "summit_home":
			stage = 15
			bedtime = true
			valley.night()
			walk()
		elif after == "quarry_home":
			stage = 12
			bedtime = true
			field_note += " Cantera: la segunda luz apareció con la chapa quieta."
			valley.night()
			walk()
		elif after == "last_call":
			show_departure_choice()
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
		elif after == "choice": overlay("choice", "Tenés el botón de la radio bajo el pulgar.", ["Costó abrir la puerta.", "Todo en orden."])
		else:
			stage = 0
			heard = true
			walk()
	elif mode == "bench" and advance:
		walk()
		observing = true
	elif mode == "end" and (advance or key == KEY_F2):
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
	elif mode == "archive_choice":
		archive_entry = index
		save_game(true, "walk")
		overlay("message", "Fechás la hoja y la dejás en la bandeja del archivo. Antes de salir, podés avisarle a Mara por radio.", "Espacio · guardar")
	elif mode == "last_night_choice":
		if index == 0:
			night_investigation = 1
			score.cue("misterio", 22, -16.0)
			bed_pose = Transform3D(Basis.IDENTITY, Vector3(1.37, 0.06, 4.55))
			bed_pitch = 0.0
			overlay("night_cut", "La luz se mete entre los molles. Salís. Después hay una zanja que no recordás haber cruzado. La radio te golpea contra el pecho.\n\n«¿Me escuchás? Buscá la piedra blanca. Voy a dejar el canal abierto». Suena a Mara.", "Espacio · seguir la voz")
		else:
			begin_dream()
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
		else:
			approach_mara_door()
	elif mode == "day2_reply":
		var reply: = "Me alegro. Esa cama tiene sus años." if index == 0 else "A mí la primera noche me despertó hasta el viento."
		conversation([reply, "Nos hablamos cuando tengas la lectura."], "day2_confirm")
	elif mode == "trail_check_in":
		trail_check_in = true
		asked_mara_to_stay = index == 1
		field_note += " Le dijiste a Mara que agradecías el silencio." if index == 0 else " Le pediste a Mara un poco de charla."
		conversation(["Te entiendo. Hay días que bajo por ahí para escuchar los pasos."] if index == 0 else ["Te acompaño un rato. Desde acá se ve la curva antes del cauce."], "sighting_return")
	elif mode == "choice":
		conversation(["Ah, sí.", "Para cerrar tenés que levantar un poquito la hoja.", "Me olvidé de avisarte."] if index == 0 else ["Bueno.", "Dejá el bolso tranquilo.", "El mapa está en la mesa, abajo del cuaderno."], "trail")
	elif mode == "rest" and index == 1: walk()
	elif mode == "rest" and index == 0:
		if stage == 18:
			save_game(true, "walk")
			bedtime = false
			overlay("last_night_choice", "Vas a apagar la luz cuando un reflejo barre la ventana. Vuelve a aparecer entre los molles. Por la radio, Mara pregunta si seguís despierto.", ["Salís y seguís las luces en el monte.", "Cerrás la cortina y te acostás."])
			return
		if stage == 15:
			stage = 16
			bedtime = false
			awaiting_call = true
			valley.morning()
			valley.dress_day36()
			save_game(true, "walk")
			day_card("Día 36 · Después de la lluvia", "De noche escuchaste el arroyo desde la cama. A la mañana encontrás barro en el escalón de la puerta. Todavía cae una llovizna fina.", "Espacio · levantarse")
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
			conversation(["¿Celeste? Qué fino el cerro, ahora hace juego con el cielo.", "Guardá el rumbo. Cuando llegues a la antena probamos el canal."], "sighting_return")
		else: walk()
	elif mode == "fox":
		valley.route.release_fox(index == 0)
		field_note += " Lo ves bajar al cauce." if index == 0 else " Le dejás libre el paso."
		walk()
	elif mode == "field_report":
		field_note += " Recomendás la vaguada." if index == 0 else " Avisás del escalón."
		conversation(["Les marco la vuelta por abajo."] if index == 0 else ["Les aviso que la piedra está cortada."], "filo")
	elif mode == "reception":
		conversation(["Ahora sí. Te oigo clarito."] if index == 0 else ["Dale. Dejo la radio prendida."], "reception_done")
	elif mode == "report":
		if index == 0:
			creek_note += " Parte enviado."
			conversation(["Anotado.", "Mañana a esta hora me encontrás acá."], "sleep")
		else:
			creek_note += " Le contaste a Mara lo que viste."
			conversation(["Mi viejo volvía de ahí con los bolsillos llenos de esas piedritas.", "Cuando lavábamos los pantalones, brillaba todo el patio."], "sleep")

func begin_dream(preserve_bed: bool = false, fade_from_black: bool = false):
	score.cue("otromundo", 63, -14.0, 2.5)
	if not preserve_bed:
		bed_pose = player.transform
		bed_pitch = player.camera.rotation.x
	var first: = dream_count == 0
	dream_count += 1
	overlay("sleeping", "", "")
	shade.color = Color.BLACK if fade_from_black else Color.TRANSPARENT
	var fade: = create_tween()
	fade.tween_property(shade, "color:a", 1.0, 0.15 if fade_from_black else 1.8)
	fade.tween_callback( func():
		words.text = "Te dormís de costado. Por un momento te parece que seguís afuera." if first else "Te acostás con el pelo todavía húmedo. Cerrás los ojos. Esta vez reconocés la curva antes de verla."
		if night_investigation == 3:
			words.text = "El blanco se vuelve tela. Oís a tu papá pasar una hoja. Del otro lado del arco alguien gira la perilla de una radio. El papel y la estática hacen el mismo ruido."
		elif stage == 18 and night_investigation > 0:
			words.text = "Entre la piedra y la almohada hay un instante que no podés ubicar. En el sueño, la radio sigue abierta."
		valley.strange_sky(true)
		player.walking = false
		player.low_gravity = true
		position_on_planet()
		player.velocity = Vector3.ZERO
		player.rotation.y = 0.0
		player.camera.rotation.x = 0.4)
	fade.tween_interval(5.0)
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
			day_card("Día 41 · El dibujo", waking + "Intentás dibujar el arco en el reverso de un parte. Cuando enderezás el dintel, deja de parecerse al del sueño. Hoy termina tu relevo. Antes de bajar la llave al puesto de Mara, querés pasar por el museo.", "Espacio · levantarse")
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
			day_card("Día 27 · La cantera", "Abrís los ojos. El libro de tu viejo está abierto en el piso, al lado de la cama. En el margen de Saturno hay dos círculos a lápiz. Pasás el pulgar por el más chico. A los seis años dibujabas en todos los libros. ¿También en éste?", "Espacio · levantarse"))

func show_first_dream_wake():
	overlay("first_dream_wake", "Abrís los ojos. Afuera sigue oscuro. Tardás un rato en reconocer el techo. Al mover las piernas, te sorprende el peso de la sábana. Buscás el cuaderno a tientas.", "E · anotar lo que recordás")
	shade.color = Color.BLACK

func show_archive():
	var caption: = "El dintel de la maqueta cae hacia el mismo lado que en tu sueño. Detrás del vidrio está el dibujo, fechado el 12 de julio, la fecha del poste. En el reverso se alcanza a leer: «Repuesto el poste del cauce. En la bajada vi dos luces. Alguien pedía que esperara. No le entendí el indicativo»."
	if night_investigation >= 2:
		caption += "\n\nEn los cuadernos de la estación también había dos destellos y una advertencia. Acá falta una página. No sabés si alguna vez estuvo en la cueva."
	if crossing_response >= 0:
		caption += "\n\nEn tu cuaderno quedó anotado: «%s»" % CROSSING_NOTES[crossing_response]
	if archive_entry >= 0:
		overlay("message", caption + "\n\nTu parte quedó en la bandeja.", "Espacio · cerrar")
		return
	overlay("archive_choice", caption + "\n\nHay una hoja en blanco para agregar un testimonio. ¿Qué dejás en el archivo?", ["Dejás las horas y los rumbos de las luces.", "Agregás el dibujo y aclarás que viene de un sueño."])

func open_book():
	overlay("book", "", "")
	var book_memory: = str(keepsakes.get("libro", ""))
	var travel_memory: = str(keepsakes.get("puesto", ""))
	book_view.open("imprenta grande" in book_memory, "cinta verde" in travel_memory)

func enter_cave():
	score.silence(3.0)
	if not cave_built:
		LastNight.build_cave(valley)
		cave_built = true
	valley.cave_darkness()
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
	if local.y < -1.2 or absf(local.x) > 5.2 or local.z > 0:
		player.position = LastNight.CAVE + cave_checkpoint
		player.velocity = Vector3.ZERO
		return
	if local.z < -22.4 and local.y > 0.55:
		cave_checkpoint = LastNight.CHECKPOINT
	if local.z < -38.0 and not cave_exit_open:
		player.position.z = LastNight.CAVE.z - 37.9
	if cave_exit_open and local.z < -38.0:
		if not crux_found and local.z < -42.0:
			player.position.z = LastNight.CAVE.z - 41.9
		if crux_found and follow_last_light and local.z < -43.0:
			cue_clearing()
		if crux_found and local.z < -46.0:
			start_final_dream(follow_last_light)
			return
		if not crux_found:
			hint.text = "E · reconocer la Cruz del Sur" if looking_at_crux() else "Buscá la Cruz del Sur entre las copas."
		else:
			hint.text = "Seguí por debajo de la cruz, entre los troncos."
		return
	update_night_target()
	hint.text = "L · encender la linterna     R · llamar a Mara" if not flashlight_out else "L · linterna     R · Mara"
	if local.z > -22.0 and flashlight_out:
		hint.text = "Espacio · saltar entre las piedras     R · Mara"
	if not target.is_empty():
		hint.text = "E · " + target

func call_from_cave():
	var local: Vector3 = player.position - LastNight.CAVE
	var line: = "Buscá los bordes claros. Hay tres piedras que sobresalen. Si resbalás, volvé a la repisa y tomá aire."
	if local.z < -22.0:
		line = "Escuchá el viento. La salida tiene que estar de ese lado. Si me dejás de oír, seguí hasta donde veas cielo."
	radio.play_interference()
	overlay("cave_text", "«%s»" % line, "Espacio · guardar la radio", "radio")

func inspect_cave():
	if cave_exit_open and not crux_found and player.position.z < LastNight.CAVE.z - 38.0 and looking_at_crux():
		crux_found = true
		score.cue("cosmic", 64, -12.0, 3.0)
		overlay("cave_text", "Encontrás las dos del eje largo. Lo prolongás hacia el sur, como te enseñó tu papá. Bajás la vista sin girar la cabeza: entre los árboles hay una abertura.", "Espacio · seguir el rumbo")
		return
	match target:
		"Receptor":
			radio.play_interference()
			overlay("cave_text", "Hay un receptor, un trípode y un cable que desaparece en una grieta. En el dial está marcada la frecuencia del refugio. Al girarlo oís dos golpes secos. Del otro lado, alguien vuelve a darlos.", "Espacio · soltar")
		"Cuadernos de observación":
			if not cave_notebooks_read: score.cue("misterio", 34, -17.0)
			cave_notebooks_read = true
			night_investigation = 2
			overlay("cave_text", "14/10/1974 · «03.11. Dos destellos. El segundo bajó al claro».\n\n09/11/1978 · «La advertencia se repitió en la frecuencia del puesto».\n\nHay columnas de hora, dirección y respuesta. La última columna tiene una raya en todas las páginas. No encontrás una firma.", "Espacio · dejar los cuadernos")
		"Salida de la cueva":
			if not cave_notebooks_read:
				overlay("cave_text", "Entra aire frío. Atrás tuyo, la luz del receptor cae sobre unos cuadernos abiertos.", "Espacio · volver")
			else:
				overlay("cave_exit_choice", "Fuera de la cueva, la luz pasa entre dos troncos y se pierde. Más abajo se distingue la huella de regreso.", ["Seguís el destello hasta el claro.", "Tomás la huella de regreso."])

func cue_clearing():
	score.cue("tension", 14, -9.0, 0.35, 25.0)

func start_final_dream(blinded: bool):
	if blinded:
		cue_clearing()
		night_investigation = 3
		overlay("cave_flash", "", "")
		shade.color = Color.WHITE
		radio.play_interference()
		var flash: = create_tween()
		flash.tween_interval(0.3)
		flash.tween_property(shade, "color", Color.BLACK, 0.8)
		await flash.finished
	player.intro_center = Vector3.ZERO
	player.position = bed_pose.origin
	player.velocity = Vector3.ZERO
	flashlight_out = false
	begin_dream(true, blinded)

func show_departure_choice():
	overlay("departure_choice", "La radio queda en silencio. Desde la parada ves el colectivo doblar en la curva. Un poco antes sale el sendero al puesto de abajo.", ["Subís al colectivo.", "Tomás el sendero y vas a golpear la puerta de Mara."])

func approach_mara_door():
	if not door_built:
		LastNight.build_door(valley)
		door_built = true
	valley.morning()
	player.intro_center = LastNight.DOOR
	player.intro_heading = 0.0
	player.position = LastNight.DOOR + Vector3(0, 0.08, 0)
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	player.velocity = Vector3.ZERO
	walk()
	mode = "mara_door"

func looking_at_crux() -> bool:
	var sidereal: float = SkyGuide.NIGHTS[valley.sky_chapter][0]
	var axis: = (SkyGuide.direction(SkyGuide.STARS[0], sidereal) + SkyGuide.direction(SkyGuide.STARS[2], sidereal)).normalized()
	return ( - player.camera.global_basis.z).dot(axis) > cos(deg_to_rad(11.0))

func can_watch_sky() -> bool:
	var outdoors: bool = player.position.z < -0.5 or absf(player.position.x) > 3.6
	return outdoors and target.is_empty() and calendar_day() in [2, 7, 25, 27, 32] and not calendar_day() in sky_memories and float(valley.sky_mat.get_shader_parameter("nightfall")) > 0.6 and ( - player.camera.global_basis.z).y > 0.32

func watch_sky():
	var day: = calendar_day()
	sky_memories.append(day)
	if not score.is_playing():
		score.cue("noche", 32, -17.0)
	var memory: = "Tu papá siempre esperaba a que se te acostumbraran los ojos. Contás hasta diez. Aparecen estrellas que hace un momento no estaban."
	if day == 7 or day == 27:
		memory = "Buscás la Cruz del Sur. En la vereda, tu papá te tapaba con una mano las luces de la calle. «Buscá las dos del eje largo», te decía. Cuando la encontrabas, retiraba la mano."
	elif day == 25 or day == 32:
		memory = "Estás por decirle que ya la encontraste. Abrís la boca. Después bajás la vista un rato, hasta que podés volver a mirar."
	overlay("message", memory, "Espacio · seguir")

func hear_last_voice():
	radio.play_interference()
	overlay("last_voice", "Del otro lado del arco el cielo tiene dos lunas. Oís una voz: «¿Ya la encontraste?». La radio está apagada. Te acordás de esa pregunta, pero no del todo de la voz.", ["«¿Quién es…?»", "«¿Papá…?»"])

func show_ending():
	var memory_of_book: = str(keepsakes.get("libro", "En la guarda sigue el dibujo que hiciste con tu papá."))
	var ending: = "Subís al colectivo. Desde el asiento ves la curva que baja al puesto. Antes de que desaparezca, abrís Observar el Cielo. " + memory_of_book + "\n\nLa radio va apagada en tu mochila. Justo al doblar oís dos golpes secos."
	if ending_at_door:
		ending = "Golpeás dos veces. Guardás la llave en el bolsillo para tener la mano libre. Del otro lado cruje una tabla.\n\nTe quedás en el escalón, con Observar el Cielo bajo el brazo. " + memory_of_book
	if last_voice_reply >= 0:
		ending += "\n\nEsta vez, cuando pensás en tu papá, volvés a mirar hasta encontrar la cruz."
	overlay("end", ending, "Fin · Espacio para volver al menú")

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
	var data = {"version": 1, "slot": slot, "title": title, "state": state, "mode": resume_mode, "pose": player.transform, "pitch": player.camera.rotation.x, "paragraph": recall.paragraph, "chapter": valley.sky_chapter, "door": valley.door_open, "book": valley.book_unpacked, "night": valley.sky_mat.get_shader_parameter("nightfall"), "dusk": valley.sky_mat.get_shader_parameter("dusk"), "music": music.get_playback_position() if music.playing else 0.0}
	return Saves.write(slot, automatic, data)

func restore(data: Dictionary):
	score.silence(0.2)
	slot = data.slot
	for key in STATE:
		if data.state.has(key): set(key, data.state[key])
	if stage == 3: stage = 4
	menu.hide()
	player.camera.current = true
	player.transform = data.pose
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
	if stage >= 0:
		if data.book: valley.unpack_book()
		else: valley.leave_bag()
	if stage < 0:
		music.begin()
		music.seek(data.music)
	if data.door: valley.toggle_door()
	if float(data.get("dusk", 0.0) if data.dusk != null else 0.0) > 0.3: valley.sunset()
	var saved_night: = clampf(float(data.night) if data.get("night") != null else 0.0, 0.0, 1.0)
	if stage == 7 and day7_dusk and not second_sighting:
		valley.sky_mat.set_shader_parameter("nightfall", saved_night)
		valley.night(12)
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
		"approach": approach()
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
	day_card("Día 25 · La quebrada larga", "Pasaron más de dos semanas. Al abrir el cuaderno, encontrás las estrellas del sueño dibujadas en una esquina. Afuera clareó. Mara todavía tiene que darte el encargo para hoy.", "Espacio · levantarse")

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

func show_sighting():
	mode = "sighting"
	sighting_waiting = true
	player.walking = false
	player.looking_only = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hands.show_map(false)
	hands.hold("")
	overlay_choices.hide()
	radio_panel.hide()
	shade.hide()
	words.text = ""
	var ridge: Vector3 = valley.route.at(valley.route.trail(448) + 34.0, 448)
	valley.beacon.position = ridge + Vector3.UP * 60.0
	valley.beacon.scale = Vector3.ONE * 2.15
	hint.text = "Mirá el cielo sobre la ladera."

func update_sighting():
	var camera: Camera3D = player.camera
	var direction: Vector3 = valley.beacon.position - camera.global_position
	if not camera.is_position_in_frustum(valley.beacon.position):
		var flat := Vector3(direction.x, 0.0, direction.z).normalized()
		var sideways := flat.dot(camera.global_basis.x)
		var turn := "izquierda" if sideways < 0.0 else "derecha"
		hint.text = "Mirá más arriba, sobre el abra." if absf(sideways) < 0.22 and direction.dot(-camera.global_basis.z) > 0 else "Mirá hacia la %s, sobre la ladera." % turn
		return
	sighting_waiting = false
	hint.text = ""
	score.cue("melancholy", 31, -15.0, 1.7)
	var flash = valley.beacon
	var next_flash: Vector3 = flash.position + Vector3(6.0, 12.0, -11.0)
	var sequence_tween := create_tween()
	sequence_tween.tween_interval(0.35)
	sequence_tween.tween_callback(flash.show)
	sequence_tween.tween_interval(0.72)
	sequence_tween.tween_callback(flash.hide)
	sequence_tween.tween_interval(0.55)
	sequence_tween.tween_property(flash, "position", next_flash, 0.0)
	sequence_tween.tween_callback(flash.show)
	sequence_tween.tween_interval(0.79)
	sequence_tween.tween_callback(flash.hide)
	sequence_tween.tween_callback(func():
		second_sighting = true
		radio.play_interference()
		field_note += " Camino al abra ves dos destellos sobre la ladera."
		overlay("sighting_response", "El azul dura menos que un parpadeo. La radio se corta a mitad de una palabra: «…cruces…».", ["Le preguntás a Mara si lo vio.", "Guardás el rumbo para más tarde."]))

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
	heard = true
	valley.unpack_book()
	stage = int({"arrival": 0, "2": 1, "sighting": 7, "7": 6, "dream7": 7, "25": 8, "dream25": 9, "27": 10, "32": 13, "camp": 13, "36": 16, "dream36": 18, "41": 19}.get(code, 0))
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
		bedtime = true
		valley.arrival_light(1.0)

func map_destination() -> Variant:
	if stage < 0: return Vector3.ZERO
	if stage == 19 and archive_entry >= 0: return null
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
		19: return route.at(route.trail(292), 292)
	return null
