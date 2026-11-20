extends Control

const Arrival = preload("res://llegada.gd")
const ROUTE = preload("res://travesia.gd")
const Exploration = preload("res://exploracion.gd")
const Creek = preload("res://cauce.gd")
const Museum = preload("res://museo.gd")
const INK = Color("#384235")
const ROUTE_COLOR = Color("#875d41")
const WATER = Color("#496d72")
const PAPER = preload("res://diario_papel.webp")
const PAPER_FIELD := Rect2(0, 0, 560, 330)
const PAGE_ASPECT := 1.33 / 1.14
const COFFEE = preload("res://equipo/mancha_cafe.webp")
const ATLAS_EARTH = preload("res://diario_hallazgos.webp")
const GRID_STEPS := [50, 100, 100, 50, 40, 40, 40, 10]
const INTERVALS := [2, 10, 10, 2, 2, 2, 2, 2]
const ARRIVAL_ZONE := 7
const LABEL_INK := Color("#30382d")
const LABEL_HALO := Color("#eadcb9")
const LABEL_SIZE := 19
const CARDINAL_CENTER := Vector2(515, 44)
const CARDINAL_AREA := Rect2(471, 5, 84, 76)
const THUMB_AREA := Rect2(0, 88, 55, 147)
const LIMITS = [
	Rect2(-67, -205, 134, 237),
	Rect2(-347, -8, 695, 542),
	Rect2(-354, 464, 708, 526),
	Rect2(-177, -203, 173, 151),
]
var dream_sheet := 0
var arrival_sheet := -1
var active_zone := -1
var found: Dictionary = {}
var objective_mark: Variant = null
var location := Vector3.ZERO
var relief: Dictionary = {}
var contours: Dictionary = {}
var pins: Array[Dictionary] = []
var used_labels: Array[Rect2] = []
var markers := Node2D.new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(markers)
	markers.draw.connect(draw_markers)
	hide()

static func zone_at(pos: Vector3, previous := -1) -> int:
	# Keep the current sheet until the player walks through the shared stretch.
	var south_margin := -6.0 if previous == 3 else (0.0 if previous == -1 else 6.0)
	if pos.x < -49.0 - south_margin and pos.z > 15.0 + south_margin: return 3
	var distance := ROUTE.ORIGIN_Z - pos.z
	if distance < (23.0 if previous == 0 else (7.0 if previous == 1 else 15.0)): return 0
	return 1 if distance < (516.0 if previous == 1 else (484.0 if previous == 2 else 500.0)) else 2

func open_at(pos: Vector3, dream: int, arrival: int, goal: Variant):
	if dream_sheet != dream or arrival_sheet != arrival:
		active_zone = -1
	dream_sheet = dream
	arrival_sheet = arrival
	objective_mark = goal
	track(pos)
	show()

func track(pos: Vector3):
	var zone := zone_at(pos, active_zone)
	if arrival_sheet >= 0: zone = ARRIVAL_ZONE
	elif dream_sheet > 0: zone = 3 + dream_sheet
	if active_zone != zone:
		active_zone = zone
		queue_redraw()
	location = pos
	markers.queue_redraw()

func survey_extent(zone: int) -> Rect2:
	var coverage: Rect2
	if zone < 4: coverage = LIMITS[zone]
	elif zone == ARRIVAL_ZONE:
		var origin := Arrival.origin(arrival_sheet)
		coverage = Rect2(origin.x - 40.0, -22.0, 80.0, 66.0)
	else: coverage = Rect2(-73.0, -33.0, 146.0, 177.0)
	var width := coverage.size.y * PAPER_FIELD.size.x / PAPER_FIELD.size.y / PAGE_ASPECT
	return Rect2(coverage.get_center().x - width * 0.5, coverage.position.y, width, coverage.size.y)

func frame(limits: Rect2) -> Rect2:
	var width := PAPER_FIELD.size.y / limits.size.y * limits.size.x * PAGE_ASPECT
	return Rect2(PAPER_FIELD.get_center().x - width * 0.5, PAPER_FIELD.position.y, width, PAPER_FIELD.size.y)

