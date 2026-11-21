class_name TireSlipSmoke
extends RefCounted

const SLIP_SPEED := 3.0
const SLIP_SPEED_FOR_FULL_SMOKE := 8.0
const FULL_SMOKE_CAR_SPEED := 50.0
const BURNOUT_MAX_SPEED := 8.0
const HARD_BRAKE_WHEEL_SPEED := 20.0
const HARD_BRAKE_SPEED_FOR_FULL_SMOKE := 60.0
const HARD_BRAKE_MAX_SMOKE := 0.5
const HANDBRAKE_MIN_SPEED := 5.0
const HANDBRAKE_SMOKE := 0.7
const MIN_SMOKE_AT_LOW_SPEED := 0.3


static func slip_amount(
	grounded: bool,
	throttle: float,
	handbraking: bool,
	sideways_speed: float,
	forward_speed: float,
	total_speed: float
) -> float:
	if not grounded:
		return 0.0
	var side_slip := (absf(sideways_speed) - SLIP_SPEED) / SLIP_SPEED_FOR_FULL_SMOKE
	var amount := clampf(side_slip, 0.0, 1.0)
	if handbraking and total_speed > HANDBRAKE_MIN_SPEED:
		amount = maxf(amount, HANDBRAKE_SMOKE)
	var burnout := burnout_amount(grounded, throttle, handbraking, forward_speed, total_speed)
	amount = maxf(amount, burnout)
	var hard_braking := hard_braking_amount(throttle, forward_speed)
	return maxf(amount, hard_braking)


static func burnout_amount(
	grounded: bool, throttle: float, handbraking: bool, forward_speed: float, total_speed: float
) -> float:
	if not grounded:
		return 0.0
	if not handbraking:
		return 0.0
	var pushing_forward := throttle > 0.0
	var not_rolling_backward := forward_speed > -0.5
	var slow := total_speed < BURNOUT_MAX_SPEED
	if not pushing_forward or not not_rolling_backward or not slow:
		return 0.0
	var slowness := 1.0 - total_speed / BURNOUT_MAX_SPEED
	return 0.6 * slowness + 0.2


static func hard_braking_amount(throttle: float, forward_speed: float) -> float:
	var braking_while_rolling_backward := throttle > 0.0 and forward_speed < -HARD_BRAKE_WHEEL_SPEED
	var braking_while_rolling_forward := throttle < 0.0 and forward_speed > HARD_BRAKE_WHEEL_SPEED
	if not braking_while_rolling_backward and not braking_while_rolling_forward:
		return 0.0
	var excess_speed := absf(forward_speed) - HARD_BRAKE_WHEEL_SPEED
	var amount := excess_speed / HARD_BRAKE_SPEED_FOR_FULL_SMOKE
	return clampf(amount, 0.0, HARD_BRAKE_MAX_SMOKE)


static func speed_ratio(total_speed: float) -> float:
	return clampf(total_speed / FULL_SMOKE_CAR_SPEED, 0.0, 1.0)


static func visible_amount(slip: float, burnout: float, total_speed: float) -> float:
	var speed_scale := lerpf(MIN_SMOKE_AT_LOW_SPEED, 1.0, speed_ratio(total_speed))
	return maxf(slip * speed_scale, burnout)
