extends Node3D

const Climate = preload("res://clima.gd")
const SkyGuide = preload("res://constelacion.gd")
const Signage = preload("res://carteleria.gd")
const FieldKit = preload("res://equipo_campo.gd")
const Refuge = preload("res://refugio.gd")
const Creek = preload("res://cauce.gd")
const Cable = preload("res://camino_del_cable.gd")
const LastNight = preload("res://final_night.gd")
const Birds = preload("res://aves.gd")
const South = preload("res://quebrada_sur.gd")
const Stone = preload("res://piedra_serrana.gd")
const Exploration = preload("res://exploracion.gd")
const Flora = preload("res://flora.gd")
const Trail = preload("res://travesia.gd")

var rng: = RandomNumberGenerator.new()
var route = Trail.new()
var birds = Birds.new()
var desk_radio: StaticBody3D
var desk_note: StaticBody3D
var bag_drop: StaticBody3D
var mara_path_open := false
var desk_portable: Node3D
var env: = Environment.new()
var sun: = DirectionalLight3D.new()
var beacon := Sprite3D.new()
var second_beacon := Sprite3D.new()
var sky_mat: = ShaderMaterial.new()
var window_glass := ShaderMaterial.new()
var lighting: Tween
var hinge: = Node3D.new()
var door_open: = false
var door_motion: Tween
const grain = preload("res://grain.gdshader")
func timber(node: MeshInstance3D, across: bool = false):
	var material: = ShaderMaterial.new()
	material.shader = grain
	material.set_shader_parameter("tint", node.material_override.albedo_color)
	material.set_shader_parameter("across", across)
	node.material_override = material


func prop(mesh: Mesh, pos: Vector3, color: String, solid = false, tag = "") -> MeshInstance3D:
	var node: = MeshInstance3D.new()
	node.mesh = mesh
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = 1
	node.material_override = mat
	add_child(node)
	node.position = pos
	if solid:
		node.create_trimesh_collision()
		if tag != "": node.get_child(0).set_meta("item", tag)
	return node

func box(pos: Vector3, size: Vector3, tint: String, solid = false, tag = "") -> MeshInstance3D:
	var mesh: = BoxMesh.new()
	mesh.size = size
	return prop(mesh, pos, tint, solid, tag)

func stone(pos: Vector3, size: Vector3, color: String, solid = false) -> MeshInstance3D:
	var mesh: = SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 3
	var rock: = prop(mesh, pos, color, solid)
	rock.scale = size
	rock.rotation.y = rng.randf() * TAU
	return rock

func path_x(z: float) -> float:
	return 4.5 * sin( - z / 13.0)

