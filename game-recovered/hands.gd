extends Control

const RADIO = preload("res://equipo/radio.webp")
const PIECE = preload("res://equipo/pieza_sueno.webp")
const COMPASS = preload("res://equipo/brujula.webp")
const MAP_HAND = preload("res://equipo/mapa_mano.webp")
const MAP_GRIP = preload("res://pulgar_mapa.gdshader")
var mate_texture: Texture2D
var rig: = Node2D.new()
var sprite: = Sprite2D.new()
var paper_rig: = Node2D.new()
var paper_sprite: = Sprite2D.new()
var ptt: = ShaderMaterial.new()
var dream_bearing := ShaderMaterial.new()
var compass_finish := ShaderMaterial.new()
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
	var arm := ShaderMaterial.new()
	arm.shader = MAP_GRIP
	arm.set_shader_parameter("thumb_only", false)
	paper_sprite.material = arm
	paper_rig.hide()
	add_child(rig)
	rig.show_behind_parent = true
	rig.add_child(sprite)
	sprite.centered = false
	rig.hide()
	ptt.shader = preload("res://pulsador.gdshader")
	dream_bearing.shader = preload("res://pieza_sueno.gdshader")
	compass_finish.shader = preload("res://brujula_acabado.gdshader")
	hide()

func mount_map(sheet: Control):
	paper_rig.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sheet.size = Vector2(560, 330)

	sheet.position = Vector2(151, 10)
	sheet.scale = Vector2(1.14, 1.33)
	var thumb := Sprite2D.new()
	thumb.centered = false
	thumb.texture = MAP_HAND
	var cutout := ShaderMaterial.new()
	cutout.shader = MAP_GRIP
	thumb.material = cutout
	paper_rig.add_child(thumb)

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
	sprite.material = null
	match pose:
		"mate": sprite.texture = mate_texture
		"radio":
			sprite.texture = RADIO
			sprite.material = ptt
		"piece":
			sprite.texture = PIECE
			sprite.material = dream_bearing
		_:
			sprite.texture = COMPASS
			sprite.material = compass_finish
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
	press_motion.tween_interval(0.58)
	press_motion.tween_method(set_press, 1.0, 0.0, 0.2)

func set_press(value: float):
	press = value
	update_pose()

func set_piece_signal(value: float):
	dream_bearing.set_shader_parameter("bearing", value)

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
		var fit := size.x * 0.59 / maxf(size.y, 1.0) * MAP_HAND.get_height() / MAP_HAND.get_width()
		place_grip(paper_rig, MAP_HAND, minf(0.78, fit), true, sway, tilt, map_lift)
	if rig.visible and sprite.texture:
		var grip_height := 0.43
		match pose:
			"radio": grip_height = 0.53
			"piece":
				# The tesseract sprite has more space above the fingers than the compass.
				var width_fit := size.x * 0.44 / maxf(size.y, 1.0) * PIECE.get_height() / PIECE.get_width()
				grip_height = minf(0.63, width_fit)
		place_grip(rig, sprite.texture, grip_height, false, sway + Vector2(-3, 5) * press, tilt + press * 0.032, lift)
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
	if pose == "compass": draw_compass_face()

func draw_compass_face():
	draw_set_transform_matrix(rig.transform * Transform2D(0, Vector2(1.0, 0.77), 0, Vector2(188, 145)))
	var origin: = Vector2.ZERO
	var r: = 87.0
	var ink := Color("#453d31")
	var red := Color("#9c362c")
	draw_arc(origin, r * 0.97, 0.0, TAU, 64, Color("#8f7451a8"), 1.5, true)
	draw_arc(origin, r * 0.57, 0.0, TAU, 56, Color("#8c765347"), 1.0, true)
	for i in 32:
		var angle: = TAU * i / 32 - heading
		var unit: = Vector2(sin(angle), - cos(angle))
		var cardinal := i % 8 == 0
		var tick_start := 0.845 if cardinal else (0.885 if i % 4 == 0 else 0.94)
		draw_line(origin + unit * r * tick_start, origin + unit * r * 0.967, red if i == 0 else ink, 2.25 if cardinal else 1.15, true)
	for i in 4:
		var angle: = PI / 2 * i - heading
		var center: = origin + Vector2(sin(angle), - cos(angle)) * r * 0.74
		var label: String = ["N", "E", "S", "O"][i]
		var font: = ThemeDB.fallback_font
		var fs: = roundi(r * 0.32)
		draw_string(font, center + Vector2( - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / 2.0, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, red if i == 0 else ink)
	var north: = Vector2( - sin(heading), - cos(heading))
	var base: = north.orthogonal() * r * 0.13
	var tip := north * r * 0.63
	var tail := -north * r * 0.56
	draw_colored_polygon(PackedVector2Array([base, tip, -base]), red)
	draw_colored_polygon(PackedVector2Array([base, tail, -base]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip, base]), Color("#c2664b"))
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tail, -base]), Color("#6b6350"))
	draw_circle(origin, r * 0.076, Color("#765a3b"), true, -1.0, true)
	draw_circle(origin, r * 0.048, Color("#d8b978"), true, -1.0, true)
