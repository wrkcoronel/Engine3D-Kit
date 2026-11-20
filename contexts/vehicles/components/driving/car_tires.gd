class_name CarTires
extends Node

const LOW_SPEED_FOR_SLIP := 2.0

@export var peak_friction := 1.0
@export var sliding_friction := 0.7
@export var cornering_per_radian := 8.0
@export var rolling_resistance := 0.015


static func limit_to_friction(wanted_force: Vector2, max_force: float) -> Vector2:
	if wanted_force.length() <= max_force:
		return wanted_force
	return wanted_force.normalized() * max_force


static func force_to_stop(speed: float, mass_per_wheel: float, delta: float) -> float:
	return -speed * mass_per_wheel / delta


func force_on_ground(
	command: CarWheelCommand,
	forward_speed: float,
	sideways_speed: float,
	load: float,
	mass_per_wheel: float,
	delta: float,
) -> Vector2:
	if command.locked:
		return _locked_wheel_force(forward_speed, sideways_speed, load, mass_per_wheel, delta)
	var longitudinal := _longitudinal_force(command, forward_speed, load, mass_per_wheel, delta)
	var lateral := _lateral_force(forward_speed, sideways_speed, load, mass_per_wheel, delta)
	var wanted := Vector2(longitudinal, lateral)
	return limit_to_friction(wanted, peak_friction * load)


func is_slipping(
	command: CarWheelCommand, forward_speed: float, sideways_speed: float, load: float
) -> bool:
	if load <= 0.0:
		return false
	if command.locked:
		var sliding_velocity := Vector2(forward_speed, sideways_speed)
		return sliding_velocity.length() > LOW_SPEED_FOR_SLIP
	return absf(command.drive_force) > peak_friction * load


func _longitudinal_force(
	command: CarWheelCommand,
	forward_speed: float,
	load: float,
	mass_per_wheel: float,
	delta: float,
) -> float:
	var stop_force := force_to_stop(forward_speed, mass_per_wheel, delta)
	var rolling_limit := rolling_resistance * load
	var resistance_limit := command.brake_force + rolling_limit
	var resistance := clampf(stop_force, -resistance_limit, resistance_limit)
	return command.drive_force + resistance


func _lateral_force(
	forward_speed: float,
	sideways_speed: float,
	load: float,
	mass_per_wheel: float,
	delta: float,
) -> float:
	var slip_reference_speed := maxf(absf(forward_speed), LOW_SPEED_FOR_SLIP)
	var slip_angle := atan2(sideways_speed, slip_reference_speed)
	var grip_force := -slip_angle * cornering_per_radian * load
	var stop_force := force_to_stop(sideways_speed, mass_per_wheel, delta)
	var largest_useful_force := absf(stop_force)
	return clampf(grip_force, -largest_useful_force, largest_useful_force)


func _locked_wheel_force(
	forward_speed: float,
	sideways_speed: float,
	load: float,
	mass_per_wheel: float,
	delta: float,
) -> Vector2:
	var stop_forward := force_to_stop(forward_speed, mass_per_wheel, delta)
	var stop_sideways := force_to_stop(sideways_speed, mass_per_wheel, delta)
	var stop_sliding := Vector2(stop_forward, stop_sideways)
	return limit_to_friction(stop_sliding, sliding_friction * load)
