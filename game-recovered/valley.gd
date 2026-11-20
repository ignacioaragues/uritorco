extends Node3D

const Creek = preload("res://cauce.gd")
const LastNight = preload("res://final_night.gd")
const Exploration = preload("res://exploracion.gd")
const Flora = preload("res://flora.gd")
const Trail = preload("res://travesia.gd")

var rng: = RandomNumberGenerator.new()
var route = Trail.new()
var env: = Environment.new()
var sun: = DirectionalLight3D.new()
var beacon := Sprite3D.new()
var second_beacon := Sprite3D.new()
var sky_mat: = ShaderMaterial.new()
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
	sky_mat.shader = preload("res://sierra.gdshader")
	sky_mat.set_shader_parameter("faint_stars", preload("res://estrellas.png"))
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
	for i in range(24):
		var x: = i * 1.2 - 14
		stone(Vector3(x, 0, -33 + sin(x) * 0.6), Vector3(1, 0.17, 0.7), "a29b92")

	plaster(box(Vector3(0, 1.4, 6), Vector3(7, 2.8, 0.22), "a79679", true))
	plaster(box(Vector3(-3.5, 1.4, 2.8), Vector3(0.22, 2.8, 6.5), "998975", true))
	for piece in [[2.8, 0.5, 6.5, 1.0], [2.8, 2.56, 6.5, 0.48], [0.4, 1.66, 1.6, 1.32], [5.2, 1.66, 1.6, 1.32]]:
		plaster(box(Vector3(3.5, piece[1], piece[0]), Vector3(0.22, piece[3], piece[2]), "998975", true))
	box(Vector3(3.5, 1.02, 2.8), Vector3(0.4, 0.12, 3.4), "65503f")
	box(Vector3(3.5, 1.65, 2.8), Vector3(0.12, 1.32, 0.09), "755c48")
	for x in [-2.35, 2.35]:
		plaster(box(Vector3(x, 1.4, -0.4), Vector3(2.35, 2.8, 0.22), "a89b87", true))
	box(Vector3(0, 2.95, 2.65), Vector3(8, 0.23, 8), "5c5148", true).rotation.z = 0.035
	box(Vector3(2.55, 0.45, 2.35), Vector3(1.8, 0.9, 0.7), "705744", true)
	box(Vector3(2.59, 1.08, 2.35), Vector3(0.55, 0.35, 0.24), "3f514c", true, "Radio")
	box(Vector3(2.42, 1.32, 2.35), Vector3(0.025, 0.38, 0.025), "9e9b92")
	box(Vector3(2.64, 1.12, 2.48), Vector3(0.15, 0.045, 0.01), "dfbd74")
	box(Vector3(1.95, 0.93, 2.35), Vector3(0.38, 0.05, 0.32), "dbc8a2", true, "Nota")
	box(Vector3(2.55, 0.4, 4.5), Vector3(1.2, 0.8, 2.3), "787c61", true, "Cama")
	var lamp: = OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(-1, 1.95, 1)
	lamp.light_color = Color("#ffbe77")
	lamp.omni_range = 8
	lamp.light_energy = 1.5
	var end: = Vector3(path_x(-72), 0, -72)
	box(end + Vector3(2, 0.45, 0), Vector3(2.2, 0.15, 0.58), "79614a", true, "Banco")
	for offset in [1.25, 2.75]:
		box(end + Vector3(offset, 0.2, 0), Vector3(0.18, 0.45, 0.42), "675747", true)
	build_sighting_lights()
	dress_shelter()
	furnish()
	dress_creek()
	rock_banks()
	add_child(route)
	Creek.dress(self)
	dress_refuge_junction()
	preload("res://museo.gd").build(self)
	LastNight.build_door(self)
	route.signpost(LastNight.STOP + Vector3(2.1, 0, -0.6), "Parada", "Parada · Colectivo", 0.0, true)
	var fork := LastNight.door_approach(0.22)
	route.signpost(fork + Vector3(0.0, 0, -2.4), "Puesto de abajo", "Puesto de abajo →", -1.72, true)

	Exploration.build(self)