func _draw():
	var zone := active_zone
	if zone < 0: return
	pins.clear()
	used_labels.clear()
	draw_texture_rect_region(PAPER, PAPER_FIELD, Rect2(78, 67, 924, 640), Color(0.92, 0.93, 0.89, 0.52))
	if dream_sheet > 0:
		draw_dream_symbols()
		return
	var limits := survey_extent(zone)
	var plot := frame(limits)
	var cache_key := zone + arrival_sheet if zone == ARRIVAL_ZONE else zone
	if not relief.has(cache_key): relief[cache_key] = make_relief(zone, limits)
	draw_texture_rect(relief[cache_key], plot, false, Color(1, 1, 1, 0.82))
	if zone == 0:
		draw_texture_rect(COFFEE, Rect2(469, 243, 87, 80), false, Color(0.69, 0.48, 0.32, 0.33))
	draw_grid(limits, plot, GRID_STEPS[zone])
	if not contours.has(cache_key): contours[cache_key] = make_contours(zone, limits)
	var lines: Dictionary = contours[cache_key]
	if not lines.minor.is_empty(): draw_multiline(lines.minor, Color("#9d826458"), 0.76, true)
	if not lines.major.is_empty(): draw_multiline(lines.major, Color("#81644689"), 1.08, true)
	if zone == ARRIVAL_ZONE:
		draw_arrival(limits)
	else:
		match zone:
			0: draw_local(limits)
			3: draw_south(limits)
			_: draw_ridge(limits)
	for crease in [173.0, 384.0]:
		draw_line(Vector2(crease, 0), Vector2(crease, 330), Color("#6d514821"), 2.0, true)
		draw_line(Vector2(crease + 1.3, 0), Vector2(crease + 1.3, 330), Color("#fff6db54"), 0.8, true)
	draw_pins()
	draw_cardinals()

func draw_markers():
	var zone := active_zone
	if zone < 0 or dream_sheet > 0: return
	var limits := survey_extent(zone)
	var inside := frame(limits).grow(-9.0)
	if zone != ARRIVAL_ZONE: draw_finds(limits)
	var at := point(limits, location).clamp(inside.position, inside.end)
	if objective_mark is Vector3:
		var destination: Vector3 = objective_mark
		if zone == 3 and Vector2(destination.x, destination.z).length() < 1.0:
			destination = Creek.return_point(1.0)
		var goal := point(limits, destination)
		if inside.has_point(goal):
			markers.draw_circle(goal, 7.0, Color("#f1d9a7"), true, -1, true)
			markers.draw_circle(goal, 7.0, Color("#805035"), false, 1.8, true)
			markers.draw_circle(goal, 2.3, Color("#805035"), true, -1, true)
		else:
			var direction := (goal - inside.get_center()).normalized()
			var edge := Vector2(inside.size.x * 0.5 / maxf(absf(direction.x), 0.001), inside.size.y * 0.5 / maxf(absf(direction.y), 0.001))
			var tip := inside.get_center() + direction * minf(edge.x, edge.y)
			var back := tip - direction * 13.0
			var side := direction.orthogonal() * 5.0
			var arrow := PackedVector2Array([back - side, tip, back + side])
			markers.draw_polyline(arrow, LABEL_HALO, 5.0, true)
			markers.draw_polyline(arrow, Color("#805035"), 2.4, true)
	for axis in [Vector2(5.7, 0), Vector2(0, 5.7)]:
		markers.draw_line(at - axis, at + axis, Color("#f3e0b9"), 4.4, true)
		markers.draw_line(at - axis, at + axis, Color("#983e2d"), 2.1, true)

