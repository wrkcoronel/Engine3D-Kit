class_name CarGrip
extends Node

const REST_SPEED := 0.15
const BURNOUT_MAX_SPEED := 2.0

@export var grip := 20.0
@export var corner_scrub := 0.25
@export var drift_grip := 2.5
@export var drift_grip_loss := 10.0
@export var drift_grip_recover := 2.5
@export var handbrake_decel := 8.0
@export var drift_full_speed := 12.0

var current := 20.0


static func is_burnout(throttle: float, handbraking: bool, grounded: bool, speed: float) -> bool:
	if not handbraking or not grounded:
		return false
	return throttle > 0.0 and speed < BURNOUT_MAX_SPEED


func drift_amount() -> float:
	return clampf(1.0 - current / grip, 0.0, 1.0)


func update(handbraking: bool, total_speed: float, delta: float) -> void:
	var grip_target := grip
	if handbraking:
		var speed_fraction := clampf(1.0 - total_speed / drift_full_speed, 0.0, 1.0)
		grip_target = lerpf(drift_grip, grip, speed_fraction)
	var grip_rate := drift_grip_loss if grip_target < current else drift_grip_recover
	current = lerpf(current, grip_target, 1.0 - exp(-grip_rate * delta))


func apply_to_velocity(
	forward_speed: float,
	sideways_speed: float,
	forward: Vector3,
	right: Vector3,
	grounded: bool,
	delta: float,
) -> Vector3:
	var remaining_sideways := sideways_speed
	if grounded:
		remaining_sideways = sideways_speed * exp(-current * delta)

	var sideways_removed := absf(sideways_speed) - absf(remaining_sideways)
	var speed_before_scrub := sqrt(forward_speed * forward_speed + sideways_speed * sideways_speed)
	var speed_after_scrub := maxf(speed_before_scrub - sideways_removed * corner_scrub, 0.0)
	var new_forward_speed := (
		signf(forward_speed)
		* sqrt(
			maxf(
				speed_after_scrub * speed_after_scrub - remaining_sideways * remaining_sideways, 0.0
			)
		)
	)
	return forward * new_forward_speed + right * remaining_sideways


func apply_handbrake_or_rest(
	velocity: Vector3, throttle: float, handbraking: bool, grounded: bool, delta: float
) -> Vector3:
	if is_burnout(throttle, handbraking, grounded, velocity.length()):
		return Vector3.ZERO
	if handbraking and grounded:
		return velocity.move_toward(Vector3.ZERO, handbrake_decel * delta)
	if throttle == 0.0 and velocity.length() < REST_SPEED and grounded:
		return Vector3.ZERO
	return velocity
