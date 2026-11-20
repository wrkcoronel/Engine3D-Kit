extends TestCase

const OPEN_STRAIGHT_START := Vector3(-1400.0, 0.1, 1450.0)
const FACING_PLUS_X := -90.0
const SETTLE_TICKS := 20
const FULL_THROTTLE_TICKS := 3600
const HUNDRED_KMH := 100.0
const MAX_SECONDS_TO_HUNDRED := 9.0
const GOL_GTI_SLOWEST_TOP_KMH := 174.0
const GOL_GTI_FASTEST_TOP_KMH := 215.0
const TOP_GEAR := 5


func test_full_throttle_shifts_and_reaches_gol_gti_speed() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, OPEN_STRAIGHT_START, FACING_PLUS_X)
	await scenario.settle(SETTLE_TICKS)
	var engine := scenario.car.get_node("Engine") as CarEngine
	var seconds_to_hundred := INF
	var highest_gear := 0
	for tick: int in FULL_THROTTLE_TICKS:
		await scenario.drive(1, _floor_it)
		highest_gear = maxi(highest_gear, engine.gear)
		var reached_hundred := _kmh(scenario.car) >= HUNDRED_KMH
		if reached_hundred and is_inf(seconds_to_hundred):
			seconds_to_hundred = tick / 60.0
	var top_kmh := _kmh(scenario.car)
	print(
		(
			"0-100 em %.1f s, final %.0f km/h, ate a marcha %d"
			% [seconds_to_hundred, top_kmh, highest_gear]
		)
	)
	assert_true(seconds_to_hundred < MAX_SECONDS_TO_HUNDRED, "vai de 0 a 100 km/h em menos de 9 s")
	assert_true(top_kmh > GOL_GTI_SLOWEST_TOP_KMH, "passa da maxima do Gol GTI mais lento")
	assert_true(top_kmh < GOL_GTI_FASTEST_TOP_KMH, "nao passa muito da maxima do Gol GTI")
	assert_eq(highest_gear, TOP_GEAR, "passa pelas 5 marchas")


func _kmh(driven_car: Car) -> float:
	return driven_car.linear_velocity.length() * CarTelemetryFrame.KMH_PER_METER_PER_SECOND


func _floor_it(driven_car: Car) -> void:
	driven_car.input.throttle = 1.0