func draw_cardinals():
	var font := ThemeDB.fallback_font
	var center := CARDINAL_CENTER
	draw_line(center + Vector2(0, -14), center + Vector2(0, 12), LABEL_HALO, 3.5, true)
	draw_line(center + Vector2(-15, 0), center + Vector2(15, 0), LABEL_HALO, 3.5, true)
	draw_line(center + Vector2(0, -14), center + Vector2(0, 12), INK, 1.5, true)
	draw_line(center + Vector2(-15, 0), center + Vector2(15, 0), INK, 1.5, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -15), center + Vector2(-4, -2), center + Vector2(4, -2)]), INK)
	for mark in [["N", Vector2(-6, -19)], ["S", Vector2(-5, 28)], ["O", Vector2(-32, 5)], ["E", Vector2(19, 5)]]:
		var baseline: Vector2 = center + mark[1]
		draw_string_outline(font, baseline, mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 3, LABEL_HALO)
		draw_string(font, baseline, mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LABEL_INK)

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
	draw_route(limits, 81, access_road, INK)
	draw_route(limits, 36, func(t):
		var d: float = t * 40.0
		return Vector3(ROUTE.trail(d), 0, ROUTE.ORIGIN_Z - d), INK)
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
	pin(limits, Creek.crossing_point(1.0), "Pasarela", Vector2(9, 18))
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
	if active_zone == 1:
		draw_route(limits, 81, access_road, INK)
		draw_route(limits, 54, ROUTE.eastern_access, ROUTE_COLOR)
	draw_route(limits, 301, func(t): return Vector3(ROUTE.trail(t * ROUTE.CREST), 0, ROUTE.ORIGIN_Z - t * ROUTE.CREST), INK)
	draw_route(limits, 49, func(t):
		var d := lerpf(ROUTE.LAJA_FORK, ROUTE.LAJA_JOIN, t)
		return Vector3(ROUTE.detour(d), 0, ROUTE.ORIGIN_Z - d), ROUTE_COLOR)
	draw_route(limits, 91, ROUTE.quarry_point, ROUTE_COLOR)
	draw_route(limits, 141, ROUTE.western_approach, ROUTE_COLOR)
	draw_route(limits, 201, ROUTE.ascent_point, INK)
	draw_route(limits, 31, func(t): return ROUTE.summit_point(lerpf(ROUTE.SUMMIT_JOIN, 1, t)), INK)
	pin(limits, Vector3(ROUTE.trail(Museum.DISTANCE) + Museum.SITE_OFFSET, 0, ROUTE.ORIGIN_Z - Museum.DISTANCE), "Museo")
	pin(limits, Vector3(ROUTE.trail(420), 0, ROUTE.ORIGIN_Z - 420), "Abra")
	pin(limits, ROUTE.quarry_point(1), "Cantera", Vector2(-15, 15))
	pin(limits, ROUTE.summit_point(1), "Cumbre", Vector2(8, -4))
	pin(limits, ROUTE.camp_point(), "Campamento", Vector2(9, 24))
	pin(limits, Vector3(ROUTE.trail(ROUTE.CREST), 0, ROUTE.ORIGIN_Z - ROUTE.CREST), "Filo", Vector2(-24, -13))

func access_road(t: float) -> Vector3:
	var z := lerpf(6.0, ROUTE.ORIGIN_Z, t)
	return Vector3(4.5 * sin(-z / 13.0), 0, z)

func draw_arrival(limits: Rect2):
	var index := arrival_sheet
	if index == 0:
		draw_route(limits, 97, func(t):
			var x := lerpf(-58.0, 58.0, t)
			var z := -3.0 + 3.1 * sin(x * 0.055) * smoothstep(13.0, 55.0, absf(x))
			return Arrival.world_position(index, Vector3(x, 0, z)), INK)
		draw_route(limits, 50, func(t):
			var x := lerpf(2.8, 47.0, t)
			return Arrival.world_position(index, Vector3(x, 0, Arrival.branch_z(x))), ROUTE_COLOR)
		pin(limits, Arrival.world_position(index, Arrival.STOP_CENTER), "Parada")
	else:
		if index == 2:
			draw_route(limits, 89, func(t):
				var x := lerpf(-58.0, 58.0, t)
				return Arrival.world_position(index, Vector3(x, 0, -10.45)), WATER)
		draw_route(limits, 121, func(t):
			return Arrival.world_position(index, Arrival.path_point(index, lerpf(-60.0, 60.0, t))), ROUTE_COLOR)
		match index:
			1: pin(limits, Arrival.world_position(index, Vector3(0, 0, -10.0)), "Tronco")
			2: pin(limits, Arrival.world_position(index, Vector3(0, 0, -10.45)), "Puente")
			5: pin(limits, Arrival.world_position(index, Vector3(0, 0, -11.0)), "Laja")

