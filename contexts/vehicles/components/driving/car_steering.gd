class_name CarSteering
extends RefCounted

const SLOW_RESPONSE_FRACTION := 0.4

var wheel_position := 0.0


static func wheel_angle(
	steering: float, max_angle: float, forward_speed: float, speed_for_half_angle: float
) -> float:
	var speed_reduction := 1.0 + absf(forward_speed) / speed_for_half_angle
	return steering * max_angle / speed_reduction


func smooth(
	steer_input: float, speed_ratio: float, response: float, return_rate: float, delta: float
) -> float:
	var slow_response := response * SLOW_RESPONSE_FRACTION
	var rate_toward_input := lerpf(response, slow_response, clampf(speed_ratio, 0.0, 1.0))
	var rate := rate_toward_input
	if _returning_to_center(steer_input):
		rate = return_rate
	wheel_position = move_toward(wheel_position, steer_input, rate * delta)
	return wheel_position


func _returning_to_center(steer_input: float) -> bool:
	if steer_input == 0.0:
		return true
	return signf(steer_input) != signf(wheel_position)
