extends Control

const Alien = preload("res://hallazgos_sueno.gd")
const ROUTE = preload("res://travesia.gd")
const Exploration = preload("res://exploracion.gd")
const Creek = preload("res://cauce.gd")
const LastNight = preload("res://final_night.gd")
const INK = Color("#424a3c")
const ROUTE_COLOR = Color("#875d41")
const WATER = Color("#496d72")
const PAPER = preload("res://diario_papel.webp")
const PAPER_FIELD := Rect2(5, 57, 550, 237)
const PAGE_ASPECT := 1.33 / 1.14
const COFFEE = preload("res://equipo/mancha_cafe.webp")
const ATLAS_EARTH = preload("res://diario_hallazgos.webp")
const ATLAS_DREAM = preload("res://diario_suenos.webp")
const GRID_STEPS := [50, 100, 100, 50, 40, 40, 40]
const INTERVALS := [2, 10, 10, 2, 2, 2, 2]
const SCALES := [50, 100, 100, 50, 40, 40, 40]
const LIMITS = [
	Rect2(-67, -205, 134, 223),
	Rect2(-345, 12, 695, 510),
	Rect2(-354, 480, 708, 510),
	Rect2(-177, -203, 173, 151),
]
const TITLES = ["Acceso y refugio", "Laderas y quebradas", "Filo y cumbre", "Quebrada sur", "Las estrías", "Las terrazas", "Los arcos"]
var dream_sheet := 0
var found: Dictionary = {}
var objective_mark: Variant = null
var location := Vector3.ZERO
var relief: Dictionary = {}
var contours: Dictionary = {}
var used_labels: Array[Rect2] = []
var title_face := SystemFont.new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_face.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	hide()

static func zone_at(pos: Vector3) -> int:
	if pos.x < -49.0 and pos.z > 15.0: return 3
	var distance := ROUTE.ORIGIN_Z - pos.z
	if distance < 15.0: return 0
	return 1 if distance < 500.0 else 2

func survey_extent(zone: int) -> Rect2:
	var coverage: Rect2 = LIMITS[zone] if zone < 4 else Rect2(-73.0, -33.0, 146.0, 177.0)
	var width := coverage.size.y * PAPER_FIELD.size.x / PAPER_FIELD.size.y / PAGE_ASPECT
	return Rect2(coverage.get_center().x - width * 0.5, coverage.position.y, width, coverage.size.y)

func frame(limits: Rect2) -> Rect2:
	var width := PAPER_FIELD.size.y / limits.size.y * limits.size.x * PAGE_ASPECT
	return Rect2(PAPER_FIELD.get_center().x - width * 0.5, PAPER_FIELD.position.y, width, PAPER_FIELD.size.y)

func _draw():
	var zone := zone_at(location) if dream_sheet == 0 else 3 + dream_sheet
	var limits := survey_extent(zone)
	var plot := frame(limits)
	used_labels.clear()
	draw_texture_rect_region(PAPER, Rect2(0, 0, 560, 330), Rect2(78, 67, 924, 640), Color(0.92, 0.93, 0.89, 0.52))
	if not relief.has(zone): relief[zone] = make_relief(zone, limits)
	draw_texture_rect(relief[zone], plot, false, Color(1, 1, 1, 0.82))
	if zone == 0:
		draw_texture_rect(COFFEE, Rect2(469, 243, 87, 80), false, Color(0.69, 0.48, 0.32, 0.33))
	draw_grid(limits, plot, GRID_STEPS[zone])
	if not contours.has(zone): contours[zone] = make_contours(zone, limits)
	var lines: Dictionary = contours[zone]
	if not lines.minor.is_empty(): draw_multiline(lines.minor, Color("#9d826477"), 0.76, true)
	if not lines.major.is_empty(): draw_multiline(lines.major, Color("#816446ae"), 1.08, true)
	if dream_sheet > 0:
		draw_dream(limits)
	else:
		match zone:
			0: draw_local(limits)
			3: draw_south(limits)
			_: draw_ridge(limits)
	draw_finds(limits)
	draw_rect(plot, Color("#7d7869"), false, 1.0)
	for crease in [173.0, 384.0]:
		draw_line(Vector2(crease, 0), Vector2(crease, 330), Color("#6d514821"), 2.0, true)
		draw_line(Vector2(crease + 1.3, 0), Vector2(crease + 1.3, 330), Color("#fff6db54"), 0.8, true)
	draw_margins(zone, limits)

	if objective_mark is Vector3:
		var destination: Vector3 = objective_mark
		if zone == 0 and zone_at(destination) == 3:
			destination = Creek.crossing_point(0.0)
		elif zone == 3 and Vector2(destination.x, destination.z).length() < 1.0:
			destination = Creek.return_point(1.0)
		if contains(limits, destination):
			var goal := point(limits, destination)
			draw_circle(goal, 5.4, Color("#f2d5a4"), true, -1, true)
			draw_circle(goal, 5.4, Color("#805035"), false, 1.35, true)
			draw_circle(goal, 1.8, Color("#805035"), true, -1, true)
	var at := point(limits, location).clamp(plot.position + Vector2(3, 3), plot.end - Vector2(3, 3))
	for axis in [Vector2(5.7, 0), Vector2(0, 5.7)]:
		draw_line(at - axis, at + axis, Color("#f3e0b9"), 4.4, true)
		draw_line(at - axis, at + axis, Color("#983e2d"), 2.1, true)

