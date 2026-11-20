extends RefCounted

const ACTIONS = ["Recoger la mochila", "Saltar el tronco", "Agarrarte del pasamanos", "Probar la brújula", "Consultar el mapa", "Trepar con la cuerda", "Acomodarte el pulóver", "Buscar la llave"]
const HEADINGS = [0.0, -0.52, 0.72, 1.05, -0.8, 0.26, -1.19, 0.5]

static func origin(index: int) -> Vector3:
	return Vector3(index * 240, 76, 1200)

static func local_position(index: int, point: Vector3) -> Vector3:
	return (point - origin(index)).rotated(Vector3.UP, - HEADINGS[index])

static func world_position(index: int, point: Vector3) -> Vector3:
	return origin(index) + point.rotated(Vector3.UP, HEADINGS[index])

static func build_fragments(v):
	for index in ACTIONS.size():
		var center: = origin(index)
		var road_color: String = ["5b5e59", "9a7f5a", "887762", "85694e", "a88b65", "9a7357", "82654c", "6d6550"][index]
		var first_child: int = v.get_child_count()
		if index == 2:
			v.box(center + Vector3(0, -0.22, 10), Vector3(112, 0.44, 36), "777657", true)
			v.box(center + Vector3(0, -0.22, -56), Vector3(112, 0.44, 86), "777657", true)
			v.box(center + Vector3(0, -1.2, -10.5), Vector3(112, 0.25, 5), "777e65", true)
			var water = v.box(center + Vector3(0, -0.83, -10.5), Vector3(112, 0.02, 4.96), "466b6e")
			water.material_override.roughness = 0.22
		else:
			v.box(center + Vector3(0, -0.22, -18), Vector3(112, 0.44, 188), "777657", true)
		var road_width: = 6.0 if index == 0 else 2.6
		for i in range(-3, 19):
			if index == 2 and i in [2, 3]: continue
			var bend: = maxf(0, i - 3) * 0.27
			var path = v.box(center + Vector3(bend, 0.025, - i * 5), Vector3(road_width, 0.05, 5.7), road_color)
			path.rotation.y = - 0.055 * maxf(0, i - 3)
		for side in [-1, 1]:
			for i in range(17):
				var foot: = center + Vector3(side * (4 + 6 * absf(sin(i * 1.57 + index))), 0, 22 - i * 5.8)
				v.stone(foot, Vector3(3 + i % 3, 2 + i % 4, 6), ["827b64", "787858", "666950", "89795d"][i % 4])
				if (i + index) % 3 != 0:
					v.box(foot + Vector3.UP * 1.25, Vector3(0.16, 2.5, 0.17), "6b5745")
					v.stone(foot + Vector3.UP * 2.7, Vector3(2.3, 1.35, 2), "657551")
			v.stone(center + Vector3(side * 23, 1, -68), Vector3(33, 25, 64), "676d57")
		v.stone(center + Vector3(-10, 0, 12), Vector3(27, 11, 12), "6a7056")
		v.stone(center + Vector3(26, 0, -44), Vector3(45, 26, 35), "6c735c")
		v.stone(center + Vector3(-14, 0, -95), Vector3(85, 38, 42), "697a70")
		var item: = center + Vector3(1.3, 0.35, -10)
		match index:
			0:
				item.x = center.x + 3.23
				v.box(center + Vector3(3.6, 2.15, -10), Vector3(1.8, 0.1, 2.9), "a49477")
				for offset in [-1, 1]:
					v.box(center + Vector3(3.6, 1.05, -10 + offset), Vector3(0.12, 2.1, 0.12), "685b4a")
				v.box(center + Vector3(3.6, 0.54, -10), Vector3(0.55, 0.12, 2.2), "a18a62")
				v.arrival_bag = v.box(item, Vector3(0.62, 0.63, 0.32), "695343", true, ACTIONS[index])
				var strap = v.box(item + Vector3(0, 0.01, 0.17), Vector3(0.16, 0.41, 0.025), "94826b")
				strap.reparent(v.arrival_bag)
				v.box(item + Vector3(0, -0.12, 0.19), Vector3(0.44, 0.22, 0.12), "a27748").reparent(v.arrival_bag)
				for side in [-1, 1]:
					v.box(item + Vector3(side * 0.19, 0, -0.19), Vector3(0.08, 0.52, 0.12), "464637").reparent(v.arrival_bag)
			1:
				var log: = CylinderMesh.new()
				log.top_radius = 0.23
				log.bottom_radius = 0.29
				log.height = 3.4
				v.prop(log, center + Vector3(0, 0.21, -10), "69523b", true, ACTIONS[index]).rotation.z = PI / 2.0
			2:
				for plank in range(12):
					v.box(center + Vector3(0, -0.075, -8.05 - plank * 0.445), Vector3(2.7, 0.15, 0.445), "93734f", true)
				v.box(center + Vector3(1.46, 0.83, -10), Vector3(0.1, 0.12, 5.2), "735944", true, ACTIONS[index])
				for z in [-8.0, -12.4]:
					v.box(center + Vector3(1.46, 0.44, z), Vector3(0.14, 0.88, 0.15), "735944")
			3, 4:
				v.stone(item - Vector3.UP * 0.14, Vector3(1.06, 0.45, 0.8), "87745c")
			5:
				v.box(center + Vector3(0, 0.69, -11.45), Vector3(3.1, 1.38, 2.25), "85796d", true, ACTIONS[index])
				for side in [-1, 1]:
					v.box(center + Vector3(side * 0.16, 0.71, -10.305), Vector3(0.03, 1.38, 0.03), "ac9164")
				for rung in range(6):
					v.box(center + Vector3(0, 0.23 + rung * 0.2, -10.29), Vector3(0.33, 0.035, 0.035), "ac9164")
			_:
				v.stone(item - Vector3.UP * 0.16, Vector3(0.92, 0.47, 0.76), "87745c")
				v.box(item, Vector3(0.38, 0.3, 0.28), ["675246", "777561", "94704b", "72604b"][index % 4], true, ACTIONS[index])

		var fragment: = Node3D.new()
		var props: Array[Node] = v.get_children().slice(first_child)
		v.add_child(fragment)
		fragment.position = center
		for prop in props:
			prop.reparent(fragment)
		fragment.rotation.y = HEADINGS[index]

static func sign_at(v, point: Vector3, caption: String):
	v.box(point + Vector3(0, 0.85, 0), Vector3(0.1, 1.7, 0.1), "5e5042")
	v.box(point + Vector3.UP * 1.55, Vector3(1.55, 0.48, 0.09), "514d40")
	var label: = Label3D.new()
	label.text = caption
	label.font_size = 38
	label.pixel_size = 0.0035
	label.modulate = Color("#ebdeba")
	v.add_child(label)
	label.position = point + Vector3(0, 1.55, -0.065)
	label.rotation.y = PI

static func build(v):
	v.build_yard_fence()
	sign_at(v, Vector3(v.path_x(-34) + 2, 0, -34), "PUESTO ↑")
	for side in [-1, 1]:
		for i in 8:
			v.stone(Vector3(v.path_x(-18) + side * 2.4, 0.25, -18 + i * 0.48), Vector3(0.68, 0.5, 0.65), "80796a")
