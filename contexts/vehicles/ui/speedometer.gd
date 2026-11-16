## VELOCIMETRO (HUD): velocidade em km/h, barra de rotacao (RPM), marcha e luz do freio de mao.
## Quem manda os valores e o car.gd, chamando update_hud() enquanto o jogador dirige.
class_name Speedometer
extends CanvasLayer

const RPM_COLOR := Color(1.0, 0.85, 0.2)
const REDLINE_COLOR := Color(1.0, 0.15, 0.1)

@onready var _speed: Label = $Root/VBox/SpeedRow/Speed
@onready var _bar: ProgressBar = $Root/VBox/RpmBar
@onready var _gear: Label = $Root/VBox/InfoRow/Gear
@onready var _brake: Label = $Root/VBox/InfoRow/Handbrake
@onready var _fill: StyleBoxFlat = _bar.get_theme_stylebox("fill")

## kmh: velocidade. rpm: 0 a 1. gear: "N", "R", "1".."5". handbrake: luz acesa.
func update_hud(kmh: float, rpm: float, gear: String, handbrake: bool) -> void:
	_speed.text = str(roundi(kmh))
	_bar.value = rpm
	# a barra vai de amarelo ate vermelho perto do limite
	_fill.bg_color = RPM_COLOR.lerp(REDLINE_COLOR, clampf(inverse_lerp(0.7, 0.95, rpm), 0.0, 1.0))
	_gear.text = gear
	_brake.modulate.a = 1.0 if handbrake else 0.2
