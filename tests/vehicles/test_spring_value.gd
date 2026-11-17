extends TestCase

const TICK := 1.0 / 60.0
const STIFFNESS := 90.0
const DAMPING := 10.0


func test_spring_settles_on_target() -> void:
	var spring := SpringValue.new()
	_run(spring, 3.0, 180)
	assert_near(spring.value, 3.0, 0.01, "depois de 3 segundos a mola para no alvo")
	assert_near(spring.speed, 0.0, 0.05, "e para de se mexer")


func test_spring_overshoots_like_suspension() -> void:
	var spring := SpringValue.new()
	var highest := 0.0
	for tick_index: int in 60:
		spring.step(1.0, STIFFNESS, DAMPING, TICK)
		highest = maxf(highest, spring.value)
	assert_true(highest > 1.0, "a mola passa um pouco do alvo antes de assentar")
	assert_true(highest < 1.5, "mas nao passa demais")


func test_spring_at_rest_stays_still() -> void:
	var spring := SpringValue.new()
	_run(spring, 0.0, 30)
	assert_near(spring.value, 0.0, 0.0001, "sem alvo novo a mola nao se mexe")


func _run(spring: SpringValue, target: float, ticks: int) -> void:
	for tick_index: int in ticks:
		spring.step(target, STIFFNESS, DAMPING, TICK)