func _ready():
	rng.seed = 2403
	var world: = WorldEnvironment.new()
	add_child(world)
	world.environment = env
	env.tonemap_exposure = 0.82
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky_mat.shader = preload("res://sierra.gdshader")
	sky_mat.set_shader_parameter("dusk", 0.0)
	sky_mat.set_shader_parameter("other_world", 0.0)
	configure_sky(0)
	env.sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#eee1ce")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_sky_affect = 0.0
	env.fog_density = 0.0027
	env.fog_light_color = Color("#c6ac9d")
	add_child(sun)
	sun.rotation_degrees = Vector3(-22, -52, 0)
	sun.light_color = Color("#ffd3a1")
	sun.shadow_enabled = true
	route.ground_material = Trail.make_ground_material(PackedVector2Array(Creek.PATH), LastNight.STOP, LastNight.DOOR_PATH_END, Exploration.segments())
	route.ground_material.set_shader_parameter("south_paths", Creek.crossing_trace())
	Creek.build_ground(self, route.ground_material)
	# Se conserva la distribución de piedras de las partidas anteriores.
	for sample in 79 * 2: rng.randf()
	build_distant_ridges()
	for i in range(24):
		var z: = rng.randf_range(-80, 4)
		var side: = -1 if i % 2 == 0 else 1
		var x: = path_x(z) + side * rng.randf_range(17, 35)
		var size_m := Vector3(rng.randf_range(12, 21), rng.randf_range(4, 9), rng.randf_range(10, 22))
		if z > -36.0 and Creek.trail_distance(Vector2(x, z)) < size_m.x + 5.0: continue
		if z < -13.0 and absf(x - route.eastern_x_at(z)) < size_m.x + 5.0: continue
		if absf(x - LastNight.DOOR.x) < size_m.x + 5.0 and absf(z - LastNight.DOOR.z + 3.0) < size_m.z + 5.0: continue
		if z < route.WEST_START_Z + size_m.z and absf(x - route.western_x_at(z)) < size_m.x + 7.0: continue
		if (LastNight.door_path_distance(x, z) < maxf(size_m.x, size_m.z) * 0.6 + 4.0
			or Exploration.clearance(Vector2(x, z)) < maxf(size_m.x, size_m.z) * 0.6 + 2.5):
			# Se conserva el sorteo de orientación para las piedras siguientes.
			rng.randf()
			continue
		stone(Vector3(x, -1, z), size_m, "837f65", true)
	var tufts: Array[Vector4] = []
	for i in range(160):
		var z: = rng.randf_range(-84, 10)
		var x: = rng.randf_range(-45, 45)
		if abs(x - path_x(z)) < 4.8 or (abs(x) < 12.5 and z > -15.5): continue
		if Creek.trail_distance(Vector2(x, z)) < 4.0: continue
		if z < -17.0 and absf(x - route.eastern_x_at(z)) < 4.0: continue
		if absf(x - LastNight.DOOR.x) < 6.0 and absf(z - LastNight.DOOR.z + 2.0) < 8.0: continue
		if z < route.WEST_START_Z + 1.0 and absf(x - route.western_x_at(z)) < 5.0: continue
		var k: = rng.randf_range(0.5, 2.1)
		if i % 3 == 0:
			if LastNight.door_path_distance(x, z) < 5.5 or Exploration.clearance(Vector2(x, z)) < 1.8 * k + 1.6:
				rng.randf()
			else:
				stone(Creek.point(x, z), Vector3(2.2, 1.4, 1.8) * k, "928678", true)
		elif Exploration.clearance(Vector2(x, z)) >= 1.0:
			tufts.append(Vector4(x, Creek.height(x, z) - 0.05, z, k))
	Flora.grass_batch(self, tufts)
	for sample in 24: rng.randf()

	plaster(box(Vector3(0, 1.4, 6), Vector3(7, 2.8, 0.22), "a79679", true))
	plaster(box(Vector3(-3.5, 1.4, 2.8), Vector3(0.22, 2.8, 6.5), "998975", true))
	for piece in [[2.8, 0.5, 6.5, 1.0], [2.8, 2.56, 6.5, 0.48], [0.4, 1.66, 1.6, 1.32], [5.2, 1.66, 1.6, 1.32]]:
		plaster(box(Vector3(3.5, piece[1], piece[0]), Vector3(0.22, piece[3], piece[2]), "998975", true))
	box(Vector3(3.5, 1.02, 2.8), Vector3(0.4, 0.12, 3.4), "65503f")
	box(Vector3(3.5, 1.65, 2.8), Vector3(0.12, 1.32, 0.09), "755c48")
	var pane := QuadMesh.new()
	pane.size = Vector2(3.40, 1.24)
	var glass := prop(pane, Vector3(3.51, 1.70, 2.80), "9bafb8")
	glass.rotation.y = PI * 0.5
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	window_glass.shader = preload("res://vidrio_lluvia.gdshader")
	glass.material_override = window_glass
	for x in [-2.35, 2.35]:
		plaster(box(Vector3(x, 1.4, -0.4), Vector3(2.35, 2.8, 0.22), "a89b87", true))
	box(Vector3(0, 2.93, 2.65), Vector3(8, 0.23, 8), "5c5148", true).rotation.z = 0.025
	box(Vector3(0, 2.795, 2.76), Vector3(7.19, 0.16, 6.66), "73614d", true)
	var fascia := box(Vector3(0, 2.825, -0.52), Vector3(7.27, 0.20, 0.092), "665648")
	fascia.material_override = Refuge.wood("665648", true)
	desk_note = Refuge.desk(self)
	desk_radio = FieldKit.desk_radio(self, Vector3(2.64, 0.90, 2.42))
	desk_radio.rotation.y = PI + 0.24
	desk_portable = desk_radio.get_node("Transceptor")
	Refuge.bed(self)
	Refuge.exterior_equipment(self, Creek.point(-5.15, -5.65), Creek.point(-4.17, 2.27))
	bag_drop = FieldKit.item(self, Vector3(1.52, 0.20, 5.03), "Dejar la mochila", Vector3.ZERO, Vector3(0.51, 0.33, 0.62))
	bag_drop.collision_layer = 0
	var lamp: = OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(-1, 1.95, 1)
	lamp.light_color = Color("#ffbe77")
	lamp.omni_range = 8
	lamp.light_energy = 1.5
	Signage.station(self)
	build_sighting_lights()
	dress_shelter()
	furnish()
	dress_path_verges()
	rock_banks()
	add_child(route)
	Creek.dress(self, Exploration.clearance)
	South.build(self)
	dress_birds()
	preload("res://museo.gd").build(self)
	Exploration.build(self)

func open_mara_path():
	if mara_path_open: return
	mara_path_open = true
	route.ground_material.set_shader_parameter("mara_track", true)
	LastNight.build_door(self)
	var fork := LastNight.door_approach(0.22)
	route.signpost(fork + Vector3(0.0, 0, -2.4), "", "Camino vecinal →", -1.72, true)

func update_desk_radio(held: bool):
	if desk_portable.visible != held: return
	desk_portable.visible = not held
	desk_radio.collision_layer = 0 if held else 1

func set_desk_note(present: bool):
	if desk_note.visible == present: return
	desk_note.visible = present
	desk_note.collision_layer = 1 if present else 0

func set_bag_drop(active: bool):
	bag_drop.collision_layer = 2 if active else 0

func dress_birds():
	add_child(birds)
	for d in [85.0, 395.0, 890.0]:
		birds.add_flight(Birds.Species.JOTE, route.at(route.trail(d), d) + Vector3.UP * 19.0, Vector2(30, 23), d * 0.022)
	birds.add_flight(Birds.Species.JOTE, Creek.crossing_point(0.64) + Vector3.UP * 18.0, Vector2(37, 24), 2.4)
	birds.add_flight(Birds.Species.CARANCHO, Vector3(-54, 11, 23), Vector2(23, 19), 1.2)
	birds.add_flight(Birds.Species.CARANCHO, route.at(102, 686) + Vector3.UP * 11.0, Vector2(34, 28), 3.3)
	for i in 3:
		birds.add_flight(Birds.Species.GOLONDRINA, Creek.point(-26.0 - i * 16, 73.0 + i * 4) + Vector3.UP * (4.5 + i * 0.53),
			Vector2(11, 6), i * 2.13)

var ridge_materials: Array[ShaderMaterial] = []
var ridge_light := Vector2(-1.0, -1.0)