func build_distant_ridges():
	const SECTIONS := 96
	const ROWS := [Vector2(0.67, 0.0), Vector2(0.82, 0.36), Vector2(1.0, 1.0), Vector2(1.18, 0.16)]
	for layer in 2:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var material := StandardMaterial3D.new()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = Color("#7d8b8a") if layer == 0 else Color("#6c7772")
		surface.set_material(material)
		for index in SECTIONS:
			var angle := TAU * index / SECTIONS
			var south := smoothstep(0.0, 0.68, sin(angle))
			var north := smoothstep(0.0, 0.8, -sin(angle))
			var hills := 24 + 9 * sin(angle * 3 + layer) + 8 * sin(angle * 7 + layer) + 3 * cos(angle * 13) + rng.randf_range(-2, 2) - layer * 7
			var radius := 166.0 - layer * 39.0 + north * (1200 - layer * 100) + south * (250 - layer * 25)
			var bottom := lerpf(-2.0, -26.0, south)
			var crest := hills + north * (218 - layer * 40) + south * (17 - layer * 9)
			for row in ROWS:
				var distance: float = radius * row.x
				var y := lerpf(bottom, crest, row.y)
				surface.add_vertex(Vector3(distance * cos(angle), y, -28.0 + distance * sin(angle)))
		for index in SECTIONS:
			var next := ((index + 1) % SECTIONS) * ROWS.size()
			for row in range(ROWS.size() - 1):
				var a := index * ROWS.size() + row
				var b := next + row
				for vertex in [a + 1, a, b + 1, b + 1, a, b]:
					surface.add_index(vertex)
		surface.generate_normals()
		var ridge := MeshInstance3D.new()
		ridge.mesh = surface.commit()
		ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ridge)

func dress_refuge_junction():
	route.signpost(Vector3(1.25, 0.0, -17.8), "Sendero del cauce", "← Cauce", 0.0, true)
	route.signpost(Vector3(6.75, 0.0, -17.8), "Camino al acceso", "Cumbre →", 0.0, true)

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

func sunset():
	var tween: = transition()
	tween.tween_method( func(v): sky_mat.set_shader_parameter("dusk", v), 0.0, 1.0, 5.0)
	tween.tween_property(sun, "rotation:x", deg_to_rad(-10), 5.0)
	tween.tween_property(sun, "light_color", Color("#ffb07d"), 5.0)
	tween.tween_property(env, "ambient_light_energy", 0.7, 5.0)

var weather_day: = 0

func update_weather(day: int):
	if day == weather_day: return
	weather_day = day
	var cloud: float = {1: 0.19, 2: 0.12, 7: 0.56, 25: 0.29, 27: 0.38, 32: 0.08, 36: 0.86, 41: 0.46}.get(day, 0.0)
	sky_mat.set_shader_parameter("cloud_cover", cloud)
	env.fog_density = lerpf(0.0027, 0.009, cloud * cloud)

func cave_darkness():
	if lighting and lighting.is_valid(): lighting.kill()
	sky_mat.set_shader_parameter("nightfall", 1.0)
	sun.light_energy = 0.0
	env.fog_enabled = false
	env.ambient_light_energy = 0.018

func cave_moonlight():
	env.fog_enabled = true
	var tween := transition()
	tween.tween_property(env, "ambient_light_color", Color("#aab6d1"), 1.3)
	tween.tween_property(env, "ambient_light_energy", 0.14, 1.3)

func night(duration: float = 6.0):
	sun.shadow_enabled = false
	var tween: = transition()
	tween.tween_method( func(v): sky_mat.set_shader_parameter("nightfall", v), float(sky_mat.get_shader_parameter("nightfall")), 1.0, duration)
	tween.tween_property(sun, "light_energy", 0.045, duration)
	tween.tween_property(sun, "light_color", Color("#abc4ed"), duration)
	tween.tween_property(env, "ambient_light_color", Color("#9ba5bf"), duration)
	tween.tween_property(env, "ambient_light_energy", 0.19, duration)
	tween.tween_property(env, "fog_light_color", Color("#424960"), duration)

