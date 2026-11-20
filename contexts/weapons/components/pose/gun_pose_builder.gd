class_name GunPoseBuilder
extends RefCounted

const PISTOL_CHAMBER_TURN_END := 0.75


static func add_sight(pose: GunModelPose, model: Node3D, aim_amount: float) -> void:
	var sight_marker := GunSight.marker(model)
	if sight_marker == null:
		return
	var sight_position := GunSight.aligned_position(sight_marker, model.scale)
	var sight_rotation := GunSight.aligned_rotation(sight_marker)
	pose.blend_to(sight_position, sight_rotation, aim_amount)


static func add_ammo_check(
	pose: GunModelPose,
	model: Node3D,
	check_marker: Marker3D,
	check_amount: float,
	reload_turn: float,
	turns_pistol_first: bool
) -> void:
	if AmmoCheckPose.holds_magazine(check_marker):
		var held_offset := AmmoCheckPose.HELD_GUN_OFFSET * check_amount
		var held_turn := AmmoCheckPose.HELD_GUN_TURN * check_amount
		pose.add(held_offset, held_turn)
		return
	var turn := maxf(check_amount, reload_turn)
	if turns_pistol_first:
		turn = smoothstep(0.0, PISTOL_CHAMBER_TURN_END, turn)
	var check_position := AmmoCheckPose.gun_position(check_marker, model.scale)
	var check_basis := AmmoCheckPose.gun_basis(check_marker)
	pose.turn_to(check_position, check_basis, turn)