func build_distant_ridges():
	const SECTIONS := 144
	const ROWS := [Vector2(0.78, 0.0), Vector2(0.86, 0.33), Vector2(0.92, 0.70), Vector2(1.0, 1.0), Vector2(1.09, 0.0)]
	const PALETTE := ["737869", "7c8986", "879aa1", "9babba"]
	# Se conserva la secuencia original de piedras junto al refugio.
	for sample in 2 * 96: rng.randf()
	for layer in PALETTE.size():
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in SECTIONS:
			var azimuth := TAU * index / SECTIONS
			var north := smoothstep(0.0, 0.86, -sin(azimuth))
			var south := smoothstep(0.0, 0.84, sin(azimuth))
			var rolls := 0.43 * sin(azimuth * 5.0 + 1.8 * layer) + 0.29 * sin(azimuth * 9.0 - layer) + 0.19 * cos(azimuth * 16.0 + 0.6 * layer)
			var peaks := 0.48 * pow(absf(sin(azimuth * 3.0 + 0.77 * layer)), 3.5) + rolls
			var base := 228.0 + north * 1040.0 + south * 142.0
			var distance := base * (1.0 + layer * 0.40) * (1.0 + rolls * 0.055)
			var angle := 0.100 + 0.011 * layer + peaks * 0.063 + north * 0.076
			var crest := distance * angle
			var foot := -17.0 - layer * 3.0
			for index_row in ROWS.size():
				var row: Vector2 = ROWS[index_row]
				var radius: float = distance * row.x
				var side := 0.74 + 0.17 * sin(azimuth * 19.0 + index_row * 1.23 + layer) + 0.09 * sin(azimuth * 37.0 - index_row * 2.0)
				surface.set_uv(Vector2(side, row.y))
				surface.add_vertex(Vector3(radius * cos(azimuth), lerpf(foot, crest, row.y), -30.0 + radius * sin(azimuth)))
		for index in SECTIONS:
			var next := ((index + 1) % SECTIONS) * ROWS.size()
			for row in range(ROWS.size() - 1):
				var a := index * ROWS.size() + row
				var b := next + row
				for vertex in [a + 1, a, b + 1, b + 1, a, b]:
					surface.add_index(vertex)
		var ridge := MeshInstance3D.new()
		ridge.mesh = surface.commit()
		var paint := ShaderMaterial.new()
		paint.shader = preload("res://perfil_sierra.gdshader")
		paint.set_shader_parameter("stone", Color(PALETTE[layer]))
		paint.set_shader_parameter("distance_layer", layer / 3.0)
		ridge_materials.append(paint)
		ridge.material_override = paint
		ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ridge)

func shade_ridges():
	var nightfall: float = sky_mat.get_shader_parameter("nightfall")
	var dusk: float = sky_mat.get_shader_parameter("dusk")
	birds.visible = nightfall < 0.68 and weather_rain < 0.57
	if ridge_light == Vector2(nightfall, dusk): return
	ridge_light = Vector2(nightfall, dusk)
	for mat in ridge_materials:
		mat.set_shader_parameter("nightfall", nightfall)
		mat.set_shader_parameter("dusk", dusk)

func build_sighting_lights():
	var glow := Gradient.new()
	glow.offsets = PackedFloat32Array([0.0, 0.19, 0.38, 1.0])
	glow.colors = PackedColorArray([Color("#efffff"), Color("#9ef3fff6"), Color("#64d6ec82"), Color("#61c4ee00")])
	var texture := GradientTexture2D.new()
	texture.gradient = glow
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	for light in [beacon, second_beacon]:
		light.texture = texture
		light.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(light)
		light.hide()

func transition() -> Tween:
	if lighting and lighting.is_valid():
		lighting.kill()
	lighting = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return lighting

var weather_day := 0
var weather_rain := -1.0
var cloud_tick := -1.0
var atmosphere_sample := Vector4(-1, -1, -1, -1)
var exterior_light := true
var light_target := ""
var light_duration := 0.0

func set_sun_phase(dusk: float, dark: float):
	sky_mat.set_shader_parameter("dusk", dusk)
	sky_mat.set_shader_parameter("nightfall", dark)

func sunset(duration: float = 5.0):
	var tween := transition()
	light_target = "dusk"
	light_duration = duration
	tween.tween_method(func(v): sky_mat.set_shader_parameter("dusk", v), float(sky_mat.get_shader_parameter("dusk")), 1.0, duration)

func night(duration: float = 6.0, dusk_duration: float = 14.0):
	exterior_light = true
	var tween := transition()
	light_target = "night"
	light_duration = duration
	tween.tween_method(func(v): sky_mat.set_shader_parameter("nightfall", v), float(sky_mat.get_shader_parameter("nightfall")), 1.0, duration)
	tween.tween_method(func(v): sky_mat.set_shader_parameter("dusk", v), float(sky_mat.get_shader_parameter("dusk")), 1.0, minf(duration, dusk_duration))

func remaining_light_transition() -> float:
	return maxf(0.0, light_duration - lighting.get_total_elapsed_time()) if lighting and lighting.is_running() else 0.0

func restore_light(dusk: float, dark: float):
	if lighting and lighting.is_valid(): lighting.kill()
	light_target = ""
	set_sun_phase(dusk, dark)
	atmosphere_sample = Vector4(-1, -1, -1, -1)

