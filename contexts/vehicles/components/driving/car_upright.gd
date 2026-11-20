class_name CarUpright
extends RefCounted

const MIN_UP_ALIGNMENT := 0.5
const LIFT := 1.0
const MAX_SPEED := 3.0


static func is_flipped(car_basis: Basis) -> bool:
	var up_alignment := car_basis.y.dot(Vector3.UP)
	return up_alignment < MIN_UP_ALIGNMENT


static func can_upright(car_basis: Basis, speed: float) -> bool:
	if speed > MAX_SPEED:
		return false
	return is_flipped(car_basis)


static func flat_transform(car_transform: Transform3D) -> Transform3D:
	var forward := _flat_forward(car_transform.basis)
	var flat_basis := Basis.looking_at(forward, Vector3.UP)
	return Transform3D(flat_basis, car_transform.origin)


static func upright_transform(car_transform: Transform3D) -> Transform3D:
	var standing := flat_transform(car_transform)
	standing.origin += Vector3.UP * LIFT
	return standing


static func _flat_forward(car_basis: Basis) -> Vector3:
	var forward := -car_basis.z
	forward.y = 0.0
	if forward.length() > 0.01:
		return forward.normalized()
	var forward_from_roof := car_basis.y
	forward_from_roof.y = 0.0
	if forward_from_roof.length() > 0.01:
		return forward_from_roof.normalized()
	return Vector3.FORWARD
