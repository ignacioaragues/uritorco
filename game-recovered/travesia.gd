extends Node3D


const ORIGIN_Z: = -76.0
const WEST_START_Z := -22.0
const WEST_JOIN := 0.44
const HALF_WIDTH: = 360.0
const FAR: = 980.0
const CREST: = 922.0
const CREEK_DISTANCE: = 96.0
const SUMMIT_JOIN: = 0.37
var rng: = RandomNumberGenerator.new()
var ground_rows: = PackedFloat32Array()
var birds: Array[Node3D] = []
var wings: Array[Node3D] = []
var fox: = Node3D.new()
var legs: Array[Node3D] = []
var fox_waits: = false
var fox_departure: = -1.0
var fox_start: = Vector3.ZERO
var fox_speed: = 1.4
var time: = 0.0


static func trail(d: float) -> float:
	return -1.9 + 54.0 * sin(d / 83.0) + 18.0 * sin(d / 27.0)

static func detour(d: float) -> float:
	return trail(d) + 36.0 * sin(PI * clampf((d - 124.0) / 94.0, 0, 1))

static func creek_overlook(t: float) -> Vector3:
	var d: = lerpf(43.0, 104.0, t)
	var x: = trail(d) - 19.0 * sin(PI * t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func elevation(x: float, d: float) -> float:
	var t: = smoothstep(0, 65, d)
	var roll: = 6.0 * sin(d / 63.0) + 4.0 * sin(x / 53.0 + d / 89.0)
	var shoulder: = 20.0 * pow(clampf(absf(x - trail(d)) / 180.0, 0, 1), 2)
	var lip: = 3.1 * smoothstep(169.8, 170.2, d) * (1.0 - smoothstep(9, 26, absf(x - trail(170)))) * (1.0 - smoothstep(180, 218, d))
	var summit: = 45.0 * exp( - pow((x - 146.0) / 76.0, 2) - pow((d - 948.0) / 61.0, 2))
	var bed: = CREEK_DISTANCE + 2.0 * sin((x - trail(CREEK_DISTANCE)) / 14.0)
	var banks: = 1.0 - smoothstep(1.8, 8.0, absf(d - bed))
	var reach: = 1.0 - smoothstep(47.0, 69.0, absf(x - trail(CREEK_DISTANCE)))
	return summit + (0.136 * maxf(0, d) + roll + shoulder) * t + lip - 2.3 * banks * reach

func at(x: float, d: float) -> Vector3:
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

func creek_marker() -> Vector3:
	return at(trail(CREEK_DISTANCE) + 1.5, CREEK_DISTANCE)

func _ready():
	rng.seed = 853
	for i in range(-1, 246): ground_rows.append(i * 4.0)
	for d in range(89, 106):
		if d % 4 != 0: ground_rows.append(float(d))
	ground_rows.append(169.8)
	ground_rows.append(170.2)
	ground_rows.sort()
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for d in ground_rows:
		for ix in range(181):
			var x: = - HALF_WIDTH + ix * 4
			surface.add_vertex(at(x, d))
	for j in range(ground_rows.size() - 1):
		for i in range(180):
			var a: = j * 181 + i
			for index in [a, a + 181, a + 1, a + 1, a + 181, a + 182]: surface.add_index(index)
	surface.generate_normals()
	var land: = MeshInstance3D.new()
	land.mesh = surface.commit()
	var mat: = ShaderMaterial.new()
	mat.shader = preload("res://monte.gdshader")
	var west_start := western_approach(0.0)
	var west_end := western_approach(1.0)
	mat.set_shader_parameter("west_start", Vector2(west_start.x, west_start.z))
	mat.set_shader_parameter("west_end", Vector2(west_end.x, west_end.z))
	land.material_override = mat
	add_child(land)
	land.create_trimesh_collision()
	var crossing: = trail(170.0)
	signpost(creek_overlook(0.0) + Vector3(-1.6, 0, 0), "Desvío del cauce", "Mirador del cauce ↖")
	var overlook: = creek_overlook(0.63)
	signpost(overlook + Vector3(-1.4, 0, 0), "Mirador del cauce", "Mirador del cauce")
	box(self, Vector3(0.42, 0.43, 1.35), overlook + Vector3(-1.4, 0.2, -1.3), "978a73")
	signpost(at(trail(124) + 2, 124), "Paso de la laja", "Filo por la laja  ↑\nRodeo por la vaguada  →")
	signpost(at(crossing + 1.3, 169.0), "Trepar la laja", "Laja")
	signpost(at(crossing + 1.3, 171.0), "Bajar la laja", "Descenso")
	signpost(at(trail(CREST), CREST), "Hito del filo", "Filo del puesto")
	plant()
	make_wildlife()
	fox.hide()
	var repeater: = at(trail(420) + 1.6, 420)
	signpost(repeater, "Antena del abra", "Radio · Abra del viento")
	box(self, Vector3(0.08, 4.0, 0.08), repeater + Vector3(0, 2, 0), "655a50")
	for h in [2.85, 3.45, 3.94]:
		box(self, Vector3(1.15, 0.04, 0.07), repeater + Vector3(0, h, 0), "737a75")
	signpost(at(trail(292) - 1.7, 292), "Sala de las sierras", "Museo de sitio →")
	signpost(west_start + Vector3(0.7, 0.0, 1.6), "Sendero oeste", "Sendero oeste ↖")
	signpost(west_end + Vector3(2.0, 0.0, 0.0), "Sendero oeste", "Refugio · senda del oeste")

func signpost(pos: Vector3, tag: String, caption: String):
	var pole: = box(self, Vector3(0.17, 1.5, 0.14), pos + Vector3.UP * 0.75, "6c5443")
	pole.create_trimesh_collision()
	pole.get_child(0).set_meta("item", tag)
	var board: = box(self, Vector3(1.35, 0.43, 0.1), pos + Vector3.UP * 1.25, "665847")
	board.create_trimesh_collision()
	board.get_child(0).set_meta("item", tag)
	var text: = Label3D.new()
	board.add_child(text)
	text.position.z = 0.114
	text.text = caption
	text.font_size = 32
	text.pixel_size = 0.002
	text.modulate = Color("#e6d8b5")
	text.double_sided = true

func box(parent: Node3D, size_m: Vector3, pos: Vector3, color: String) -> MeshInstance3D:
	var mesh: = BoxMesh.new()
	mesh.size = size_m
	var node: = MeshInstance3D.new()
	node.mesh = mesh
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func scattered(mesh: PrimitiveMesh, transforms: Array[Transform3D], color: String):
	var batch: = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i in transforms.size(): batch.set_instance_transform(i, transforms[i])
	var inst: = MultiMeshInstance3D.new()
	inst.multimesh = batch
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	inst.material_override = mat
	add_child(inst)

func plant():
	var grass: Array[Transform3D] = []
	var shrubs: Array[Transform3D] = []
	var stems: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	for i in range(7600):
		var d: = rng.randf_range(8, FAR)
		var x: = trail(d) + rng.randf_range(-120, 120)
		var west_t := inverse_lerp(WEST_START_Z, quarry_point(WEST_JOIN).z, ORIGIN_Z - d)
		if west_t < 1.0 and absf(x - western_approach(west_t).x) < 3.8: continue
		if absf(d - 292) < 8 and absf(x - trail(292) - 6) < 7: continue
		if absf(x - trail(d)) < 2.6 or (d > 124 and d < 218 and absf(x - detour(d)) < 2.6): continue
		var pos: = at(x, d)
		var scale_m: = rng.randf_range(0.7, 1.8)
		var turn: = Basis(Vector3.UP, rng.randf() * TAU)
		if i % 12 == 0 and (d < 540 or i % 36 == 0):
			stems.append(Transform3D(turn.scaled(Vector3(0.19, 1.6, 0.23) * scale_m), pos + Vector3.UP * 0.76 * scale_m))
			for j in range(3):
				var angle: = j * 2.1 + turn.get_euler().y
				shrubs.append(Transform3D(turn.scaled(Vector3(2.4, 1.65, 2.0) * scale_m), pos + Vector3(cos(angle) * 0.78, 1.48 + j * 0.2, sin(angle) * 0.78) * scale_m))
		elif i % 8 == 0:
			rocks.append(Transform3D(turn.scaled(Vector3(2.1, 1.8, 2.4) * scale_m), pos))
		else:
			for j in range(4):
				var angle: = j * 1.57
				grass.append(Transform3D(turn.rotated(Vector3.FORWARD, 0.15 * j).scaled(Vector3(0.32, 0.74, 0.28) * scale_m), pos + Vector3(0.14 * cos(angle), 0.25, 0.14 * sin(angle)) * scale_m))
	var ball: = SphereMesh.new()
	ball.radial_segments = 7
	ball.rings = 3
	var blade: = CylinderMesh.new()
	blade.top_radius = 0.0
	blade.radial_segments = 3
	blade.height = 1
	scattered(blade, grass, "ae9865")
	scattered(ball, shrubs, "657253")
	scattered(BoxMesh.new(), stems, "705c49")
	scattered(ball, rocks, "8c7e72")

func make_wildlife():
	add_child(fox)
	box(fox, Vector3(0.2, 0.25, 0.62), Vector3(0, 0.35, 0), "a18c76")
	box(fox, Vector3(0.17, 0.18, 0.23), Vector3(0, 0.47, -0.32), "a49580")
	box(fox, Vector3(0.1, 0.09, 0.17), Vector3(0, 0.43, -0.46), "695e54")
	for x in [-0.065, 0.065]: box(fox, Vector3(0.05, 0.12, 0.075), Vector3(x, 0.59, -0.29), "6e6051")
	box(fox, Vector3(0.15, 0.15, 0.43), Vector3(0, 0.26, 0.43), "7c7063").rotation.x = 0.32
	for dx in [-0.071, 0.071]:
		for dz in [-0.19, 0.2]: legs.append(box(fox, Vector3(0.052, 0.25, 0.059), Vector3(dx, 0.16, dz), "6c5745"))
	for i in range(3):
		var bird: = Node3D.new()
		add_child(bird)
		birds.append(bird)
		box(bird, Vector3(0.27, 0.22, 0.92), Vector3.ZERO, "403c38")
		for side in [-1, 1]:
			var wing: = Node3D.new()
			bird.add_child(wing)
			wings.append(wing)
			box(wing, Vector3(1.38, 0.07, 0.46), Vector3(side * 0.68, 0, 0), "3e3c39")
			box(wing, Vector3(0.68, 0.06, 0.29), Vector3(side * 1.56, -0.02, 0.12), "514d46")

func release_fox(linger: bool):
	fox_waits = false
	fox_departure = time
	fox_start = fox.position
	fox_speed = 1.0 if linger else 2.4

func _process(delta):
	time += delta
	var phase: = time * 0.18
	var d: = 47 + 5 * sin(phase)
	var x: = trail(47) + 7 * cos(phase)
	if fox_departure >= 0:
		var elapsed: = minf(time - fox_departure, 15.0) * fox_speed
		fox.position = at(fox_start.x + elapsed, ORIGIN_Z - fox_start.z + elapsed * 0.5)
		fox.rotation.y = -1.1
	elif not fox_waits:
		fox.position = at(x, d)
		fox.rotation.y = atan2(7 * sin(phase), 5 * cos(phase))
	for i in legs.size():
		legs[i].rotation.x = 0 if fox_waits or (fox_departure >= 0 and time - fox_departure >= 15) else sin(time * 5 + (PI if i in [1, 2] else 0.0)) * 0.42
	for i in birds.size():
		var a: = time * 0.12 + i * 2.1
		var station: = [85.0, 395.0, 890.0][i] as float
		birds[i].position = at(trail(station) + 28 * cos(a), station + 19 * sin(a)) + Vector3.UP * (18 + sin(a) * 2)
		birds[i].rotation = Vector3(0, atan2(28 * sin(a), 19 * cos(a)), 0.13)
		wings[2 * i].rotation.z = 0.1 * sin(a * 2)
		wings[2 * i + 1].rotation.z = - wings[2 * i].rotation.z

static func quarry_point(t: float) -> Vector3:
	var d: = 300 + 310 * t
	var x: = trail(300) - 220 * t + 12 * sin(TAU * t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func western_approach(t: float) -> Vector3:
	var join := quarry_point(WEST_JOIN)
	var z := lerpf(WEST_START_Z, join.z, t)
	var x := lerpf(4.5 * sin(-WEST_START_Z / 13.0), join.x, t) - 39.0 * sin(PI * t)
	return Vector3(x, elevation(x, ORIGIN_Z - z), z)

static func western_x_at(z: float) -> float:
	var progress := clampf(inverse_lerp(WEST_START_Z, quarry_point(WEST_JOIN).z, z), 0.0, 1.0)
	return western_approach(progress).x

static func summit_point(t: float) -> Vector3:
	var d: = lerpf(CREST, 948, t) + 11 * sin(TAU * t)
	var x: = lerpf(trail(CREST), 146, t)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func camp_point() -> Vector3:
	var beside_trail: = summit_point(0.49)
	var x: = beside_trail.x - 2.0
	var d: = ORIGIN_Z - beside_trail.z + 4.1
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)

static func ascent_point(progress: float) -> Vector3:
	var join: = summit_point(SUMMIT_JOIN)
	var distance_along: = lerpf(8.0, ORIGIN_Z - join.z, progress)
	var x: = lerpf(33.0, join.x, progress)
	x += sin(PI * progress) * 128.0 + sin(TAU * progress * 4.0) * sin(PI * progress) * 16.0
	return Vector3(x, elevation(x, distance_along), ORIGIN_Z - distance_along)

static func crossing_point(progress: float) -> Vector3:
	var start: = quarry_point(0.53)
	var d: = ORIGIN_Z - start.z + progress * 221.0
	var x: = start.x - progress * 146.0 + 17.0 * sin(TAU * progress)
	return Vector3(x, elevation(x, d), ORIGIN_Z - d)
