class_name FlashlightPose
extends RefCounted

const HAND_POSITION := Vector3(-0.2, -0.18, -0.3)
const SCOPE_POSITION := Vector3(-0.04, -0.07, -0.25)
const UNDER_BARREL_OFFSET := Vector3(0.0, -0.06, 0.12)
const LOWERED_OFFSET := Vector3(-0.05, -0.4, 0.1)
const LOWERED_TILT := Vector3(-1.0, 0.0, 0.0)


static func hand_pose(camera_transform: Transform3D) -> Transform3D:
	var in_camera_space := Transform3D(Basis.IDENTITY, HAND_POSITION)
	return camera_transform * in_camera_space


static func scope_pose(camera_transform: Transform3D) -> Transform3D:
	var in_camera_space := Transform3D(Basis.IDENTITY, SCOPE_POSITION)
	return camera_transform * in_camera_space


static func under_barrel_pose(
	weapon_transform: Transform3D, muzzle_position: Vector3
) -> Transform3D:
	var weapon_basis := weapon_transform.basis.orthonormalized()
	var muzzle_in_weapon_space := weapon_transform.affine_inverse() * muzzle_position
	var light_in_weapon_space := muzzle_in_weapon_space + UNDER_BARREL_OFFSET
	var light_position := weapon_transform * light_in_weapon_space
	return Transform3D(weapon_basis, light_position)


static func lowered_pose(pose_in_camera: Transform3D, lowered_amount: float) -> Transform3D:
	var tilt := Basis.from_euler(LOWERED_TILT * lowered_amount)
	var lowered_basis := tilt * pose_in_camera.basis
	var lowered_origin := pose_in_camera.origin + LOWERED_OFFSET * lowered_amount
	return Transform3D(lowered_basis, lowered_origin)
