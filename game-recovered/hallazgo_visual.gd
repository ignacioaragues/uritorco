extends RefCounted

static func glint(parent: Node3D, at: Vector3, tone: Color):
	var plane := QuadMesh.new()
	plane.size = Vector2(0.31, 0.31)
	var flare := MeshInstance3D.new()
	flare.mesh = plane
	var shine := ShaderMaterial.new()
	shine.shader = preload("res://destello_hallazgo.gdshader")
	shine.set_shader_parameter("glint", tone)
	shine.set_shader_parameter("phase", fposmod(parent.global_position.x, TAU))
	flare.material_override = shine
	flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(flare)
	flare.position = at
