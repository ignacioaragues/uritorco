extends Control

const ROUTE = preload("res://travesia.gd")
const Exploration = preload("res://exploracion.gd")
const Creek = preload("res://cauce.gd")
const LastNight = preload("res://final_night.gd")
const INK = Color("#424a3c")
const ROUTE_COLOR = Color("#936c49")
const WATER = Color("#59757a")
const LIMITS = [
	Rect2(-67, -205, 134, 223),
	Rect2(-345, 12, 695, 510),
	Rect2(-354, 480, 708, 510),
	Rect2(-177, -203, 173, 151),
]
const TITLES = ["Acceso y refugio", "Laderas y quebradas", "Filo y cumbre", "Quebrada sur"]
var objective_mark: Variant = null
var location := Vector3.ZERO
var contours: Dictionary = {}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

static func zone_at(pos: Vector3) -> int:
	if pos.x < -49.0 and pos.z > 15.0: return 3
	var distance := ROUTE.ORIGIN_Z - pos.z
	if distance < 15.0: return 0
	return 1 if distance < 500.0 else 2

func _draw():
	var zone := zone_at(location)
	var limits: Rect2 = LIMITS[zone]
	draw_string(ThemeDB.fallback_font, Vector2(24, 29), TITLES[zone], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	for mark in [["N", Vector2(514, 32)], ["S", Vector2(514, 70)], ["O", Vector2(496, 51)], ["E", Vector2(533, 51)]]:
		draw_string(ThemeDB.fallback_font, mark[1], mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_line(Vector2(522, 33), Vector2(522, 57), INK, 1.2, true)
	draw_line(Vector2(509, 45), Vector2(534, 45), INK, 1.2, true)
	if not contours.has(zone): contours[zone] = make_contours(zone, limits)
	if not contours[zone].is_empty(): draw_multiline(contours[zone], Color("#ae976d"), 0.7, true)
	match zone:
		0: draw_local(limits)
		3: draw_south(limits)
		_: draw_ridge(limits)
	if objective_mark is Vector3:
		var destination: Vector3 = objective_mark
		if zone == 0 and zone_at(destination) == 3:
			destination = Creek.crossing_point(0.0)
		elif zone == 3 and Vector2(destination.x, destination.z).length() < 1.0:
			destination = Creek.return_point(1.0)
		if contains(limits, destination):
			var goal := point(limits, destination)
			draw_colored_polygon(PackedVector2Array([goal + Vector2(0, -6), goal + Vector2(6, 0), goal + Vector2(0, 6), goal + Vector2(-6, 0)]), Color("#96613e"))
	var at := point(limits, location)
	var marker := Vector2(clampf(at.x, 14, 546), clampf(at.y, 79, 312))
	for axis in [Vector2(6, 0), Vector2(0, 6)]:
		draw_line(marker - axis, marker + axis, Color("#9b4531"), 2.6, true)

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
	pin(limits, Vector3.ZERO, "Refugio")
	pin(limits, Vector3(Exploration.MOLLAR.x, 0, Exploration.MOLLAR.y), "Mollar", Vector2(-54, 13))
	pin(limits, Creek.crossing_point(0.0), "Lajas", Vector2(-48, -8))
	pin(limits, Creek.crossing_point(0.28), "Quebrada sur", Vector2(8, -5))
	pin(limits, LastNight.STOP, "Parada")
	pin(limits, ROUTE.ascent_point(0), "Acceso")
	pin(limits, Creek.post(), "Poste")
	pin(limits, Creek.marker(), "Regla del cauce")

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
	draw_route(limits, 51, Creek.return_point, ROUTE_COLOR.lightened(0.13))

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

func contains(limits: Rect2, pos: Vector3) -> bool:
	return limits.has_point(Vector2(pos.x, ROUTE.ORIGIN_Z - pos.z))

func point(limits: Rect2, pos: Vector3) -> Vector2:
	return Vector2(20 + 520 * inverse_lerp(limits.position.x, limits.end.x, pos.x),
		304 - 225 * inverse_lerp(limits.position.y, limits.end.y, ROUTE.ORIGIN_Z - pos.z))

func draw_route(limits: Rect2, count: int, sample: Callable, color: Color):
	var line := PackedVector2Array()
	for i in count:
		var pos: Vector3 = sample.call(float(i) / (count - 1))
		if contains(limits, pos):
			line.append(point(limits, pos))
		elif line.size() > 0:
			if line.size() > 1: draw_polyline(line, color, 1.8, true)
			line.clear()
	if line.size() > 1: draw_polyline(line, color, 1.8, true)

func pin(limits: Rect2, pos: Vector3, text: String, offset := Vector2(7, -5)):
	if not contains(limits, pos): return
	var mark := point(limits, pos)
	draw_circle(mark, 2.6, INK)
	draw_string(ThemeDB.fallback_font, mark + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)

func make_contours(zone: int, limits: Rect2) -> PackedVector2Array:
	var lines := PackedVector2Array()
	var lowland := zone in [0, 3]
	var steps := 30 if lowland else 36
	var levels := [-13.0, -10.0, -7.0, -4.0, -1.0, 2.0, 5.0, 8.0] if lowland else range(16, 185, 12 if zone == 1 else 10)
	var previous: Array[Vector3] = []
	for row in steps + 1:
		var current: Array[Vector3] = []
		var d := lerpf(limits.position.y + 0.51, limits.end.y - 0.51, row / float(steps))
		var z := ROUTE.ORIGIN_Z - d
		for col in steps + 1:
			var x := lerpf(limits.position.x + 0.51, limits.end.x - 0.51, col / float(steps))
			var h := Creek.outer_height(x, z) if lowland and z >= -72.0 else ROUTE.elevation(x, d)
			current.append(Vector3(x, h, z))
		if row > 0:
			for col in steps:
				for corners in [[previous[col], previous[col + 1], current[col]], [previous[col + 1], current[col + 1], current[col]]]:
					for level in levels:
						for edge in 3:
							var a: Vector3 = corners[edge]
							var b: Vector3 = corners[(edge + 1) % 3]
							if (a.y < level) != (b.y < level):
								lines.append(point(limits, a.lerp(b, inverse_lerp(a.y, b.y, level))))
		previous = current
	return lines
