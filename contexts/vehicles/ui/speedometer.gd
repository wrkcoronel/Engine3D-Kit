class_name Speedometer
extends CanvasLayer

const RPM_COLOR := Color(1.0, 0.85, 0.2)
const REDLINE_COLOR := Color(1.0, 0.15, 0.1)

@export var speedo_scale := 3.6
@export var gears := 5

var _rpm := 0.0

@onready var _speed: Label = $Root/VBox/SpeedRow/Speed
@onready var _bar: ProgressBar = $Root/VBox/RpmBar
@onready var _gear: Label = $Root/VBox/InfoRow/Gear
@onready var _brake: Label = $Root/VBox/InfoRow/Handbrake
@onready var _fill: StyleBoxFlat = _bar.get_theme_stylebox("fill")


func update_drive(
	delta: float,
	speed: float,
	move_sign: float,
	handbrake: bool,
	max_speed: float,
	reverse_max_speed: float,
) -> void:
	var gear := "N"
	var target_rpm := 0.15
	if speed >= 0.5:
		if move_sign < 0.0:
			gear = "R"
			target_rpm = 0.2 + 0.6 * clampf(speed / reverse_max_speed, 0.0, 1.0)
		else:
			var g := clampi(int(speed / max_speed * gears) + 1, 1, gears)
			var within := clampf(speed / max_speed * gears - (g - 1), 0.0, 1.0)
			gear = str(g)
			target_rpm = 0.35 + 0.65 * within
	_rpm = lerpf(_rpm, target_rpm, 1.0 - exp(-12.0 * delta))
	update_hud(speed * speedo_scale, _rpm, gear, handbrake)


func update_hud(kmh: float, rpm: float, gear: String, handbrake: bool) -> void:
	_speed.text = str(roundi(kmh))
	_bar.value = rpm
	_fill.bg_color = RPM_COLOR.lerp(REDLINE_COLOR, clampf(inverse_lerp(0.7, 0.95, rpm), 0.0, 1.0))
	_gear.text = gear
	_brake.modulate.a = 1.0 if handbrake else 0.2
