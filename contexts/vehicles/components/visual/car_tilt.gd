class_name CarTilt
extends Node

const MIN_HORIZONTAL_SPEED_FOR_AIR_PITCH := 2.0

@export var tilt_smooth_ground := 14.0
@export var tilt_smooth_air := 5.0

var _was_on_floor := true


func update(delta: float, car: CharacterBody3D, visual: Node3D, ground_probe: GroundProbe) -> void:
	var forward := _flat_forward(car)
	var surface_up := Vector3.UP
	var nose := _air_nose(car, forward)
	var smoothing_rate := tilt_smooth_air
	var visual_height := 0.0
	if car.is_on_floor():
		surface_up = _grounded_up(car, ground_probe)
		nose = (forward - surface_up * forward.dot(surface_up)).normalized()
		smoothing_rate = tilt_smooth_ground
		visual_height = _grounded_visual_height(car, ground_probe)
	else:
		surface_up = _level_up(nose)
	var smoothing := 1.0 - exp(-smoothing_rate * delta)
	var just_landed := car.is_on_floor() and not _was_on_floor
	var ground_is_measured := car.is_on_floor() and ground_probe.found_ground
	if just_landed or ground_is_measured:
		smoothing = 1.0
	_was_on_floor = car.is_on_floor()
	visual.position.y = lerpf(visual.position.y, visual_height, smoothing)
	_apply_orientation(visual, surface_up, nose, smoothing)
	if car.is_on_floor():
		visual.position.y += ground_probe.required_lift(visual.global_transform)


func _flat_forward(car: CharacterBody3D) -> Vector3:
	var forward := -car.global_basis.z
	forward.y = 0.0
	return forward.normalized()


func _air_nose(car: CharacterBody3D, forward: Vector3) -> Vector3:
	var speed_along_forward := absf(car.velocity.dot(forward))
	if speed_along_forward <= MIN_HORIZONTAL_SPEED_FOR_AIR_PITCH:
		return forward
	var velocity_direction := forward * speed_along_forward + Vector3.UP * car.velocity.y
	return velocity_direction.normalized()


func _grounded_up(car: CharacterBody3D, ground_probe: GroundProbe) -> Vector3:
	if ground_probe.found_ground:
		return ground_probe.surface_normal
	return car.get_floor_normal()


func _grounded_visual_height(car: CharacterBody3D, ground_probe: GroundProbe) -> float:
	if not ground_probe.found_ground:
		return 0.0
	return ground_probe.center_height - car.global_position.y


func _apply_orientation(
	visual: Node3D, surface_up: Vector3, nose: Vector3, smoothing: float
) -> void:
	var backward := -nose
	var right := surface_up.cross(backward)
	var target := Basis(right, surface_up, backward).get_rotation_quaternion()
	var current := visual.global_basis.get_rotation_quaternion()
	visual.global_basis = Basis(current.slerp(target, smoothing))


func _level_up(nose: Vector3) -> Vector3:
	var up_along_nose := nose * Vector3.UP.dot(nose)
	return (Vector3.UP - up_along_nose).normalized()
