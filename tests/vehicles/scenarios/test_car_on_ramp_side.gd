extends TestCase

const ACROSS_RAMP5_START := Vector3(96.5, 2.2, -114.0)
const ON_RAMP5_SIDE_EDGE := Vector3(105.0, 2.2, -116.0)
const FACING_PLUS_X := -90.0
const FACING_MINUS_X := 90.0
const SETTLE_TICKS := 30
const MAX_UPHILL_DRIFT := 0.05


func test_crosses_ramp_without_sliding_uphill() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, ACROSS_RAMP5_START, FACING_PLUS_X)
	await scenario.drive(SETTLE_TICKS, _release)
	var start_z := scenario.car.global_position.z
	await scenario.drive(150, CarScenario.hold_speed(2.0))
	var uphill_drift := absf(scenario.car.global_position.z - start_z)
	var distance_across := scenario.car.global_position.x - ACROSS_RAMP5_START.x
	assert_true(distance_across > 3.0, "anda atravessando a rampa")
	assert_true(uphill_drift < MAX_UPHILL_DRIFT, "atravessando a rampa nao escorrega rampa acima")


func test_leaves_side_edge_without_bouncing() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, ON_RAMP5_SIDE_EDGE, FACING_MINUS_X)
	await scenario.drive(SETTLE_TICKS, _release)
	var floor_changes := 0
	var was_on_floor := scenario.car.is_on_floor()
	for tick: int in 120:
		await scenario.drive(1, CarScenario.hold_speed(2.0))
		var on_floor := scenario.car.is_on_floor()
		if on_floor != was_on_floor:
			floor_changes += 1
		was_on_floor = on_floor
	assert_eq(floor_changes, 0, "com metade do carro na borda, volta para a rampa sem quicar")


func _release(driven_car: Car) -> void:
	driven_car.input.clear()
