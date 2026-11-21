extends CharacterBody3D

signal footfall(surface: StringName, impact: float)

const Creek = preload("res://cauce.gd")
const CAPSULE_CENTER := 0.86
const LEDGE_MIN_HEIGHT := 0.52
const LEDGE_MAX_HEIGHT := 1.58
const LEDGE_REACH := 1.02
const STEP_LENGTH := 1.51

var camera: = Camera3D.new()
var flashlight: = SpotLight3D.new()
var flashlight_haze := ShaderMaterial.new()
var ray: = RayCast3D.new()
var capsule := CapsuleShape3D.new()
const DEFAULT_SCENE_BOUNDS := Rect2(-32, -55, 64, 67)
var scene_bounds := DEFAULT_SCENE_BOUNDS
var intro_center: = Vector3.ZERO
var intro_heading: = 0.0
var low_gravity: = false
var water_depth := 0.0
var dream_bounds := Rect2(-32, -55, 64, 67)
var walking: = false
var looking_only := false
var climb_points: Array[Vector3] = []
var rope_climbing := false
var ledge_climbing := false
var rope_phase := 0.0
var rope_steps := 0
var rope_heading := 0.0
var rope_entry_pitch := 0.0
var rope_descending := false
var ledge_elapsed := 0.0
var look_speed: = 0.002
var step_distance := 0.0

func _ready():
	var hit: = CollisionShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.72
	hit.shape = capsule
	hit.position.y = CAPSULE_CENTER
	add_child(hit)
	add_child(camera)
	camera.position.y = 1.59
	camera.add_child(flashlight)
	var beam_axis := Vector3(-0.031, 0.033, -1.0).normalized()
	flashlight.position = Vector3(0.22, -0.23, -0.18)
	flashlight.quaternion = Quaternion(Vector3.FORWARD, beam_axis)
	flashlight.light_color = Color("#ffedc9")
	flashlight.light_energy = 1.9
	flashlight.spot_range = 26.0
	flashlight.spot_angle = 24.0
	flashlight.spot_attenuation = 1.65
	flashlight.shadow_enabled = true
	flashlight.shadow_bias = 0.20
	flashlight.shadow_normal_bias = 3.0
	flashlight.hide()
	var beam := MeshInstance3D.new()
	var screen := QuadMesh.new()
	screen.size = Vector2(2.0, 2.0)
	beam.mesh = screen
	beam.extra_cull_margin = 1000.0
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_haze.shader = preload("res://haz_linterna.gdshader")
	flashlight_haze.set_shader_parameter("light_origin", flashlight.position)
	flashlight_haze.set_shader_parameter("light_axis", beam_axis)
	beam.material_override = flashlight_haze
	flashlight.add_child(beam)
	camera.fov = 72
	camera.add_child(ray)
	ray.target_position = Vector3(0, 0, -2.7)
	ray.collision_mask = 3
	ray.add_exception(self)

func _unhandled_input(event):
	if (walking or looking_only) and climb_points.is_empty() and event is InputEventMouseMotion:
		rotate_y( - event.relative.x * look_speed)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * look_speed, -1.45, 1.45)

func climb_ledge() -> bool:
	var points := ledge_route()
	if points.is_empty(): return false
	climb_points.assign(points)
	ledge_climbing = true
	ledge_elapsed = 0.0
	rope_entry_pitch = camera.rotation.x
	velocity = Vector3.ZERO
	return true

func ledge_route() -> Array[Vector3]:
	if not walking or not is_on_floor() or low_gravity or not climb_points.is_empty(): return []
	var look := -camera.global_basis.z
	if absf(look.y) > 0.87: return []
	var forward := Vector3(look.x, 0.0, look.z).normalized()
	var start := global_position
	var probe := start + Vector3.UP * 0.43
	var face := raycast_surface(probe, probe + forward * LEDGE_REACH)
	if face.is_empty() or face.normal.dot(-forward) < 0.72 or absf(face.normal.y) > 0.35: return []
	var item := str(face.collider.get_meta("item", ""))
	if not item.is_empty() and item != "Subir al escalón": return []
	var edge: Vector3 = face.position
	var ledge := edge + forward * 0.56
	var top := raycast_surface(Vector3(ledge.x, start.y + LEDGE_MAX_HEIGHT + 0.11, ledge.z), Vector3(ledge.x, start.y + LEDGE_MIN_HEIGHT, ledge.z))
	if top.is_empty() or top.normal.y < 0.86 or top.position.y > start.y + LEDGE_MAX_HEIGHT: return []
	var landing: Vector3 = top.position
	var lateral := Vector3(-forward.z, 0.0, forward.x)
	for offset in [lateral * 0.26, lateral * -0.26, forward * 0.27]:
		var support: Vector3 = landing + offset
		var side := raycast_surface(support + Vector3.UP * 0.13, support - Vector3.UP * 0.17)
		if side.is_empty() or side.normal.y < 0.83: return []
	var stop := start + forward * maxf(0.0, (edge - start).dot(forward) - 0.39)
	var ground := raycast_surface(stop + Vector3.UP * 0.29, stop - Vector3.UP * 0.22)
	if ground.is_empty() or ground.normal.y < 0.72: return []
	stop.y = maxf(start.y, ground.position.y) + 0.06
	var crest := Vector3(stop.x, landing.y + 0.19, stop.z)
	var stand := landing + Vector3.UP * 0.08
	if not capsule_has_room(crest) or not capsule_has_room(stand): return []
	if not raycast_surface(crest + Vector3.UP * 1.64, stand + Vector3.UP * 1.64).is_empty(): return []
	return [stop, stop.lerp(crest, 0.39), crest, landing + Vector3.UP * 0.19, stand]

