class_name WeaponSpread
extends RefCounted


static func direction(
	aim_basis: Basis, spread: float, angle: float, radius_fraction: float
) -> Vector3:
	var deviation := sqrt(radius_fraction) * spread
	var forward := -aim_basis.z
	var sideways := aim_basis.x * cos(angle) * deviation
	var upward := aim_basis.y * sin(angle) * deviation
	return (forward + sideways + upward).normalized()


static func random_direction(aim_basis: Basis, spread: float) -> Vector3:
	var angle := randf() * TAU
	var radius_fraction := randf()
	return direction(aim_basis, spread, angle, radius_fraction)
