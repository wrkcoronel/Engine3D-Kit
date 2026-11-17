class_name CarBodyLean
extends Node

@export var pitch_per_acceleration_deg := 0.3
@export var roll_per_acceleration_deg := 0.4
@export var max_pitch_deg := 4.0
@export var max_roll_deg := 6.0
@export var spring_stiffness := 90.0
@export var spring_damping := 10.0
@export var landing_dip_per_fall_speed := 0.08
@export var max_landing_dip_speed := 1.6

var _pitch := SpringValue.new()
var _roll := SpringValue.new()
var _height := SpringValue.new()
var _last_velocity := Vector3.ZERO
var _rest_position := Vector3.ZERO


func setup(chassis: Node3D) -> void:
	_rest_position = chassis.position


func update(
	delta: float, car_velocity: Vector3, car_basis: Basis, grounded: bool, chassis: Node3D
) -> void:
	var acceleration := (car_velocity - _last_velocity) / delta
	_last_velocity = car_velocity
	var target_pitch := 0.0
	var target_roll := 0.0
	if grounded:
		var forward_acceleration := acceleration.dot(-car_basis.z)
		var sideways_acceleration := acceleration.dot(car_basis.x)
		var raw_pitch := forward_acceleration * pitch_per_acceleration_deg
		var raw_roll := sideways_acceleration * roll_per_acceleration_deg
		target_pitch = clampf(raw_pitch, -max_pitch_deg, max_pitch_deg)
		target_roll = clampf(raw_roll, -max_roll_deg, max_roll_deg)
	_pitch.step(target_pitch, spring_stiffness, spring_damping, delta)
	_roll.step(target_roll, spring_stiffness, spring_damping, delta)
	_height.step(0.0, spring_stiffness, spring_damping, delta)
	var pitch_angle := deg_to_rad(_pitch.value)
	var roll_angle := deg_to_rad(_roll.value)
	chassis.rotation = Vector3(pitch_angle, 0.0, roll_angle)
	chassis.position = _rest_position + Vector3.UP * _height.value


func land(fall_speed: float) -> void:
	var dip_speed := minf(fall_speed * landing_dip_per_fall_speed, max_landing_dip_speed)
	_height.speed -= maxf(dip_speed, 0.0)