func raycast_surface(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func capsule_has_room(foot: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = foot + Vector3.UP * CAPSULE_CENTER
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func climb_rope(points: Array[Vector3], heading: float):
	if not climb_points.is_empty() or points.is_empty(): return
	climb_points.assign(points)
	rope_steps = points.size()
	rope_climbing = true
	rope_descending = points[-1].y < points[0].y
	rope_heading = heading
	rope_entry_pitch = camera.rotation.x
	rope_phase = 0.0
	velocity = Vector3.ZERO

func finish_climb():
	rope_climbing = false
	ledge_climbing = false
	camera.position.y = 1.59
	camera.rotation.z = 0.0
	camera.rotation.x = rope_entry_pitch

func _physics_process(delta):
	if not climb_points.is_empty():
		step_distance = 0.0
		if not walking: return
		var speed := 2.2
		if rope_climbing:
			var moving := Input.is_physical_key_pressed(KEY_W)
			var pulling := climb_points.size() < rope_steps and climb_points.size() > 2
			if moving and pulling: rope_phase += delta * TAU / 0.71
			var push := pow(maxf(0.0, sin(rope_phase - 0.46)), 1.45)
			var settling := maxf(0.0, -sin(rope_phase - 0.46))
			var lean := 0.046 * sin(rope_phase * 0.5) if pulling else 0.0
			if pulling: speed = 0.09 + 2.8 * push
			rotation.y = lerp_angle(rotation.y, rope_heading, minf(1.0, delta * 9.0))
			camera.rotation.z = lerpf(camera.rotation.z, lean, minf(1.0, delta * 12.0))
			var pitch := -0.16 if not pulling else lerpf(-0.31, 0.17, push)
			if rope_descending and pulling: pitch -= 0.12
			camera.rotation.x = lerpf(camera.rotation.x, pitch, minf(1.0, delta * 11.0))
			camera.position.y = lerpf(camera.position.y, 1.59 - (0.10 * settling if pulling else 0.0), minf(1.0, delta * 12.0))
			if not moving: return
		elif ledge_climbing:
			ledge_elapsed += delta
			var bracing := 1.0 - smoothstep(0.13, 0.35, ledge_elapsed)
			var mantle := climb_points.size() == 2
			speed = 1.24 if bracing > 0.40 else (2.66 if mantle else 2.36)
			camera.rotation.x = lerpf(camera.rotation.x, -0.36 if bracing > 0.35 or mantle else 0.11, minf(1.0, delta * 11.0))
			camera.position.y = lerpf(camera.position.y, 1.59 - 0.16 * bracing - (0.07 if mantle else 0.0), minf(1.0, delta * 11.0))
		var next: = position.move_toward(climb_points[0], speed * delta)
		var collision: = move_and_collide(next - position)
		if collision or position.distance_to(climb_points[0]) < 0.02:
			climb_points.pop_front()
			if collision: climb_points.clear()
			if climb_points.is_empty(): finish_climb()
		return
	var direction: = Vector3.ZERO
	if walking:
		direction = Vector3(int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)), 0, int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W)))
	direction = transform.basis * direction.normalized()
	var resistance := smoothstep(0.045, 1.60, water_depth)
	var speed := lerpf(3.4, 1.42, resistance)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= (3.8 if low_gravity else lerpf(16.0, 10.0, resistance)) * delta
	var previous := position
	var was_grounded := is_on_floor()
	var fall_speed := -velocity.y
	move_and_slide()
	if intro_center != Vector3.ZERO:
		var local: = (position - intro_center).rotated(Vector3.UP, - intro_heading)
		var bounds := dream_bounds if low_gravity else scene_bounds
		local.x = clampf(local.x, bounds.position.x, bounds.end.x)
		local.z = clampf(local.z, bounds.position.y, bounds.end.y)
		position = intro_center + local.rotated(Vector3.UP, intro_heading)
	else:
		var lateral: = lerpf(46, 354, smoothstep(0, 55, -76 - position.z))
		position.x = clampf(position.x, -maxf(lateral, Creek.west_limit(position.z)), lateral)
		position.z = clampf(position.z, -1049, Creek.LIMIT_Z)
	update_footfalls(position - previous, was_grounded, fall_speed)

func update_footfalls(motion: Vector3, was_grounded: bool, fall_speed: float):
	if not walking or not is_on_floor(): return
	if not was_grounded and fall_speed > 2.7:
		step_distance = 0.0
		footfall.emit(floor_sound(), smoothstep(2.7, 9.0, fall_speed))
		return
	step_distance += Vector2(motion.x, motion.z).length()
	if step_distance < STEP_LENGTH: return
	step_distance = fmod(step_distance, STEP_LENGTH)
	footfall.emit(floor_sound(), 0.0)

func floor_sound() -> StringName:
	for i in range(get_slide_collision_count() - 1, -1, -1):
		var slide := get_slide_collision(i)
		if slide.get_normal().y < 0.65: continue
		var body := slide.get_collider()
		if not is_instance_valid(body): continue
		var surface: StringName = body.get_meta("footstep", &"")
		if surface != &"": return surface
	var below := raycast_surface(global_position + Vector3.UP * 0.10, global_position + Vector3.DOWN * 0.19)
	return below.collider.get_meta("footstep", &"") if not below.is_empty() else &""
