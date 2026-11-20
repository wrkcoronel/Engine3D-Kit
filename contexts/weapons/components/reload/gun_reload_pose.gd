class_name GunReloadPose
extends RefCounted

var offset := Vector3.ZERO
var rotation := Vector3.ZERO
var turn := 0.0


func clear() -> void:
	offset = Vector3.ZERO
	rotation = Vector3.ZERO
	turn = 0.0
