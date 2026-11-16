## COICE: cada tiro empurra a arma pra tras/cima e ela volta suave.
class_name GunRecoil
extends Node

@export var kick_position := Vector3(0.0, 0.01, 0.07)
@export var kick_rotation_deg := Vector3(4.0, 0.0, 0.0)
@export var recover := 14.0

var _kick := 0.0

func fire() -> void:
	_kick = 1.0

func update(delta: float) -> void:
	_kick = lerpf(_kick, 0.0, 1.0 - exp(-recover * delta))

func pos(steady: float) -> Vector3:
	return kick_position * _kick * steady

func rot(steady: float) -> Vector3:
	return Vector3(deg_to_rad(kick_rotation_deg.x), deg_to_rad(kick_rotation_deg.y), deg_to_rad(kick_rotation_deg.z)) * _kick * steady