func dress_shelter():
	for i in range(15):
		var z: = -0.33 + i * 0.43
		timber(box(Vector3(0, 0.012, z), Vector3(6.8, 0.02, 0.42), ["82674d", "8d7053", "877057"][i % 3]), true)
	for i in range(6):
		box(Vector3(0, 2.63, i * 1.15 - 0.25), Vector3(7.1, 0.16, 0.15), "5d4a39")
	var pan: = CylinderMesh.new()
	pan.top_radius = 0.185
	pan.bottom_radius = 0.13
	pan.height = 0.055
	prop(pan, Vector3(-3.0, 1.04, 3.26), "383837")
	box(Vector3(-2.82, 1.06, 3.26), Vector3(0.045, 0.035, 0.22), "49433c")
	box(Vector3(2.55, 0.86, 5.26), Vector3(0.89, 0.13, 0.51), "c8b99a")
	for i in range(6):
		box(Vector3(2.55, 0.812, 3.42 + i * 0.075), Vector3(1.21, 0.014, 0.038), "ad825c")
	var shade: = CylinderMesh.new()
	shade.height = 0.21
	shade.top_radius = 0.085
	shade.bottom_radius = 0.24
	prop(shade, Vector3(-1, 2.02, 1), "ba925f")
	box(Vector3(-1, 2.4, 1), Vector3(0.018, 0.59, 0.018), "443f39")

func dress_creek():
	var bed: = SurfaceTool.new()
	bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gravel: = StandardMaterial3D.new()
	gravel.cull_mode = BaseMaterial3D.CULL_DISABLED
	gravel.vertex_color_use_as_albedo = true
	bed.set_material(gravel)
	var last: = PackedVector3Array()
	for i in range(39):
		var x: = i * 0.8 - 15.2
		var z: = -33.0 + sin(x) * 0.6
		var row: = PackedVector3Array([Vector3(x, 0.036, z - rng.randf_range(0.8, 1.4)), Vector3(x, 0.038, z), Vector3(x, 0.036, z + rng.randf_range(0.8, 1.4))])
		if i > 0:
			for j in range(2):
				for point in [last[j], row[j], last[j + 1], last[j + 1], row[j], row[j + 1]]:
					bed.set_color(Color("#7c7871") if point == row[1] or point == last[1] else Color("#9c907a"))
					bed.set_normal(Vector3.UP)
					bed.add_vertex(point)
		last = row
	var channel: = MeshInstance3D.new()
	channel.mesh = bed.commit()
	add_child(channel)
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
		if Exploration.clearance(Vector2(x, z)) >= 2.85:
			Flora.tree(self, Creek.point(x, z), i % 3, 0.9 + i % 4 * 0.13, i * 1.93)
	var marker: Vector3 = route.creek_marker()
	for i in range(-60, 61):
		var x: float = marker.x + i * 0.72
		var d: float = route.CREEK_DISTANCE + 2.0 * sin((x - route.trail(route.CREEK_DISTANCE)) / 14.0)
		for j in range(-2, 3):
			stone(route.at(x, d + j * 0.44) + Vector3.UP * 0.03, Vector3(1.0, 0.2, 0.64), "8a8272")
	for i in range(30):
		var x: = rng.randf_range(-12, 12)
		stone(Vector3(x, 0.018, -33 + sin(x) * 0.6 + rng.randf_range(-0.7, 0.7)), Vector3(0.56, 0.12, 0.36), "696c66")

func unpack_calendar():
	var center: = Vector3(2.51, 0.9, 4.02)
	box(center, Vector3(0.46, 0.035, 0.36), "ded1b4", true, "Calendario")
	for i in range(5):
		box(center + Vector3(-0.19 + i * 0.095, 0.02, 0), Vector3(0.004, 0.003, 0.27), "9e9988")
	for i in range(4):
		box(center + Vector3(0, 0.02, -0.13 + i * 0.086), Vector3(0.38, 0.003, 0.004), "9e9988")
	var ticket: = box(center + Vector3(0.09, 0.026, 0.08), Vector3(0.24, 0.008, 0.105), "c18f61")
	ticket.rotation.y = 0.18

func morning():
	sun.shadow_enabled = true
	env.fog_enabled = true
	if lighting and lighting.is_valid():
		lighting.kill()
	sky_mat.set_shader_parameter("dusk", 0.0)
	sky_mat.set_shader_parameter("nightfall", 0.0)
	sun.rotation_degrees = Vector3(-24, 68, 0)
	sun.light_energy = 0.9
	sun.light_color = Color("#ffe0b8")
	env.ambient_light_color = Color("#dce6de")
	env.ambient_light_energy = 0.86
	env.fog_light_color = Color("#98b3b7")


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

