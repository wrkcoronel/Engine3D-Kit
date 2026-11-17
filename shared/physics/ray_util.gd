class_name RayUtil


static func dist(world: World3D, from: Vector3, dir: Vector3, length: float) -> float:
	var end_point: Vector3 = from + dir * length

	var query := PhysicsRayQueryParameters3D.create(from, end_point, 1)

	var hit: Dictionary = world.direct_space_state.intersect_ray(query)

	if hit.is_empty():
		return -1.0

	var impact_position: Vector3 = hit.position
	return from.distance_to(impact_position)
