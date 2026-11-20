class_name Speedometer
extends CanvasLayer

const TEXT_FONT_EMBOLDEN := 0.4
const LIGHT_ON_ALPHA := 1.0
const LIGHT_OFF_ALPHA := 0.2

@onready var _bar: RpmBar = $Root/Bar
@onready var _readout: SpeedReadout = $Root/Readout
@onready var _unit: Label = $Root/Unit
@onready var _gear: GearBadge = $Root/Gear
@onready var _mode: Label = $Root/Mode
@onready var _brake: Label = $Root/Handbrake


func _ready() -> void:
	var italic_font := ItalicFont.create(TEXT_FONT_EMBOLDEN)
	_unit.add_theme_font_override("font", italic_font)


func set_rpm_scale(redline_rpm: float) -> void:
	_bar.redline_rpm = redline_rpm


func update_hud(kmh: float, rpm: float, gear: String, handbrake: bool, manual: bool) -> void:
	_readout.speed_kmh = roundi(kmh)
	_gear.gear_text = gear
	_gear.manual = manual
	_bar.target_rpm = rpm
	_mode.text = _mode_text(manual)
	_brake.modulate.a = LIGHT_OFF_ALPHA
	if handbrake:
		_brake.modulate.a = LIGHT_ON_ALPHA


func _mode_text(manual: bool) -> String:
	if manual:
		return "MANUAL"
	return "AUTO"
