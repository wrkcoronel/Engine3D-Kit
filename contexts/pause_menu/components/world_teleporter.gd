class_name WorldTeleporter
extends RefCounted

const RAMPS_GROUP := "ramps"
const MOTELS_GROUP := "motels"
const VEHICLES_GROUP := "vehicles"
const RAMP_APPROACH_DISTANCE := 20.0
const BRING_CAR_DISTANCE := 5.0
const GO_TO_CAR_SIDE_DISTANCE := 3.0
const PLAYER_GROUND_HEIGHT := 1.0
const VEHICLE_GROUND_HEIGHT := 0.2
const MOTEL_PLAYER_OFFSET := Vector3(0.5, 1.0, 4.5)
const MOTEL_VEHICLE_OFFSET := Vector3(4.5, 0.2, 7.0)


static func ramp_target_transform(ramp_transform: Transform3D, for_vehicle: bool) -> Transform3D:
	var flat_basis := _flat_basis(ramp_transform.basis)
	var approach_offset := flat_basis.z * RAMP_APPROACH_DISTANCE
	var height := PLAYER_GROUND_HEIGHT
	if for_vehicle:
		height = VEHICLE_GROUND_HEIGHT
	var target_origin := ramp_transform.origin + approach_offset + Vector3.UP * height
	return Transform3D(flat_basis, target_origin)


static func motel_target_transform(motel_transform: Transform3D, for_vehicle: bool) -> Transform3D:
	var flat_basis := _flat_basis(motel_transform.basis)
	var local_offset := MOTEL_PLAYER_OFFSET
	if for_vehicle:
		local_offset = MOTEL_VEHICLE_OFFSET
	var target_origin := motel_transform.origin + flat_basis * local_offset
	return Transform3D(flat_basis, target_origin)


static func bring_car_target_transform(player_transform: Transform3D) -> Transform3D:
	var flat_basis := _flat_basis(player_transform.basis)
	var forward_offset := -flat_basis.z * BRING_CAR_DISTANCE
	var target_origin := Vector3(
		player_transform.origin.x + forward_offset.x,
		VEHICLE_GROUND_HEIGHT,
		player_transform.origin.z + forward_offset.z
	)
	return Transform3D(flat_basis, target_origin)


static func go_to_car_target_transform(car_transform: Transform3D) -> Transform3D:
	var flat_basis := _flat_basis(car_transform.basis)
	var side_offset := -flat_basis.x * GO_TO_CAR_SIDE_DISTANCE
	var target_origin := Vector3(
		car_transform.origin.x + side_offset.x,
		PLAYER_GROUND_HEIGHT,
		car_transform.origin.z + side_offset.z
	)
	return Transform3D(flat_basis, target_origin)


static func teleport_to_ramp(tree: SceneTree) -> bool:
	var ramp := _first_node_3d(tree, RAMPS_GROUP)
	if ramp == null:
		return false
	var player_target := ramp_target_transform(ramp.global_transform, false)
	var vehicle_target := ramp_target_transform(ramp.global_transform, true)
	return _apply_teleport(tree, player_target, vehicle_target)


static func teleport_to_motel(tree: SceneTree) -> bool:
	var motel := _first_node_3d(tree, MOTELS_GROUP)
	if motel == null:
		return false
	var player_target := motel_target_transform(motel.global_transform, false)
	var vehicle_target := motel_target_transform(motel.global_transform, true)
	return _apply_teleport(tree, player_target, vehicle_target)


static func bring_car_to_player(tree: SceneTree) -> bool:
	var vehicle := _first_node_3d(tree, VEHICLES_GROUP)
	if vehicle == null or not vehicle.has_method("teleport_to"):
		return false
	if _vehicle_has_driver(vehicle):
		return true
	var rig := PlayerRig.find(tree)
	if rig == null or not rig.is_ready():
		return false
	var target := bring_car_target_transform(rig.body.global_transform)
	vehicle.call("teleport_to", target)
	return true


static func teleport_player_to_car(tree: SceneTree) -> bool:
	var vehicle := _first_node_3d(tree, VEHICLES_GROUP)
	if vehicle == null:
		return false
	if _vehicle_has_driver(vehicle):
		return true
	var rig := PlayerRig.find(tree)
	if rig == null or not rig.is_ready():
		return false
	var target := go_to_car_target_transform(vehicle.global_transform)
	rig.body.global_transform = target
	rig.body.velocity = Vector3.ZERO
	rig.body.reset_physics_interpolation()
	return true


static func _apply_teleport(
	tree: SceneTree, player_target: Transform3D, vehicle_target: Transform3D
) -> bool:
	var active_vehicle := _find_active_vehicle(tree)
	if active_vehicle != null:
		active_vehicle.call("teleport_to", vehicle_target)
		return true
	var rig := PlayerRig.find(tree)
	if rig == null:
		return false
	if not rig.is_ready():
		return false
	rig.body.global_transform = player_target
	rig.body.velocity = Vector3.ZERO
	rig.body.reset_physics_interpolation()
	return true


static func _find_active_vehicle(tree: SceneTree) -> Node:
	if tree == null:
		return null
	var vehicles := tree.get_nodes_in_group(VEHICLES_GROUP)
	for vehicle: Node in vehicles:
		if not vehicle.has_method("has_driver"):
			continue
		if not vehicle.has_method("teleport_to"):
			continue
		var driving: bool = vehicle.call("has_driver")
		if driving:
			return vehicle
	return null


static func _vehicle_has_driver(vehicle: Node) -> bool:
	if not vehicle.has_method("has_driver"):
		return false
	var driving: bool = vehicle.call("has_driver")
	return driving


static func _first_node_3d(tree: SceneTree, group_name: String) -> Node3D:
	if tree == null:
		return null
	return tree.get_first_node_in_group(group_name) as Node3D


static func _flat_basis(source_basis: Basis) -> Basis:
	var yaw := source_basis.get_euler().y
	return Basis(Vector3.UP, yaw)
