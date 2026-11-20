class_name GunModelPose
extends RefCounted

var position := Vector3.ZERO
var rotation := Vector3.ZERO


func _init(start_position: Vector3, start_rotation: Vector3) -> void:
	position = start_position
	rotation = start_rotation


func blend_to(target_position: Vector3, target_rotation: Vector3, amount: float) -> void:
	position = position.lerp(target_position, amount)
	var pitch := lerp_angle(rotation.x, target_rotation.x, amount)
	var yaw := lerp_angle(rotation.y, target_rotation.y, amount)
	var roll := lerp_angle(rotation.z, target_rotation.z, amount)
	rotation = Vector3(pitch, yaw, roll)


func turn_to(target_position: Vector3, target_basis: Basis, amount: float) -> void:
	position = position.lerp(target_position, amount)
	var current_basis := Basis.from_euler(rotation)
	rotation = current_basis.slerp(target_basis, amount).get_euler()


func add(offset_position: Vector3, offset_rotation: Vector3) -> void:
	position += offset_position
	rotation += offset_rotation
