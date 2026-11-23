extends Node3D

const Trail = preload("res://travesia.gd")
const Creek = preload("res://cauce.gd")
const Flora = preload("res://flora.gd")
const Stone = preload("res://piedra_serrana.gd")
const Models = preload("res://fauna_modelos.gd")
const FOX := "zorro"
const TEGU := "overo"
const REED := "cortadera"
const CAVY := "cuis"
const CHINGOLO := "chingolo"
const BIRD_PERCH := Vector2(-12.9, -18.95)
const CAVY_LATER := [Vector2(19.0, -9.4), Vector2(-33.8, 50.1)]
const TEGU_LATER := [Vector2(-31.4, -8.3), Vector2(-22.4, 57.4)]
const ESPINILLO := "espinillo"
const CACTUS := "cactus"
const ESPINILLO_SITES := [Vector3(32.5, 1.02, -0.5), Vector3(-28.6, 0.92, -32.4),
	Vector3(-16.6, 1.13, 41.8), Vector3(7.0, 0.89, 39.4)]
const CACTUS_SITES := [Vector2(-45.6, -19.6), Vector2(-35.0, -32.0),
	Vector2(50.2, 5.7), Vector2(-57.0, 31.8)]
const FOX_START := Vector2(18.1, -2.6)
const FOX_END := Vector2(30.2, -7.1)
const FOX_MID := (FOX_START + FOX_END) * 0.5
const FOX_CROSS_SECONDS := 4.25
const NATURAL_TARGET_DISTANCE := 13.0
const TEGU_REST_ANGLE := -2.89
const CAVY_CREEK := Vector2(-20.45, 31.0)
const CAVY_LAJAS := Vector2(-22.0, -28.75)
const CAVY_REFUGE_CREEK := Vector2(3.18, 0.80)
const CAVY_REFUGE_LAJAS := Vector2(-1.38, -3.0)
const ENTRIES := {
	FOX: ["Zorro gris pampeano", "Cruzó la huella del mollar al trote. Alcancé a ver el lomo gris y, antes de que se metiera en los arbustos, la punta negra de la cola."],
	TEGU: ["Lagarto overo", "Se calentaba sobre una laja de la orilla. Tenía manchas claras entre las bandas oscuras y una cola larga que casi tocaba el suelo."],
	REED: ["Cortadera", "Las hojas largas se arquean hasta el suelo. De cerca, cada penacho está hecho de ramitas finas. Dibujé la mata entera para acordarme de su forma."],
	CAVY: ["Cuis moro", "Había dos comiendo al borde de la huella. Uno levantó la cabeza un momento. Alcancé a ver la raya clara arriba del ojo antes de que se metiera entre los pastos."],
	ESPINILLO: ["Espinillo en flor", "De lejos, las flores parecen motitas de polen. De cerca se ven las hojitas de a pares. Dibujé dos espinas que salen juntas de la rama."],
	CACTUS: ["Cactus serrano", "Apenas sobresale del suelo. Desde arriba, las costillas se abren como los gajos de una naranja. Dibujé cómo salen las espinas en grupos."],
	CHINGOLO: ["Chingolo", "Se erizó al oírme. Alcancé a dibujarle las rayas de la cabeza, el pico corto y el cuello color ladrillo."],
}
const SKETCHES := {
	CHINGOLO: "res://naturaleza_chingolo.webp",
	FOX: "res://naturaleza_zorro.webp",
	TEGU: "res://naturaleza_overo.webp",
	REED: "res://naturaleza_cortadera.webp",
	CAVY: "res://naturaleza_cuis.webp",
	ESPINILLO: "res://naturaleza_espinillo.webp",
	CACTUS: "res://naturaleza_cactus.webp",
}

var fox: Node3D
var tegu: Node3D
var tegu_home := Vector3.ZERO
var current_tegu_home := Vector3.ZERO
var tegu_outcrops: Array[Vector3] = []
var chingolo: Node3D
var bird_perch := Vector3.ZERO
var bird_flight := -1.0
var reed_foot := Vector3.ZERO
var espinillo_focus: Array[Vector3] = []
var cactus_focus: Array[Vector3] = []
var day_seen := 0
var fox_clock := -1.0
var fox_armed := true
var tegu_clock := -1.0
var cavies: Array[Node3D] = []
var cavy_idle := 0.0
var current_cavy_site := Vector2.INF
var cavy_bolt := -1.0
var cavy_start := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
var drawings_on_wall: Dictionary = {}

