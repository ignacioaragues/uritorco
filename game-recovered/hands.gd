extends Control

const RADIO = preload("res://equipo/radio.webp")
const COMPASS = preload("res://equipo/brujula.webp")
const MAP_HAND = preload("res://equipo/mapa_mano.webp")
var mate_texture: Texture2D
var rig: = Node2D.new()
var sprite: = Sprite2D.new()
var paper_rig: = Node2D.new()
var paper_sprite: = Sprite2D.new()
var ptt: = ShaderMaterial.new()
var pose: = ""
var requested_pose := ""
var map_requested := false
var map_lift := 0.0
var map_movement: Tween
var heading := 0.0
var target_heading := 0.0
var phase: = 0.0
var stride: = 0.0
var lift: = 0.0
var press: = 0.0
var movement: Tween
var press_motion: Tween

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://equipo/mate.webp"):
		mate_texture = load("res://equipo/mate.webp")
	add_child(paper_rig)
	paper_rig.add_child(paper_sprite)
	paper_sprite.texture = MAP_HAND
	paper_sprite.centered = false
	paper_rig.hide()
	add_child(rig)
	rig.show_behind_parent = true
	rig.add_child(sprite)
	sprite.centered = false
	rig.hide()
	ptt.shader = preload("res://pulsador.gdshader")
	hide()

func mount_map(sheet: Control):
	paper_rig.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sheet.size = Vector2(560, 330)

	sheet.position = Vector2(207, 33)
	sheet.scale = Vector2(0.99, 1.19)

func hold(next: String):
	if next == requested_pose: return
	requested_pose = next
	if movement: movement.kill()
	if press_motion: press_motion.kill()
	press = 0.0
	if next.is_empty() and pose.is_empty(): return
	movement = create_tween().set_trans(Tween.TRANS_SINE)
	if next == pose:
		movement.tween_method(set_lift, lift, 1.0, 0.28 * (1.0 - lift))
		return
	if not pose.is_empty() and lift > 0.0:
		movement.tween_method(set_lift, lift, 0.0, 0.22 * lift)
	movement.tween_callback(apply_pose.bind(next))
	if not next.is_empty():
		movement.tween_method(set_lift, 0.0, 1.0, 0.28)

func apply_pose(next: String):
	pose = next
	rig.visible = pose in ["radio", "compass", "piece", "mate"]
	if not rig.visible:
		lift = 0.0
		if not paper_rig.visible: hide()
		queue_redraw()
		return
	sprite.texture = mate_texture if pose == "mate" else (RADIO if pose == "radio" else COMPASS)
	sprite.material = ptt if pose == "radio" else null
	show()
	set_lift(0.0)

func show_map(open: bool):
	if open == map_requested: return
	map_requested = open
	if map_movement: map_movement.kill()
	map_movement = create_tween().set_trans(Tween.TRANS_SINE)
	if open:
		show()
		paper_rig.show()
		update_pose()
		map_movement.tween_method(set_map_lift, map_lift, 1.0, 0.28 * (1.0 - map_lift))
	else:
		map_movement.tween_method(set_map_lift, map_lift, 0.0, 0.22 * map_lift)
		map_movement.tween_callback(func():
			paper_rig.hide()
			if not rig.visible: hide())

func set_map_lift(value: float):
	map_lift = value
	update_pose()

func set_lift(value: float):
	lift = value
	update_pose()

func press_button():
	if requested_pose != "radio": return
	if press_motion: press_motion.kill()
	press_motion = create_tween().set_trans(Tween.TRANS_SINE)
	if pose != "radio":
		press_motion.tween_interval(0.22 * lift + 0.2)
	elif lift < 0.5:
		press_motion.tween_interval(0.2)
	press_motion.tween_method(set_press, press, 1.0, 0.12)
	press_motion.tween_interval(0.13)
	press_motion.tween_method(set_press, 1.0, 0.0, 0.2)

func set_press(value: float):
	press = value
	update_pose()

func set_bearing(value: float):
	target_heading = value
	if pose != "compass" or lift < 0.18: heading = value

func step(delta: float, speed: float):
	if pose == "compass":
		heading = lerp_angle(heading, target_heading, 1.0 - exp(-delta * 13.0))
	var target: = clampf(speed / 3.4, 0.0, 1.0)
	stride = move_toward(stride, target, delta * 4.0)
	phase = fmod(phase + speed * delta * 1.85, TAU)
	if visible: update_pose()

func update_pose():
	var sway: = Vector2(sin(phase) * 2.6, cos(phase * 2) * 1.7) * stride
	var tilt: = sin(phase) * 0.007 * stride
	if paper_rig.visible:
		place_grip(paper_rig, MAP_HAND, 0.71, true, sway, tilt, map_lift)
	if rig.visible and sprite.texture:
		place_grip(rig, sprite.texture, 0.53 if pose == "radio" else 0.43, false, sway + Vector2(-3, 5) * press, tilt + press * 0.032, lift)
	if pose == "radio": ptt.set_shader_parameter("squeeze", press)
	queue_redraw()

func place_grip(node: Node2D, texture: Texture2D, fraction: float, left: bool, sway: Vector2, angle: float, amount: float):
	var height: = size.y * fraction
	var factor: = height / texture.get_height()
	var extent: = texture.get_size() * factor
	var pivot: = extent * Vector2(0.55, 0.85)
	var x: float = -4.0 if left else size.x - extent.x + 3
	node.scale = Vector2.ONE * factor
	node.rotation = angle
	node.position = Vector2(x, size.y - height + size.y * 0.05) + sway + pivot - pivot.rotated(angle) + Vector2.DOWN * (1 - amount) * height

