extends TestCase

const STIFFNESS := 24500.0
const DAMPING := 2500.0
const QUARTER_CAR_WEIGHT := 2450.0


func test_spring_at_rest_holds_a_quarter_of_the_car() -> void:
	var push := CarSuspension.spring_force(0.1, 0.0, STIFFNESS, DAMPING)
	assert_near(push, QUARTER_CAR_WEIGHT, 1.0, "10 cm de mola seguram 1/4 do carro")


func test_spring_never_pulls_the_car_down() -> void:
	var push := CarSuspension.spring_force(0.0, -5.0, STIFFNESS, DAMPING)
	assert_eq(push, 0.0, "mola esticando rapido nao puxa o carro para o chao")


func test_damper_resists_fast_compression() -> void:
	var still := CarSuspension.spring_force(0.1, 0.0, STIFFNESS, DAMPING)
	var compressing := CarSuspension.spring_force(0.1, 1.0, STIFFNESS, DAMPING)
	assert_near(
		compressing - still, DAMPING, 0.1, "comprimindo a 1 m/s o amortecedor soma a sua forca"
	)


func test_bump_stop_only_acts_at_the_end_of_travel() -> void:
	var before_stop := CarSuspension.bump_stop_force(0.2, 0.28, 150000.0)
	var into_stop := CarSuspension.bump_stop_force(0.30, 0.28, 150000.0)
	assert_eq(before_stop, 0.0, "antes do batente ele nao empurra")
	assert_near(into_stop, 3000.0, 0.1, "2 cm dentro do batente empurram 3000 N")


func test_anti_roll_pushes_the_more_compressed_side() -> void:
	var compressed_side := CarSuspension.anti_roll_force(0.2, 0.1, 8000.0)
	var lighter_side := CarSuspension.anti_roll_force(0.1, 0.2, 8000.0)
	assert_near(compressed_side, 800.0, 0.01, "o lado mais comprimido recebe mais forca")
	assert_near(lighter_side, -800.0, 0.01, "o outro lado perde a mesma forca")


func test_front_wheels_are_the_first_two() -> void:
	assert_true(CarSuspension.is_front(CarSuspension.FRONT_LEFT), "dianteira esquerda e da frente")
	assert_true(CarSuspension.is_front(CarSuspension.FRONT_RIGHT), "dianteira direita e da frente")
	assert_true(not CarSuspension.is_front(CarSuspension.REAR_LEFT), "traseira nao e da frente")