func _ready():
	var models := Models.new()
	fox = models.make_fox(self)
	tegu = models.make_tegu(self)
	fox.hide()
	tegu.hide()
	dress_bank()
	current_tegu_home = tegu_home
	for site in TEGU_LATER:
		tegu_outcrops.append(build_basking_rock(site))
	chingolo = models.make_chingolo(self)
	chingolo.hide()
	var perch_base := ground(BIRD_PERCH)
	bird_perch = perch_base + Vector3(-0.28, 0.81, -0.09)
	Flora.branch(self, perch_base - Vector3.UP * 0.08, perch_base + Vector3(-0.10, 0.79, -0.09), 0.044, 0.017, true)
	Flora.branch(self, perch_base + Vector3(-0.10, 0.79, -0.09), bird_perch + Vector3(-0.24, -0.006, 0.0), 0.022, 0.007)
	var first := models.make_cavy(self)
	var second := first.duplicate() as Node3D
	add_child(second)
	second.scale *= 0.91
	cavies.assign([first, second])
	reset_cavies()
	dress_pastizal(CAVY_CREEK, CAVY_REFUGE_CREEK, 2097)
	dress_pastizal(CAVY_LAJAS, CAVY_REFUGE_LAJAS, 2781)
	for i in CAVY_LATER.size():
		dress_pastizal(CAVY_LATER[i], CAVY_REFUGE_LAJAS, 2845 + i)
	dress_flora()

func dress_flora():
	for i in ESPINILLO_SITES.size():
		var site: Vector3 = ESPINILLO_SITES[i]
		var root := ground(Vector2(site.x, site.z))
		Flora.tree(self, root, Flora.Kind.ESPINILLO, site.y, 0.62 + i * 1.63, 1.07, true)
		espinillo_focus.append(root + Vector3(-0.49, 1.76, 0.20) * site.y)
	var stones := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4052
	var sites := CACTUS_SITES.duplicate()
	var cauce := Creek.trail_point(0.43)
	sites.append(Vector2(cauce.x + 1.65, cauce.z + 1.15))
	sites.append(Vector2(5.4, -17.8))
	for i in sites.size():
		var site: Vector2 = sites[i]
		var rotation := -0.30 + i * 1.67
		for bud in 2 + (i + 1) % 2:
			var cluster := Vector2(-0.30 * bud, 0.16 * sin(bud * 2.7)).rotated(rotation)
			var at := ground(site + cluster)
			var size := (1.10 - 0.25 * bud) * rng.randf_range(0.83, 1.13)
			Flora.cactus(self, at, size, rng.randf() * TAU)
			cactus_focus.append(at + Vector3.UP * 0.18 * size)
		for offset in [Vector2(-1.10, 0.28), Vector2(-0.45, -0.53)]:
			var foot := ground(site + offset.rotated(rotation))
			var cut := Stone.fragment(stones, foot - Vector3.UP * 0.06,
				Vector3(1.12, 0.23, 0.71), 0.67 + rotation, rng, Creek.surface_point, Stone.LAJA_PROFILE)
			Stone.solid(self, foot, cut, "Laja del cactus")
	Stone.finish(self, stones, "Lajas chicas")

func dress_bank():
	const ROCK_X := -31.6
	const REED_X := -25.4
	var ridge := ground(Vector2(ROCK_X, Creek.channel_z(ROCK_X) - 9.7)) - Vector3.UP * 0.09
	var rng := RandomNumberGenerator.new()
	rng.seed = 958
	var face := Stone.surface()
	var shape := Stone.fragment(face, ridge, Vector3(3.35, 0.31, 2.75), 0.8, rng, Creek.surface_point)
	Stone.solid(self, ridge, shape, "Laja calentada por el sol")
	for offset in [Vector3(-1.32, 0, 0.69), Vector3(0.88, 0, 1.13)]:
		var foot := Creek.surface_point(ridge + offset) - Vector3.UP * 0.06
		var chip := Stone.fragment(face, foot, Vector3(0.96, 0.22, 0.63), rng.randf() * TAU, rng, Creek.surface_point)
		Stone.solid(self, foot, chip, "Laja menor")
	Stone.finish(self, face, "Lajas de la orilla").material_override = Stone.paint("928679")
	tegu_home = ridge
	for point in shape.slice(-Stone.SIDES):
		tegu_home.y += (point.y - ridge.y) / Stone.SIDES
	tegu_home.y -= 0.012
	tegu.position = tegu_home
	tegu.rotation.y = TEGU_REST_ANGLE

	reed_foot = ground(Vector2(REED_X, Creek.channel_z(REED_X) - 7.2))
	var tuft: Array[Vector4] = []
	for offset in [Vector3.ZERO, Vector3(-0.77, 0, -0.18), Vector3(0.48, 0, 0.53)]:
		var at := Creek.surface_point(reed_foot + offset)
		tuft.append(Vector4(at.x, at.y - 0.08, at.z, 1.15 if offset == Vector3.ZERO else 0.74))
	Flora.herb_batch(self, tuft, Flora.Herb.CORTADERA)