func update_weather(day: int, rain: float = 0.0, local_mist: float = 0.0):
	var changed_day := day != weather_day
	var tick := floorf(Time.get_ticks_msec() * 0.005) * 0.20
	if changed_day or tick != cloud_tick:
		cloud_tick = tick
		var wind: float = Climate.profile(day).wind
		sky_mat.set_shader_parameter("cloud_drift", Vector2(-0.016, 0.009) * wind * tick)
	var dusk: float = sky_mat.get_shader_parameter("dusk")
	var dark: float = sky_mat.get_shader_parameter("nightfall")
	var sample := Vector4(rain, local_mist, dusk, dark)
	if not changed_day and (sample - atmosphere_sample).length_squared() < 0.00000005: return
	weather_day = day
	weather_rain = rain
	atmosphere_sample = sample
	var profile := Climate.profile(day)
	var coverage: Vector2 = profile.cloud
	var cloud := lerpf(lerpf(coverage.x, coverage.y, maxf(dark, dusk * 0.26)), 0.97, rain)
	if changed_day:
		sky_mat.set_shader_parameter("cloud_pattern", day * 0.873)
		update_night_catalog(day)
		sky_mat.set_shader_parameter("high_day", profile.sky)
		sky_mat.set_shader_parameter("rim_day", profile.rim)
		sky_mat.set_shader_parameter("cirrus_amount", profile.cirrus)
	sky_mat.set_shader_parameter("cloud_cover", cloud)
	sky_mat.set_shader_parameter("storm_amount", rain)
	sky_mat.set_shader_parameter("valley_mist", clampf(local_mist * 160.0, 0.0, 0.94))
	route.ground_material.set_shader_parameter("wet_ground", 0.49 + rain * 0.42 if day == 36 else rain * 0.46)
	route.ground_material.set_shader_parameter("surface_rain", rain)
	window_glass.set_shader_parameter("rain", rain)
	window_glass.set_shader_parameter("moisture", clampf(rain * 1.43 + (0.07 if day == 36 else 0.0), 0.0, 1.0))
	if is_instance_valid(storm_water):
		storm_water.visible = day == 36
		storm_water.material_override.set_shader_parameter("rain", rain)
	for mat in ridge_materials:
		mat.set_shader_parameter("storm_amount", rain)
		mat.set_shader_parameter("valley_mist", clampf(local_mist * 160.0, 0.0, 0.94))
	update_celestial_light(day, dusk, dark)
	if not exterior_light: return
	shape_daylight(profile, rain, local_mist, dusk, dark)

func shape_daylight(profile: Dictionary, rain: float, local_mist: float, dusk: float, dark: float):
	var sun_tone: Color = profile.light
	var drizzle := smoothstep(0.01, 0.76, rain)
	var diffuse := maxf(drizzle, clampf(local_mist * 70.0, 0.0, 0.55))
	var setting := sun_tone.lerp(Color("#ffb78f"), dusk).lerp(Color("#bccbd3"), diffuse)
	sun.light_color = setting.lerp(Color("#abc4ed"), dark)
	var above_horizon := smoothstep(-0.10, 0.13, sun_direction.y)
	sun.light_energy = lerpf(float(profile.sun) * above_horizon * (1.0 - 0.85 * diffuse), 0.025, dark)
	sun.shadow_enabled = dark < 0.76
	sun.shadow_opacity = (1.0 - 0.86 * diffuse) * (1.0 - smoothstep(0.32, 0.76, dark))
	sun.look_at(sun.global_position - sun_direction)

	var ambient := Color("#dce6de").lerp(Color("#d5b9ac"), dusk).lerp(Color("#bac6ce"), diffuse)
	env.ambient_light_color = ambient.lerp(Color("#9ba5bf"), dark)
	env.ambient_light_energy = lerpf(lerpf(0.86, 0.69, dusk) * (1.0 - diffuse * 0.24), 0.115, dark)
	var air := Color("#a9b7b7").lerp(Color("#b4a5a0"), dusk).lerp(Color("#899fa9"), diffuse)
	env.fog_light_color = air.lerp(Color("#30374c"), dark)
	env.fog_density = lerpf(float(profile.mist) + local_mist, 0.0105, drizzle * 0.87)

func cave_darkness():
	exterior_light = false
	if lighting and lighting.is_valid(): lighting.kill()
	light_target = ""
	sky_mat.set_shader_parameter("nightfall", 1.0)
	sun.light_energy = 0.0
	env.fog_enabled = false
	env.ambient_light_energy = 0.018

func cave_moonlight():
	env.fog_enabled = true
	env.fog_density = 0.0027
	var tween := transition()
	tween.tween_property(env, "ambient_light_color", Color("#aab6d1"), 1.3)
	tween.tween_property(env, "ambient_light_energy", 0.14, 1.3)

func dress_shelter():
	var finishes := [Refuge.wood("82674d", true), Refuge.wood("8d7053", true), Refuge.wood("877057", true)]
	for i in range(15):
		var z: = -0.33 + i * 0.43
		FieldKit.block(self, Vector3(0, 0.012, z), Vector3(6.8, 0.02, 0.42), finishes[i % 3])
	for i in range(6):
		box(Vector3(0, 2.63, i * 1.15 - 0.25), Vector3(7.1, 0.16, 0.15), "5d4a39")
	Refuge.pendant(self, Vector3(-1, 2.02, 1))

func dress_path_verges():
	for sample in 39 * 2: rng.randf()
	var tufts: = SurfaceTool.new()
	tufts.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat: = StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	tufts.set_material(mat)
	for i in range(850):
		var z: = rng.randf_range(-78, -3)
		var x: = path_x(z) + rng.randf_range(1.7, 12) * (-1 if i % 2 else 1)
		if absf(z + 33 - sin(x) * 0.6) < 1.35: continue
		for blade in range(7):
			var root: = Vector3(x + rng.randf_range(-0.3, 0.3), 0.03, z + rng.randf_range(-0.3, 0.3))
			var tip: = root + Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(0.14, 0.52), 0.04)
			for v in [root, root + Vector3(0.045, 0, 0.01), tip]:
				tufts.set_color(Color("#c7af75") if v == tip else Color("#787751"))
				tufts.add_vertex(v)
	tufts.generate_normals()
	var grass: = MeshInstance3D.new()
	grass.mesh = tufts.commit()
	add_child(grass)
	for i in range(12):
		var z: = -7 - i * 5.9
		var x: = path_x(z) + (4.0 + i % 4) * (-1 if i % 2 else 1)
		if LastNight.door_path_distance(x, z) < 2.5: x += 4.6
		if z < route.WEST_START_Z:
			var west: float = route.western_x_at(z)
			if absf(x - west) < 3.8:
				x = west + (4.15 if x > path_x(z) else -4.15)
		if Exploration.clearance(Vector2(x, z)) >= 2.85:
			Flora.tree(self, Creek.point(x, z), i % 3, 0.9 + i % 4 * 0.13, i * 1.93)
	for sample in 121 * 5: rng.randf()
	for sample in 30 * 3: rng.randf()

