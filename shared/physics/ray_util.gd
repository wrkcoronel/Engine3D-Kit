## Utilitario: raio de fisica reutilizado pela parede e pelo cover.
class_name RayUtil

## Distancia ate o primeiro hit (so na layer 1 = mundo), ou -1 se nao bateu em nada.
static func dist(world: World3D, from: Vector3, dir: Vector3, length: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * length, 1)
	var hit := world.direct_space_state.intersect_ray(query)
	return -1.0 if hit.is_empty() else from.distance_to(hit.position)
