extends TestCase

const THIRTY_KMH := 30.0 / 3.6
const DIAGONAL_TOWARD_BUILDING1 := -45.8
const SETTLE_TICKS := 30


func test_bate_de_lado_no_building1_a_30kmh() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, Vector3(25.8, 0.1, -12.45), DIAGONAL_TOWARD_BUILDING1)
	await scenario.settle(SETTLE_TICKS)
	await scenario.drive(180, CarScenario.hold_speed(THIRTY_KMH))
	scenario.print_events("bate_de_lado_no_building1_a_30kmh")
	var building_touches := scenario.events_containing("encostou em Buildings/Building1")
	assert_true(building_touches.size() > 0, "o carro chega a bater no Building1")
	for sudden_stop: String in scenario.events_containing("FREOU DE REPENTE"):
		assert_true(sudden_stop.contains("Buildings/"), "freada so batendo em predio")
	var takeoffs := scenario.events_containing("SAIU DO CHAO")
	assert_eq(takeoffs.size(), 0, "bater na parede nao tira o carro do chao")
