class_name CarSeat
extends RefCounted

const EXIT_SIDE_DISTANCE := 2.2
const EXIT_LIFT := 0.3


static func find_player_near(
	tree: SceneTree, car_position: Vector3, enter_distance: float
) -> PlayerRig:
	var rig := PlayerRig.find(tree)
	if rig == null:
		return null
	if not rig.is_ready():
		return null
	if car_position.distance_to(rig.body.global_position) > enter_distance:
		return null
	return rig


static func hide_player(rig: PlayerRig) -> void:
	rig.body.process_mode = Node.PROCESS_MODE_DISABLED
	rig.body.visible = false
	rig.collision.set_deferred("disabled", true)


static func place_player_beside(rig: PlayerRig, car_transform: Transform3D) -> void:
	var body := rig.body
	var left_side := -car_transform.basis.x * EXIT_SIDE_DISTANCE
	body.global_position = car_transform.origin + left_side + Vector3.UP * EXIT_LIFT
	body.rotation.y = car_transform.basis.get_euler().y
	body.velocity = Vector3.ZERO
	body.process_mode = Node.PROCESS_MODE_INHERIT
	body.visible = true
	rig.collision.set_deferred("disabled", false)
	rig.camera.make_current()
