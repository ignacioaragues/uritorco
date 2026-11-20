extends RefCounted

const CAVE: = Vector3(0, 80, 1900)
const DOOR: = Vector3(0, 80, 2100)
const ENTRY: = Vector3(0, 0.08, -5)
const CHECKPOINT: = Vector3(0, 0.78, -23)

static func build_cave(v):
	v.box(CAVE + Vector3(0, -0.45, -5), Vector3(8, 0.9, 12), "474239", true)
	v.box(CAVE + Vector3(0, -2.9, -16), Vector3(9, 0.5, 15), "292725", true)
	for ledge in [[-0.65, 0.13, -13.1], [0.65, 0.38, -16.6], [-0.45, 0.62, -20.1]]:
		v.box(CAVE + Vector3(ledge[0], ledge[1] - 0.45, ledge[2]), Vector3(2.5, 0.9, 2.35), "5c5349", true)
	v.box(CAVE + Vector3(0, 0.25, -29), Vector3(8, 0.9, 15.5), "47443d", true)
	v.box(CAVE + Vector3(0, 0.25, -43), Vector3(10, 0.9, 15), "484b37", true)
	for side in [-1, 1]:
		v.box(CAVE + Vector3(side * 4.2, 1.2, -18), Vector3(0.65, 8, 37), "383632", true)
		for i in range(13):
			v.stone(CAVE + Vector3(side * (3.3 + 0.32 * sin(i)), 1.8, -3 - i * 2.55), Vector3(2.4, 6.5, 4.0), "544d44")
		for i in range(6):
			var base: = CAVE + Vector3(side * (4 + sin(i) * 0.8), 0.7, -38 - i * 2.15)
			v.box(base + Vector3.UP * 1.8, Vector3(0.22, 3.6, 0.22), "43372e")
			v.stone(base + Vector3.UP * 3.45, Vector3(3.4, 3.7, 4.9), "393f32")
	v.box(CAVE + Vector3(0, 4.05, -20), Vector3(9, 0.8, 32), "393630", true)
	v.box(CAVE + Vector3(-2.55, 1.15, -28), Vector3(1.1, 0.9, 3), "63503f", true)
	v.box(CAVE + Vector3(-2.48, 1.79, -28), Vector3(0.75, 0.38, 0.76), "414948", true, "Receptor")
	for i in range(3):
		v.box(CAVE + Vector3(-2.075, 1.79, -28.28 + i * 0.21), Vector3(0.04, 0.075, 0.1), "9c8567")
	v.box(CAVE + Vector3(-2.48, 1.63, -26.85), Vector3(0.48, 0.055, 0.64), "a09273", true, "Cuadernos de observación")
	var tripod: = CAVE + Vector3(2.4, 0.7, -30.3)
	for leg in [Vector3(-0.25, 0, 0.17), Vector3(0.25, 0, 0.17), Vector3(0, 0, -0.28)]:
		var foot: Vector3 = tripod + leg
		var strut = v.box(foot.lerp(tripod + Vector3.UP * 0.95, 0.5), Vector3(0.04, 0.04, 0.99), "665e51")
		strut.look_at(tripod + Vector3.UP * 0.95)
	v.box(tripod + Vector3.UP * 0.99, Vector3(0.28, 0.15, 0.29), "50545a")
	var lamp = v.box(CAVE + Vector3(-2.48, 1.88, -28.35), Vector3(0.085, 0.042, 0.035), "b65734")
	lamp.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	v.box(CAVE + Vector3(1.05, 1.43, -36.1), Vector3(0.15, 1.44, 0.15), "a19272", true, "Salida de la cueva")
	var glow = v.stone(CAVE + Vector3(0, 2.25, -48.2), Vector3(0.4, 0.43, 0.4), "9ababc")
	glow.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

static func build_door(v):
	v.box(DOOR + Vector3(0, -0.25, -3), Vector3(11, 0.5, 12), "7e765b", true)
	v.plaster(v.box(DOOR + Vector3(0, 1.6, -5.1), Vector3(7.4, 3.2, 0.35), "b09d80", true))
	v.timber(v.box(DOOR + Vector3(0, 1.12, -4.86), Vector3(1.22, 2.24, 0.15), "705342", true, "Puerta de Mara"))
	v.box(DOOR + Vector3(0.42, 1.12, -4.76), Vector3(0.12, 0.065, 0.06), "a08d68")
