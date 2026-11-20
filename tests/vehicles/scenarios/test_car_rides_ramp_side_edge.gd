extends TestCase

const LOW_ON_RAMP3_SIDE_EDGE := Vector3(57.0, 2.0, 105.3)
const HIGH_ON_RAMP3_SIDE_EDGE := Vector3(50.0, 3.0, 105.3)
const CENTER_ON_RAMP3_SIDE_EDGE := Vector3(57.0, 2.0, 105.0)
const FACING_UPHILL_RAMP3 := 90.0
const FACING_DOWNHILL_RAMP3 := -90.0
const SETTLE_TICKS := 30
const DRIVE_TICKS := 240
const CRAWL_SPEED := 1.5
const MAX_WHEEL_FLOAT := 0.1


func test_crawls_uphill_with_wheels_on_side_edge() -> void:
	await _assert_wheels_stay_on_ramp(LOW_ON_RAMP3_SIDE_EDGE, FACING_UPHILL_RAMP3, "subindo")


func test_crawls_downhill_with_wheels_on_side_edge() -> void:
	await _assert_wheels_stay_on_ramp(HIGH_ON_RAMP3_SIDE_EDGE, FACING_DOWNHILL_RAMP3, "descendo")


func test_crawls_with_center_right_on_side_edge() -> void:
	var label := "centro na borda"
	await _assert_wheels_stay_on_ramp(CENTER_ON_RAMP3_SIDE_EDGE, FACING_UPHILL_RAMP3, label)


func _assert_wheels_stay_on_ramp(position: Vector3, yaw_degrees: float, label: String) -> void:
	var scenario := CarScenario.new()
	scenario.start(self, position, yaw_degrees)
	await scenario.settle(SETTLE_TICKS)
	await scenario.drive(DRIVE_TICKS, CarScenario.hold_speed(CRAWL_SPEED))
	var worst_float := scenario.worst_wheel_float
	print(label, ": maior vao entre a roda mais baixa e o chao %.2f m" % worst_float)
	var message := label + ": devagar na borda da rampa, o carro nao flutua acima dela"
	assert_true(worst_float < MAX_WHEEL_FLOAT, message)
