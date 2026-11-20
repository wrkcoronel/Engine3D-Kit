class_name GunCoverPeek
extends Node

@export var check_angle := 55.0
@export var smooth := 12.0

var amount := 0.0


func update(
	delta: float, body: CharacterBody3D, head: HeadLean, aiming: bool, wall_check_distance: float
) -> void:
	amount = lerpf(
		amount, _target(body, head, aiming, wall_check_distance), 1.0 - exp(-smooth * delta)
	)
	head.lean = amount


func _target(
	body: CharacterBody3D, head: HeadLean, aiming: bool, wall_check_distance: float
) -> float:
	if not aiming:
		return 0.0
	var world := body.get_world_3d()
	var fwd := -body.global_basis.z
	var right := body.global_basis.x
	var from := body.to_global(head.rest_position)
	var d0 := RayUtil.dist(world, from, fwd, wall_check_distance)
	if d0 < 0.0:
		return 0.0
	var angle := deg_to_rad(check_angle)
	var length := d0 / cos(angle) * 1.2 + 0.3
	var side_clear := head.lean_distance + 0.25
	for s: float in [1.0, -1.0]:
		var diag: Vector3 = fwd.rotated(Vector3.UP, -angle * s)
		if (
			RayUtil.dist(world, from, diag, length) < 0.0
			and RayUtil.dist(world, from, right * s, side_clear) < 0.0
		):
			return s
	return 0.0
