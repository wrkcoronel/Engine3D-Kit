class_name AmmoCheckPose
extends RefCounted

const CHECK_MARKER := "Conferencia"
const CHAMBER_MARKER := "ConferenciaCamara"
const MAGAZINE_NODE := "Carregador"
const TARGET_META := "alvo"
const PULL_META := "puxar_carregador"
const DEFAULT_TARGET := Vector3(0.05, -0.1, -0.3)
const HELD_GUN_OFFSET := Vector3(0.0, -0.05, 0.03)
const HELD_GUN_TURN := Vector3(-0.12, 0.12, 0.3)


static func marker(model: Node3D, checking_chamber: bool) -> Marker3D:
	if checking_chamber:
		var chamber_marker := model.find_child(CHAMBER_MARKER, true, false) as Marker3D
		if chamber_marker != null:
			return chamber_marker
	return model.find_child(CHECK_MARKER, true, false) as Marker3D


static func holds_magazine(check_marker: Marker3D) -> bool:
	return check_marker.get_parent().name == MAGAZINE_NODE


static func target(check_marker: Marker3D) -> Vector3:
	return check_marker.get_meta(TARGET_META, DEFAULT_TARGET)


static func magazine_pull(check_marker: Marker3D) -> Vector3:
	return check_marker.get_meta(PULL_META, Vector3.ZERO)


static func look_basis(check_marker: Marker3D) -> Basis:
	var toward_eye := target(check_marker).normalized()
	return Basis.looking_at(toward_eye, Vector3.UP)


static func gun_basis(check_marker: Marker3D) -> Basis:
	var marker_basis := check_marker.basis.orthonormalized()
	return look_basis(check_marker) * marker_basis.inverse()


static func gun_position(check_marker: Marker3D, model_scale: Vector3) -> Vector3:
	var marker_offset := gun_basis(check_marker) * (check_marker.position * model_scale)
	return target(check_marker) - marker_offset
