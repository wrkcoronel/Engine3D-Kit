extends TestCase

const RAMP6_RIGHT_EDGE_X := -55.0
const CENTER_PAST_RAMP6_EDGE := Vector3(-54.7, 1.6, -124.0)
const CENTER_ON_RAMP6_BESIDE_EDGE := Vector3(-55.3, 1.6, -124.0)
const WHEELS_ON_RAMP6_BODY_OVER_EDGE := Vector3(-55.8, 1.6, -124.0)
const MIDDLE_OF_RAMP6 := Vector3(-60.0, 1.6, -124.0)
const ON_RAMP5_EDGE_DIAGONAL := Vector3(103.5, 2.3, -114.0)
const ON_RAMP1_EDGE_DIAGONAL := Vector3(23.5, 2.0, -13.0)
const FACING_MINUS_Z := 0.0
const DIAGONAL_PLUS_X_UPHILL_RAMP5 := -130.0
const DIAGONAL_PLUS_X_UPHILL_RAMP1 := -50.0
const SETTLE_TICKS := 20
const FALL_TICKS := 180
const STUCK_CHECK_TICKS := 300
const CRAWL_TICKS := 420
const SLOW_SPEED := 3.0
const CRAWL_SPEED := 1.0
const MIN_ROLL_WHEN_FALLING := 30.0
const MAX_LEAN_ON_WHEELS := 5.0
const MAX_HEIGHT_ON_FLOOR := 1.0
const MAX_WHEEL_FLOAT := 0.1
const MIN_CLIMB_FRACTION_ON_EDGE := 0.9


func test_center_past_edge_tips_over_and_falls() -> void:
	var scenario := await _start(CENTER_PAST_RAMP6_EDGE, FACING_MINUS_Z)
	await scenario.drive(FALL_TICKS, CarScenario.hold_speed(SLOW_SPEED))
	var car := scenario.car
	var roll := scenario.worst_roll_degrees
	print("centro fora: rolou ate %.1f graus, terminou em %s" % [roll, car.global_position])
	assert_true(roll > MIN_ROLL_WHEN_FALLING, "com o centro fora da rampa o carro tomba")
	var ended_on_floor := car.global_position.y < MAX_HEIGHT_ON_FLOOR
	assert_true(ended_on_floor, "com o centro fora da rampa o carro cai em menos de 3 s")
	var fell_beside_ramp := car.global_position.x > RAMP6_RIGHT_EDGE_X
	assert_true(fell_beside_ramp, "cai para o lado do vazio, nao volta para a rampa")


func test_body_over_edge_with_wheels_on_ramp_drives_normally() -> void:
	var middle_scenario := await _start(MIDDLE_OF_RAMP6, FACING_MINUS_Z)
	var climbed_in_middle := await _climb(middle_scenario)
	cleanup()
	var scenario := await _start(WHEELS_ON_RAMP6_BODY_OVER_EDGE, FACING_MINUS_Z)
	var climbed_on_edge := await _climb(scenario)
	var lean := scenario.worst_roll_degrees
	var climb_text := "subiu %.1f m (no meio %.1f m)" % [climbed_on_edge, climbed_in_middle]
	print("carroceria fora: inclinou ate %.1f graus, %s" % [lean, climb_text])
	assert_true(lean < MAX_LEAN_ON_WHEELS, "com as rodas na rampa o carro nao tomba")
	var minimum_climb := climbed_in_middle * MIN_CLIMB_FRACTION_ON_EDGE
	var message := "com as rodas na rampa o carro sobe quase igual ao meio da rampa"
	assert_true(climbed_on_edge > minimum_climb, message)
	var wheel_float := scenario.worst_wheel_float
	assert_true(wheel_float < MAX_WHEEL_FLOAT, "na borda nenhuma roda flutua acima da rampa")


func _climb(scenario: CarScenario) -> float:
	var start_z := scenario.car.global_position.z
	await scenario.drive(FALL_TICKS, CarScenario.hold_speed(SLOW_SPEED))
	return start_z - scenario.car.global_position.z


func test_half_off_edge_does_not_get_stuck() -> void:
	var scenario := await _start(CENTER_ON_RAMP6_BESIDE_EDGE, FACING_MINUS_Z)
	await scenario.drive(STUCK_CHECK_TICKS, CarScenario.hold_speed(SLOW_SPEED))
	var car := scenario.car
	print("metade fora: terminou em %s" % car.global_position)
	var on_floor_beside := car.global_position.y < MAX_HEIGHT_ON_FLOOR
	var message := "com metade fora o carro nao fica preso na quina: cai para o chao"
	assert_true(on_floor_beside, message)


func test_crawling_off_ramp5_edge_ends_on_floor() -> void:
	await _assert_crawls_off(ON_RAMP5_EDGE_DIAGONAL, DIAGONAL_PLUS_X_UPHILL_RAMP5, "ramp5")


func test_crawling_off_ramp1_edge_ends_on_floor() -> void:
	await _assert_crawls_off(ON_RAMP1_EDGE_DIAGONAL, DIAGONAL_PLUS_X_UPHILL_RAMP1, "ramp1")


func _assert_crawls_off(position: Vector3, yaw_degrees: float, label: String) -> void:
	var scenario := await _start(position, yaw_degrees)
	await scenario.drive(CRAWL_TICKS, CarScenario.hold_speed(CRAWL_SPEED))
	var car := scenario.car
	print(label, ": devagar pela quina terminou em ", car.global_position)
	var message := label + ": devagar pela quina o carro sai da rampa e para no chao"
	assert_true(car.global_position.y < MAX_HEIGHT_ON_FLOOR, message)


func _start(position: Vector3, yaw_degrees: float) -> CarScenario:
	var scenario := CarScenario.new()
	scenario.start(self, position, yaw_degrees)
	await scenario.settle(SETTLE_TICKS)
	return scenario
