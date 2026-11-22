class_name MuzzleSmoke
extends RefCounted

const LIFETIME := 1.35
const PUFF_COUNT := 8
const QUAD_SIZE := 0.15
const NIGHT_GLOW := Color(0.14, 0.16, 0.20)
const DRIFT_GRAVITY := Vector3(0.08, 0.28, 0.04)
const CULL_BOX := AABB(Vector3(-6.0, -4.0, -6.0), Vector3(12.0, 10.0, 12.0))

static var _cached_material: StandardMaterial3D


static func create() -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.emitting = false
	emitter.one_shot = true
	emitter.explosiveness = 0.82
	emitter.amount = PUFF_COUNT
	emitter.lifetime = LIFETIME
	emitter.local_coords = false
	emitter.custom_aabb = CULL_BOX
	emitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emitter.emission_sphere_radius = 0.03
	emitter.direction = Vector3(0.0, 0.18, -1.0)
	emitter.spread = 32.0
	emitter.initial_velocity_min = 0.6
	emitter.initial_velocity_max = 2.2
	emitter.gravity = DRIFT_GRAVITY
	emitter.damping_min = 1.6
	emitter.damping_max = 2.8
	emitter.angle_min = -180.0
	emitter.angle_max = 180.0
	emitter.angular_velocity_min = -35.0
	emitter.angular_velocity_max = 35.0
	emitter.scale_amount_min = 0.7
	emitter.scale_amount_max = 1.35
	emitter.scale_amount_curve = _growth_curve()
	emitter.color_ramp = _fade_gradient()
	emitter.mesh = _build_quad()
	return emitter


static func _build_quad() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(QUAD_SIZE, QUAD_SIZE)
	quad.material = _material()
	return quad


static func _material() -> StandardMaterial3D:
	if _cached_material != null:
		return _cached_material
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = MuzzleSmokeTexture.get_texture()
	material.roughness = 1.0
	material.emission_enabled = true
	material.emission = NIGHT_GLOW
	material.disable_receive_shadows = true
	material.proximity_fade_enabled = true
	material.proximity_fade_distance = 0.12
	_cached_material = material
	return _cached_material


static func _growth_curve() -> Curve:
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.25))
	growth.add_point(Vector2(0.35, 0.9))
	growth.add_point(Vector2(1.0, 1.7))
	return growth


static func _fade_gradient() -> Gradient:
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.5, 1.0])
	fade.colors = PackedColorArray(
		[
			Color(0.75, 0.76, 0.78, 0.0),
			Color(0.72, 0.74, 0.78, 0.13),
			Color(0.55, 0.58, 0.62, 0.05),
			Color(0.48, 0.5, 0.56, 0.0),
		]
	)
	return fade
