class_name CarTireFx
extends Node

@export var smoke_slip_speed := 3.0
@export var skid_step := 0.4
@export var skid_width := 0.35
@export var max_skid_marks := 400
@export var smoke_full_speed := 50.0

var _car: CharacterBody3D
var _smoke: Array[CPUParticles3D] = []
var _skid_root: Node3D
var _skid_tex: GradientTexture2D
var _skid_decals: Array[Decal] = []
var _skid_next := 0
var _skid_last: Array = [null, null]


func setup(car: CharacterBody3D, visual: Node3D) -> void:
	_car = car
	for c in visual.get_children():
		var mesh := c as MeshInstance3D
		if mesh:
			mesh.layers = 2
	_smoke = [
		_make_tire_smoke(visual, Vector3(-1.05, 0.1, 1.3)),
		_make_tire_smoke(visual, Vector3(1.05, 0.1, 1.3)),
	]


func update(
	grounded: bool,
	throttle: float,
	handbraking: bool,
	lat: float,
	fs0: float,
	total: float,
) -> void:
	var smoke := 0.0
	var burnout_smoke := 0.0
	if grounded:
		smoke = clampf((absf(lat) - smoke_slip_speed) / 8.0, 0.0, 1.0)
		if handbraking and total > 5.0:
			smoke = maxf(smoke, 0.7)
		var accelerating_from_low_speed := throttle > 0.0 and fs0 > -0.5 and total < 8.0
		var burnout := handbraking and accelerating_from_low_speed
		if burnout:
			burnout_smoke = 0.6 * (1.0 - total / 8.0) + 0.2
			smoke = maxf(smoke, burnout_smoke)
		var hard_braking := (throttle > 0.0 and fs0 < -20.0) or (throttle < 0.0 and fs0 > 20.0)
		if hard_braking:
			smoke = maxf(smoke, clampf((absf(fs0) - 20.0) / 60.0, 0.0, 0.5))
	_update_skids(smoke)
	var speed_k := clampf(total / smoke_full_speed, 0.0, 1.0)
	smoke *= lerpf(0.3, 1.0, speed_k)
	smoke = maxf(smoke, burnout_smoke)
	for s in _smoke:
		s.emitting = smoke > 0.06
		s.color = Color(1.0, 1.0, 1.0, lerpf(0.3, 1.0, smoke))
		s.scale_amount_min = lerpf(0.6, 1.8, smoke)
		s.scale_amount_max = lerpf(1.0, 3.0, smoke)
		s.speed_scale = lerpf(0.9, 2.4, speed_k)
		s.initial_velocity_max = lerpf(1.2, 4.0, speed_k)


func _make_tire_smoke(visual: Node3D, pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.emitting = false
	p.amount = 120
	p.lifetime = 1.4
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0.0, 0.6, 0.0)
	p.damping_min = 0.5
	p.damping_max = 1.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.8))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.85, 0.85, 0.85, 0.55), Color(0.6, 0.6, 0.6, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = fade
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var soft := Gradient.new()
	soft.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	soft.offsets = PackedFloat32Array([0.0, 1.0])
	tex.gradient = soft
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	quad.material = mat
	p.mesh = quad
	visual.add_child(p)
	return p


func _update_skids(amount: float) -> void:
	var marking := amount > 0.25
	var space := _car.get_world_3d().direct_space_state
	for i in _smoke.size():
		if not marking:
			_skid_last[i] = null
			continue
		var from := _smoke[i].global_position + Vector3.UP * 0.5
		var query := PhysicsRayQueryParameters3D.create(
			from, from + Vector3.DOWN * 1.5, 1, [_car.get_rid()]
		)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			_skid_last[i] = null
			continue
		var p: Vector3 = hit.position
		var n: Vector3 = hit.normal
		if _skid_last[i] == null:
			_skid_last[i] = p
			continue
		var last: Vector3 = _skid_last[i]
		var seg := p - last
		var seg_len := seg.length()
		if seg_len > 4.0:
			_skid_last[i] = p
			continue
		if seg_len < skid_step:
			continue
		var dir := (seg - n * seg.dot(n)).normalized()
		var d := _next_skid_decal()
		d.size = Vector3(skid_width, 0.3, seg_len * 1.25)
		d.modulate = Color(1.0, 1.0, 1.0, lerpf(0.45, 0.95, amount))
		d.global_transform = Transform3D(Basis(n.cross(dir), n, dir), (p + last) * 0.5 + n * 0.02)
		_skid_last[i] = p


func _next_skid_decal() -> Decal:
	if _skid_root == null:
		_skid_root = Node3D.new()
		_skid_root.top_level = true
		add_child(_skid_root)
		var fade := Gradient.new()
		fade.colors = PackedColorArray(
			[
				Color(0.02, 0.02, 0.02, 0.0),
				Color(0.02, 0.02, 0.02, 1.0),
				Color(0.02, 0.02, 0.02, 0.0),
			]
		)
		fade.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		_skid_tex = GradientTexture2D.new()
		_skid_tex.gradient = fade
		_skid_tex.width = 32
		_skid_tex.height = 8
		_skid_tex.fill_from = Vector2(0.0, 0.0)
		_skid_tex.fill_to = Vector2(1.0, 0.0)
	if _skid_decals.size() < max_skid_marks:
		var d := Decal.new()
		d.texture_albedo = _skid_tex
		d.cull_mask = 1
		_skid_root.add_child(d)
		_skid_decals.append(d)
		return d
	_skid_next = (_skid_next + 1) % max_skid_marks
	return _skid_decals[_skid_next]
