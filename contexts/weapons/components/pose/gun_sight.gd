class_name GunSight
extends RefCounted

const MARKER_NAME := "AlinhamentoMira"


static func marker(model: Node3D) -> Marker3D:
	return model.get_node_or_null(MARKER_NAME) as Marker3D


static func aligned_position(sight_marker: Marker3D, model_scale: Vector3) -> Vector3:
	var sight_basis := sight_marker.basis.orthonormalized().inverse()
	var eye_point := sight_marker.position * model_scale
	return -(sight_basis * eye_point)


static func aligned_rotation(sight_marker: Marker3D) -> Vector3:
	var sight_basis := sight_marker.basis.orthonormalized().inverse()
	return sight_basis.get_euler()