func morning():
	exterior_light = true
	env.fog_enabled = true
	restore_light(0.0, 0.0)


func rock_banks():
	var shades: = ["82634e", "735c50", "946e54", "796458"]
	for cluster in [[-19, 1, 4], [-33, -1, 6], [-42, 1, 5], [-57, -1, 4]]:
		for i in range(cluster[2]):
			var z: = float(cluster[0]) + rng.randf_range(-2.8, 2.8)
			var width: = rng.randf_range(1.3, 3.3)
			var x: = path_x(z) + float(cluster[1]) * (2.8 + width + rng.randf_range(0, 3))
			var west: float = route.western_x_at(z)
			if z < route.WEST_START_Z and absf(x - west) < width + 2.6:
				var outer := minf(west, path_x(z)) if cluster[1] < 0 else maxf(west, path_x(z))
				x = outer + float(cluster[1]) * (width + 3.0)
			var height: = rng.randf_range(1.1, 3.5)
			var vertices: = PackedVector3Array()
			for j in range(7):
				var a: = TAU * j / 7.0 + rng.randf_range(-0.12, 0.12)
				var radius: = rng.randf_range(0.83, 1.05)
				vertices.append(Vector3(cos(a) * width * radius, -0.18, sin(a) * width * 0.82))
			for j in range(7):
				var base: = vertices[j]
				var cut: = rng.randf_range(0.53, 0.83)
				vertices.append(Vector3(base.x * cut + width * 0.12, height * (0.69 + 0.2 * base.x / width) + rng.randf_range(-0.1, 0.1), base.z * cut))
			var crown: = Vector3(width * 0.17, height * 0.98, 0)
			var surface: = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in range(7):
				var k: = (j + 1) % 7
				for v in [vertices[j], vertices[k + 7], vertices[j + 7], vertices[j], vertices[k], vertices[k + 7], vertices[j + 7], vertices[k + 7], crown]:
					surface.set_smooth_group(-1)
					surface.add_vertex(v)
			surface.generate_normals()
			if LastNight.door_path_distance(x, z) >= width + 3.6 and Exploration.clearance(Vector2(x, z)) >= width + 2.1:
				prop(surface.commit(), Vector3(x, 0, z), shades[i % shades.size()], true)

func plaster(wall: MeshInstance3D):
	var material: = ShaderMaterial.new()
	material.shader = preload("res://limewash.gdshader")
	material.set_shader_parameter("pigment", wall.material_override.albedo_color)
	wall.material_override = material

var calendar_month: Label3D
var calendar_dates: Array[Label3D] = []
var calendar_strokes: Array[MeshInstance3D] = []
var calendar_previous_day: = 0

func calendar_text(point: Vector3, text: String) -> Label3D:
	var label: = Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.00105
	label.outline_size = 0
	label.modulate = Color("#473c32")
	add_child(label)
	label.position = point
	return label

func update_calendar(day: int):
	if day == calendar_previous_day: return
	calendar_previous_day = day
	var november: = day > 31
	var date: = day - 31 if november else day
	calendar_month.text = "NOVIEMBRE" if november else "OCTUBRE"
	for cell in calendar_dates.size():
		var number: = cell + 1
		calendar_dates[cell].visible = not november or number <= 30
		calendar_dates[cell].modulate = Color("#893f34") if number == date else Color("#473c32")
		calendar_strokes[cell].visible = number < date

var wall_postcard_added := false
var wall_sketches: Dictionary = {}
var mara_stone: StaticBody3D
var mara_wine: StaticBody3D
var refuge_shelf: MeshInstance3D

func update_shelter_details(day: int, stone_sent: bool, wine_sent: bool):
	if day >= 27 and not wall_postcard_added:
		wall_postcard_added = true
		Refuge.postcard(self)
	if day >= 7 and stone_sent and not is_instance_valid(mara_stone):
		mara_stone = Refuge.map_weight(self)
	if day >= 36 and wine_sent and not is_instance_valid(mara_wine):
		var shelf_top := refuge_shelf.position + Vector3(-0.72, refuge_shelf.mesh.size.y * 0.5, -0.056)
		mara_wine = Refuge.wine_parcel(self, shelf_top)

func hang_sketch(index: int, image: Texture2D, motif := -1):
	if wall_sketches.has(index): return
	var x := -0.38 + index * 0.51
	var y := 1.53 + (0.1 if index % 2 == 0 else 0.0)
	wall_sketches[index] = Refuge.wall_sketch(self, Vector3(x, y, 5.85), image, motif)

