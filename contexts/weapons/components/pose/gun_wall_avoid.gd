class_name GunWallAvoid
extends Node

@export var check_distance := 1.1
@export var min_distance := 0.45
@export var offset := Vector3(0.0, -0.1, 0.35)
@export var rotation_deg := Vector3(65.0, -15.0, 0.0)
@export var smooth := 12.0

var amount := 0.0


func update(delta: float, cam: Camera3D) -> void:
	amount = lerpf(amount, _closeness(cam), 1.0 - exp(-smooth * delta))


func pos(k: float) -> Vector3:
	return offset * k


func rot(k: float) -> Vector3:
	return (
		Vector3(deg_to_rad(rotation_deg.x), deg_to_rad(rotation_deg.y), deg_to_rad(rotation_deg.z))
		* k
	)


func _closeness(cam: Camera3D) -> float:
	var d := RayUtil.dist(
		cam.get_world_3d(), cam.global_position, -cam.global_basis.z, check_distance
	)
	if d < 0.0:
		return 0.0
	return clampf(inverse_lerp(check_distance, min_distance, d), 0.0, 1.0)
