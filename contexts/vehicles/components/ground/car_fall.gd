class_name CarFall
extends RefCounted

const MAX_FALL_SPEED := 45.0


static func limited_vertical_speed(vertical_speed: float, real_vertical_speed: float) -> float:
	var falling := vertical_speed < 0.0
	if not falling:
		return vertical_speed
	var downward_speed_moved := minf(real_vertical_speed, 0.0)
	var speed_actually_moved := maxf(vertical_speed, downward_speed_moved)
	return maxf(speed_actually_moved, -MAX_FALL_SPEED)
