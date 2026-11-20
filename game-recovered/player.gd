extends CharacterBody3D

const Creek = preload("res://cauce.gd")

var camera: = Camera3D.new()
var flashlight: = SpotLight3D.new()
var ray: = RayCast3D.new()
var intro_center: = Vector3.ZERO
var intro_heading: = 0.0
var low_gravity: = false
var walking: = false
var looking_only := false
var climb_points: Array[Vector3] = []
var rope_climbing := false
var rope_phase := 0.0
var rope_steps := 0
var rope_heading := 0.0
var rope_entry_pitch := 0.0
var look_speed: = 0.002

func _ready():
	var hit: = CollisionShape3D.new()
	var capsule: = CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.72
	hit.shape = capsule
	hit.position.y = 0.86
	add_child(hit)
	add_child(camera)
	camera.position.y = 1.59
	camera.add_child(flashlight)
	flashlight.light_color = Color("#ffedc9")
	flashlight.light_energy = 1.9
	flashlight.spot_range = 26.0
	flashlight.spot_angle = 24.0
	flashlight.spot_attenuation = 1.65
	flashlight.shadow_enabled = true
	flashlight.hide()
	camera.fov = 72
	camera.add_child(ray)
	ray.target_position = Vector3(0, 0, -2.7)
	ray.collision_mask = 3
	ray.add_exception(self)

func _unhandled_input(event):
	if (walking or looking_only) and not rope_climbing and event is InputEventMouseMotion:
		rotate_y( - event.relative.x * look_speed)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * look_speed, -1.45, 1.45)

func climb_to(landing: Vector3):
	if not climb_points.is_empty(): return
	var clearance: = maxf(position.y, landing.y) + 0.36
	climb_points.assign([Vector3(position.x, clearance, position.z), Vector3(landing.x, clearance, landing.z), landing])
	velocity = Vector3.ZERO

func climb_rope(points: Array[Vector3], heading: float):
	if not climb_points.is_empty() or points.is_empty(): return
	climb_points.assign(points)
	rope_steps = points.size()
	rope_climbing = true
	rope_heading = heading
	rope_entry_pitch = camera.rotation.x
	rope_phase = 0.0
	velocity = Vector3.ZERO

func finish_rope_climb():
	rope_climbing = false
	camera.position.y = 1.59
	camera.rotation.z = 0.0
	camera.rotation.x = rope_entry_pitch

func _physics_process(delta):
	if not climb_points.is_empty():
		if not walking: return
		var speed := 2.2
		if rope_climbing:
			rope_phase += delta * TAU / 0.58
			var pulling := climb_points.size() > 2 and climb_points.size() < rope_steps
			if pulling: speed = 0.35 + 2.2 * pow(maxf(0.0, sin(rope_phase)), 1.25)
			var lean := 0.022 * sin(rope_phase * 0.5) if pulling else 0.0
			rotation.y = lerp_angle(rotation.y, rope_heading, minf(1.0, delta * 9.0))
			camera.rotation.z = lerpf(camera.rotation.z, lean, minf(1.0, delta * 8.0))
			camera.rotation.x = lerpf(camera.rotation.x, 0.18 if pulling else -0.21, minf(1.0, delta * 5.0))
			camera.position.y = lerpf(camera.position.y, 1.59 + 1.55 * lean, minf(1.0, delta * 9.0))
		var next: = position.move_toward(climb_points[0], speed * delta)
		var collision: = move_and_collide(next - position)
		if collision or position.distance_to(climb_points[0]) < 0.02:
			climb_points.pop_front()
			if collision: climb_points.clear()
			if rope_climbing and climb_points.is_empty(): finish_rope_climb()
		return
	var direction: = Vector3.ZERO
	if walking:
		direction = Vector3(int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)), 0, int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W)))
	direction = transform.basis * direction.normalized()
	velocity.x = direction.x * 3.4
	velocity.z = direction.z * 3.4
	velocity.y -= (3.8 if low_gravity else 16.0) * delta
	move_and_slide()
	if intro_center != Vector3.ZERO:
		var local: = (position - intro_center).rotated(Vector3.UP, - intro_heading)
		local.x = clampf(local.x, -32.0, 32.0)
		local.z = clampf(local.z, -55.0, 12.0)
		position = intro_center + local.rotated(Vector3.UP, intro_heading)
		return
	var lateral: = lerpf(46, 354, smoothstep(0, 55, -76 - position.z))
	position.x = clampf(position.x, - lateral, lateral)
	position.z = clampf(position.z, -1049, Creek.LIMIT_Z)
