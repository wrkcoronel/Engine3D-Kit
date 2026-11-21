class_name MuzzleSmoke
extends RefCounted

const LIFETIME := 1.1
const PUFF_COUNT := 6
const QUAD_SIZE := 0.12
const CULL_BOX := AABB(Vector3(-4.0, -4.0, -4.0), Vector3(8.0, 8.0, 8.0))


static func create() -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.emitting = false
	emitter.one_shot = true
	emitter.explosiveness = 0.9
	emitter.amount = PUFF_COUNT
	emitter.lifetime = LIFETIME
	emitter.local_coords = false
	emitter.custom_aabb = CULL_BOX
	emitter.direction = Vector3(0.0, 0.2, -1.0)
	emitter.spread = 25.0
	emitter.initial_velocity_min = 0.4
	emitter.initial_velocity_max = 1.1
	emitter.gravity = Vector3(0.0, 0.2, 0.0)
	emitter.damping_min = 0.8
	emitter.damping_max = 1.6
	emitter.scale_amount_min = 0.5
	emitter.scale_amount_max = 0.9
	emitter.scale_amount_curve = _growth_curve()
	emitter.color_ramp = _fade_gradient()
	emitter.mesh = _build_quad()
	return emitter


static func _build_quad() -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = MuzzleFlashTextures.puff()
	var quad := QuadMesh.new()
	quad.size = Vector2(QUAD_SIZE, QUAD_SIZE)
	quad.material = material
	return quad


static func _growth_curve() -> Curve:
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.4))
	growth.add_point(Vector2(1.0, 1.8))
	return growth


static func _fade_gradient() -> Gradient:
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 1.0])
	fade.colors = PackedColorArray(
		[
			Color(0.75, 0.75, 0.78, 0.0),
			Color(0.75, 0.75, 0.78, 0.22),
			Color(0.6, 0.6, 0.62, 0.0),
		]
	)
	return fade
