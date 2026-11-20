extends RefCounted

const FINISH = preload("res://acabado_equipo.gdshader")
const SIDES := 24

static func material(tint: String, cloth := false, roughness := 0.83) -> ShaderMaterial:
	var finish := ShaderMaterial.new()
	finish.shader = FINISH
	finish.set_shader_parameter("tint", Color(tint))
	finish.set_shader_parameter("fabric", 1.0 if cloth else 0.0)
	finish.set_shader_parameter("wear", 0.95 if cloth else 0.55)
	finish.set_shader_parameter("roughness", roughness)
	return finish

static func mesh_part(parent: Node3D, mesh: Mesh, offset: Vector3, finish: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = finish
	parent.add_child(piece)
	piece.position = offset
	return piece

static func block(parent: Node3D, at: Vector3, size: Vector3, finish: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_part(parent, mesh, at, finish)

static func cylinder(parent: Node3D, at: Vector3, base: float, top: float, height: float, finish: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = base
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 0
	return mesh_part(parent, mesh, at, finish)

static func item(parent: Node3D, at: Vector3, label: String, hit_center: Vector3, hit_size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.set_meta("item", label)
	parent.add_child(body)
	body.position = at
	var box_shape := BoxShape3D.new()
	box_shape.size = hit_size
	var hit := CollisionShape3D.new()
	hit.shape = box_shape
	body.add_child(hit)
	hit.position = hit_center
	return body

static func shell(parent: Node3D, profile: Array[Vector4], finish: Material, softness := 0.62) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	for ring in profile:
		for i in SIDES:
			var angle := TAU * i / SIDES
			var x := cos(angle)
			var z := sin(angle)
			vertices.append(Vector3(signf(x) * pow(absf(x), softness) * ring.y,
				ring.x, ring.w + signf(z) * pow(absf(z), softness) * ring.z))
	return mesh_part(parent, rings(vertices, SIDES), Vector3.ZERO, finish)

static func rings(vertices: PackedVector3Array, width: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices: surface.add_vertex(vertex)
	for row in range(vertices.size() / width - 1):
		for i in width:
			var a := row * width + i
			var b := row * width + (i + 1) % width
			for index in [a, a + width, b, b, a + width, b + width]:
				surface.add_index(index)
	surface.generate_normals()
	return surface.commit()

static func cord(parent: Node3D, points: PackedVector3Array, radius: float, finish: Material):
	const SIDES_PER_CORD := 8
	var vertices := PackedVector3Array()
	for i in points.size():
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var frame := Basis(Quaternion(Vector3.UP, tangent))
		for side in SIDES_PER_CORD:
			var a := TAU * side / SIDES_PER_CORD
			vertices.append(points[i] + (frame.x * cos(a) + frame.z * sin(a)) * radius)
	mesh_part(parent, rings(vertices, SIDES_PER_CORD), Vector3.ZERO, finish)

static func belt(parent: Node3D, points: PackedVector3Array, width: float, finish: Material):
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var across := Vector3.RIGHT * width * 0.5
		for point in [a - across, a + across, b - across, a + across, b + across, b - across]:
			surface.add_vertex(point)
		for point in [a - across, b - across, a + across, a + across, b - across, b + across]:
			surface.add_vertex(point)
	surface.generate_normals()
	mesh_part(parent, surface.commit(), Vector3.ZERO, finish)

static func backpack(parent: Node3D, at: Vector3, label: String) -> StaticBody3D:
	var pack := item(parent, at, label, Vector3(0, -0.013, 0.025), Vector3(0.50, 0.57, 0.39))
	var canvas := material("626b50", true)
	var gusset := material("788064", true)
	var flap := material("868263", true)
	var trim := material("444e41", true)
	var webbing := material("4e5142", true)
	var thread := material("958762", true)
	var leather := material("85664a", true)
	var metal := material("716d65", false, 0.44)

	shell(pack, [
		Vector4(-0.301, 0.005, 0.004, 0),
		Vector4(-0.293, 0.185, 0.107, 0),
		Vector4(-0.265, 0.227, 0.134, 0),
		Vector4(-0.177, 0.252, 0.161, -0.008),
		Vector4(0.010, 0.262, 0.171, -0.011),
		Vector4(0.143, 0.241, 0.156, -0.014),
		Vector4(0.223, 0.203, 0.146, -0.012),
		Vector4(0.267, 0.155, 0.115, -0.015),
		Vector4(0.294, 0.069, 0.065, -0.02),
		Vector4(0.299, 0.005, 0.004, -0.02),
	], canvas)
	shell(pack, [
		Vector4(-0.259, 0.03, 0.018, 0.149),
		Vector4(-0.244, 0.159, 0.061, 0.164),
		Vector4(-0.211, 0.184, 0.081, 0.164),
		Vector4(-0.119, 0.184, 0.087, 0.171),
		Vector4(-0.071, 0.146, 0.063, 0.166),
		Vector4(-0.056, 0.03, 0.012, 0.167),
	], gusset)
	shell(pack, [
		Vector4(0.105, 0.034, 0.012, 0.12),
		Vector4(0.124, 0.179, 0.035, 0.113),
		Vector4(0.166, 0.216, 0.053, 0.100),
		Vector4(0.217, 0.19, 0.065, 0.086),
		Vector4(0.270, 0.163, 0.082, 0.011),
		Vector4(0.304, 0.041, 0.030, 0.006),
	], flap)

	var zipper := PackedVector3Array([
		Vector3(-0.176, -0.145, 0.223), Vector3(-0.152, -0.107, 0.243), Vector3(-0.112, -0.114, 0.253),
		Vector3(-0.026, -0.120, 0.258), Vector3(0.067, -0.116, 0.258), Vector3(0.129, -0.112, 0.245),
		Vector3(0.161, -0.130, 0.235), Vector3(0.175, -0.164, 0.227),
	])
	cord(pack, zipper, 0.008, trim)
	var teeth := PackedVector3Array()
	for point in zipper: teeth.append(point + Vector3(0, 0, 0.005))
	cord(pack, teeth, 0.0024, thread)
	block(pack, Vector3(0.120, -0.125, 0.251), Vector3(0.022, 0.012, 0.010), metal).rotation.z = -0.33
	cord(pack, PackedVector3Array([Vector3(0.121, -0.128, 0.257), Vector3(0.137, -0.152, 0.269), Vector3(0.151, -0.148, 0.262)]), 0.003, leather)
	cord(pack, PackedVector3Array([Vector3(-0.066, 0.269, -0.023), Vector3(-0.054, 0.326, -0.016), Vector3(-0.026, 0.349, -0.012), Vector3(0.026, 0.349, -0.012), Vector3(0.054, 0.326, -0.018), Vector3(0.070, 0.268, -0.024)]), 0.011, webbing)

	for side in [-1.0, 1.0]:
		var x: float = side * 0.125
		belt(pack, PackedVector3Array([Vector3(x, 0.248, 0.107), Vector3(x, 0.191, 0.150), Vector3(x, 0.121, 0.166), Vector3(x, 0.025, 0.170), Vector3(x, -0.033, 0.164)]), 0.027, leather)
		var clasp := block(pack, Vector3(x, 0.042, 0.179), Vector3(0.036, 0.027, 0.012), metal)
		block(clasp, Vector3(0, 0, 0.007), Vector3(0.024, 0.015, 0.005), trim)
		cord(pack, PackedVector3Array([Vector3(x, 0.246, -0.113), Vector3(x, 0.179, -0.180), Vector3(x * 1.43, 0.045, -0.227), Vector3(x * 1.55, -0.088, -0.207), Vector3(x * 1.4, -0.193, -0.160), Vector3(x * 1.37, -0.263, -0.105)]), 0.025, webbing)
		cord(pack, PackedVector3Array([Vector3(side * 0.173, -0.267, 0.104), Vector3(side * 0.227, -0.206, 0.136), Vector3(side * 0.249, -0.046, 0.141), Vector3(side * 0.224, 0.115, 0.131), Vector3(side * 0.185, 0.198, 0.113)]), 0.004, thread)
	var patch := block(pack, Vector3(-0.043, -0.179, 0.250), Vector3(0.086, 0.041, 0.010), leather)
	cord(patch, PackedVector3Array([Vector3(-0.025, -0.006, 0.004), Vector3(-0.006, 0.009, 0.004), Vector3(0.010, -0.004, 0.004), Vector3(0.018, 0.004, 0.004), Vector3(0.029, -0.006, 0.004)]), 0.0022, thread)
	return pack

static func desk_radio(parent: Node3D, at: Vector3) -> StaticBody3D:
	var radio := item(parent, at, "Radio", Vector3(0, 0.15, 0), Vector3(0.238, 0.295, 0.164))
	var case_shell := material("474943", false, 0.74)
	var rubber := material("343632")
	var recess := material("262b28")
	var bronze := material("a19276", false, 0.46)
	var inset := material("757c64", false, 0.48)
	var button := material("bb692e")
	block(radio, Vector3(0, 0.021, -0.006), Vector3(0.196, 0.035, 0.13), rubber)
	block(radio, Vector3(0, 0.043, -0.047), Vector3(0.174, 0.042, 0.032), case_shell)
	var unit := Node3D.new()
	unit.name = "Transceptor"
	radio.add_child(unit)
	unit.position = Vector3(0, 0.027, 0.005)
	unit.rotation.x = -0.105
	shell(unit, [
		Vector4(0.014, 0.004, 0.004, 0),
		Vector4(0.015, 0.070, 0.027, 0),
		Vector4(0.027, 0.081, 0.033, 0),
		Vector4(0.207, 0.084, 0.035, 0),
		Vector4(0.223, 0.078, 0.032, 0),
		Vector4(0.229, 0.068, 0.025, 0),
		Vector4(0.230, 0.004, 0.004, 0),
	], case_shell, 0.32)
	block(unit, Vector3(0, 0.150, 0.033), Vector3(0.106, 0.088, 0.007), rubber)
	for slot in 5:
		var y := 0.12 + slot * 0.014
		block(unit, Vector3(0, y, 0.037), Vector3(0.081 + slot * 0.003, 0.006, 0.004), recess)
		block(unit, Vector3(0, y + 0.0034, 0.040), Vector3(0.081 + slot * 0.003, 0.0018, 0.0018), case_shell)
	block(unit, Vector3(0.001, 0.080, 0.034), Vector3(0.077, 0.030, 0.008), recess)
	block(unit, Vector3(0.001, 0.080, 0.039), Vector3(0.067, 0.022, 0.0018), inset)
	var channel := Label3D.new()
	unit.add_child(channel)
	channel.position = Vector3(0.002, 0.080, 0.0405)
	channel.text = "03"
	channel.modulate = Color("#d4c7a3")
	channel.font_size = 36
	channel.outline_size = 0
	channel.pixel_size = 0.00047
	block(unit, Vector3(0.081, 0.151, 0.014), Vector3(0.016, 0.064, 0.026), button)
	cylinder(unit, Vector3(-0.052, 0.241, -0.008), 0.014, 0.0125, 0.028, bronze)
	cylinder(unit, Vector3(-0.052, 0.328, -0.009), 0.012, 0.008, 0.169, rubber)
	cylinder(unit, Vector3(-0.052, 0.416, -0.009), 0.009, 0.007, 0.009, case_shell)
	cylinder(unit, Vector3(0.040, 0.242, -0.007), 0.019, 0.018, 0.025, rubber)
	block(unit, Vector3(0.043, 0.255, -0.018), Vector3(0.003, 0.0016, 0.012), bronze)
	for x in [-0.061, 0.061]:
		cylinder(unit, Vector3(x, 0.044, 0.035), 0.0034, 0.0034, 0.0026, bronze).rotation.x = PI / 2.0
	return radio
