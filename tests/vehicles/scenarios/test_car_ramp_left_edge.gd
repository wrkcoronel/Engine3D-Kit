extends TestCase

const START_ON_RAMP1_LEFT_EDGE := Vector3(16.5, 2.0, -13.0)
const SETTLE_TICKS := 30
const DRIVE_TICKS := 300
const REST_TICKS := 180
const MAX_HEIGHT_AT_REST := 0.3
const CRAWL_SPEED := 0.5
const SLOW_SPEED := 1.0
const YAW_DIAGONAL := 50.0
const YAW_NEARLY_SIDEWAYS := 70.0
const YAW_SIDEWAYS := 90.0


func test_diagonal_crawl_does_not_stay_on_edge() -> void:
	await _assert_ends_on_floor(YAW_DIAGONAL, CRAWL_SPEED, "diagonal devagar")


func test_nearly_sideways_crawl_does_not_stay_on_edge() -> void:
	await _assert_ends_on_floor(YAW_NEARLY_SIDEWAYS, CRAWL_SPEED, "quase de lado devagar")


func test_sideways_slow_does_not_stay_on_edge() -> void:
	await _assert_ends_on_floor(YAW_SIDEWAYS, SLOW_SPEED, "de lado")


func _assert_ends_on_floor(yaw_degrees: float, speed: float, label: String) -> void:
	var scenario := CarScenario.new()
	scenario.start(self, START_ON_RAMP1_LEFT_EDGE, yaw_degrees)
	await scenario.settle(SETTLE_TICKS)
	await scenario.drive(DRIVE_TICKS, CarScenario.hold_speed(speed))
	await scenario.drive(REST_TICKS, _release)
	var car := scenario.car
	var message := label + ": nao fica preso na quina da rampa"
	assert_true(car.global_position.y < MAX_HEIGHT_AT_REST, message)
	assert_true(car.velocity.y > -CarFall.MAX_FALL_SPEED, label + ": sem gravidade acumulada")


func _release(driven_car: Car) -> void:
	driven_car.input.clear()
