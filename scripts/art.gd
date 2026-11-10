class_name Art
extends RefCounted

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

static func shape(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = material(color, glow)
	parent.add_child(node)
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(parent, mesh, pos, color)

static func ball(parent: Node3D, pos: Vector3, radius: float, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	return shape(parent, mesh, pos, color, glow)

static func spike(parent: Node3D, pos: Vector3, size: float, color: Color, tilt: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = size * 0.32
	mesh.height = size
	mesh.radial_segments = 5
	var node := shape(parent, mesh, pos, color)
	node.rotation_degrees = tilt
	return node

static func ring(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.93
	mesh.outer_radius = radius
	mesh.rings = 24
	mesh.ring_segments = 6
	return shape(parent, mesh, pos, color, 1.0)