func hang_calendar():
	var calendar := Vector3(2.7, 1.62, -0.27)
	var backing := box(calendar, Vector3(0.447, 0.523, 0.025), "9c886d", true, "Calendario")
	backing.material_override = FieldKit.material("9c886d")
	var page := FieldKit.material("dfcea7")
	FieldKit.block(self, calendar + Vector3(0, 0, 0.013), Vector3(0.429, 0.506, 0.010), page)
	var last_page := FieldKit.block(self, calendar + Vector3(0.122, -0.232, 0.021), Vector3(0.172, 0.033, 0.009), page)
	last_page.rotation.x = -0.13
	FieldKit.block(self, calendar + Vector3(0, 0.185, 0.021), Vector3(0.425, 0.108, 0.012), FieldKit.material("804f43"))
	var clip_finish := FieldKit.material("6c6458", false, 0.49)
	for side in [-1.0, 1.0]:
		var clip := FieldKit.cylinder(self, calendar + Vector3(side * 0.128, 0.241, 0.024), 0.010, 0.010, 0.011, clip_finish)
		clip.rotation.x = PI / 2.0
	var grid := FieldKit.material("b29e7c")
	for column in 8:
		FieldKit.block(self, calendar + Vector3((column - 3.5) * 0.052, -0.039, 0.0184), Vector3(0.0015, 0.290, 0.0013), grid)
	for row in 6:
		FieldKit.block(self, calendar + Vector3(0, 0.106 - row * 0.058, 0.0185), Vector3(0.365, 0.0015, 0.0013), grid)
	calendar_month = calendar_text(calendar + Vector3(0, 0.185, 0.030), "")
	calendar_month.modulate = Color("#f4e6c8")
	for cell in range(31):
		var point: = calendar + Vector3((cell % 7 - 3) * 0.052, 0.077 - floorf(cell / 7.0) * 0.058, 0.025)
		calendar_dates.append(calendar_text(point, str(cell + 1)))
		var stroke: = box(point + Vector3.FORWARD * -0.004, Vector3(0.033, 0.004, 0.003), "893f34")
		stroke.rotation.z = 0.24
		calendar_strokes.append(stroke)
	update_calendar(1)

func furnish():
	Refuge.chair(self)
	hang_calendar()
	Refuge.floor_runner(self)

	add_child(hinge)
	hinge.position = Vector3(-1.16, 0, -0.4)

	plaster(box(Vector3(0.65, 1.40, -0.4), Vector3(1.05, 2.80, 0.22), "a89b87", true))
	plaster(box(Vector3(-0.52, 2.53, -0.4), Vector3(1.30, 0.55, 0.22), "a89b87", true))
	var trim := Refuge.wood("735f4d")
	FieldKit.block(self, Vector3(-0.51, 2.265, -0.43), Vector3(1.39, 0.078, 0.24), trim)
	for x in [-1.168, 0.153]:
		FieldKit.block(self, Vector3(x, 1.127, -0.43), Vector3(0.068, 2.255, 0.24), trim)
	var door: = box(Vector3(-0.51, 1.13, -0.4), Vector3(1.28, 2.24, 0.085), "785a43", true, "Puerta")
	door.reparent(hinge)
	door.material_override = Refuge.wood("785a43")
	for i in range(7):
		var grain: = box(Vector3.ZERO, Vector3(0.004, 2.18, 0.087), "6f5745")
		grain.reparent(door, false)
		grain.position.x = -0.48 + i * 0.16
	var latch: = box(Vector3.ZERO, Vector3(0.14, 0.045, 0.18), "b5a17b")
	latch.reparent(door, false)
	latch.position = Vector3(0.43, -0.08, 0)
	refuge_shelf = box(Vector3(-1.7, 1.52, 5.7), Vector3(2.1, 0.09, 0.43), "745942", true)
	refuge_shelf.material_override = Refuge.wood("745942", true)
	var bracket := Refuge.wood("654c3c")
	for x in [-2.45, -0.95]:
		Refuge.brace(self, Vector3(x, 1.30, 5.86), Vector3(x, 1.492, 5.56), 0.060, bracket)
	kitchen_and_privy()

var bag: StaticBody3D
var book_unpacked: = false

func leave_bag():
	if bag or book_unpacked: return
	bag = FieldKit.backpack(self, Vector3(1.58, 0.244, 5.03), "Bolso")
	bag.rotation = Vector3(-1.44, 0.25, 0.0)

func unpack_book(ribbon := false):
	if book_unpacked: return
	book_unpacked = true
	if bag:
		bag.queue_free()
		bag = null
	Refuge.closed_book(self, ribbon)

func toggle_door():
	if door_motion and door_motion.is_running(): return
	door_open = not door_open
	door_motion = create_tween().set_trans(Tween.TRANS_SINE)
	door_motion.tween_property(hinge, "rotation:y", deg_to_rad(-90) if door_open else 0.0, 0.42)

func arrival_light(amount: float):
	exterior_light = true
	var tween := transition()
	light_target = ""
	var old: float = sky_mat.get_shader_parameter("nightfall")
	tween.tween_method(func(v): set_sun_phase(v, v), old, amount, 2.5)

var sky_chapter: = 0
var sun_direction := Vector3.UP
var moon_direction := Vector3.DOWN

func configure_sky(chapter: int):
	sky_chapter = chapter
	var day: int = weather_day if weather_day > 0 else SkyGuide.CHAPTER_DAYS[chapter]
	sky_mat.set_shader_parameter("moon_radius", SkyGuide.MOON_RADIUS)
	update_night_catalog(day)
	if chapter == 0: sky_mat.set_shader_parameter("nightfall", 0.0)
	update_celestial_light(day, float(sky_mat.get_shader_parameter("dusk")), float(sky_mat.get_shader_parameter("nightfall")))

func update_celestial_light(day: int, dusk: float, dark: float):
	var pair := SkyGuide.sun_and_moon(day, dusk, dark)
	sun_direction = pair[0]
	moon_direction = pair[1]
	sky_mat.set_shader_parameter("daylight_dir", sun_direction)
	sky_mat.set_shader_parameter("moon_dir", moon_direction)

func update_night_catalog(day: int):
	var sidereal := SkyGuide.sidereal_at(sky_chapter, day)
	var stars := PackedVector4Array()
	for star in SkyGuide.STARS:
		var dir := SkyGuide.direction(star, sidereal)
		stars.append(Vector4(dir.x, dir.y, dir.z, star[3]))
	var planets := PackedVector3Array()
	for planet in SkyGuide.PLANETS:
		planets.append(SkyGuide.direction(planet, sidereal))
	sky_mat.set_shader_parameter("catalog", stars)
	sky_mat.set_shader_parameter("planet_dirs", planets)
	sky_mat.set_shader_parameter("galactic_pole", SkyGuide.direction(SkyGuide.GALACTIC_POLE, sidereal))

