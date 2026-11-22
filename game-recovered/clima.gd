extends RefCounted

const STORM_CLEAR_SECONDS := 52.0
const STORM_RETURN_NIGHT := 72.0
const STORM_RETURN_DUSK := 42.0

# Nubosidad de día y de noche, bruma base, capa alta, exposición al viento y luz directa.
const DAYS := {
	1: {"cloud": Vector2(0.27, 0.17), "mist": 0.0028, "cirrus": 0.52, "wind": 0.18,
		"sun": 0.87, "light": Color("#ffdbb1"), "sky": Color("#859eaf"), "rim": Color("#dcc3ac")},
	2: {"cloud": Vector2(0.10, 0.06), "mist": 0.0018, "cirrus": 0.19, "wind": 0.14,
		"sun": 0.97, "light": Color("#ffe4bd"), "sky": Color("#659ab6"), "rim": Color("#e3d6bb")},
	7: {"cloud": Vector2(0.54, 0.16), "mist": 0.0036, "cirrus": 0.29, "wind": 0.24,
		"sun": 0.69, "light": Color("#e7dec6"), "sky": Color("#6e8da6"), "rim": Color("#b9b7bf")},
	25: {"cloud": Vector2(0.61, 0.10), "mist": 0.0040, "cirrus": 0.22, "wind": 0.11,
		"sun": 0.58, "light": Color("#e4e1d5"), "sky": Color("#8298aa"), "rim": Color("#d3c8b7")},
	27: {"cloud": Vector2(0.65, 0.21), "mist": 0.0040, "cirrus": 0.16, "wind": 0.35,
		"sun": 0.65, "light": Color("#e3d9c6"), "sky": Color("#748d9a"), "rim": Color("#bac5be")},
	32: {"cloud": Vector2(0.08, 0.05), "mist": 0.00145, "cirrus": 0.37, "wind": 0.37,
		"sun": 1.00, "light": Color("#fff0d9"), "sky": Color("#648fb2"), "rim": Color("#cbdbd8")},
	36: {"cloud": Vector2(0.46, 0.24), "mist": 0.0043, "cirrus": 0.12, "wind": 0.44,
		"sun": 0.79, "light": Color("#d6dee0"), "sky": Color("#748694"), "rim": Color("#b5bfbe")},
	40: {"cloud": Vector2(0.17, 0.08), "mist": 0.0020, "cirrus": 0.25, "wind": 0.20,
		"sun": 0.94, "light": Color("#ffe3bf"), "sky": Color("#7099b4"), "rim": Color("#d7cfb9")},
	41: {"cloud": Vector2(0.33, 0.13), "mist": 0.0040, "cirrus": 0.44, "wind": 0.09,
		"sun": 0.82, "light": Color("#f4dfc1"), "sky": Color("#9aaab0"), "rim": Color("#e9d6c4")},
}

static func profile(day: int) -> Dictionary:
	return DAYS.get(day, DAYS[1])

static func rain(stage: int, position: Vector3, return_seconds: float = STORM_CLEAR_SECONDS) -> float:
	if stage in [16, 17, 18]:
		var front := lerpf(0.54, 0.72, smoothstep(-8.0, 95.0, position.z))
		if stage == 18: front *= 1.0 - smoothstep(1.5, STORM_CLEAR_SECONDS, return_seconds)
		return front
	if stage in [10, 11]:
		var into_ladera := smoothstep(182.0, 465.0, -position.z)
		var quarry_side := 0.65 + 0.35 * smoothstep(10.0, 142.0, -position.x)
		return into_ladera * quarry_side * 0.31
	return 0.0

static func local_mist(day: int, position: Vector3) -> float:
	if day == 25:
		var hollow := 1.0 - smoothstep(12.0, 67.0, absf(position.z + 172.0))
		return hollow * (1.0 - smoothstep(18.0, 40.0, position.y)) * 0.0060
	if day == 36:
		return smoothstep(25.0, 92.0, position.z) * (1.0 - smoothstep(-6.5, 4.0, position.y)) * 0.0030
	if day == 41:
		return smoothstep(-64.0, -12.0, position.z) * (1.0 - smoothstep(7.0, 19.0, position.y)) * 0.0045
	return 0.0

static func wind(day: int, position: Vector3, rain_amount: float) -> float:
	var exposed := smoothstep(15.0, 126.0, position.y)
	var base: float = profile(day).wind
	return clampf(base * (0.53 + exposed * 0.81) + rain_amount * 0.36, 0.0, 1.0)
