class_name CarSkidMarks
extends RefCounted

const START_AMOUNT := 0.25
const STEP_LENGTH := 0.4
const MARK_WIDTH := 0.35
const MARK_HEIGHT := 0.3
const MARK_LENGTH_OVERLAP := 1.25
const MARK_LIFT := 0.02
const MAX_MARKS := 400
const MAX_SEGMENT_LENGTH := 4.0
const RAY_LIFT := 0.5
const RAY_LENGTH := 1.5
const WORLD_LAYER_MASK := 1
const MARK_COLOR := Color(0.02, 0.02, 0.02)

var _car_body: PhysicsBody3D
var _root: Node3D
var _texture: GradientTexture2D
var _decals: Array[Decal] = []
var _next_decal_index := 0
var _last_points: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _has_last_point: Array[bool] = [false, false]


func setup(host: Node, car_body: PhysicsBody3D) -> void:
	_car_body = car_body
	_texture = _build_texture()
	_root = Node3D.new()
	_root.top_level = true
	host.add_child(_root)


func update(
	wheel_positions: Array[Vector3], amount: float, space_state: PhysicsDirectSpaceState3D
) -> void:
	var marking := amount > START_AMOUNT
	for wheel_index: int in wheel_positions.size():
		if not marking:
			_has_last_point[wheel_index] = false
			continue
		_mark_wheel(wheel_index, wheel_positions[wheel_index], amount, space_state)


func _mark_wheel(
	wheel_index: int, wheel_position: Vector3, amount: float, space_state: PhysicsDirectSpaceState3D
) -> void:
	var hit := _ground_below(wheel_position, space_state)
	if hit.is_empty():
		_has_last_point[wheel_index] = false
		return
	var hit_point := hit["position"] as Vector3
	var surface_normal := hit["normal"] as Vector3
	if not _has_last_point[wheel_index]:
		_last_points[wheel_index] = hit_point
		_has_last_point[wheel_index] = true
		return
	var last_point := _last_points[wheel_index]
	var segment := hit_point - last_point
	var segment_length := segment.length()
	if segment_length > MAX_SEGMENT_LENGTH:
		_last_points[wheel_index] = hit_point
		return
	if segment_length < STEP_LENGTH:
		return
	_place_mark(last_point, hit_point, surface_normal, amount)
	_last_points[wheel_index] = hit_point


func _ground_below(wheel_position: Vector3, space_state: PhysicsDirectSpaceState3D) -> Dictionary:
	var ray_start := wheel_position + Vector3.UP * RAY_LIFT
	var ray_end := ray_start + Vector3.DOWN * RAY_LENGTH
	var excluded: Array[RID] = [_car_body.get_rid()]
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, WORLD_LAYER_MASK, excluded)
	return space_state.intersect_ray(query)


func _place_mark(
	last_point: Vector3, hit_point: Vector3, surface_normal: Vector3, amount: float
) -> void:
	var segment := hit_point - last_point
	var along_surface := segment - surface_normal * segment.dot(surface_normal)
	var direction := along_surface.normalized()
	var side_direction := surface_normal.cross(direction)
	var decal := _next_decal()
	decal.size = Vector3(MARK_WIDTH, MARK_HEIGHT, segment.length() * MARK_LENGTH_OVERLAP)
	decal.modulate = Color(1.0, 1.0, 1.0, lerpf(0.45, 0.95, amount))
	var mark_basis := Basis(side_direction, surface_normal, direction)
	var midpoint := (hit_point + last_point) / 2.0 + surface_normal * MARK_LIFT
	decal.global_transform = Transform3D(mark_basis, midpoint)


func _next_decal() -> Decal:
	if _decals.size() < MAX_MARKS:
		var decal := Decal.new()
		decal.texture_albedo = _texture
		decal.cull_mask = WORLD_LAYER_MASK
		_root.add_child(decal)
		_decals.append(decal)
		return decal
	_next_decal_index = (_next_decal_index + 1) % MAX_MARKS
	return _decals[_next_decal_index]


func _build_texture() -> GradientTexture2D:
	var fade := Gradient.new()
	var transparent := Color(MARK_COLOR, 0.0)
	var opaque := Color(MARK_COLOR, 1.0)
	fade.colors = PackedColorArray([transparent, opaque, transparent])
	fade.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.width = 32
	texture.height = 8
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.0)
	return texture
