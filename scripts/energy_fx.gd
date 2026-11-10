class_name EnergyFX
extends RefCounted

static func particles(parent: Node3D, tint: Color, radius: float, amount: int = 32) -> CPUParticles3D:
	var effect := CPUParticles3D.new()
	effect.amount = amount
	effect.lifetime = 0.7
	effect.preprocess = 0.2
	effect.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = radius
	effect.direction = Vector3.UP
	effect.spread = 25
	effect.initial_velocity_min = 1.0
	effect.initial_velocity_max = 3.0
	effect.gravity = Vector3(0, 0.5, 0)
	effect.scale_amount_min = 0.07
	effect.scale_amount_max = 0.24
	var quad := QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = preload("res://assets/vfx/energy.svg")
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false
	quad.material = material
	effect.mesh = quad
	var gradient := Gradient.new()
	gradient.set_color(0, Color(tint, 0.0))
	gradient.add_point(0.15, tint)
	gradient.set_color(1, Color(tint, 0.0))
	effect.color_ramp = gradient
	parent.add_child(effect)
	return effect

static func aura_material(tint: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/aura.gdshader")
	material.set_shader_parameter("energy_color", tint)
	return material
