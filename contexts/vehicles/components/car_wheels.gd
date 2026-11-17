class_name CarWheels
extends Node

const WHEEL_RADIUS := 0.4
const BURNOUT_SURFACE_SPEED := 18.0

var _front_wheels: Array[Node3D] = []
var _rear_wheels: Array[Node3D] = []
var _rest_basis := Basis.IDENTITY
var _front_rolled_angle := 0.0
var _rear_rolled_angle := 0.0


static func rolled_angle_after(angle: float, surface_speed: float, delta: float) -> float:
	var angular_speed := surface_speed / WHEEL_RADIUS
	var new_angle := angle + angular_speed * delta
	return wrapf(new_angle, -PI, PI)


func setup(visual: Node3D) -> void:
	_front_wheels = [visual.get_node("WheelFL") as Node3D, visual.get_node("WheelFR") as Node3D]
	_rear_wheels = [visual.get_node("WheelBL") as Node3D, visual.get_node("WheelBR") as Node3D]
	_rest_basis = _front_wheels[0].basis


func update(
	delta: float,
	forward_speed: float,
	steer_angle: float,
	rear_wheels_locked: bool,
	burning_out: bool,
) -> void:
	var rear_surface_speed := forward_speed
	if rear_wheels_locked:
		rear_surface_speed = 0.0
	if burning_out:
		rear_surface_speed = BURNOUT_SURFACE_SPEED
	_front_rolled_angle = rolled_angle_after(_front_rolled_angle, forward_speed, delta)
	_rear_rolled_angle = rolled_angle_after(_rear_rolled_angle, rear_surface_speed, delta)
	for wheel: Node3D in _front_wheels:
		wheel.basis = _wheel_basis(steer_angle, _front_rolled_angle)
	for wheel: Node3D in _rear_wheels:
		wheel.basis = _wheel_basis(0.0, _rear_rolled_angle)


func _wheel_basis(steer_angle: float, rolled_angle: float) -> Basis:
	var steer := Basis(Vector3.UP, steer_angle)
	var roll_forward := Basis(Vector3.RIGHT, -rolled_angle)
	return steer * roll_forward * _rest_basis
