class_name SmokeEmitters
extends RefCounted

const TIRE_LIFETIME := 2.6
const EXHAUST_LIFETIME := 1.6
const TIRE_QUAD_SIZE := 1.4
const EXHAUST_QUAD_SIZE := 0.5
const SMOKE_RISE := 0.25
const NIGHT_GLOW := Color(0.3, 0.33, 0.42)
const CULL_BOX := AABB(Vector3(-30.0, -5.0, -30.0), Vector3(60.0, 40.0, 60.0))
const EXHAUST_RISE := 0.1


static func create_material(puff_texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = puff_texture
	material.roughness = 1.0
	material.emission_enabled = true
	material.emission = NIGHT_GLOW
	material.disable_receive_shadows = true
	material.proximity_fade_enabled = true
	material.proximity_fade_distance = 0.2
	return material


static func create_tire_smoke(
	material: StandardMaterial3D, wind_velocity: Vector3
) -> CPUParticles3D:
	var emitter := _base_emitter(material, TIRE_QUAD_SIZE, wind_velocity, SMOKE_RISE)
	emitter.amount = 110
	emitter.lifetime = TIRE_LIFETIME
	emitter.direction = Vector3.UP
	emitter.spread = 35.0
	emitter.initial_velocity_min = 0.5
	emitter.initial_velocity_max = 1.8
	emitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emitter.emission_sphere_radius = 0.18
	emitter.scale_amount_curve = _growth_curve(0.35, 2.4)
	emitter.color_ramp = _fade_gradient(0.5)
	return emitter


static func create_exhaust_smoke(
	material: StandardMaterial3D, wind_velocity: Vector3
) -> CPUParticles3D:
	var emitter := _base_emitter(material, EXHAUST_QUAD_SIZE, wind_velocity, EXHAUST_RISE)
	emitter.amount = 40
	emitter.lifetime = EXHAUST_LIFETIME
	emitter.direction = Vector3(0.0, 0.15, 1.0)
	emitter.spread = 10.0
	emitter.initial_velocity_min = 0.6
	emitter.initial_velocity_max = 1.2
	emitter.scale_amount_curve = _growth_curve(0.2, 1.1)
	emitter.color_ramp = _fade_gradient(0.25)
	return emitter


static func _base_emitter(
	material: StandardMaterial3D, quad_size: float, wind_velocity: Vector3, rise: float
) -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.emitting = false
	emitter.custom_aabb = CULL_BOX
	emitter.local_coords = false
	emitter.gravity = Vector3(wind_velocity.x, rise, wind_velocity.z)
	emitter.damping_min = 0.9
	emitter.damping_max = 1.4
	emitter.angle_min = -180.0
	emitter.angle_max = 180.0
	emitter.angular_velocity_min = -25.0
	emitter.angular_velocity_max = 25.0
	emitter.scale_amount_min = 0.8
	emitter.scale_amount_max = 1.6
	var quad := QuadMesh.new()
	quad.size = Vector2(quad_size, quad_size)
	quad.material = material
	emitter.mesh = quad
	return emitter


static func _growth_curve(start_scale: float, end_scale: float) -> Curve:
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, start_scale))
	growth.add_point(Vector2(1.0, end_scale))
	return growth


static func _fade_gradient(peak_alpha: float) -> Gradient:
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.12, 1.0])
	fade.colors = PackedColorArray(
		[
			Color(0.62, 0.64, 0.68, 0.0),
			Color(0.7, 0.72, 0.76, peak_alpha),
			Color(0.5, 0.52, 0.56, 0.0),
		]
	)
	return fade
