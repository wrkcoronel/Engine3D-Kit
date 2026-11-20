class_name GunAim
extends Node

@export var fov := 55.0
@export var smooth := 14.0
@export var stability := 0.7

var amount := 0.0
var _hip_fov := 0.0


func update(delta: float, cam: Camera3D, wants_aim: bool) -> void:
	if _hip_fov == 0.0:
		_hip_fov = cam.fov
	amount = lerpf(amount, 1.0 if wants_aim else 0.0, 1.0 - exp(-smooth * delta))
	cam.fov = lerpf(_hip_fov, fov, amount)


func reset() -> void:
	amount = 0.0


func steady() -> float:
	return 1.0 - stability * amount
