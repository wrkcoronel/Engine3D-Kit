extends TestCase

const HUNDRED_KMH := 100.0 / 3.6
const FAST_KMH := 130.0 / 3.6
const CRAWL_SPEED := 1.0
const FACING_PLUS_Z := 180.0
const FACING_MINUS_Z := 0.0
const DIAGONAL_PLUS_X_UPHILL_RAMP5 := -130.0
const DIAGONAL_PLUS_X_UPHILL_RAMP1 := -50.0
const SETTLE_TICKS := 30
const MAX_EDGE_SLIDE_SECONDS := 1.0
const MAX_VISUAL_TURN_PER_FRAME_DEGREES := 3.0


func test_ramp5_entrada_100kmh() -> void:
	var scenario := await _start(Vector3(100.0, 0.1, -200.0), FACING_PLUS_Z)
	await scenario.drive(480, CarScenario.hold_speed(HUNDRED_KMH))
	_assert_reached_ramp(scenario, "ramp5_entrada_100kmh", 100.0)
	_assert_telemetry_clean(scenario, "ramp5_entrada_100kmh")


func test_ramp5_entrada_130kmh() -> void:
	var scenario := await _start(Vector3(100.0, 0.1, -250.0), FACING_PLUS_Z)
	await scenario.drive(520, CarScenario.hold_speed(FAST_KMH))
	_assert_reached_ramp(scenario, "ramp5_entrada_130kmh", 130.0)
	_assert_telemetry_clean(scenario, "ramp5_entrada_130kmh")


func test_ramp1_entrada_130kmh() -> void:
	var scenario := await _start(Vector3(20.0, 0.1, 58.0), FACING_MINUS_Z)
	await scenario.drive(520, CarScenario.hold_speed(FAST_KMH))
	_assert_reached_ramp(scenario, "ramp1_entrada_130kmh", 130.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_130kmh")


func test_ramp1_entrada_100kmh() -> void:
	var scenario := await _start(Vector3(20.0, 0.1, 60.0), FACING_MINUS_Z)
	await scenario.drive(420, CarScenario.hold_speed(HUNDRED_KMH))
	_assert_reached_ramp(scenario, "ramp1_entrada_100kmh", 100.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_100kmh")


func test_ramp1_entrada_na_borda_x25() -> void:
	var scenario := await _start(Vector3(24.8, 0.1, 15.0), FACING_MINUS_Z)
	await scenario.drive(360, CarScenario.hold_speed(9.0))
	_assert_reached_ramp(scenario, "ramp1_entrada_na_borda_x25", 32.0)
	_assert_telemetry_clean(scenario, "ramp1_entrada_na_borda_x25")


func test_ramp5_borda_x105_devagar() -> void:
	var scenario := await _start(Vector3(103.5, 2.3, -114.0), DIAGONAL_PLUS_X_UPHILL_RAMP5)
	await scenario.drive(420, CarScenario.hold_speed(CRAWL_SPEED))
	_assert_telemetry_clean(scenario, "ramp5_borda_x105_devagar")
	_assert_falls_smoothly(scenario, "ramp5_borda_x105_devagar")


func test_ramp1_borda_x25_devagar() -> void:
	var scenario := await _start(Vector3(23.5, 2.0, -13.0), DIAGONAL_PLUS_X_UPHILL_RAMP1)
	await scenario.drive(420, CarScenario.hold_speed(CRAWL_SPEED))
	_assert_telemetry_clean(scenario, "ramp1_borda_x25_devagar")
	_assert_falls_smoothly(scenario, "ramp1_borda_x25_devagar")


func _start(position: Vector3, yaw_degrees: float) -> CarScenario:
	var scenario := CarScenario.new()
	scenario.start(self, position, yaw_degrees)
	await scenario.settle(SETTLE_TICKS)
	return scenario


func _assert_telemetry_clean(scenario: CarScenario, label: String) -> void:
	scenario.print_events(label)
	var bumps := scenario.events_containing("SOLAVANCO")
	var quick_losses := scenario.events_containing("PERDEU O CHAO RAPIDO")
	var hangs := scenario.events_containing("PENDURADO NA BORDA")
	var edge_slide_time := scenario.telemetry.longest_edge_slide_time
	assert_eq(bumps.size(), 0, label + ": nenhum SOLAVANCO (salto vertical acima de 2 m/s)")
	assert_eq(quick_losses.size(), 0, label + ": nenhum PERDEU O CHAO RAPIDO")
	assert_eq(hangs.size(), 0, label + ": nenhum PENDURADO NA BORDA")
	var slide_message := label + ": escorrega da borda em menos de 1 s"
	assert_true(edge_slide_time < MAX_EDGE_SLIDE_SECONDS, slide_message)
	for sudden_stop: String in scenario.events_containing("FREOU DE REPENTE"):
		assert_true(sudden_stop.contains("Buildings/"), label + ": freada so batendo em predio")


func _assert_reached_ramp(scenario: CarScenario, label: String, target_kmh: float) -> void:
	var minimum_kmh := target_kmh * 0.9
	var message := label + ": chegou na rampa a pelo menos %.0f km/h" % minimum_kmh
	assert_true(scenario.ramp_touch_kmh >= minimum_kmh, message)
	print(label, ": tocou a rampa a %.0f km/h" % scenario.ramp_touch_kmh)


func _assert_falls_smoothly(scenario: CarScenario, label: String) -> void:
	var worst_turn := scenario.worst_fall_visual_turn_degrees
	print(label, ": maior giro do visual em um frame caindo ou pousando %.2f graus" % worst_turn)
	var message := label + ": o visual cai e pousa suave, sem girar mais de 3 graus em um frame"
	assert_true(worst_turn < MAX_VISUAL_TURN_PER_FRAME_DEGREES, message)