var wall_glove_added: = false
var wall_postcard_added: = false

func update_shelter_wall(day: int):
	if day >= 7 and not wall_glove_added:
		wall_glove_added = true
		var hook: = Vector3(1.82, 1.62, -0.24)
		box(hook, Vector3(0.018, 0.024, 0.11), "665d50")
		var glove: = box(hook + Vector3(0, -0.13, 0.065), Vector3(0.14, 0.17, 0.042), "6f6051", true, "Guante izquierdo")
		glove.rotation.z = -0.12
		box(hook + Vector3(0, -0.045, 0.064), Vector3(0.143, 0.038, 0.045), "514c42")
		for finger in range(4):
			stone(hook + Vector3(-0.043 + finger * 0.031, -0.224 + absf(finger - 1.5) * 0.015, 0.061), Vector3(0.033, 0.081, 0.041), "746557")
		stone(hook + Vector3(0.075, -0.142, 0.064), Vector3(0.075, 0.036, 0.042), "746557")
	if day >= 27 and not wall_postcard_added:
		wall_postcard_added = true
		var postcard: = Vector3(-2.57, 1.58, -0.255)
		box(postcard, Vector3(0.32, 0.22, 0.023), "d4c19e", true, "Postal de Paula")
		var illustration: = QuadMesh.new()
		illustration.size = Vector2(0.31, 0.21)
		var print_surface: = prop(illustration, postcard + Vector3(0, 0, 0.013), "ffffff")
		var material: = print_surface.material_override as StandardMaterial3D
		if ResourceLoader.exists("res://postal_munich.webp"):
			material.albedo_texture = load("res://postal_munich.webp")
		box(postcard + Vector3(0, 0.108, 0.022), Vector3(0.018, 0.018, 0.028), "6e5944")

func furnish_desk_corner():
	var chair: = Vector3(2.42, 0, 1.61)
	timber(box(chair + Vector3.UP * 0.46, Vector3(0.43, 0.07, 0.41), "896448", true))
	for x in [-0.17, 0.17]:
		for z in [-0.16, 0.16]:
			var height: = 0.93 if z < 0.0 else 0.46
			timber(box(chair + Vector3(x, height * 0.5, z), Vector3(0.047, height, 0.047), "70513b"))
	for height in [0.71, 0.86]:
		timber(box(chair + Vector3(0, height, -0.16), Vector3(0.38, 0.08, 0.044), "896448", true))

	var calendar: = Vector3(2.7, 1.62, -0.27)
	box(calendar, Vector3(0.42, 0.5, 0.025), "d9c8a4", true, "Calendario")
	box(calendar + Vector3(0, 0.185, 0.017), Vector3(0.418, 0.11, 0.012), "785044")
	calendar_month = calendar_text(calendar + Vector3(0, 0.185, 0.028), "")
	calendar_month.modulate = Color("#f4e6c8")
	for cell in range(31):
		var point: = calendar + Vector3((cell % 7 - 3) * 0.052, 0.077 - floorf(cell / 7.0) * 0.058, 0.025)
		calendar_dates.append(calendar_text(point, str(cell + 1)))
		var stroke: = box(point + Vector3.FORWARD * -0.004, Vector3(0.033, 0.004, 0.003), "893f34")
		stroke.rotation.z = 0.24
		calendar_strokes.append(stroke)
	update_calendar(1)

	var notebook: = Vector3(2.35, 0.919, 2.53)
	box(notebook, Vector3(0.25, 0.037, 0.19), "506354").rotation.y = -0.09
	box(notebook + Vector3(0, -0.004, 0.088), Vector3(0.23, 0.022, 0.012), "d8c9a9").rotation.y = -0.09
	box(Vector3(2.56, 0.909, 2.52), Vector3(0.014, 0.014, 0.16), "b18649").rotation.y = 0.31