func strange_sky(active: bool):
	exterior_light = false
	light_target = ""
	env.fog_density = 0.0027
	var tween: = transition()
	var amount: = 1.0 if active else 0.0
	var previous = sky_mat.get_shader_parameter("other_world")
	tween.tween_method( func(v): sky_mat.set_shader_parameter("other_world", v), float(previous) if previous != null else 0.0, amount, 2.0)
	tween.tween_method( func(v): sky_mat.set_shader_parameter("nightfall", v), float(sky_mat.get_shader_parameter("nightfall")), 1.0, 2.0)
	tween.tween_property(env, "fog_light_color", Color("#765484") if active else Color("#424960"), 2.0)
	tween.tween_property(env, "ambient_light_color", Color("#bba6c8") if active else Color("#9ba5bf"), 2.0)
	tween.tween_property(env, "ambient_light_energy", 0.58, 2.0)
	tween.tween_property(sun, "light_energy", 0.18, 2.0)
	tween.tween_property(sun, "light_color", Color("#ecd0ac") if active else Color("#abc4ed"), 2.0)

func kitchen_and_privy():
	Refuge.kitchenette(self)
	Refuge.refrigerator(self)
	var center := Vector3(8.0, 0.0, 7.35)
	for side in [-1, 1]:
		timber(box(center + Vector3(side * 0.82, 1.12, 0), Vector3(0.09, 2.24, 1.75), "897660", true))
	timber(box(center + Vector3(0, 1.12, 0.84), Vector3(1.65, 2.24, 0.1), "87725a", true))
	box(center + Vector3(0, 2.29, 0), Vector3(1.9, 0.09, 2.08), "72786e", true).rotation.x = 0.06
	privy_hinge = Node3D.new()
	add_child(privy_hinge)
	privy_hinge.position = center + Vector3( - 0.79, 0, - 0.86)
	var panel: = box(center + Vector3(0, 1.05, - 0.86), Vector3(1.54, 2.1, 0.08), "72614c", true, "Puerta del baño")
	timber(panel)
	panel.reparent(privy_hinge)
	box(center + Vector3(0, 0.25, 0.35), Vector3(0.84, 0.5, 0.66), "9d886a", true)
	stone(center + Vector3(0, 0.51, 0.35), Vector3(0.34, 0.025, 0.4), "49463e")

var quarry_plate: MeshInstance3D

func ground_support(top: Vector3, width: float, depth: float, tint: String):
	var bottom: float = route.terrain_point(top).y
	for x in [-width * 0.5, width * 0.5]:
		for z in [-depth * 0.5, depth * 0.5]:
			bottom = minf(bottom, route.terrain_point(top + Vector3(x, 0, z)).y)
	var height := maxf(0.04, top.y - bottom + 0.055)
	box(top - Vector3.UP * height * 0.5, Vector3(width, height, depth), tint, true)

func dress_day27():
	if quarry_plate: return
	route.signpost(route.quarry_point(0) + Vector3.RIGHT * 1.4, "Desvío de la cantera", "Cantera · cable viejo ←")
	var previous := Vector3.ZERO
	for i in range(33):
		var foot: Vector3 = route.terrain_point(route.quarry_point(i / 32.0))
		ground_support(foot + Vector3.UP * 3.0, 0.18, 0.18, "715e49")
		var eye := foot + Vector3.UP * 2.8
		if i > 0:
			var cable := box((eye + previous) * 0.5, Vector3(0.04, 0.04, eye.distance_to(previous)), "4f524b")
			cable.look_at(eye)
		previous = eye
	var end: Vector3 = route.terrain_point(route.quarry_point(1))
	for side in [-1, 1]:
		ground_support(end + Vector3(side, 1.2, -1), 0.23, 0.4, "68594c")
	box(end + Vector3(0, 0.82, -1), Vector3(2.3, 0.22, 0.23), "57534a", true)
	quarry_plate = box(end + Vector3(0, 1.38, -1), Vector3(1.1, 0.76, 0.06), "b6aa8a", true, "Chapa del malacate")
	Cable.build(self)
	Refuge.cutting(self)

var arrival_bag: StaticBody3D
var arrival_fragments: Array[Node3D] = []
var summit_dressed: = false

func dress_day32():
	if summit_dressed: return
	summit_dressed = true
	route.signpost(route.eastern_access(0.54) + Vector3(2.0, 0, 0), "Camino al acceso", "Acceso a la cumbre")
	var access: Vector3 = route.terrain_point(route.ascent_point(0))
	route.signpost(access + Vector3.RIGHT * 2.0, "Acceso a la cumbre", "Uritorco · Inicio del ascenso")
	box(access + Vector3(-2.4, 0.42, 1.1), Vector3(1.8, 0.14, 0.42), "7a634c", true)
	for offset in [-2.94, -1.86]:
		ground_support(access + Vector3(offset, 0.38, 1.1), 0.15, 0.37, "665342")
	for progress in [0.31, 0.64, 0.92]:
		var foot: Vector3 = route.ascent_point(progress)
		var uphill: Vector3 = route.ascent_point(progress + 0.02) - foot
		place_descent_sign(foot, uphill, "Acceso · seguí las pircas")
	var summit: Vector3 = route.summit_point(1)
	var descent: Vector3 = route.summit_point(0.94)
	place_descent_sign(descent, summit - descent, "Bajada · acceso")
	route.signpost(summit, "Hito de la cumbre", "Uritorco · Cumbre")
	var ground := func(at: Vector3) -> Vector3:
		return route.surface_point(at.x, route.ORIGIN_Z - at.z)
	var base: Vector3 = ground.call(summit + Vector3(0.0, 0.0, -0.25))
	var cairn_rng := RandomNumberGenerator.new()
	cairn_rng.seed = 3441
	var faces := Stone.surface()
	var plinth := Stone.fragment(faces, base, Vector3(0.88, 0.48, 0.62), 0.36, cairn_rng, ground)
	Stone.solid(self, base, plinth, "Base del hito", "Hito de la cumbre")
	Stone.finish(self, faces, "Base de piedra de la cumbre")
	dress_camp()

