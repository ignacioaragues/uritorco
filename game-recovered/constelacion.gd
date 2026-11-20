extends RefCounted


const NIGHTS = [
	[13.00854, Vector3(-0.000117, 0.934241, 0.356643), Vector3(-0.700679, -0.713473, -0.002364)], 
	[13.07425, Vector3(0.17595, 0.949098, 0.261257), Vector3(-0.700207, -0.71394, 0.000478)], 
	[13.4028, Vector3(0.830332, 0.502559, -0.240799), Vector3(-0.698499, -0.715486, 0.013342)], 
	[14.5856, Vector3(-0.870401, 0.313345, 0.37976), Vector3(-0.701349, -0.711734, 0.03929)]
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
	["Regulus", 10.14, 11.97, 1.35], ["Peacock", 20.43, -56.74, 1.94]
]

static func direction(star: Array, sidereal: float = NIGHTS[0][0]) -> Vector3:
	var h: = deg_to_rad((sidereal - float(star[1])) * 15.0)
	var dec: = deg_to_rad(float(star[2]))
	var lat: = deg_to_rad(-30.75)
	return Vector3( - cos(dec) * sin(h), sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(h), sin(dec) * cos(lat) - cos(dec) * sin(lat) * cos(h)).normalized()

static func identify(look: Vector3, chapter: int = 0) -> String:
	if look.dot(NIGHTS[chapter][1]) > cos(deg_to_rad(3.4)): return "Luna"
	var closest: = cos(deg_to_rad(2.0))
	var name: = ""
	for star in STARS:
		var similarity: = direction(star, NIGHTS[chapter][0]).dot(look)
		if similarity > closest:
			closest = similarity
			name = star[0]
	return name