func furnish():
	furnish_desk_corner()

	box(Vector3(1.27, 0.032, 3.95), Vector3(0.84, 0.012, 1.72), "816956")
	for j in range(9):
		box(Vector3(1.27, 0.04, 3.25 + j * 0.16), Vector3(0.82, 0.006, 0.025), "a58c69")
	var cup: = CylinderMesh.new()
	cup.top_radius = 0.057
	cup.bottom_radius = 0.05
	cup.height = 0.11
	prop(cup, Vector3(2.93, 0.96, 2.22), "d5c9a9")
	stone(Vector3(2.93, 1.016, 2.22), Vector3(0.095, 0.005, 0.095), "60524b")
	var handle: = TorusMesh.new()
	handle.inner_radius = 0.026
	handle.outer_radius = 0.035
	prop(handle, Vector3(2.995, 0.965, 2.22), "d5c9a9").rotation.x = PI / 2

	add_child(hinge)
	hinge.position = Vector3(-1.16, 0, -0.4)

	box(Vector3(0.65, 1.36, -0.4), Vector3(1.05, 2.72, 0.17), "987e64", true)
	box(Vector3(-0.52, 2.5, -0.4), Vector3(1.3, 0.46, 0.2), "75624d", true)
	var door: = box(Vector3(-0.51, 1.13, -0.4), Vector3(1.28, 2.24, 0.085), "785a43", true, "Puerta")
	door.reparent(hinge)
	timber(door)
	for i in range(7):
		var grain: = box(Vector3.ZERO, Vector3(0.008, 2.18, 0.09), "624e40")
		grain.reparent(door, false)
		grain.position.x = -0.48 + i * 0.16
	var latch: = box(Vector3.ZERO, Vector3(0.14, 0.045, 0.18), "b5a17b")
	latch.reparent(door, false)
	latch.position = Vector3(0.43, -0.08, 0)
	timber(box(Vector3(-1.7, 1.52, 5.7), Vector3(2.1, 0.09, 0.43), "745942", true), true)
	kitchen_and_privy()

var bag: MeshInstance3D
var book_unpacked: = false

func leave_bag():
	if bag or book_unpacked: return
	bag = box(Vector3(1.8, 0.21, 5.1), Vector3(0.64, 0.39, 0.37), "655143", true, "Bolso")
	var strap: = box(Vector3.ZERO, Vector3(0.08, 0.015, 0.38), "3f433c")
	strap.reparent(bag, false)
	strap.position.y = 0.2

func unpack_book():
	if book_unpacked: return
	book_unpacked = true
	if bag: bag.queue_free()
	for i in range(1):
		var titles: = ["Observar el Cielo", "Flora serrana", "Cuaderno de campo"]
		var cover: = box(Vector3(-1.75, 1.61, 5.66), Vector3(0.49, 0.58, 0.074), ["394c64", "506651", "955f43"][i], true, titles[i])
		cover.rotation = Vector3(PI / 2, 0.1, 0)
		cover.scale = Vector3(0.75, 0.67, 1)
		var title: = Label3D.new()
		cover.add_child(title)
		title.position = Vector3(0, 0.045, -0.039)
		title.rotation.y = PI
		title.text = titles[i].replace(" el ", " el\n").replace(" de ", " de\n").replace("Flora ", "Flora\n")
		title.font_size = 36
		title.pixel_size = 0.00165
		title.outline_size = 0
		title.modulate = Color("#f4ddb0")
		var pages: = box(Vector3.ZERO, Vector3(0.46, 0.011, 0.06), "ccbfa1")
		pages.reparent(cover, false)
		pages.position.y = 0.293
		if i == 0:
			var author: = Label3D.new()
			cover.add_child(author)
			author.position = Vector3(0, -0.175, -0.04)
			author.rotation.y = PI
			author.text = "DAVID H. LEVY"
			author.outline_size = 0
			author.font_size = 27
			author.pixel_size = 0.00092
			author.modulate = Color("#ecdbb1")

func toggle_door():
	if door_motion and door_motion.is_running(): return
	door_open = not door_open
	door_motion = create_tween().set_trans(Tween.TRANS_SINE)
	door_motion.tween_property(hinge, "rotation:y", deg_to_rad(90) if door_open else 0.0, 0.42)