func _draw():
	if pose == "piece":
		draw_set_transform_matrix(rig.transform)
		var center: = Vector2(188, 145)
		draw_circle(center, 92, Color("#424846"))
		var phase4: = Time.get_ticks_msec() * 0.0006
		var corners: = PackedVector2Array()
		for i in 16:
			var x: = float((i & 1) * 2 - 1)
			var w: = float(((i >> 3) & 1) * 2 - 1)
			var z: = float(((i >> 2) & 1) * 2 - 1)
			var y: = float(((i >> 1) & 1) * 2 - 1)
			var depth: = 3.5 - w * cos(phase4) - x * sin(phase4)
			corners.append(center + Vector2(x * cos(phase4) - w * sin(phase4) + 0.38 * z, y + 0.35 * z) * 92 / depth)
		for i in 16:
			for bit in [1, 2, 4, 8]:
				if not (i & bit): draw_line(corners[i], corners[i | bit], Color("#d2c99c"), 2.5, true)
		return
	if pose == "radio":
		draw_radio_face()
	elif pose == "compass":
		draw_compass_face()

func draw_radio_face():
	draw_set_transform_matrix(rig.transform * Transform2D(-0.028, Vector2(110, 369)))
	draw_rect(Rect2(0, 0, 103, 43), Color("#2b2b28"))
	draw_rect(Rect2(4, 4, 94, 34), Color("#444a3d"))
	draw_rect(Rect2(4, 4, 94, 4), Color("#505649"))
	draw_rect(Rect2(4, 37, 94, 2), Color("#656152"))
	var lamp := Color("#c9723d") if press > 0.22 else Color("#655447")
	draw_circle(Vector2(20, 21), 5.1, Color("#2e2d27"), true, -1, true)
	draw_circle(Vector2(20, 20.5), 3.45, lamp, true, -1, true)
	if press > 0.22:
		draw_circle(Vector2(19, 19.5), 1.55, Color("#ffc281"), true, -1, true)
	draw_string(ThemeDB.fallback_font, Vector2(34, 29), "03", HORIZONTAL_ALIGNMENT_CENTER, 48.0, 25, Color("#d1c9a8"))
	draw_line(Vector2(11, 50), Vector2(50, 50), Color("#777061"), 1.7, true)
	draw_line(Vector2(13, 54), Vector2(36, 54), Color("#655f50"), 1.4, true)
	for x in [8.0, 83.0]:
		var screw := Vector2(x, 93)
		draw_circle(screw, 4.5, Color("#6b675c"), true, -1, true)
		draw_line(screw + Vector2(-2.0, 1.2), screw + Vector2(2.0, -1.2), Color("#38372f"), 1.5, true)

func compass_axis(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))

func draw_compass_face():
	draw_set_transform_matrix(rig.transform * Transform2D(0, Vector2(1.0, 0.77), 0, Vector2(188, 145)))
	var ink := Color("#534632")
	var subdued := Color("#ae9671")
	var brass := Color("#ab8550")
	var red := Color("#a03c30")
	draw_circle(Vector2.ZERO, 87.5, Color("#b7a280"), true, -1, true)
	draw_circle(Vector2.ZERO, 84.5, Color("#e0d0a7"), true, -1, true)
	draw_circle(Vector2.ZERO, 70.0, Color("#efe0b5"), true, -1, true)
	draw_circle(Vector2.ZERO, 65, subdued, false, 1.6, true)
	draw_circle(Vector2.ZERO, 51, Color("#c5b18a"), false, 1.2, true)
	for i in 48:
		var unit := compass_axis(TAU * i / 48.0)
		var length_px := 79.0 if i % 4 else 73.0
		draw_line(unit * length_px, unit * 83.0, ink, 1.35 if i % 4 else 2.0, true)
	draw_line(Vector2(0, -86), Vector2(0, -75), red, 3.3, true)

	for i in 4:
		var angle := PI / 2.0 * i - heading
		var center := compass_axis(angle) * 56.0
		var label: String = ["N", "E", "S", "O"][i]
		var font := ThemeDB.fallback_font
		var fs := 24 if i == 0 else 21
		var x := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, center + Vector2(-x * 0.5, fs * 0.34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, red if i == 0 else ink)
		var minor := compass_axis(angle + PI / 4.0)
		draw_circle(minor * 56, 1.8, subdued, true, -1, true)
	var north := compass_axis(-heading)
	var side := north.orthogonal() * 7.3
	var point := north * 44.0
	var tail := -north * 33.0
	draw_colored_polygon(PackedVector2Array([side + Vector2(1.5, 2.5), point + Vector2(1.5, 2.5), -side + Vector2(1.5, 2.5), tail + Vector2(1.5, 2.5)]), Color("#58452c54"))
	draw_colored_polygon(PackedVector2Array([side, point, Vector2.ZERO]), Color("#773128"))
	draw_colored_polygon(PackedVector2Array([-side, point, Vector2.ZERO]), Color("#b8533f"))
	draw_colored_polygon(PackedVector2Array([side, tail, Vector2.ZERO]), Color("#6d6a51"))
	draw_colored_polygon(PackedVector2Array([-side, tail, Vector2.ZERO]), Color("#959479"))
	draw_circle(Vector2.ZERO, 6.6, ink, true, -1, true)
	draw_circle(Vector2.ZERO, 4.8, brass, true, -1, true)
	draw_circle(Vector2(-1.2, -1.0), 1.6, Color("#e8c997"), true, -1, true)
	draw_arc(Vector2.ZERO, 80.5, -2.66, -2.02, 18, Color("#fff3cf7a"), 2.2, true)
