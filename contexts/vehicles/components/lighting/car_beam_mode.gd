class_name CarBeamMode
extends RefCounted

enum Mode { OFF, LOW, HIGH }


static func next(mode: Mode) -> Mode:
	if mode == Mode.OFF:
		return Mode.LOW
	if mode == Mode.LOW:
		return Mode.HIGH
	return Mode.OFF


static func label(mode: Mode) -> String:
	if mode == Mode.LOW:
		return "farol baixo"
	if mode == Mode.HIGH:
		return "farol alto"
	return "farois desligados"


static func spot_energy(mode: Mode) -> float:
	if mode == Mode.LOW:
		return 16.0
	if mode == Mode.HIGH:
		return 30.0
	return 0.0


static func spot_range(mode: Mode) -> float:
	if mode == Mode.HIGH:
		return 65.0
	return 35.0


static func spot_angle_degrees(mode: Mode) -> float:
	if mode == Mode.HIGH:
		return 24.0
	return 34.0


static func pitch_degrees(mode: Mode) -> float:
	if mode == Mode.HIGH:
		return -0.5
	return -3.5


static func lens_glow(mode: Mode) -> float:
	if mode == Mode.LOW:
		return 2.0
	if mode == Mode.HIGH:
		return 4.0
	return 0.05
