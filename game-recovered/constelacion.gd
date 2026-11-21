extends RefCounted

const CHAPTER_DAYS := [1, 2, 7, 25]
const MOON_RADIUS := 0.061
const GALACTIC_POLE := ["", 12.8573, 27.1283, 0.0]

const NIGHTS = [
	[13.00854, Vector3(-0.000117, 0.934241, -0.356643), Vector3(-0.700679, -0.713473, 0.002364)],
	[13.07425, Vector3(0.17595, 0.949098, -0.261257), Vector3(-0.700207, -0.71394, -0.000478)],
	[13.4028, Vector3(0.830332, 0.502559, 0.240799), Vector3(-0.698499, -0.715486, -0.013342)],
	[14.5856, Vector3(-0.870401, 0.313345, -0.37976), Vector3(-0.701349, -0.711734, -0.03929)]
]

const STARS = [
	["Acrux · Cruz del Sur", 12.443, -63.1, 0.76], ["Mimosa · Cruz del Sur", 12.795, -59.69, 1.25], 
	["Gacrux · Cruz del Sur", 12.519, -57.11, 1.63], ["Imai · Cruz del Sur", 12.252, -58.75, 2.79], 
	["Rigil Kentaurus", 14.66, -60.83, -0.27], ["Hadar", 14.06, -60.37, 0.61], 
	["Canopus", 6.4, -52.7, -0.74], ["Achernar", 1.63, -57.24, 0.46], 
	["Antares", 16.49, -26.43, 0.96], ["Espiga", 13.42, -11.16, 0.98], 
	["Arturo", 14.26, 19.18, -0.05], ["Sirio", 6.75, -16.72, -1.46], 
	["Fomalhaut", 22.96, -29.62, 1.16], ["Shaula", 17.56, -37.1, 1.62], 
	["Atria", 16.81, -69.03, 1.91], ["Miaplacidus", 9.22, -69.72, 1.67], 
	["Avior", 8.38, -59.51, 1.86], ["Alsephina", 8.75, -54.71, 1.95], 
	["Regulus", 10.14, 11.97, 1.35], ["Peacock", 20.43, -56.74, 1.94],
	["Sargas · Escorpio", 17.622, -42.998, 1.87], ["Dschubba · Escorpio", 16.005, -22.622, 2.29],
	["Acrab · Escorpio", 16.090, -19.805, 2.56], ["Girtab · Escorpio", 17.708, -39.029, 2.39],
	["Alnair · Grulla", 22.137, -46.96, 1.74], ["Betria · Triángulo Austral", 15.919, -63.43, 2.83],
	["Gamma del Triángulo Austral", 15.315, -68.68, 2.89], ["Aspidiske · Carina", 9.285, -59.275, 2.25],
	["Suhail · Vela", 9.133, -43.433, 2.21], ["Altair · Águila", 19.846, 8.868, 0.77],
	["Vega · Lira", 18.615, 38.783, 0.03], ["Deneb · Cisne", 20.691, 45.280, 1.25],
]

const PLANETS = [["Júpiter", 16.71, -21.1, -2.16], ["Saturno", 19.32, -22.9, 0.55]]

static func sidereal_at(chapter: int, day: int) -> float:
	return NIGHTS[chapter][0] + (day - CHAPTER_DAYS[chapter]) * 0.055

static func direction(star: Array, sidereal: float = NIGHTS[0][0]) -> Vector3:
	var h: = deg_to_rad((sidereal - float(star[1])) * 15.0)
	var dec: = deg_to_rad(float(star[2]))
	var lat: = deg_to_rad(-30.75)
	var east := -cos(dec) * sin(h)
	var up := sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(h)
	# North is -Z on Hernán's map and compass.
	var north := sin(dec) * cos(lat) - cos(dec) * sin(lat) * cos(h)
	return Vector3(east, up, -north).normalized()

static func identify(look: Vector3, chapter: int, day: int) -> String:
	if look.distance_squared_to(NIGHTS[chapter][1]) < MOON_RADIUS * MOON_RADIUS: return "Luna"
	var sidereal := sidereal_at(chapter, day)
	var closest: = cos(deg_to_rad(2.0))
	var name: = ""
	for group in [PLANETS, STARS]:
		for object in group:
			var at := direction(object, sidereal)
			var similarity := at.dot(look)
			if at.y > 0.065 and similarity > closest:
				closest = similarity
				name = object[0]
	return name
