class_name CarTilt
extends Node

@export var tilt_smooth_ground := 14.0
@export var tilt_smooth_air := 5.0


func update(delta: float, car: CharacterBody3D, visual: Node3D) -> void:
	var fwd := -car.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var up := Vector3.UP
	var nose := fwd
	var rate := tilt_smooth_air
	if car.is_on_floor():
		up = car.get_floor_normal()
		nose = (fwd - up * fwd.dot(up)).normalized()
		rate = tilt_smooth_ground
	else:
		var h := Vector2(car.velocity.x, car.velocity.z).length()
		if h > 2.0:
			nose = (fwd * h + Vector3.UP * car.velocity.y).normalized()
			up = (Vector3.UP - nose * Vector3.UP.dot(nose)).normalized()
	var z := -nose
	var target := Basis(up.cross(z), up, z).get_rotation_quaternion()
	var current := visual.global_basis.get_rotation_quaternion()
	visual.global_basis = Basis(current.slerp(target, 1.0 - exp(-rate * delta)))
