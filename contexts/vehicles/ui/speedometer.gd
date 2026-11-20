class_name Speedometer
extends CanvasLayer

const SHIFT_LIGHT_FRACTION := 0.92
const GEAR_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SHIFT_LIGHT_COLOR := Color(1.0, 0.2, 0.15, 1.0)
const LIGHT_ON_ALPHA := 1.0
const LIGHT_OFF_ALPHA := 0.2

@onready var _dial: TachometerDial = $Root/Dial
@onready var _speed: Label = $Root/Speed
@onready var _gear: Label = $Root/Gear
@onready var _mode: Label = $Root/Mode
@onready var _brake: Label = $Root/Handbrake


func set_rpm_scale(redline_rpm: float) -> void:
	_dial.redline_rpm = redline_rpm
	_dial.max_rpm = TachometerDial.dial_max_for(redline_rpm)


func update_hud(kmh: float, rpm: float, gear: String, handbrake: bool, manual: bool) -> void:
	_speed.text = str(roundi(kmh))
	_gear.text = gear
	_dial.target_rpm = rpm
	_gear.modulate = _gear_color(rpm)
	_mode.text = _mode_text(manual)
	_brake.modulate.a = LIGHT_OFF_ALPHA
	if handbrake:
		_brake.modulate.a = LIGHT_ON_ALPHA


func _gear_color(rpm: float) -> Color:
	var shift_light_rpm := _dial.redline_rpm * SHIFT_LIGHT_FRACTION
	if rpm >= shift_light_rpm:
		return SHIFT_LIGHT_COLOR
	return GEAR_COLOR


func _mode_text(manual: bool) -> String:
	if manual:
		return "MANUAL"
	return "AUTO"