func draw_margins(zone: int, limits: Rect2):
	var font := ThemeDB.fallback_font
	var series := "PUESTO DE OBSERVACIÓN SERRANA   /   URITORCO" if dream_sheet == 0 else "CROQUIS DE HERNÁN   /   SUEÑO %d" % dream_sheet
	draw_string(font, Vector2(17, 16), series, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	draw_string(title_face, Vector2(16, 45), TITLES[zone], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#413f33"))
	draw_line(Vector2(16, 51), Vector2(540, 51), Color("#928a73"), 1.1, true)
	var center := Vector2(512, 32)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0,-13), center + Vector2(-4,3), center, center + Vector2(4,3)]), INK)
	draw_line(center + Vector2(0, -2), center + Vector2(0, 7), INK, 1.0, true)
	draw_line(center + Vector2(-13, 0), center + Vector2(13, 0), INK, 0.8, true)
	for mark in [["N", Vector2(508, 16)], ["S", Vector2(508, 48)], ["O", Vector2(485, 36)], ["E", Vector2(529, 36)]]:
		draw_string(font, mark[1], mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)
	if dream_sheet == 0:
		for i in [0, 1]:
			var x: int = 18 + i * 69
			var tone := ROUTE_COLOR if i == 0 else WATER
			draw_line(Vector2(x, 306), Vector2(x + 14, 306), tone, 1.4, true)
			draw_string(font, Vector2(x + 18, 310), "Senda" if i == 0 else "Cauce", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	draw_string(font, Vector2(18, 324), "Equidistancia %d m" % INTERVALS[zone], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)

	var meters: int = SCALES[zone]
	var length_px := frame(limits).size.x * meters / limits.size.x
	var start := Vector2(382, 310)
	for i in 4:
		var bar := Rect2(start + Vector2(i * length_px / 4.0, 0), Vector2(length_px / 4.0, 4))
		draw_rect(bar, Color("#45483b") if i % 2 == 0 else Color("#dccdab"))
	draw_rect(Rect2(start, Vector2(length_px, 4)), INK, false, 0.8)
	draw_string(font, start + Vector2(0, 15), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
	draw_string(font, start + Vector2(length_px - 5, 15), "%d m" % meters, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)

func draw_grid(limits: Rect2, plot: Rect2, span: float):
	var ink := Color("#6d76643d")
	var x := ceilf(limits.position.x / span) * span
	while x < limits.end.x:
		var screen := point(limits, Vector3(x, 0, projection_z())).x
		draw_line(Vector2(screen, plot.position.y), Vector2(screen, plot.end.y), ink, 0.65, true)
		x += span
	var d := ceilf(limits.position.y / span) * span
	while d < limits.end.y:
		var screen := point(limits, Vector3(0, 0, projection_z() - d)).y
		draw_line(Vector2(plot.position.x, screen), Vector2(plot.end.x, screen), ink, 0.65, true)
		d += span

func draw_local(limits: Rect2):
	draw_route(limits, 81, func(t):
		var z := lerpf(6.0, -74.0, t)
		return Vector3(4.5 * sin(-z / 13.0), 0, z), INK)
	draw_route(limits, 33, ROUTE.eastern_access, ROUTE_COLOR)
	draw_route(limits, 141, ROUTE.western_approach, ROUTE_COLOR)
	draw_route(limits, 101, Creek.trail_point, ROUTE_COLOR)
	for path in [Exploration.EAST, Exploration.WEST, Exploration.SOUTH]:
		draw_route(limits, 54, func(t):
			var at := Exploration.path_point(path, t)
			return Vector3(at.x, 0, at.y), ROUTE_COLOR)
	draw_south_paths(limits)
	draw_channel(limits, -66.0)
	pin(limits, Vector3.ZERO, "Puesto Uritorco", Vector2(12, -9))
	pin(limits, Vector3(Exploration.MOLLAR.x, 0, Exploration.MOLLAR.y), "Mollar", Vector2(-54, 13))
	pin(limits, Creek.crossing_point(0.0), "Lajas", Vector2(-48, -8))
	pin(limits, Creek.crossing_point(0.28), "Quebrada sur", Vector2(8, -5))
	pin(limits, LastNight.STOP, "Parada", Vector2(-49, -9))
	pin(limits, ROUTE.ascent_point(0), "Acceso")
	pin(limits, Creek.post(), "Poste")
	pin(limits, Creek.marker(), "Regla del cauce", Vector2(11, 18))

func draw_south(limits: Rect2):
	draw_channel(limits, -177.0)
	draw_route(limits, 101, Creek.trail_point, ROUTE_COLOR)
	draw_south_paths(limits)
	pin(limits, Creek.crossing_point(0), "Lajas · refugio", Vector2(-7, -10))
	pin(limits, Creek.post(), "Poste", Vector2(-9, 18))
	pin(limits, Creek.marker(), "Regla", Vector2(-2, 19))
	pin(limits, Creek.crossing_point(1), "Pasarela", Vector2(-41, 28))

func draw_south_paths(limits: Rect2):
	draw_route(limits, 101, Creek.crossing_point, ROUTE_COLOR)
	draw_route(limits, 51, Creek.return_point, ROUTE_COLOR)

func draw_channel(limits: Rect2, west: float):
	draw_route(limits, 101, func(t):
		var x := lerpf(west, 48.0, t)
		return Creek.point(x, Creek.channel_z(x)), WATER)

func draw_ridge(limits: Rect2):
	draw_route(limits, 301, func(t): return Vector3(ROUTE.trail(t * ROUTE.CREST), 0, ROUTE.ORIGIN_Z - t * ROUTE.CREST), INK)
	draw_route(limits, 49, func(t):
		var d := lerpf(ROUTE.LAJA_FORK, ROUTE.LAJA_JOIN, t)
		return Vector3(ROUTE.detour(d), 0, ROUTE.ORIGIN_Z - d), ROUTE_COLOR)
	draw_route(limits, 45, ROUTE.creek_overlook, ROUTE_COLOR)
	draw_route(limits, 91, ROUTE.quarry_point, ROUTE_COLOR)
	draw_route(limits, 141, ROUTE.western_approach, ROUTE_COLOR)
	draw_route(limits, 201, ROUTE.ascent_point, INK)
	draw_route(limits, 31, func(t): return ROUTE.summit_point(lerpf(ROUTE.SUMMIT_JOIN, 1, t)), INK)
	draw_route(limits, 61, func(t):
		var x := ROUTE.trail(ROUTE.CREEK_DISTANCE) + lerpf(-55, 55, t)
		var d := ROUTE.CREEK_DISTANCE + 2.0 * sin((x - ROUTE.trail(ROUTE.CREEK_DISTANCE)) / 14.0)
		return Vector3(x, 0, ROUTE.ORIGIN_Z - d), WATER)
	pin(limits, ROUTE.creek_overlook(0.63), "Mirador", Vector2(-52, 16))
	pin(limits, Vector3(ROUTE.trail(292), 0, ROUTE.ORIGIN_Z - 292), "Museo")
	pin(limits, Vector3(ROUTE.trail(420), 0, ROUTE.ORIGIN_Z - 420), "Abra")
	pin(limits, ROUTE.quarry_point(1), "Cantera", Vector2(-15, 15))
	pin(limits, Vector3(ROUTE.trail(ROUTE.CREST), 0, ROUTE.ORIGIN_Z - ROUTE.CREST), "Filo", Vector2(-24, -8))
	pin(limits, ROUTE.camp_point(), "Campamento", Vector2(-77, 17))
	pin(limits, ROUTE.summit_point(1), "Cumbre", Vector2(8, -4))

func draw_dream(limits: Rect2):
	var start := LastNight.dream_point(dream_sheet, 0.0)
	pin(limits, start, "Llegada", Vector2(9, 15))
	for site in Alien.SITES[dream_sheet - 1]:
		var at: Vector2 = site[1]
		pin(limits, LastNight.dream_surface(dream_sheet, at), site[0], Vector2(12, -12))
	if dream_sheet == 3:
		for i in 5:
			var arch := point(limits, LastNight.dream_point(3, 10.0 + 9.0 * i))
			draw_arc(arch, 4.0 + i * 0.25, PI, TAU, 14, Color("#66536f"), 1.5, true)
		pin(limits, LastNight.final_arch(), "Arcos", Vector2(12, -9))

func draw_finds(limits: Rect2):
	var dreaming := dream_sheet > 0
	var entries: Dictionary = Alien.FINDS if dreaming else Exploration.FINDS
	var atlas := ATLAS_DREAM if dreaming else ATLAS_EARTH
	var columns := 3 if dreaming else 4
	var tile := atlas.get_size() / Vector2(columns, 2)
	var here := Vector2(location.x, location.z)
	for id in entries:
		var entry: Array = entries[id]
		if dreaming and entry[4] != dream_sheet: continue
		var at: Vector2 = entry[2]
		if dreaming: at += Vector2(LastNight.PLANET.x, LastNight.PLANET.z)
		var world := Vector3(at.x, 0, at.y)
		if not contains(limits, world): continue
		var seen := found.has(id)
		if not seen and here.distance_to(at) > 13.5: continue
		var mark := point(limits, world)
		var picture := Vector2(34, 34) if seen else Vector2(29, 29)
		var plot := frame(limits)
		var offset := Vector2(-13, 18) if entry[0] % 2 == 0 else Vector2(15, 18)
		var badge := (mark + offset).clamp(plot.position + picture * 0.5, plot.end - picture * 0.5)
		var index: int = entry[0]
		var src := Rect2(Vector2(index % columns, index / columns) * tile, tile)
		draw_line(mark, mark.lerp(badge, 0.60), Color("#6e655098"), 0.75, true)
		draw_circle(badge, 12.0, Color("#f5deb566" if seen else "#f8d78b80"), true, -1, true)
		draw_texture_rect_region(atlas, Rect2(badge - picture * 0.5, picture), src, Color.WHITE if seen else Color(1, 1, 1, 0.76))

func projection_z() -> float:
	return LastNight.PLANET.z if dream_sheet > 0 else ROUTE.ORIGIN_Z

func contains(limits: Rect2, pos: Vector3) -> bool:
	return limits.has_point(Vector2(pos.x, projection_z() - pos.z))

func point(limits: Rect2, pos: Vector3) -> Vector2:
	var plot := frame(limits)
	var d := projection_z() - pos.z
	return Vector2(plot.position.x + plot.size.x * inverse_lerp(limits.position.x, limits.end.x, pos.x),
		plot.end.y - plot.size.y * inverse_lerp(limits.position.y, limits.end.y, d))

func draw_route(limits: Rect2, count: int, sample: Callable, color: Color):
	var line := PackedVector2Array()
	for i in count:
		var pos: Vector3 = sample.call(float(i) / (count - 1))
		if contains(limits, pos):
			line.append(point(limits, pos))
		elif line.size() > 0:
			stroke_route(line, color)
			line.clear()
	stroke_route(line, color)

func stroke_route(line: PackedVector2Array, color: Color):
	if line.size() < 2: return
	if color == WATER:
		draw_polyline(line, Color("#7b9f9d8f"), 2.75, true)
		draw_polyline(line, color, 1.2, true)
	elif color == INK:
		draw_polyline(line, Color("#f2e0b6"), 3.4, true)
		draw_polyline(line, INK, 1.45, true)
	else:
		var phase := 0.0
		var start := line[0]
		for i in range(1, line.size()):
			var end := line[i]
			var length_px := start.distance_to(end)
			if length_px > 0.0001:
				var done := 0.0
				while done < length_px:
					var painting := phase < 4.0
					var advance := minf(length_px - done, (4.0 if painting else 6.4) - phase)
					if painting:
						draw_line(start.lerp(end, done / length_px), start.lerp(end, (done + advance) / length_px), color, 1.45, true)
					done += advance
					phase = fposmod(phase + advance, 6.4)
			start = end

func pin(limits: Rect2, pos: Vector3, text: String, offset := Vector2(7, -5)):
	if not contains(limits, pos): return
	var mark := point(limits, pos)
	var font := ThemeDB.fallback_font
	const SIZE := 13
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var label := mark + offset
	for choice in [offset, Vector2(9, -7), Vector2(-width - 10, -7), Vector2(9, 16), Vector2(-width - 10, 16), Vector2(9, -26), Vector2(-width-10, 29)]:
		var candidate: Vector2 = mark + choice
		var block := Rect2(candidate - Vector2(2, 12), Vector2(width + 4, 16))
		if block.position.x < 13 or block.end.x > 547 or block.position.y < 58 or block.end.y > 291: continue
		var free := true
		for previous in used_labels:
			if previous.intersects(block):
				free = false
				break
		if free:
			label = candidate
			used_labels.append(block)
			break
	var end := Vector2(clampf(mark.x, label.x, label.x+width), label.y - 4.0)
	if end.distance_to(mark) > 7: draw_line(mark, end, Color("#5c584b9e"), 0.72, true)
	draw_rect(Rect2(mark - Vector2(1.8, 1.8), Vector2(3.6, 3.6)), INK)
	draw_string_outline(font, label, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 3, Color("#e1d2ad"))
	draw_string(font, label, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, INK)

func ground_height(x: float, d: float) -> float:
	if dream_sheet > 0: return LastNight.planet_height(dream_sheet, x, d)
	var z := ROUTE.ORIGIN_Z - d
	return Creek.outer_height(x, z) if z >= -72.0 else ROUTE.elevation(x, maxf(d, 0.0))

func make_relief(zone: int, limits: Rect2) -> ImageTexture:
	const COLUMNS := 192
	const ROWS := 126
	var heights := PackedFloat32Array()
	for row in ROWS + 2:
		var d := limits.end.y - (row - 1) * limits.size.y / (ROWS - 1.0)
		for col in COLUMNS + 2:
			var x := limits.position.x + (col - 1) * limits.size.x / (COLUMNS - 1.0)
			heights.append(ground_height(x,d))
	var stride := COLUMNS + 2
	var tex := Image.create_empty(COLUMNS, ROWS, false, Image.FORMAT_RGB8)
	var lowland := zone in [0, 3, 4, 5, 6]
	for row in ROWS:
		for col in COLUMNS:
			var i := (row + 1) * stride + col + 1
			var dx := (heights[i + 1] - heights[i - 1]) * (COLUMNS - 1.0) / limits.size.x
			var dz := (heights[i + stride] - heights[i - stride]) * (ROWS - 1.0) / limits.size.y
			var weathered := clampf((dx - dz) * 0.20, -0.19, 0.14)
			var band := smoothstep(-10.0, 15.0, heights[i]) if lowland else smoothstep(0.0, 168.0, heights[i])
			var soil := Color("#c2c4a6").lerp(Color("#d7cca8"), band)
			if dream_sheet > 0:
				var hue: Color = [Color("#abb8be"), Color("#bdaba3"), Color("#b6aabe")][dream_sheet - 1]
				soil = hue.lerp(Color("#d9ccb5"), band * 0.72)
			var detail := 0.008 * sin(col * 0.73 + row * 1.91) + 0.006 * sin(row * 4.11 - col * 3.17)
			tex.set_pixel(col, row, soil.lightened(maxf(0, weathered + detail)).darkened(maxf(0, -weathered - detail)))
	return ImageTexture.create_from_image(tex)

func make_contours(zone: int, limits: Rect2) -> Dictionary:
	var minor := PackedVector2Array()
	var major := PackedVector2Array()
	var lowland := zone in [0, 3, 4, 5, 6]
	var steps := 54 if lowland else 49
	var interval: int = INTERVALS[zone]
	var levels := range(-14, 18, interval) if lowland else range(10, 190, interval)
	var previous: Array[Vector3] = []
	for row in steps + 1:
		var current: Array[Vector3] = []
		var d := lerpf(limits.position.y + 0.35, limits.end.y - 0.35, row / float(steps))
		var z := projection_z() - d
		for col in steps + 1:
			var x := lerpf(limits.position.x + 0.35, limits.end.x - 0.35, col / float(steps))
			current.append(Vector3(x, ground_height(x, d), z))
		if row > 0:
			for col in steps:
				for corners in [[previous[col], previous[col + 1], current[col]], [previous[col + 1], current[col + 1], current[col]]]:
					for level in levels:
						for edge in 3:
							var a: Vector3 = corners[edge]
							var b: Vector3 = corners[(edge + 1) % 3]
							if (a.y < level) != (b.y < level):
								var cross := point(limits, a.lerp(b, inverse_lerp(a.y, b.y, level)))
								if level % (interval * 5) == 0: major.append(cross)
								else: minor.append(cross)
		previous = current
	return {"minor": minor, "major": major}
