class_name EntityRelocator
extends RefCounted

const MIN_SPAWN_DISTANCE := 12.0
const MAX_SPAWN_DISTANCE := 25.0
const MAX_ATTEMPTS := 24


static func pick_spot(
	target_position: Vector3,
	target_forward: Vector3,
	prefer_behind: bool,
	bounds: Rect2,
	random: RandomNumberGenerator
) -> Vector3:
	var flat_forward := Vector3(target_forward.x, 0.0, target_forward.z)
	if flat_forward.length_squared() < 0.001:
		flat_forward = Vector3.FORWARD
	flat_forward = flat_forward.normalized()
	var base_angle := atan2(flat_forward.x, flat_forward.z)
	if prefer_behind:
		base_angle += PI

	var fallback := target_position - flat_forward * MIN_SPAWN_DISTANCE
	fallback.y = 0.0

	for attempt: int in range(MAX_ATTEMPTS):
		var spread := deg_to_rad(105.0)
		if not prefer_behind:
			spread = deg_to_rad(70.0)
		var angle := base_angle + random.randf_range(-spread, spread)
		var distance := random.randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
		var candidate := Vector3(
			target_position.x + sin(angle) * distance,
			0.0,
			target_position.z + cos(angle) * distance
		)
		if _inside_bounds(candidate, bounds):
			return candidate
	return _clamp_to_bounds(fallback, bounds)


static func _inside_bounds(point: Vector3, bounds: Rect2) -> bool:
	if not bounds.has_area():
		return true
	return bounds.has_point(Vector2(point.x, point.z))


static func _clamp_to_bounds(point: Vector3, bounds: Rect2) -> Vector3:
	if not bounds.has_area():
		return point
	var clamped_x := clampf(point.x, bounds.position.x + 2.0, bounds.end.x - 2.0)
	var clamped_z := clampf(point.z, bounds.position.y + 2.0, bounds.end.y - 2.0)
	return Vector3(clamped_x, 0.0, clamped_z)
