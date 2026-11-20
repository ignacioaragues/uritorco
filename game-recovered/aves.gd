extends Node3D

enum Species { JOTE, CARANCHO, GOLONDRINA }

class Flight:
	var kind: Species
	var bird := Node3D.new()
	var wings: Array[Node3D] = []
	var center: Vector3
	var radius: Vector2
	var offset: float

var flights: Array[Flight] = []
var elapsed := 0.0

func add_flight(kind: Species, center: Vector3, radius: Vector2, offset: float):
	var flight := Flight.new()
	flight.kind = kind
	flight.center = center
	flight.radius = radius
	flight.offset = offset
	add_child(flight.bird)
	flights.append(flight)
	match kind:
		Species.JOTE: jote(flight)
		Species.CARANCHO: carancho(flight)
		Species.GOLONDRINA: swallow(flight)

func form(parent: Node3D, at: Vector3, size: Vector3, tint: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 9
	mesh.rings = 5
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = ink(tint)
	parent.add_child(instance)
	instance.position = at
	instance.scale = size
	return instance

func ink(tint: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint)
	material.roughness = 1.0
	return material

func feather(parent: Node3D, side: float, points: Array, tint: String):
	var walk := PackedVector2Array(points)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in Geometry2D.triangulate_polygon(walk):
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(walk[i].x * side, 0, walk[i].y))
	var patch := MeshInstance3D.new()
	patch.mesh = surface.commit()
	var material := ink(tint)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	patch.material_override = material
	parent.add_child(patch)

func wings_for(flight: Flight) -> Array[Node3D]:
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position.x = side * 0.06
		flight.bird.add_child(wing)
		flight.wings.append(wing)
	return flight.wings

func jote(flight: Flight):
	var bird := flight.bird
	form(bird, Vector3.ZERO, Vector3(0.18, 0.15, 0.48), "433d39")
	form(bird, Vector3(0, 0.020, -0.245), Vector3(0.089, 0.081, 0.102), "615b55")
	form(bird, Vector3(0, -0.01, 0.27), Vector3(0.23, 0.048, 0.23), "3c3533")
	var side := -1.0
	for wing in wings_for(flight):
		form(wing, Vector3(side * 0.32, 0, 0.026), Vector3(0.72, 0.056, 0.31), "453c38")
		form(wing, Vector3(side * 0.71, -0.014, 0.040), Vector3(0.47, 0.043, 0.24), "716b61")
		for i in 5:
			var tip := Vector3(side * (0.88 + 0.09 * sin(i * 0.63)), -0.016, -0.045 + i * 0.056)
			form(wing, tip, Vector3(0.29, 0.031, 0.052), "443b36").rotation.y = -(i - 1) * 0.11 * side
		side = 1.0

func carancho(flight: Flight):
	var bird := flight.bird
	form(bird, Vector3.ZERO, Vector3(0.138, 0.14, 0.34), "6c5748")
	form(bird, Vector3(0, -0.04, -0.076), Vector3(0.12, 0.095, 0.20), "d0b798")
	form(bird, Vector3(0, 0.038, -0.17), Vector3(0.092, 0.085, 0.115), "ddd0ab")
	form(bird, Vector3(0, 0.027, -0.21), Vector3(0.074, 0.067, 0.081), "856547")
	form(bird, Vector3(0, 0.020, -0.25), Vector3(0.044, 0.044, 0.059), "b8875d")
	form(bird, Vector3(0, -0.012, 0.25), Vector3(0.17, 0.037, 0.31), "b9a386")
	form(bird, Vector3(0, -0.015, 0.37), Vector3(0.16, 0.04, 0.105), "50433c")
	var side := -1.0
	for wing in wings_for(flight):
		feather(wing, side, [Vector2(0, -0.075), Vector2(0.32, -0.125), Vector2(0.62, -0.045),
			Vector2(0.74, 0.045), Vector2(0.56, 0.134), Vector2(0.23, 0.16), Vector2(0, 0.08)], "605149")
		form(wing, Vector3(side * 0.48, -0.008, 0.017), Vector3(0.25, 0.02, 0.125), "c8bba5")
		side = 1.0

func swallow(flight: Flight):
	var bird := flight.bird
	form(bird, Vector3.ZERO, Vector3(0.060, 0.052, 0.16), "435461")
	form(bird, Vector3(0, -0.013, -0.027), Vector3(0.057, 0.042, 0.108), "cfbea6")
	form(bird, Vector3(0, -0.008, -0.07), Vector3(0.034, 0.035, 0.037), "8e6552")
	var side := -1.0
	for wing in wings_for(flight):
		feather(wing, side, [Vector2(0, -0.028), Vector2(0.09, -0.061), Vector2(0.23, -0.014),
			Vector2(0.30, 0.066), Vector2(0.122, 0.044), Vector2(0.03, 0.069)], "445863")
		feather(bird, side, [Vector2(0, 0.046), Vector2(0.037, 0.071), Vector2(0.055, 0.163),
			Vector2(0.016, 0.122), Vector2(0, 0.098)], "3f4d5b")
		side = 1.0

func _process(delta: float):
	elapsed += delta
	if not visible: return
	for flight in flights:
		var kind := flight.kind
		var a: float = elapsed * [0.14, 0.26, 0.60][kind] + flight.offset
		var lift: float = sin(a * 2.0) * [1.7, 1.5, 0.82][kind]
		var shift := Vector3(flight.radius.x * cos(a), lift, flight.radius.y * sin(a))
		flight.bird.position = flight.center + shift
		var heading := atan2(flight.radius.x * sin(a), -flight.radius.y * cos(a))
		flight.bird.rotation = Vector3(0.06 * cos(a * 2.0), heading, 0.16 + 0.10 * cos(a))
		var strength: float = [0.12, 0.64, 0.84][kind]
		var glide := smoothstep(-0.05, 0.6, sin(a * 3.0 + 0.3)) if kind != Species.JOTE else 0.70
		flight.wings[0].rotation.z = strength * glide * sin(elapsed * [2.9, 11.0, 22.3][kind] + flight.offset)
		flight.wings[1].rotation.z = -flight.wings[0].rotation.z
