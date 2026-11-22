extends RefCounted

const CHAPTER_DAYS := [1, 2, 7, 25]
const MOON_RADIUS := 0.083
const GALACTIC_POLE := ["", 12.8573, 27.1283, 0.0]
const SIDEREAL_HOURS := [13.00854, 13.07425, 13.4028, 14.5856]
const LATITUDE := -30.75 * PI / 180.0
const AXIAL_TILT := 23.44 * PI / 180.0

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
	["Betelgeuse · Orión", 5.919, 7.407, 0.45], ["Rigel · Orión", 5.242, -8.202, 0.13],
	["Bellatrix · Orión", 5.418, 6.350, 1.64], ["Saiph · Orión", 5.796, -9.670, 2.06],
	["Mintaka · Cinturón de Orión", 5.533, -0.299, 2.23], ["Alnilam · Cinturón de Orión", 5.603, -1.202, 1.69],
	["Alnitak · Cinturón de Orión", 5.679, -1.943, 1.74], ["Adhara · Can Mayor", 6.977, -28.972, 1.50],
	["Wezen · Can Mayor", 7.140, -26.393, 1.83], ["Mirzam · Can Mayor", 6.378, -17.956, 1.98],
	["Kaus Australis · Sagitario", 18.403, -34.385, 1.79], ["Nunki · Sagitario", 18.921, -26.297, 2.05],
	["Kaus Media · Sagitario", 18.350, -29.828, 2.70], ["Ascella · Sagitario", 19.043, -29.880, 2.60],
	["Beta del Pavo", 20.749, -66.203, 3.42], ["Ankaa · Fénix", 0.438, -42.306, 2.40],
]

const PLANETS = [["Júpiter", 16.71, -21.1, -2.16], ["Saturno", 19.32, -22.9, 0.55]]

static func sidereal_at(chapter: int, day: int) -> float:
	return SIDEREAL_HOURS[chapter] + (day - CHAPTER_DAYS[chapter]) * 0.055

static func direction(star: Array, sidereal: float = SIDEREAL_HOURS[0]) -> Vector3:
	return horizontal(deg_to_rad((sidereal - float(star[1])) * 15.0), deg_to_rad(float(star[2])))

static func horizontal(h: float, dec: float) -> Vector3:
	var east := -cos(dec) * sin(h)
	var up := sin(dec) * sin(LATITUDE) + cos(dec) * cos(LATITUDE) * cos(h)
	# North is -Z on Hernán's map and compass.
	var north := sin(dec) * cos(LATITUDE) - cos(dec) * sin(LATITUDE) * cos(h)
	return Vector3(east, up, -north).normalized()

static func pole_from_crux(sidereal: float) -> Vector3:
	var gacrux := direction(STARS[2], sidereal)
	var acrux := direction(STARS[0], sidereal)
	return acrux.rotated(gacrux.cross(acrux).normalized(), gacrux.angle_to(acrux) * 4.5)

static func sun_and_moon(day: int, dusk: float, dark: float) -> Array[Vector3]:
	# Aproximación para octubre y noviembre, con luna llena alrededor del Día 7.
	var sun_longitude := TAU * (273.0 + day - 80.0) / 365.24
	var sun_declination := asin(sin(AXIAL_TILT) * sin(sun_longitude))
	var sunset_angle := acos(-tan(LATITUDE) * tan(sun_declination))
	var hour_angle := lerpf(deg_to_rad(37.0), sunset_angle + deg_to_rad(1.6), dusk) + dark * deg_to_rad(28.0)
	var sun_ra := atan2(sin(sun_longitude) * cos(AXIAL_TILT), cos(sun_longitude))
	var moon_longitude := sun_longitude + PI + TAU * (day - 7.0) / 29.53
	var tilt := deg_to_rad(4.2) * sin(TAU * (day - 4.0) / 27.2)
	var moon_declination := asin(sin(tilt) * cos(AXIAL_TILT) + cos(tilt) * sin(AXIAL_TILT) * sin(moon_longitude))
	var moon_ra := atan2(sin(moon_longitude) * cos(AXIAL_TILT) - tan(tilt) * sin(AXIAL_TILT), cos(moon_longitude))
	return [horizontal(hour_angle, sun_declination), horizontal(sunset_angle + deg_to_rad(24.0) + sun_ra - moon_ra, moon_declination)]

static func identify(look: Vector3, chapter: int, day: int, moon: Vector3) -> String:
	if moon.y > 0.0 and look.distance_squared_to(moon) < MOON_RADIUS * MOON_RADIUS: return "Luna"
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
