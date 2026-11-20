extends TestCase

const REDLINE_RPM := 6800.0


func test_shows_speed_in_kmh() -> void:
	var speedometer := _make_speedometer()
	speedometer.update_hud(36.4, 2000.0, "2", false, false)
	assert_eq(_label(speedometer, "Root/Speed").text, "36", "mostra a velocidade arredondada")


func test_shows_gear_and_mode() -> void:
	var speedometer := _make_speedometer()
	speedometer.update_hud(50.0, 3000.0, "3", false, true)
	assert_eq(_label(speedometer, "Root/Gear").text, "3", "mostra a marcha")
	assert_eq(_label(speedometer, "Root/Mode").text, "MANUAL", "mostra que o cambio e manual")
	speedometer.update_hud(50.0, 3000.0, "3", false, false)
	assert_eq(_label(speedometer, "Root/Mode").text, "AUTO", "mostra que o cambio e automatico")


func test_gear_turns_red_near_redline() -> void:
	var speedometer := _make_speedometer()
	var gear := _label(speedometer, "Root/Gear")
	speedometer.update_hud(50.0, 3000.0, "3", false, true)
	assert_eq(gear.modulate, Speedometer.GEAR_COLOR, "longe do corte a marcha fica branca")
	speedometer.update_hud(50.0, REDLINE_RPM, "3", false, true)
	assert_eq(gear.modulate, Speedometer.SHIFT_LIGHT_COLOR, "no corte a marcha acende: troque")


func test_handbrake_light_turns_on_and_off() -> void:
	var speedometer := _make_speedometer()
	var light := _label(speedometer, "Root/Handbrake")
	speedometer.update_hud(10.0, 2000.0, "1", true, false)
	assert_eq(light.modulate.a, Speedometer.LIGHT_ON_ALPHA, "luz acesa com o freio de mao")
	speedometer.update_hud(10.0, 2000.0, "1", false, false)
	var off_alpha := Speedometer.LIGHT_OFF_ALPHA
	assert_near(light.modulate.a, off_alpha, 0.001, "luz apagada sem o freio de mao")


func test_dial_goes_one_number_past_redline() -> void:
	assert_eq(TachometerDial.dial_max_for(REDLINE_RPM), 8000.0, "corte em 6800, mostrador ate 8")


func test_needle_angle_covers_three_quarters_of_a_turn() -> void:
	var start := TachometerDial.angle_for(0.0)
	var end := TachometerDial.angle_for(1.0)
	assert_near(end - start, deg_to_rad(270.0), 0.0001, "o ponteiro anda 270 graus")


func _make_speedometer() -> Speedometer:
	var scene := load("res://contexts/vehicles/ui/speedometer.tscn") as PackedScene
	var speedometer := scene.instantiate() as Speedometer
	spawn(speedometer)
	speedometer.set_rpm_scale(REDLINE_RPM)
	return speedometer


func _label(speedometer: Speedometer, path: String) -> Label:
	return speedometer.get_node(path) as Label