func arrival_light(amount: float):
	sun.shadow_enabled = amount < 0.55
	var tween: = transition()
	var old = sky_mat.get_shader_parameter("nightfall")
	tween.tween_method( func(v): sky_mat.set_shader_parameter("nightfall", v), float(old) if old != null else 0.0, amount, 2.5)
	tween.tween_property(sun, "light_energy", lerpf(1.0, 0.045, amount), 2.5)
	tween.tween_property(sun, "light_color", Color("#ffd3a1").lerp(Color("#abc4ed"), amount), 2.5)
	tween.tween_property(env, "ambient_light_color", Color("#eee1ce").lerp(Color("#9ba5bf"), amount), 2.5)
	tween.tween_property(env, "ambient_light_energy", lerpf(0.85, 0.19, amount), 2.5)
	tween.tween_property(env, "fog_light_color", Color("#c6ac9d").lerp(Color("#424960"), amount), 2.5)

var sky_chapter: = 0

func configure_sky(chapter: int):
	sky_chapter = chapter
	var catalog = preload("res://constelacion.gd")
	var night_data: Array = catalog.NIGHTS[chapter]
	var stars: = PackedVector4Array()
	for star in catalog.STARS:
		var dir: Vector3 = catalog.direction(star, night_data[0])
		stars.append(Vector4(dir.x, dir.y, dir.z, star[3]))
	sky_mat.set_shader_parameter("catalog", stars)
	sky_mat.set_shader_parameter("moon_dir", night_data[1])
	sky_mat.set_shader_parameter("sun_dir", night_data[2])
	if chapter == 0: sky_mat.set_shader_parameter("nightfall", 0.0)

func strange_sky(active: bool):
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
	timber(box(Vector3(-3, 0.48, 3.6), Vector3(0.77, 0.95, 2.2), "6c5848", true))
	box(Vector3(-3, 0.97, 3.6), Vector3(0.82, 0.06, 2.25), "ada69a")
	box(Vector3(-3, 1.01, 3.25), Vector3(0.57, 0.05, 0.72), "494b46")
	box(Vector3(-3, 1.01, 4.12), Vector3(0.5, 0.02, 0.55), "666e6b")
	box(Vector3(-3.23, 1.2, 4.12), Vector3(0.04, 0.4, 0.04), "939893")
	box(Vector3(-3.15, 1.39, 4.12), Vector3(0.2, 0.04, 0.04), "939893")
	var center: = Vector3(6, 0, 3.5)
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
func dress_day27():
	if quarry_plate: return
	route.signpost(route.quarry_point(0) + Vector3.RIGHT * 1.4, "Desvío de la cantera", "Cantera · cable viejo ←")
	for i in range(33):
		var foot: Vector3 = route.quarry_point(i / 32.0)
		box(foot + Vector3.UP * 1.5, Vector3(0.18, 3, 0.18), "715e49", true)
		if i > 0:
			var previous: Vector3 = route.quarry_point((i - 1) / 32.0)
			var cable: = box((foot + previous) * 0.5 + Vector3.UP * 2.8, Vector3(0.04, 0.04, foot.distance_to(previous)), "4f524b")
			cable.look_at(foot + Vector3.UP * 2.8)
	var end: Vector3 = route.quarry_point(1)
	for side in [-1, 1]:
		box(end + Vector3(side, 0.6, -1), Vector3(0.23, 1.2, 0.4), "68594c", true)
	box(end + Vector3(0, 0.82, -1), Vector3(2.3, 0.22, 0.23), "57534a", true)
	quarry_plate = box(end + Vector3(0, 1.38, -1), Vector3(1.1, 0.76, 0.06), "b6aa8a", true, "Chapa del malacate")
	box(Vector3(3.17, 0.923, 2.49), Vector3(0.33, 0.025, 0.24), "c9b994", true, "Recorte de astronomía").rotation.y = 0.18
	box(Vector3(3.25, 0.95, 2.22), Vector3(0.19, 0.1, 0.12), "887a69")

var arrival_bag: MeshInstance3D
var arrival_fragments: Array[Node3D] = []
var summit_dressed: = false

