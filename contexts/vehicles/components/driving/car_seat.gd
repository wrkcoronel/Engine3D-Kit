class_name CarSeat
extends RefCounted

const PLAYER_GROUP := "player"
const EXIT_SIDE_DISTANCE := 2.2
const EXIT_LIFT := 0.3


static func find_player_near(
	tree: SceneTree, car_position: Vector3, enter_distance: float
) -> CharacterBody3D:
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as CharacterBody3D
	if player == null:
		return null
	if car_position.distance_to(player.global_position) > enter_distance:
		return null
	return player


static func hide_player(player: CharacterBody3D) -> void:
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	player.get_node("Collision").set_deferred("disabled", true)


static func place_player_beside(player: CharacterBody3D, car_transform: Transform3D) -> void:
	var left_side := -car_transform.basis.x * EXIT_SIDE_DISTANCE
	player.global_position = car_transform.origin + left_side + Vector3.UP * EXIT_LIFT
	player.rotation.y = car_transform.basis.get_euler().y
	player.velocity = Vector3.ZERO
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.visible = true
	player.get_node("Collision").set_deferred("disabled", false)
	(player.get_node("Head/Camera") as Camera3D).make_current()