func build_basking_rock(site: Vector2) -> Vector3:
	var base := ground(site) - Vector3.UP * 0.08
	var faces := Stone.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(site.x * site.y) * 731.0)
	var shape := Stone.fragment(faces, base, Vector3(1.95, 0.29, 1.48), 0.23, rng, Creek.surface_point, Stone.LAJA_PROFILE)
	Stone.solid(self, base, shape, "Laja calentada por el sol")
	Stone.finish(self, faces, "Laja del lagarto").material_override = Stone.paint("8f8270")
	var top := base
	for point in shape.slice(-Stone.SIDES):
		top.y += (point.y - base.y) / Stone.SIDES
	return top

func dress_pastizal(site: Vector2, shelter: Vector2, seed_value: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var roots: Array[Vector4] = []
	for tuft in 16:
		var at := site + shelter + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.15, 1.25)
		var foot := ground(at)
		roots.append(Vector4(foot.x, foot.y - 0.07, foot.z, rng.randf_range(0.58, 1.16)))
	Flora.herb_batch(self, roots, Flora.Herb.PAJA)
	roots.clear()
	for tuft in 13:
		var at := site + shelter.normalized() * 0.89 + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.35, 1.06)
		var foot := ground(at)
		roots.append(Vector4(foot.x, foot.y - 0.04, foot.z, rng.randf_range(0.20, 0.46)))
	Flora.grass_batch(self, roots)

func ground(at: Vector2) -> Vector3:
	return Creek.surface_point(Vector3(at.x, 0.0, at.y))

func advance(delta: float, day: int, player_position: Vector3, dark: float, rain: float, walking: bool, observations: Dictionary):
	if day_seen != day:
		day_seen = day
		fox_clock = -1.0
		fox_armed = true
		tegu_clock = -1.0
		fox.hide()
		tegu.hide()
		chingolo.hide()
		bird_flight = -1.0
		reset_cavies()
	if not walking: return

	var player_xz := Vector2(player_position.x, player_position.z)
	var crossing := Trail.ascent_point(0.26) if day == 32 else Vector3.ZERO
	var fox_origin := Vector2(crossing.x, crossing.z) - FOX_MID if day == 32 else Vector2.ZERO
	advance_fox(delta, player_xz, day >= 7 and day <= 32 and rain < 0.57 and dark < 0.68, fox_origin)
	var tegu_site := tegu_home
	if observations.has(TEGU):
		for outcrop in tegu_outcrops:
			if player_position.distance_squared_to(outcrop) < player_position.distance_squared_to(tegu_site): tegu_site = outcrop
	if current_tegu_home != tegu_site:
		current_tegu_home = tegu_site
		tegu_clock = -1.0
		tegu.hide()
	advance_tegu(delta, player_position, day >= 2 and rain < 0.23 and dark < 0.32)
	var cavy_site := CAVY_CREEK if day == 2 else CAVY_LAJAS
	if observations.has(CAVY):
		for site: Vector2 in CAVY_LATER:
			if player_xz.distance_squared_to(site) < player_xz.distance_squared_to(cavy_site): cavy_site = site
	if cavy_site != current_cavy_site:
		current_cavy_site = cavy_site
		reset_cavies()
	advance_cavies(delta, player_xz, cavy_site, day >= 2 and rain < 0.30 and dark < 0.39)
	advance_chingolo(delta, player_position, day >= 2 and rain < 0.25 and dark < 0.36)