func dress_day32():
	if summit_dressed: return
	summit_dressed = true
	route.signpost(route.eastern_access(0.54) + Vector3(2.0, 0, 0), "Camino al acceso", "Acceso a la cumbre")
	var access: Vector3 = route.ascent_point(0)
	route.signpost(access + Vector3.RIGHT * 2.0, "Acceso a la cumbre", "Uritorco · Inicio del ascenso")
	box(access + Vector3(-2.4, 0.42, 1.1), Vector3(1.8, 0.14, 0.42), "7a634c", true)
	for offset in [-2.94, -1.86]:
		box(access + Vector3(offset, 0.17, 1.1), Vector3(0.15, 0.42, 0.37), "665342", true)
	dress_ascent_trail()
	for progress in [0.31, 0.64, 0.92]:
		var foot: Vector3 = route.ascent_point(progress)
		var uphill: Vector3 = route.ascent_point(progress + 0.02) - foot
		place_descent_sign(foot, uphill, "Acceso · seguí las pircas")
	for i in range(1, 12):
		var foot: Vector3 = route.summit_point(lerpf(route.SUMMIT_JOIN, 1.0, i / 12.0))
		stack_ascent_stones(foot + Vector3(0, 0, 1.0))
	var summit: Vector3 = route.summit_point(1)
	var descent: Vector3 = route.summit_point(0.94)
	place_descent_sign(descent, summit - descent, "Bajada · acceso")
	route.signpost(summit, "Hito de la cumbre", "Uritorco · Cumbre")
	box(summit + Vector3(0, 0.25, - 0.25), Vector3(0.8, 0.46, 0.42), "938273", true)
	dress_camp()

func place_descent_sign(foot: Vector3, uphill: Vector3, caption: String):
	var beside := foot + Vector3(uphill.z, 0.0, -uphill.x).normalized() * 2.1
	var ground: Vector3 = route.surface_point(beside.x, route.ORIGIN_Z - beside.z)
	route.signpost(ground, "Bajada al acceso", caption, atan2(uphill.x, uphill.z))

var camp_log: MeshInstance3D

func dress_camp():
	var camp: Vector3 = route.camp_point()
	var tripod: Vector3 = route.at(camp.x + 2.1, route.ORIGIN_Z - camp.z + 0.8)
	var pivot: = tripod + Vector3.UP * 1.08
	for offset in [Vector2( - 0.44, - 0.24), Vector2(0.44, - 0.24), Vector2(0, 0.55)]:
		var foot: Vector3 = route.at(tripod.x + offset.x, route.ORIGIN_Z - tripod.z - offset.y)
		var leg: = box((foot + pivot) * 0.5, Vector3(0.046, 0.046, foot.distance_to(pivot)), "676761")
		leg.look_at(pivot)
	box(pivot, Vector3(0.29, 0.063, 0.24), "424745", true, "Trípode vacío")
	var tarp: Vector3 = route.at(camp.x - 2.6, route.ORIGIN_Z - camp.z + 0.35)
	box(tarp + Vector3.UP * 0.48, Vector3(2.5, 0.035, 1.45), "aba385").rotation = Vector3(0.44, 0.22, 0.15)
	for x in [-1.04, 1.04]:
		box(tarp + Vector3(x, 0.47, - 0.5), Vector3(0.05, 0.96, 0.05), "757366").rotation.z = 0.22
	for offset in [Vector2( - 0.44, 0.4), Vector2( - 0.17, 0.65), Vector2(0.1, 0.62), Vector2(0.44, 0.47)]:
		var foot: Vector3 = route.at(tarp.x + offset.x, route.ORIGIN_Z - tarp.z - offset.y)
		stone(foot + Vector3.UP * 0.09, Vector3(0.27, 0.22, 0.25), "77716a")
	box(camp + Vector3.UP * 0.24, Vector3(0.87, 0.48, 0.64), "6c6455", true)
	camp_log = box(camp + Vector3.UP * 0.51, Vector3(0.4, 0.058, 0.32), "b2a383", true, "Cuaderno del campamento")
	camp_log.rotation.y = 0.19
	box(camp + Vector3(0.54, 0.31, - 0.08), Vector3(0.14, 0.24, 0.14), "658078")

