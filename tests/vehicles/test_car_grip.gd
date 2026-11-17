extends TestCase

const TICK := 1.0 / 60.0


func test_burnout_keeps_stopped_car_in_place() -> void:
	var grip := _make_grip()
	var creeping := Vector3(0.0, 0.0, -0.5)
	var result := grip.apply_handbrake_or_rest(creeping, 1.0, true, true, TICK)
	assert_eq(result, Vector3.ZERO, "freio de mao e acelerador parado nao anda")


func test_handbrake_at_speed_only_slows_down() -> void:
	var grip := _make_grip()
	var fast := Vector3(0.0, 0.0, -20.0)
	var result := grip.apply_handbrake_or_rest(fast, 1.0, true, true, TICK)
	assert_true(result.length() > 19.0, "em velocidade o freio de mao nao trava o carro")
	assert_true(result.length() < 20.0, "em velocidade o freio de mao reduz a velocidade")


func test_throttle_without_handbrake_is_untouched() -> void:
	var grip := _make_grip()
	var creeping := Vector3(0.0, 0.0, -0.5)
	var result := grip.apply_handbrake_or_rest(creeping, 1.0, false, true, TICK)
	assert_eq(result, creeping, "sem freio de mao o acelerador anda normal")


func test_burnout_needs_ground() -> void:
	var grip := _make_grip()
	var flying := Vector3(0.0, 0.0, -0.5)
	var result := grip.apply_handbrake_or_rest(flying, 1.0, true, false, TICK)
	assert_eq(result, flying, "no ar o freio de mao nao para o carro")


func _make_grip() -> CarGrip:
	var grip := CarGrip.new()
	spawn(grip)
	return grip