func advance_chingolo(delta: float, listener: Vector3, active: bool):
	var distance := bird_perch.distance_to(listener)
	if not active or distance > 17.0:
		bird_flight = -1.0
		chingolo.hide()
		return
	if bird_flight < 0.0:
		chingolo.position = bird_perch
		chingolo.rotation = Vector3(0, -0.89 + sin(Time.get_ticks_msec() * 0.0019) * 0.32, 0)
		chingolo.show()
		for wing in chingolo.get_children(): wing.hide()
		if distance < 2.15: bird_flight = 0.0
		return
	bird_flight += delta
	chingolo.visible = bird_flight < 0.95
	if chingolo.visible:
		chingolo.position = bird_perch + Vector3(-2.4, 2.6, -3.7) * bird_flight
		chingolo.rotation = Vector3(0.44, 0.58, 0.12 * sin(bird_flight * 50.0))
		var phase := sin(bird_flight * TAU * 10.0)
		for i in chingolo.get_child_count():
			var wing := chingolo.get_child(i) as Node3D
			wing.show()
			wing.rotation.z = phase * (0.92 if i == 0 else -0.92)

func advance_fox(delta: float, player_xz: Vector2, active: bool, origin: Vector2 = Vector2.ZERO):
	var distance := player_xz.distance_to(FOX_MID + origin)
	if not active or distance > 25.0:
		fox_clock = -1.0
		fox_armed = true
		fox.hide()
		return
	if fox_armed and distance < 13.6:
		fox_armed = false
		fox_clock = 0.0
	if fox_clock < 0.0: return
	fox_clock += delta
	var u := (fox_clock - 0.72) / FOX_CROSS_SECONDS
	if u < 0.0: return
	if u >= 1.0:
		fox_clock = -1.0
		fox.hide()
		return
	var at := FOX_START.lerp(FOX_END, u) + origin
	var lateral := (FOX_END - FOX_START).orthogonal().normalized()
	at += lateral * sin(u * PI) * 0.8
	fox.position = get_parent().route.surface_point(at.x, Trail.ORIGIN_Z - at.y) if at.y < Trail.ORIGIN_Z else ground(at)
	var direction := (FOX_END - FOX_START).normalized() + lateral * (0.13 * cos(u * PI))
	fox.rotation.y = atan2(-direction.x, -direction.y)
	var stride := u * 53.0
	fox.position.y += 0.02 + 0.025 * absf(sin(stride))
	for i in fox.get_child_count():
		var phase := stride + (PI if i in [1, 2] else 0.0)
		fox.get_child(i).rotation.x = sin(phase) * 0.53
	fox.show()

func advance_tegu(delta: float, player_position: Vector3, active: bool):
	var distance := Vector2(player_position.x - current_tegu_home.x, player_position.z - current_tegu_home.z).length()
	if not active or distance > 23.0:
		tegu_clock = -1.0
		tegu.hide()
		return
	if tegu_clock < 0.0:
		tegu.position = current_tegu_home
		tegu.rotation.y = TEGU_REST_ANGLE
		if not tegu.visible:
			for part in tegu.get_children():
				if part.has_meta("walking_leg"): part.rotation.y = 0.0
		tegu.show()
		if player_position.distance_to(current_tegu_home) < 1.82: tegu_clock = 0.0
		return
	tegu_clock += delta
	if tegu_clock > 1.28:
		tegu.hide()
		return
	var u := clampf(tegu_clock / 1.28, 0.0, 1.0)
	var at := current_tegu_home + Vector3(2.18 * u, 0, 1.41 * u + 0.10 * sin(u * 14.0))
	var threshold := smoothstep(0.24, 0.54, u)
	tegu.position = Creek.surface_point(at).lerp(Vector3(at.x, current_tegu_home.y, at.z), 1.0 - threshold)
	tegu.rotation.y = -2.15 + 0.10 * sin(u * 24.0)
	for i in tegu.get_child_count():
		var part := tegu.get_child(i) as Node3D
		if part.has_meta("walking_leg"):
			part.rotation.y = 0.35 * sin(u * 47.0 + (PI if i in [3, 4] else 0.0))

func reset_cavies():
	cavy_idle = 0.0
	cavy_bolt = -1.0
	for cavy in cavies: cavy.hide()

