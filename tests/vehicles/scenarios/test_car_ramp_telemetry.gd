extends TestCase

const HUNDRED_KMH := 100.0 / 3.6
const FAST_KMH := 130.0 / 3.6
const EDGE_SPEED := 9.0
const FACING_PLUS_Z := 180.0
const FACING_MINUS_Z := 0.0
const SETTLE_TICKS := 30
const RAMP_TOP_HEIGHT := 5.0
const TICKS_IN_AIR_AFTER_TAKEOFF := 20


func test_ramp5_entrada_100kmh() -> void:
	var scenario := await _start(Vector3(100.0, 0.1, -200.0), FACING_PLUS_Z, HUNDRED_KMH)
	await _drive_until_ramp_takeoff(scenario, 480, HUNDRED_KMH)
	_assert_reached_ramp(scenario, "ramp5_entrada_100kmh", 100.0)
	_assert_telemetry_clean(scenario, "ramp5_entrada_100kmh")


func test_ramp5_entrada_130kmh() -> void:
	var scenario := await _start(Vector3(100.0, 0.1, -250.0), FACING_PLUS_Z, FAST_KMH)
	await _drive_until_ramp_takeoff(scenario, 520, FAST_KMH)
	_assert_reached_ramp(scenario, "ramp5_entrada_130kmh", 130.0)
	_assert_telemetry_clean(scenario, "ramp5_entrada_130kmh")


func test_ramp1_entrada_130kmh() -> void:
	var scenario := await _start(Vector3(20.0, 0.1, 55.0), FACING_MINUS_Z, FAST_KMH)
	await _drive_until_ramp_takeoff(scenario, 520, FAST_KMH)
	_assert_reached_ramp(scenario, "ramp1_entrada_130kmh", 130.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_130kmh")


func test_ramp1_entrada_100kmh() -> void:
	var scenario := await _start(Vector3(20.0, 0.1, 55.0), FACING_MINUS_Z, HUNDRED_KMH)
	await _drive_until_ramp_takeoff(scenario, 420, HUNDRED_KMH)
	_assert_reached_ramp(scenario, "ramp1_entrada_100kmh", 100.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_100kmh")


func test_ramp1_entrada_na_borda_x25() -> void:
	var scenario := await _start(Vector3(24.8, 0.1, 15.0), FACING_MINUS_Z, EDGE_SPEED)
	await scenario.drive(360, CarScenario.hold_speed(EDGE_SPEED))
	_assert_reached_ramp(scenario, "ramp1_entrada_na_borda_x25", 32.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_na_borda_x25")


func _drive_until_ramp_takeoff(scenario: CarScenario, max_ticks: int, speed: float) -> void:
	var ticks_flying_from_top := 0
	for tick: int in max_ticks:
		await scenario.drive(1, CarScenario.hold_speed(speed))
		var car := scenario.car
		var flying_from_top := car.global_position.y > RAMP_TOP_HEIGHT and not car.is_on_ground()
		ticks_flying_from_top += 1
		if not flying_from_top:
			ticks_flying_from_top = 0
		if ticks_flying_from_top >= TICKS_IN_AIR_AFTER_TAKEOFF:
			return


func _start(position: Vector3, yaw_degrees: float, start_speed: float) -> CarScenario:
	var scenario := CarScenario.new()
	scenario.start(self, position, yaw_degrees)
	await scenario.settle(SETTLE_TICKS)
	scenario.launch(start_speed)
	return scenario


func _assert_telemetry_clean(scenario: CarScenario, label: String) -> void:
	scenario.print_events(label)
	var bumps := scenario.events_containing("SOLAVANCO")
	var quick_losses := scenario.events_containing("PERDEU O CHAO RAPIDO")
	assert_eq(bumps.size(), 0, label + ": nenhum SOLAVANCO (salto vertical acima de 2 m/s)")
	assert_eq(quick_losses.size(), 0, label + ": nenhum PERDEU O CHAO RAPIDO")
	for sudden_stop: String in scenario.events_containing("FREOU DE REPENTE"):
		assert_true(sudden_stop.contains("Buildings/"), label + ": freada so batendo em predio")


func _assert_reached_ramp(scenario: CarScenario, label: String, target_kmh: float) -> void:
	var minimum_kmh := target_kmh * 0.9
	var message := label + ": chegou na rampa a pelo menos %.0f km/h" % minimum_kmh
	assert_true(scenario.ramp_touch_kmh >= minimum_kmh, message)
	print(label, ": tocou a rampa a %.0f km/h" % scenario.ramp_touch_kmh)
