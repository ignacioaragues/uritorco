extends Control

const ROUTE = preload("res://travesia.gd")
const Creek = preload("res://cauce.gd")
const LastNight = preload("res://final_night.gd")
const INK = Color("#424a3c")
const ROUTE_COLOR = Color("#936c49")
var objective_mark: Variant = null
var location: = Vector3.ZERO

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func _draw():
	var distance_along: float = ROUTE.ORIGIN_Z - location.z
	var zone: = 0 if distance_along < 15 else (1 if distance_along < 500 else 2)
	var limits: Rect2 = [Rect2(-49, -205, 98, 223), Rect2(-345, 12, 695, 510), Rect2(-354, 480, 708, 510)][zone]
	var title: String = ["Acceso y refugio", "Laderas y quebradas", "Filo y cumbre"][zone]
	var font: = ThemeDB.fallback_font
	draw_string(font, Vector2(24, 29), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	for mark in [["N", Vector2(514, 32)], ["S", Vector2(514, 70)], ["O", Vector2(496, 51)], ["E", Vector2(533, 51)]]:
		draw_string(font, mark[1], mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_line(Vector2(522, 33), Vector2(522, 57), INK, 1.2, true)
	draw_line(Vector2(509, 45), Vector2(534, 45), INK, 1.2, true)
	if zone == 0:
		draw_route(limits, 81, func(t):
			var z: = lerpf(6.0, -74.0, t)
			return Vector3(4.5 * sin( - z / 13.0), 0, z), INK)
		draw_route(limits, 33, ROUTE.eastern_access, ROUTE_COLOR)
		draw_route(limits, 141, ROUTE.western_approach, ROUTE_COLOR)
		draw_route(limits, 101, Creek.trail_point, ROUTE_COLOR)
		draw_route(limits, 41, func(t):
			var x := lerpf(-46.0, 46.0, t)
			return Creek.point(x, Creek.channel_z(x)), Color("#59757a"))
		pin(limits, Vector3(0, 0, 0), "Refugio")
		pin(limits, LastNight.STOP, "Parada")
		pin(limits, ROUTE.ascent_point(0), "Acceso")
		pin(limits, Creek.post(), "Poste")
		pin(limits, Creek.marker(), "Regla del cauce")
	else:
		draw_route(limits, 161, func(t): return Vector3(ROUTE.trail(t * ROUTE.CREST), 0, ROUTE.ORIGIN_Z - t * ROUTE.CREST), INK)
		draw_route(limits, 33, func(t):
			var d := lerpf(ROUTE.LAJA_FORK, ROUTE.LAJA_JOIN, t)
			return Vector3(ROUTE.detour(d), 0, ROUTE.ORIGIN_Z - d), ROUTE_COLOR)
		draw_route(limits, 45, ROUTE.creek_overlook, ROUTE_COLOR)
		pin(limits, ROUTE.creek_overlook(0.63), "Mirador del cauce")
		draw_route(limits, 91, ROUTE.quarry_point, ROUTE_COLOR)
		draw_route(limits, 141, ROUTE.western_approach, ROUTE_COLOR)
		draw_route(limits, 81, ROUTE.crossing_point, ROUTE_COLOR)
		draw_route(limits, 121, ROUTE.ascent_point, INK)
		draw_route(limits, 31, func(t): return ROUTE.summit_point(lerpf(ROUTE.SUMMIT_JOIN, 1, t)), INK)
		pin(limits, Vector3(ROUTE.trail(ROUTE.CREEK_DISTANCE) + 1.5, 0, ROUTE.ORIGIN_Z - ROUTE.CREEK_DISTANCE), "Cruce")
		pin(limits, Vector3(ROUTE.trail(292), 0, ROUTE.ORIGIN_Z - 292), "Museo")
		pin(limits, ROUTE.quarry_point(1), "Cantera")
		pin(limits, ROUTE.crossing_point(1), "Pasarela")
		pin(limits, Vector3(ROUTE.trail(ROUTE.CREST), 0, ROUTE.ORIGIN_Z - ROUTE.CREST), "Filo")
		pin(limits, ROUTE.camp_point(), "Campamento")
		pin(limits, ROUTE.summit_point(1), "Cumbre")
	if objective_mark is Vector3 and limits.has_point(Vector2(objective_mark.x, ROUTE.ORIGIN_Z - objective_mark.z)):
		var goal: = point(limits, objective_mark)
		draw_colored_polygon(PackedVector2Array([goal + Vector2(0, -5), goal + Vector2(5, 0), goal + Vector2(0, 5), goal + Vector2(-5, 0)]), ROUTE_COLOR)
	var marker: = Vector2(clampf(point(limits, location).x, 14, 546), clampf(point(limits, location).y, 79, 312))
	for axis in [Vector2(6, 0), Vector2(0, 6)]:
		draw_line(marker - axis, marker + axis, Color("#9b4531"), 2.6, true)

func point(limits: Rect2, pos: Vector3) -> Vector2:
	var d: = ROUTE.ORIGIN_Z - pos.z
	return Vector2(20 + 520 * inverse_lerp(limits.position.x, limits.end.x, pos.x), 304 - 225 * inverse_lerp(limits.position.y, limits.end.y, d))

func draw_route(limits: Rect2, count: int, sample: Callable, color: Color):
	var line: = PackedVector2Array()
	for i in count:
		var pos: Vector3 = sample.call(float(i) / (count - 1))
		if limits.has_point(Vector2(pos.x, ROUTE.ORIGIN_Z - pos.z)):
			line.append(point(limits, pos))
		elif line.size() > 0:
			if line.size() > 1: draw_polyline(line, color, 1.8, true)
			line.clear()
	if line.size() > 1: draw_polyline(line, color, 1.8, true)

func pin(limits: Rect2, pos: Vector3, label: String):
	if not limits.has_point(Vector2(pos.x, ROUTE.ORIGIN_Z - pos.z)): return
	var mark: = point(limits, pos)
	draw_circle(mark, 2.8, INK)
	draw_string(ThemeDB.fallback_font, mark + Vector2(7, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
