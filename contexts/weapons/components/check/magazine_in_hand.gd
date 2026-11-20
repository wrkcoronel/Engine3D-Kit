class_name MagazineInHand
extends RefCounted

const MAGAZINE_MARKER_PATH := "Visual/Carregador/Conferencia"


static func place(
	model: Node3D,
	magazine: Node3D,
	magazine_rest: Vector3,
	check_marker: Marker3D,
	camera_transform: Transform3D,
	amount: float
) -> void:
	var seated_local := Transform3D(Basis.IDENTITY, magazine_rest)
	if not AmmoCheckPose.holds_magazine(check_marker):
		if model.has_node(MAGAZINE_MARKER_PATH):
			magazine.transform = seated_local
		return
	if amount <= 0.0:
		magazine.transform = seated_local
		return
	var parent := magazine.get_parent() as Node3D
	var seated := parent.global_transform * seated_local
	var pull := AmmoCheckPose.magazine_pull(check_marker)
	var pulled_out := parent.global_transform * seated_local.translated(pull)
	var at_face := _at_face(check_marker, camera_transform)
	var drop := smoothstep(0.0, 0.3, amount)
	var bring_to_face := smoothstep(0.25, 1.0, amount)
	var dropped := seated.interpolate_with(pulled_out, drop)
	magazine.global_transform = dropped.interpolate_with(at_face, bring_to_face)


static func _at_face(check_marker: Marker3D, camera_transform: Transform3D) -> Transform3D:
	var look := AmmoCheckPose.look_basis(check_marker)
	var face_spot := Transform3D(look, AmmoCheckPose.target(check_marker))
	return camera_transform * face_spot * check_marker.transform.affine_inverse()
