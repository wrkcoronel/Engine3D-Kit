class_name CarWheels
extends Node

const WHEEL_RADIUS := CarSuspension.WHEEL_RADIUS
const BURNOUT_SURFACE_SPEED := 18.0

var _front_wheels: Array[Node3D] = []
var _rear_wheels: Array[Node3D] = []
var _rest_basis := Basis.IDENTITY
var _rest_positions: Array[Vector3] = []
var _front_rolled_angle := 0.0
var _rear_rolled_angle := 0.0


static func rolled_angle_after(angle: float, surface_speed: float, delta: float) -> float:
	var angular_speed := surface_speed / WHEEL_RADIUS
	var new_angle := angle + angular_speed * delta
	return wrapf(new_angle, -PI, PI)


func setup(wheel_parent: Node3D) -> void:
	_front_wheels = [
		wheel_parent.get_node("WheelFL") as Node3D, wheel_parent.get_node("WheelFR") as Node3D
	]
	_rear_wheels = [
		wheel_parent.get_node("WheelBL") as Node3D, wheel_parent.get_node("WheelBR") as Node3D
	]
	_rest_basis = _front_wheels[0].basis
	for wheel: Node3D in _all_wheels():
		_rest_positions.append(wheel.position)


func update(
	delta: float,
	forward_speed: float,
	steer_angle: float,
	rear_wheels_locked: bool,
	front_wheels_spinning: bool,
	center_heights: Array[float],
) -> void:
	var front_surface_speed := forward_speed
	if front_wheels_spinning:
		front_surface_speed = BURNOUT_SURFACE_SPEED
	var rear_surface_speed := forward_speed
	if rear_wheels_locked:
		rear_surface_speed = 0.0
	_front_rolled_angle = rolled_angle_after(_front_rolled_angle, front_surface_speed, delta)
	_rear_rolled_angle = rolled_angle_after(_rear_rolled_angle, rear_surface_speed, delta)
	for wheel: Node3D in _front_wheels:
		wheel.basis = _wheel_basis(steer_angle, _front_rolled_angle)
	for wheel: Node3D in _rear_wheels:
		wheel.basis = _wheel_basis(0.0, _rear_rolled_angle)
	_place_on_springs(center_heights)


func _place_on_springs(center_heights: Array[float]) -> void:
	var all_wheels := _all_wheels()
	for wheel_index: int in all_wheels.size():
		var rest_position := _rest_positions[wheel_index]
		var center_height := center_heights[wheel_index]
		all_wheels[wheel_index].position = Vector3(rest_position.x, center_height, rest_position.z)


func _all_wheels() -> Array[Node3D]:
	var all_wheels: Array[Node3D] = []
	all_wheels.append_array(_front_wheels)
	all_wheels.append_array(_rear_wheels)
	return all_wheels


func _wheel_basis(steer_angle: float, rolled_angle: float) -> Basis:
	var steer := Basis(Vector3.UP, steer_angle)
	var roll_forward := Basis(Vector3.RIGHT, -rolled_angle)
	return steer * roll_forward * _rest_basis