func draw_dream_symbols():
	var rng := RandomNumberGenerator.new()
	rng.seed = 6121 + dream_sheet * 1187
	var glyphs := [
		[[Vector2(-9, -14), Vector2(-12, 0), Vector2(-3, 12), Vector2(8, 8), Vector2(12, -6), Vector2(4, -13)], [Vector2(-18, 5), Vector2(6, -4), Vector2(17, 0)]],
		[[Vector2(-11, 12), Vector2(1, -14), Vector2(13, 12), Vector2(1, 7), Vector2(-11, 12)], [Vector2(-7, -6), Vector2(11, -3)], [Vector2(0, 14), Vector2(0, 19)]],
		[[Vector2(-15, -3), Vector2(-8, -11), Vector2(4, -11), Vector2(12, -4), Vector2(11, 3), Vector2(3, 8), Vector2(-5, 9)], [Vector2(-12, 8), Vector2(-8, 1), Vector2(-1, 1), Vector2(2, 4)]],
		[[Vector2(-12, -14), Vector2(-6, 12), Vector2(10, -1), Vector2(14, 10)], [Vector2(-1, -11), Vector2(6, -15), Vector2(13, -12)], [Vector2(9, -8), Vector2(13, -5)]],
		[[Vector2(-12, 6), Vector2(-6, 12), Vector2(3, 12), Vector2(15, -1), Vector2(9, -11), Vector2(-1, -7), Vector2(-8, 4), Vector2(3, 7)], [Vector2(-8, -12), Vector2(-13, -14)]],
		[[Vector2(-8, -17), Vector2(0, -2), Vector2(-7, 14)], [Vector2(6, -16), Vector2(11, -4), Vector2(3, 7), Vector2(9, 16)], [Vector2(-12, -3), Vector2(14, 2)]],
		[[Vector2(-16, -9), Vector2(-4, -1), Vector2(-12, 14), Vector2(1, 10), Vector2(13, -7), Vector2(15, 3)], [Vector2(-6, -14), Vector2(1, -10), Vector2(4, -13)]],
		[[Vector2(-14, -4), Vector2(-7, -14), Vector2(0, -2), Vector2(7, -13), Vector2(14, -3)], [Vector2(-10, 10), Vector2(-5, 4), Vector2(0, 10), Vector2(8, 5)], [Vector2(1, 14), Vector2(8, 13)]],
	]
	for row in 5:
		var count := rng.randi_range(6, 9)
		var tilt := rng.randf_range(-0.10, 0.10)
		for i in count:
			var center := Vector2(62.0 + i * 434.0 / (count - 1), 38.0 + row * 57.0)
			center += Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-7.0, 7.0) + tilt * i * 14.0)
			var size_m := rng.randf_range(0.63, 1.14)
			var angle := rng.randf_range(-0.26, 0.22)
			var opacity := rng.randf_range(0.59, 0.91)
			var glyph: Array = glyphs[rng.randi_range(0, glyphs.size() - 1)]
			for stroke in glyph:
				var brush := PackedVector2Array()
				for point in stroke:
					var jitter := Vector2(rng.randf_range(-0.85, 0.85), rng.randf_range(-0.85, 0.85))
					brush.append(center + (Vector2(point) + jitter).rotated(angle) * size_m)
				draw_polyline(brush, Color(0.28, 0.25, 0.24, opacity * 0.26), 3.65, true)
				draw_polyline(brush, Color(0.26, 0.23, 0.21, opacity), 1.65, true)

func draw_finds(limits: Rect2):
	const COLUMNS := 4
	var tile := ATLAS_EARTH.get_size() / Vector2(COLUMNS, 2)
	var here := Vector2(location.x, location.z)
	var plot := frame(limits)
	var occupied := used_labels.duplicate()
	for id in Exploration.FINDS:
		var entry: Array = Exploration.FINDS[id]
		var at: Vector2 = entry[2]
		var world := Vector3(at.x, 0, at.y)
		if not contains(limits, world): continue
		var seen := found.has(id)
		if not seen and here.distance_to(at) > 13.5: continue
		var mark := point(limits, world)
		var picture := Vector2(34, 34) if seen else Vector2(29, 29)
		var radius := picture * 0.5
		var badge := mark.clamp(plot.position + radius, plot.end - radius)
		var side := -1.0 if entry[0] % 2 == 0 else 1.0
		for offset in [Vector2(19 * side, 21), Vector2(-19 * side, 21), Vector2(19 * side, -21), Vector2(-19 * side, -21)]:
			var candidate := (mark + Vector2(offset)).clamp(plot.position + radius, plot.end - radius)
			if clear_of(Rect2(candidate - radius, picture), occupied):
				badge = candidate
				break
		var index: int = entry[0]
		var src := Rect2(Vector2(index % COLUMNS, index / COLUMNS) * tile, tile)
		var bounds := Rect2(badge - radius, picture)
		occupied.append(bounds)
		markers.draw_line(mark, mark.lerp(badge, 0.60), Color("#6e655098"), 0.75, true)
		markers.draw_circle(badge, 12.0, Color("#f5deb566" if seen else "#f8d78b80"), true, -1, true)
		markers.draw_texture_rect_region(ATLAS_EARTH, bounds, src, Color.WHITE if seen else Color(1, 1, 1, 0.76))