func advance_cavies(delta: float, player_xz: Vector2, site: Vector2, active: bool):
	var creek := site == CAVY_CREEK
	var distance := player_xz.distance_to(site)
	if not active or distance > 18.0:
		reset_cavies()
		return
	if (not cavies[0].visible and distance > 14.0) or cavy_bolt >= 1.65: return
	var shelter := CAVY_REFUGE_CREEK if creek else CAVY_REFUGE_LAJAS
	cavy_idle += delta
	if cavy_bolt < 0.0 and distance <= 2.40:
		cavy_bolt = 0.0
		for i in cavies.size():
			var foot := cavies[i].position
			cavy_start[i] = Vector2(foot.x, foot.z) if cavies[i].visible else site
	if cavy_bolt >= 0.0: cavy_bolt += delta
	for i in cavies.size():
		var cavy := cavies[i]
		var step := clampf((cavy_bolt - 0.15 * i) / 1.48, 0.0, 1.0)
		if step >= 1.0:
			cavy.hide()
			continue
		var local_time := cavy_idle + 1.16 * i
		var feeding := site + Vector2(0.58, 0.49) * (i if creek else -i)
		feeding += Vector2(0.17 * sin(local_time * 1.04), 0.11 * cos(local_time * 0.86))
		var retreat := site + shelter + Vector2(shelter.y, -shelter.x).normalized() * (0.44 * i)
		var point := cavy_start[i].lerp(retreat, step) if cavy_bolt >= 0.0 else feeding
		var direction := (retreat - cavy_start[i]).normalized()
		var stride := step * 61.0
		var running := step > 0.0
		var height := 0.009 + 0.013 * absf(sin(stride)) if running else 0.002
		cavy.position = ground(point) + Vector3.UP * height
		var feeding_angle := (2.35 if creek else 1.47) - i * 0.69
		cavy.rotation.y = atan2(-direction.x, -direction.y) if running else feeding_angle + 0.20 * sin(local_time * 0.87)
		cavy.rotation.x = 0.10 * sin(local_time * 4.2) if not running else 0.07 * sin(stride)
		for leg in cavy.get_child_count():
			cavy.get_child(leg).rotation.x = sin(stride + (PI if leg in [1, 2] else 0.0)) * 0.76 if running else 0.0
		cavy.show()

func aimed(camera: Camera3D, player: CharacterBody3D, observations: Dictionary) -> String:
	var head := camera.global_position
	var look := -camera.global_basis.z
	var samples := [
		[FOX, fox.global_position + Vector3.UP * 0.40, 0.47, fox.visible, NATURAL_TARGET_DISTANCE],
		[TEGU, tegu.global_position + Vector3.UP * 0.12, 0.33, tegu.visible, 8.0],
		[CHINGOLO, chingolo.global_position + Vector3.UP * 0.083, 0.18, chingolo.visible and bird_flight < 0.0, 7.3],
		[REED, to_global(reed_foot + Vector3.UP * 0.71), 0.47, true, 6.0],
	]
	if not observations.has(CAVY):
		for cavy in cavies:
			samples.append([CAVY, cavy.global_position + Vector3.UP * 0.076, 0.18, cavy.visible, 7.2])
	if not observations.has(ESPINILLO):
		for point in espinillo_focus:
			samples.append([ESPINILLO, to_global(point), 0.82, day_seen >= 2, 7.0])
	if not observations.has(CACTUS):
		for point in cactus_focus:
			samples.append([CACTUS, to_global(point), 0.24, true, 4.4])
	for observation in samples:
		var id: String = observation[0]
		if observations.has(id) or not observation[3]: continue
		var point: Vector3 = observation[1]
		var offset := point - head
		var depth := offset.dot(look)
		if depth < 0.2 or depth > observation[4] or (offset - look * depth).length() > observation[2]: continue
		var ray := PhysicsRayQueryParameters3D.create(head, point, 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return id
	return ""

func next_day_sketches(valley: Node3D, observations: Dictionary, day: int):
	var index := 0
	for id in ENTRIES:
		if observations.has(id) and int(observations[id]) < day and not drawings_on_wall.has(id):
			var texture := load(SKETCHES[id]) as Texture2D
			if texture:
				var place := Vector3(-0.30 + 0.50 * (index % 4), 1.10 - 0.35 * floorf(index * 0.25), 5.85)
				var paper := preload("res://refugio.gd").wall_sketch(valley, place, texture, -1)
				paper.name = "Dibujo de " + ENTRIES[id][0]
				drawings_on_wall[id] = paper
		index += 1
