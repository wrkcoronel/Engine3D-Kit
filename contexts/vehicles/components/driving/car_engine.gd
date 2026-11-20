class_name CarEngine
extends Node

const REVERSE := -1
const FIRST := 1
const STOPPED_SPEED := 0.5
const RPM_PER_RADIAN_PER_SECOND := 60.0 / TAU
const TORQUE_FRACTION_AT_IDLE := 0.7
const TORQUE_FRACTION_AT_REDLINE := 0.8

@export var max_torque := 190.0
@export var idle_rpm := 900.0
@export var peak_torque_rpm := 4000.0
@export var redline_rpm := 6800.0
@export var launch_rpm := 2500.0
@export var gear_ratios: Array[float] = [3.45, 1.94, 1.29, 0.97, 0.80]
@export var reverse_ratio := 3.3
@export var final_drive := 3.9
@export var drivetrain_efficiency := 0.9
@export var shift_up_rpm := 6400.0
@export var shift_down_rpm := 2800.0
@export var shift_time := 0.25
@export var engine_brake_torque := 40.0

var gear := FIRST
var rpm := 900.0
var manual := false

var _shift_time_left := 0.0
var _forward_speed := 0.0
var _throttle := 0.0


static func torque_fraction_at(
	engine_rpm: float, idle: float, peak_torque: float, redline: float
) -> float:
	if engine_rpm > redline:
		return 0.0
	if engine_rpm <= peak_torque:
		var rise := clampf(inverse_lerp(idle, peak_torque, engine_rpm), 0.0, 1.0)
		return lerpf(TORQUE_FRACTION_AT_IDLE, 1.0, rise)
	var fall := inverse_lerp(peak_torque, redline, engine_rpm)
	return lerpf(1.0, TORQUE_FRACTION_AT_REDLINE, fall)


static func engine_rpm_for(wheel_speed: float, gear_and_final_ratio: float) -> float:
	var wheel_turn_speed := wheel_speed / CarSuspension.WHEEL_RADIUS
	return wheel_turn_speed * gear_and_final_ratio * RPM_PER_RADIAN_PER_SECOND


static func wheel_force_from(
	torque: float, gear_and_final_ratio: float, efficiency: float
) -> float:
	return torque * gear_and_final_ratio * efficiency / CarSuspension.WHEEL_RADIUS


func update(throttle: float, forward_speed: float, delta: float) -> void:
	_throttle = throttle
	_forward_speed = forward_speed
	if not manual:
		_choose_direction()
	_shift_time_left = maxf(_shift_time_left - delta, 0.0)
	rpm = _rpm_from_speed()
	if gear >= FIRST and not manual:
		_shift_automatically()


func handle_driver_shifts(wants_up: bool, wants_down: bool, wants_mode_change: bool) -> void:
	if wants_mode_change:
		manual = not manual
	if not manual:
		return
	if wants_up:
		_manual_shift_up()
	if wants_down:
		_manual_shift_down()


func wants_brake() -> bool:
	var standing_still := absf(_forward_speed) < STOPPED_SPEED
	if _throttle == 0.0:
		return standing_still
	if manual:
		return _throttle < 0.0
	if _throttle > 0.0:
		return _forward_speed < -STOPPED_SPEED
	return _forward_speed > STOPPED_SPEED


func drive_force() -> float:
	if _shift_time_left > 0.0:
		return 0.0
	if _throttle == 0.0:
		return _engine_braking_force()
	if _throttle < 0.0 and manual:
		return 0.0
	if not manual and _pushes_against_gear():
		return 0.0
	var torque_fraction := torque_fraction_at(rpm, idle_rpm, peak_torque_rpm, redline_rpm)
	var torque := max_torque * torque_fraction * absf(_throttle)
	var force := wheel_force_from(torque, total_ratio(), drivetrain_efficiency)
	if gear == REVERSE:
		return -force
	return force


func total_ratio() -> float:
	if gear == REVERSE:
		return reverse_ratio * final_drive
	return gear_ratios[gear - 1] * final_drive


func gear_text() -> String:
	if gear == REVERSE:
		return "R"
	var standing_still := absf(_forward_speed) < STOPPED_SPEED
	if standing_still and _throttle == 0.0 and not manual:
		return "N"
	return str(gear)


func _pushes_against_gear() -> bool:
	var pushing_forward_in_reverse := _throttle > 0.0 and gear == REVERSE
	var pushing_backward_in_gear := _throttle < 0.0 and gear >= FIRST
	return pushing_forward_in_reverse or pushing_backward_in_gear


func _manual_shift_up() -> void:
	if gear == REVERSE:
		gear = FIRST
		return
	if gear < gear_ratios.size():
		_shift_to(gear + 1)


func _manual_shift_down() -> void:
	if gear > FIRST:
		_shift_to(gear - 1)
		return
	var standing_still := absf(_forward_speed) < STOPPED_SPEED
	if gear == FIRST and standing_still:
		gear = REVERSE


func _choose_direction() -> void:
	var wants_reverse := _throttle < 0.0 and _forward_speed <= STOPPED_SPEED
	var wants_forward := _throttle > 0.0 and _forward_speed >= -STOPPED_SPEED
	if wants_reverse:
		gear = REVERSE
	if wants_forward and gear == REVERSE:
		gear = FIRST


func _rpm_from_speed() -> float:
	var rpm_from_wheels := engine_rpm_for(absf(_forward_speed), total_ratio())
	var lowest_rpm := idle_rpm
	if _throttle != 0.0:
		lowest_rpm = launch_rpm
	return maxf(rpm_from_wheels, lowest_rpm)


func _shift_automatically() -> void:
	var top_gear := gear_ratios.size()
	if rpm > shift_up_rpm and gear < top_gear:
		_shift_to(gear + 1)
		return
	if rpm < shift_down_rpm and gear > FIRST:
		_shift_to(gear - 1)


func _shift_to(new_gear: int) -> void:
	gear = new_gear
	_shift_time_left = shift_time
	rpm = _rpm_from_speed()


func _engine_braking_force() -> float:
	var rolling_forward := _forward_speed > STOPPED_SPEED and gear >= FIRST
	if not rolling_forward:
		return 0.0
	return -wheel_force_from(engine_brake_torque, total_ratio(), drivetrain_efficiency)