func dress_ascent_trail():
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: = StandardMaterial3D.new()
	material.albedo_color = Color("9a7955")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	var left: = Vector3.ZERO
	var right: = Vector3.ZERO
	for i in range(425):
		var point: Vector3
		if i <= 375:
			point = route.ascent_point(i / 375.0)
		else:
			point = route.summit_point(lerpf(route.SUMMIT_JOIN, 1.0, (i - 375) / 49.0))
		var d: float = route.ORIGIN_Z - point.z
		var next_left: Vector3 = route.surface_point(point.x - 1.0, d) + Vector3.UP * 0.044
		var next_right: Vector3 = route.surface_point(point.x + 1.0, d) + Vector3.UP * 0.044
		if i > 0:
			for vertex in [left, next_left, right, right, next_left, next_right]:
				surface.add_vertex(vertex)
		left = next_left
		right = next_right
		if i > 0 and i <= 375 and i % 19 == 0:
			stack_ascent_stones(route.surface_point(point.x + 1.4, d))
	surface.generate_normals()
	var path: = MeshInstance3D.new()
	path.mesh = surface.commit()
	add_child(path)

func stack_ascent_stones(foot: Vector3):
	var base: Vector3 = route.surface_point(foot.x, route.ORIGIN_Z - foot.z)
	for level in 3:
		var width: = 0.63 - 0.14 * level
		stone(base + Vector3.UP * (0.07 + level * 0.19), Vector3(width, 0.26, width * 0.7), "9a8971")

var crossing_dressed: = false

func dress_day36(show_crossing: bool = true):
	if not crossing_dressed:
		crossing_dressed = true
		preload("res://museo.gd").dress_archive(self)
	if not show_crossing: return
	var fork: Vector3 = route.crossing_point(0)
	route.signpost(route.surface_point(fork.x - 1.9, route.ORIGIN_Z - fork.z), "Desvío de la quebrada", "Pasarela · quebrada oeste")
	for i in range(1, 25):
		stack_ascent_stones(route.crossing_point(i / 25.0) + Vector3.RIGHT)
	var timber_fall: Vector3 = route.crossing_point(0.26)
	box(timber_fall + Vector3.UP * 0.31, Vector3(4.7, 0.62, 0.52), "6c523c", true, "Tronco caído").rotation.y = 0.35
	var shelf: Vector3 = route.crossing_point(0.72)
	var foot: Vector3 = route.surface_point(shelf.x, route.ORIGIN_Z - shelf.z - 0.47)
	box(Vector3(shelf.x, foot.y + 0.61, shelf.z - 0.78), Vector3(5.0, 1.52, 2.5), "948371", true, "Subir al escalón")
	var crossing: Vector3 = route.crossing_point(1)
	for i in range(-5, 6):
		var board: Vector3 = route.at(crossing.x + i * 0.41, route.ORIGIN_Z - crossing.z - 1.1)
		box(board + Vector3.UP * 0.16, Vector3(0.405, 0.29, 1.45), "887456", true)
	route.signpost(crossing, "Pasarela de la quebrada", "Pasarela · marca del agua")
	for i in range(-10, 11):
		var silt: Vector3 = route.at(crossing.x + i * 0.65, route.ORIGIN_Z - crossing.z - 2.0)
		stone(silt + Vector3.UP * 0.05, Vector3(0.72, 0.17, 0.47), "706d5d")

var yard_hinge: Node3D
var privy_hinge: Node3D
var museum_hinge: Node3D

func build_yard_fence():
	var gate_x: = path_x(-13.0)
	for segment in [[Vector3(-10, 0, -13), Vector3(gate_x - 2, 0, -13)], [Vector3(gate_x + 2, 0, -13), Vector3(10, 0, -13)], [Vector3(-10, 0, 10), Vector3(10, 0, 10)], [Vector3(-10, 0, -13), Vector3(-10, 0, 10)], [Vector3(10, 0, -13), Vector3(10, 0, 10)]]:
		var from: Vector3 = segment[0]
		var to: Vector3 = segment[1]
		for i in range(6):
			box(from.lerp(to, i / 5.0) + Vector3.UP * 0.64, Vector3(0.11, 1.28, 0.11), "7c6b51")
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
	swing.tween_property(node, "rotation:y", 1.62 if open else 0.0, 0.38)
	swing.tween_callback( func(): node.remove_meta("swinging"))
