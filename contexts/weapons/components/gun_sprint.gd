class_name GunSprint
extends Node

@export var offset := Vector3(-0.05, -0.05, 0.15)
@export var rotation_deg := Vector3(70.0, 15.0, 0.0)
@export var smooth := 10.0

var amount := 0.0


func update(delta: float, sprinting: bool) -> void:
	amount = lerpf(amount, 1.0 if sprinting else 0.0, 1.0 - exp(-smooth * delta))


func pos(k: float) -> Vector3:
	return offset * k


func rot(k: float) -> Vector3:
	return (
		Vector3(deg_to_rad(rotation_deg.x), deg_to_rad(rotation_deg.y), deg_to_rad(rotation_deg.z))
		* k
	)
