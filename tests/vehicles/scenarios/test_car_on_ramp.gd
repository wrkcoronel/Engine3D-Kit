extends TestCase

const RAMP_CENTER_X := 20.0
const FLAT_GROUND := Vector3(-40.0, 0.1, 60.0)
const MAX_WHEEL_SINK := -0.05
const JUMP_SPEED := 25.0
const LAUNCH_TICKS := 120


func test_climbs_slowly_without_bouncing() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, Vector3(RAMP_CENTER_X, 0.1, 6.0), 0.0)
	await scenario.drive(360, CarScenario.hold_speed(5.0))
	assert_true(scenario.floor_changes_near_ramp <= 2, "sobe sem alternar entre chao e ar")
	assert_true(scenario.worst_wheel_sink > MAX_WHEEL_SINK, "nenhuma roda entra no chao")
	assert_true(scenario.car.global_position.z < -15.0, "devagar ainda sobe a rampa")


func test_fast_car_jumps_from_ramp_top() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, Vector3(RAMP_CENTER_X, 0.1, 35.0), 0.0)
	scenario.launch(JUMP_SPEED)
	await scenario.drive(300, CarScenario.hold_speed(JUMP_SPEED))
	print("salto: roda mais afundada %.3f m" % scenario.worst_wheel_sink)
	assert_true(scenario.takeoff_climb_speed > 4.0, "sai do topo subindo, nao reto")
	assert_true(scenario.floor_changes_near_ramp <= 3, "sobe sem tremer")
	assert_true(scenario.worst_wheel_sink > MAX_WHEEL_SINK, "nenhuma roda entra no chao")


func test_reverses_down_the_ramp() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, Vector3(RAMP_CENTER_X, 4.2, -20.0), 0.0)
	await scenario.drive(300, _reverse)
	assert_true(scenario.car.global_position.z > -5.0, "de re desce a rampa ate o chao")
	assert_true(scenario.worst_wheel_sink > MAX_WHEEL_SINK, "nenhuma roda entra no chao")


func test_stops_on_ramp_and_stays() -> void:
	var scenario := CarScenario.new()
	scenario.start(self, Vector3(RAMP_CENTER_X, 0.1, 10.0), 0.0)
	await scenario.drive(300, _climb_then_brake)
	var stopped_at := scenario.car.global_position.z
	await scenario.drive(60, _release_everything)
	var drift := absf(scenario.car.global_position.z - stopped_at)
	assert_true(stopped_at < -14.0, "parou no meio da rampa")
	assert_true(drift < 0.1, "parado na rampa nao escorrega")


func test_handbrake_drags_front_wheel_drive_launch() -> void:
	var free_scenario := CarScenario.new()
	free_scenario.start(self, FLAT_GROUND, 0.0)
	await free_scenario.drive(LAUNCH_TICKS, _full_throttle)
	var moved_free := free_scenario.car.global_position.distance_to(FLAT_GROUND)
	cleanup()
	var scenario := CarScenario.new()
	scenario.start(self, FLAT_GROUND, 0.0)
	await scenario.drive(LAUNCH_TICKS, _burnout)
	var moved_with_handbrake := scenario.car.global_position.distance_to(FLAT_GROUND)
	var message := "com o freio de mao puxado a tracao dianteira arrasta o carro mais devagar"
	assert_true(moved_with_handbrake < moved_free * 0.6, message)
	await scenario.drive(60, _full_throttle)
	var speed := scenario.car.linear_velocity.length()
	assert_true(speed > 3.0, "soltando o freio de mao o carro arranca")


func _reverse(driven_car: Car) -> void:
	driven_car.input.throttle = -1.0


func _climb_then_brake(driven_car: Car) -> void:
	var reached_middle := driven_car.global_position.z < -16.0
	if not reached_middle:
		CarScenario.hold_speed(10.0).call(driven_car)
		return
	var still_moving_forward := driven_car.linear_velocity.dot(-driven_car.global_basis.z) > 0.6
	driven_car.input.throttle = 0.0
	if still_moving_forward:
		driven_car.input.throttle = -1.0


func _release_everything(driven_car: Car) -> void:
	driven_car.input.clear()


func _burnout(driven_car: Car) -> void:
	driven_car.input.throttle = 1.0
	driven_car.input.handbraking = true


func _full_throttle(driven_car: Car) -> void:
	driven_car.input.throttle = 1.0
	driven_car.input.handbraking = false
