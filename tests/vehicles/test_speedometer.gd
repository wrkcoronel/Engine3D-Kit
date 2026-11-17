extends TestCase

const MAX_SPEED := 138.9
const REVERSE_MAX_SPEED := 12.0
const GEAR_PATH := "Root/VBox/InfoRow/Gear"
const SPEED_PATH := "Root/VBox/SpeedRow/Speed"
const HANDBRAKE_PATH := "Root/VBox/InfoRow/Handbrake"


func test_neutral_when_stopped() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 0.0, 1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "N", "parado fica em neutro")


func test_neutral_below_minimum_speed() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 0.4, 1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "N", "abaixo de 0.5 m/s ainda e neutro")


func test_reverse_when_moving_backwards() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 5.0, -1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "R", "andando de re mostra R")


func test_first_gear_at_low_speed() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 10.0, 1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "1", "10 m/s e primeira marcha")


func test_third_gear_at_mid_speed() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 60.0, 1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "3", "60 m/s e terceira marcha")


func test_last_gear_at_top_speed() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, MAX_SPEED, 1.0, false)
	assert_eq(_label(speedometer, GEAR_PATH), "5", "velocidade maxima nao passa da quinta")


func test_shows_speed_in_kmh() -> void:
	var speedometer := _make_speedometer()
	_drive(speedometer, 10.0, 1.0, false)
	assert_eq(_label(speedometer, SPEED_PATH), "36", "10 m/s = 36 km/h")


func test_handbrake_light_turns_on_and_off() -> void:
	var speedometer := _make_speedometer()
	var light := speedometer.get_node(HANDBRAKE_PATH) as Label
	_drive(speedometer, 10.0, 1.0, true)
	assert_eq(light.modulate.a, 1.0, "luz acesa com o freio de mao")
	_drive(speedometer, 10.0, 1.0, false)
	assert_near(light.modulate.a, 0.2, 0.001, "luz apagada sem o freio de mao")


func _make_speedometer() -> Speedometer:
	var scene := load("res://contexts/vehicles/ui/speedometer.tscn") as PackedScene
	var speedometer := scene.instantiate() as Speedometer
	spawn(speedometer)
	return speedometer


func _drive(speedometer: Speedometer, speed: float, move_sign: float, handbrake: bool) -> void:
	speedometer.update_drive(0.1, speed, move_sign, handbrake, MAX_SPEED, REVERSE_MAX_SPEED)


func _label(speedometer: Speedometer, path: String) -> String:
	return (speedometer.get_node(path) as Label).text