func place_descent_sign(foot: Vector3, uphill: Vector3, caption: String):
	var beside := foot + Vector3(uphill.z, 0.0, -uphill.x).normalized() * 2.1
	route.signpost(beside, "Bajada al acceso", caption, atan2(uphill.x, uphill.z))

var camp_log: MeshInstance3D

func dress_camp():
	var camp: Vector3 = route.terrain_point(route.camp_point())
	var tripod: Vector3 = route.terrain_point(camp + Vector3(2.1, 0.0, -0.8))
	var pivot := tripod + Vector3.UP * 1.08
	for offset in [Vector2( - 0.44, - 0.24), Vector2(0.44, - 0.24), Vector2(0, 0.55)]:
		var foot: Vector3 = route.terrain_point(tripod + Vector3(offset.x, 0, offset.y)) - Vector3.UP * 0.065
		var leg := box((foot + pivot) * 0.5, Vector3(0.046, 0.046, foot.distance_to(pivot)), "676761", true, "Trípode vacío")
		leg.look_at(pivot)
	box(pivot, Vector3(0.29, 0.063, 0.24), "424745", true, "Trípode vacío")
	var tarp: Vector3 = route.terrain_point(camp + Vector3(-2.6, 0, -0.35))
	var pitch := Basis.from_euler(Vector3(0.44, 0.22, 0.15))
	var tarp_center := tarp + Vector3.UP * 0.48
	var lift := 0.0
	for x in [-1.25, 0.0, 1.25]:
		for z in [-0.725, 0.0, 0.725]:
			var edge := tarp_center + pitch * Vector3(x, 0, z)
			lift = maxf(lift, route.terrain_point(edge).y - edge.y + 0.18)
	tarp_center.y += lift
	box(tarp_center, Vector3(2.5, 0.035, 1.45), "aba385").basis = pitch
	for x in [-1.10, 1.10]:
		for z in [-0.60, 0.60]:
			ground_support(tarp_center + pitch * Vector3(x, -0.012, z), 0.05, 0.05, "757366")
	for offset in [Vector2( - 0.44, 0.4), Vector2( - 0.17, 0.65), Vector2(0.1, 0.62), Vector2(0.44, 0.47)]:
		var foot: Vector3 = route.terrain_point(tarp + Vector3(offset.x, 0, offset.y))
		stone(foot + Vector3.UP * 0.04, Vector3(0.27, 0.22, 0.25), "77716a")
	ground_support(camp + Vector3.UP * 0.48, 0.87, 0.64, "6c6455")
	camp_log = box(camp + Vector3.UP * 0.51, Vector3(0.4, 0.058, 0.32), "b2a383", true, "Cuaderno del campamento")
	camp_log.rotation.y = 0.19
	box(camp + Vector3(0.54, 0.31, - 0.08), Vector3(0.14, 0.24, 0.14), "658078")

var storm_water: MeshInstance3D
var archive_dressed := false

func dress_day36():
	if not archive_dressed:
		archive_dressed = true
		preload("res://museo.gd").dress_archive(self)
	if not storm_water: storm_water = South.water(self)
	storm_water.visible = weather_day == 36

var yard_hinge: Node3D
var privy_hinge: Node3D
var museum_hinge: Node3D

func build_yard_fence():
	var gate_x: = path_x(-13.0)
	for segment in [[Vector3(-10, 0, -13), Vector3(gate_x - 2, 0, -13)], [Vector3(gate_x + 2, 0, -13), Vector3(10, 0, -13)], [Vector3(-10, 0, 10), Vector3(10, 0, 10)], [Vector3(-10, 0, -13), Vector3(-10, 0, 10)], [Vector3(10, 0, -13), Vector3(10, 0, 10)]]:
		var from: Vector3 = segment[0]
		var to: Vector3 = segment[1]
		for i in range(6):
			box(from.lerp(to, i / 5.0) + Vector3.UP * 0.64, Vector3(0.11, 1.28, 0.11), "7c6b51", true)
		for height in [0.4, 0.86]:
			var rail: = box((from + to) * 0.5 + Vector3.UP * height, Vector3(0.06, 0.09, from.distance_to(to)), "94836a", true)
			rail.look_at(to + Vector3.UP * height)
	yard_hinge = Node3D.new()
	add_child(yard_hinge)
	yard_hinge.position = Vector3(gate_x - 2, 0, -13)
	for h in [0.33, 0.71]:
		box(Vector3(gate_x, h, -13), Vector3(3.97, 0.18, 0.1), "78674e", true, "Tranquera").reparent(yard_hinge)
	for x in [-1.85, 1.85]:
		box(Vector3(gate_x + x, 0.53, -13), Vector3(0.11, 0.96, 0.12), "78674e", true, "Tranquera").reparent(yard_hinge)

func swing_side_door(node: Node3D):
	if not node or node.has_meta("swinging"): return
	node.set_meta("swinging", true)
	var open: = not bool(node.get_meta("open", false))
	node.set_meta("open", open)
	var swing: = create_tween()
	var opening := 2.06 if node == yard_hinge else 1.62
	swing.tween_property(node, "rotation:y", opening if open else 0.0, 0.38)
	swing.tween_callback( func(): node.remove_meta("swinging"))
