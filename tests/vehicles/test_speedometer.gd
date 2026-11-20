extends TestCase

const REDLINE_RPM := 6800.0


func test_shows_speed_in_kmh() -> void:
	var speedometer := _make_speedometer()
	speedometer.update_hud(36.4, 2000.0, "2", false, false)
	var readout := speedometer.get_node("Root/Readout") as SpeedReadout
	assert_eq(readout.speed_kmh, 36, "mostra a velocidade arredondada")


func test_shows_gear_and_mode() -> void:
	var speedometer := _make_speedometer()
	speedometer.update_hud(50.0, 3000.0, "3", false, true)
	assert_eq(_label(speedometer, "Root/Mode").text, "MANUAL", "mostra que o cambio e manual")
	speedometer.update_hud(50.0, 3000.0, "3", false, false)
	assert_eq(_label(speedometer, "Root/Mode").text, "AUTO", "mostra que o cambio e automatico")


func test_gear_badge_follows_gear_and_mode() -> void:
	var speedometer := _make_speedometer()
	var badge := speedometer.get_node("Root/Gear") as GearBadge
	speedometer.update_hud(50.0, 3000.0, "3", false, true)
	assert_eq(badge.gear_text, "3", "a caixa mostra a marcha")
	assert_eq(badge.manual, true, "a caixa sabe que o cambio e manual")
	speedometer.update_hud(50.0, 3000.0, "3", false, false)
	assert_eq(badge.manual, false, "a caixa sabe que o cambio e automatico")


func test_handbrake_light_turns_on_and_off() -> void:
	var speedometer := _make_speedometer()
	var light := _label(speedometer, "Root/Handbrake")
	speedometer.update_hud(10.0, 2000.0, "1", true, false)
	assert_eq(light.modulate.a, Speedometer.LIGHT_ON_ALPHA, "luz acesa com o freio de mao")
	speedometer.update_hud(10.0, 2000.0, "1", false, false)
	var off_alpha := Speedometer.LIGHT_OFF_ALPHA
	assert_near(light.modulate.a, off_alpha, 0.001, "luz apagada sem o freio de mao")


func test_bar_follows_the_engine_rpm_and_redline() -> void:
	var speedometer := _make_speedometer()
	speedometer.update_hud(120.0, 3500.0, "4", false, false)
	var bar := speedometer.get_node("Root/Bar") as RpmBar
	assert_eq(bar.target_rpm, 3500.0, "a barra mira no rpm do motor")
	assert_eq(bar.redline_rpm, REDLINE_RPM, "a barra termina no corte do motor")


func test_readout_pads_speed_with_dim_zeros() -> void:
	assert_eq(SpeedReadout.padding_text(77), "0", "77 ganha um zero apagado")
	assert_eq(SpeedReadout.shown_text(77), "77", "77 aparece aceso")
	assert_eq(SpeedReadout.padding_text(0), "00", "zero ganha dois zeros apagados")
	assert_eq(SpeedReadout.shown_text(0), "0", "o ultimo zero fica aceso")
	assert_eq(SpeedReadout.padding_text(250), "", "tres digitos nao tem zero apagado")
	assert_eq(SpeedReadout.shown_text(1500), "999", "o painel nao passa de 999")


func _make_speedometer() -> Speedometer:
	var scene := load("res://contexts/vehicles/ui/speedometer.tscn") as PackedScene
	var speedometer := scene.instantiate() as Speedometer
	spawn(speedometer)
	speedometer.set_rpm_scale(REDLINE_RPM)
	return speedometer


func _label(speedometer: Speedometer, path: String) -> Label:
	return speedometer.get_node(path) as Label
