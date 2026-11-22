class_name GunCoverPeek
extends Node

@export var check_angle := 55.0
@export var smooth := 12.0

var amount := 0.0


func update(delta: float, rig: PlayerRig, aiming: bool, wall_check_distance: float) -> void:
	var target := _target(rig, aiming, wall_check_distance)
	amount = lerpf(amount, target, 1.0 - exp(-smooth * delta))
	rig.lean = amount


func _target(rig: PlayerRig, aiming: bool, wall_check_distance: float) -> float:
	if not aiming:
		return 0.0
	if rig.body == null:
		return 0.0
	var body := rig.body
	var world := body.get_world_3d()
	var fwd := -body.global_basis.z
	var right := body.global_basis.x
	var from := body.to_global(rig.eye_rest_position)
	var d0 := RayUtil.dist(world, from, fwd, wall_check_distance)
	if d0 < 0.0:
		return 0.0
	var angle := deg_to_rad(check_angle)
	var length := d0 / cos(angle) * 1.2 + 0.3
	var side_clear := rig.lean_distance + 0.25
	for s: float in [1.0, -1.0]:
		var diag: Vector3 = fwd.rotated(Vector3.UP, -angle * s)
		if (
			RayUtil.dist(world, from, diag, length) < 0.0
			and RayUtil.dist(world, from, right * s, side_clear) < 0.0
		):
			return s
	return 0.0