func projection_z() -> float:
	if arrival_sheet >= 0: return Arrival.origin(arrival_sheet).z
	return ROUTE.ORIGIN_Z

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
	if contains(limits, pos):
		pins.append({"mark": point(limits, pos), "text": text, "offset": offset})

func clear_of(bounds: Rect2, occupied: Array[Rect2]) -> bool:
	for item in occupied:
		if item.intersects(bounds): return false
	return true

func draw_pins():
	used_labels.assign([CARDINAL_AREA, THUMB_AREA])
	for item in pins:
		var mark: Vector2 = item.mark
		used_labels.append(Rect2(mark - Vector2(5, 5), Vector2(10, 10)))
	for item in pins:
		var mark: Vector2 = item.mark
		var symbol := Rect2(mark - Vector2(2.3, 2.3), Vector2(4.6, 4.6))
		draw_rect(symbol.grow(1.2), LABEL_HALO)
		draw_rect(symbol, LABEL_INK)
		draw_pin_label(mark, item.text, item.offset)

func draw_pin_label(mark: Vector2, text: String, preferred: Vector2):
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var ascent := font.get_ascent(LABEL_SIZE)
	var label_size := Vector2(width, font.get_height(LABEL_SIZE))
	var near_side := 11.0 if preferred.x > 0.0 else -width - 11.0
	var sides := [near_side, -width - near_side, -width * 0.5]
	for y in [preferred.y, 24.0, -14.0, 42.0, -30.0, 60.0, -48.0, 78.0, -66.0]:
		for x in sides:
			var baseline := mark + Vector2(x, y)
			var bounds := Rect2(baseline - Vector2(0, ascent), label_size)
			var padding := bounds.grow(3.0)
			if not PAPER_FIELD.grow(-7.0).encloses(padding) or not clear_of(padding, used_labels): continue
			used_labels.append(padding)
			var end := mark.clamp(bounds.position, bounds.end)
			if end.distance_to(mark) > 6.0:
				draw_line(mark, end, Color("#514a3ba8"), 0.9, true)
			draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, 4, LABEL_HALO)
			draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, LABEL_INK)
			return

func ground_height(x: float, d: float) -> float:
	if arrival_sheet >= 0:
		var local := Arrival.local_position(arrival_sheet, Vector3(x, 0, projection_z() - d))
		return Arrival.ground_height(arrival_sheet, local.x, -local.z)
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
	var lowland := zone != 1 and zone != 2
	for row in ROWS:
		for col in COLUMNS:
			var i := (row + 1) * stride + col + 1
			var dx := (heights[i + 1] - heights[i - 1]) * (COLUMNS - 1.0) / limits.size.x
			var dz := (heights[i + stride] - heights[i - stride]) * (ROWS - 1.0) / limits.size.y
			var weathered := clampf((dx - dz) * 0.20, -0.19, 0.14)
			var band := smoothstep(-10.0, 15.0, heights[i]) if lowland else smoothstep(0.0, 168.0, heights[i])
			var soil := Color("#c2c4a6").lerp(Color("#d7cca8"), band)
			var detail := 0.008 * sin(col * 0.73 + row * 1.91) + 0.006 * sin(row * 4.11 - col * 3.17)
			tex.set_pixel(col, row, soil.lightened(maxf(0, weathered + detail)).darkened(maxf(0, -weathered - detail)))
	return ImageTexture.create_from_image(tex)

func make_contours(zone: int, limits: Rect2) -> Dictionary:
	var minor := PackedVector2Array()
	var major := PackedVector2Array()
	var lowland := zone != 1 and zone != 2
	var steps := 54 if lowland else 49
	var interval: int = INTERVALS[zone]
	var first_level := -14 if lowland else 10
	var last_level := 16 if lowland else 180
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
					var low := minf(corners[0].y, minf(corners[1].y, corners[2].y))
					var high := maxf(corners[0].y, maxf(corners[1].y, corners[2].y))
					var next_level := first_level + (floori((low - first_level) / interval) + 1) * interval
					for level in range(maxi(first_level, next_level), mini(last_level, floori(high)) + 1, interval):
						for edge in 3:
							var a: Vector3 = corners[edge]
							var b: Vector3 = corners[(edge + 1) % 3]
							if (a.y < level) != (b.y < level):
								var cross := point(limits, a.lerp(b, inverse_lerp(a.y, b.y, level)))
								if level % (interval * 5) == 0: major.append(cross)
								else: minor.append(cross)
		previous = current
	return {"minor": minor, "major": major}
