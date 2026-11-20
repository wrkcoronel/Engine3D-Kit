extends TestCase

const FLAT_GROUND := Vector3(-40.0, 1.5, 60.0)
const FALL_TICKS := 90
const UPRIGHT_TICKS := 90
const ROCK_TICKS := 120
const MIN_UP_ALIGNMENT := 0.9


func test_upside_down_car_stands_up_with_r() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, FLAT_GROUND, 0.0)
	scenario.car.rotation.z = PI
	await scenario.drive(FALL_TICKS, _release)
	var flipped := CarUpright.is_flipped(scenario.car.global_basis)
	assert_true(flipped, "o carro comeca de cabeca para baixo")
	await scenario.drive(1, _press_upright)
	await scenario.drive(UPRIGHT_TICKS, _release)
	var up_alignment := scenario.car.global_basis.y.dot(Vector3.UP)
	assert_true(up_alignment > MIN_UP_ALIGNMENT, "apertando R o carro fica de pe")
	assert_true(scenario.car.is_on_ground(), "depois de desvirar as rodas tocam o chao")


func test_upside_down_car_rocks_back_with_steering() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, FLAT_GROUND, 0.0)
	scenario.car.rotation.z = PI
	await scenario.drive(FALL_TICKS, _release)
	await scenario.drive(ROCK_TICKS, _hold_left)
	await scenario.drive(UPRIGHT_TICKS, _release)
	var up_alignment := scenario.car.global_basis.y.dot(Vector3.UP)
	print("balancando: teto alinhado %.2f com o ceu" % up_alignment)
	assert_true(up_alignment > MIN_UP_ALIGNMENT, "segurando A capotado o carro volta a ficar de pe")


func test_upright_key_does_nothing_on_wheels() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, FLAT_GROUND, 0.0)
	await scenario.drive(FALL_TICKS, _release)
	var height_before := scenario.car.global_position.y
	await scenario.drive(1, _press_upright)
	await scenario.drive(5, _release)
	var height_after := scenario.car.global_position.y
	assert_near(height_after, height_before, 0.05, "em pe, apertar R nao levanta o carro")


func _press_upright(driven_car: Car) -> void:
	driven_car.input.clear()
	driven_car.input.wants_upright = true


func _release(driven_car: Car) -> void:
	driven_car.input.clear()


func _hold_left(driven_car: Car) -> void:
	driven_car.input.clear()
	driven_car.input.steering = 1.0
