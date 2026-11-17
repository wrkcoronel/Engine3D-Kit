extends TestCase


func test_wheel_turns_one_radian_per_radius_travelled() -> void:
	var one_radian_speed := CarWheels.WHEEL_RADIUS
	var angle := CarWheels.rolled_angle_after(0.0, one_radian_speed, 1.0)
	assert_near(angle, 1.0, 0.0001, "andar o tamanho do raio gira um radiano")


func test_stopped_wheel_does_not_turn() -> void:
	var angle := CarWheels.rolled_angle_after(0.5, 0.0, 1.0)
	assert_near(angle, 0.5, 0.0001, "roda parada fica no mesmo angulo")


func test_reverse_turns_wheel_backwards() -> void:
	var angle := CarWheels.rolled_angle_after(0.0, -CarWheels.WHEEL_RADIUS, 0.5)
	assert_near(angle, -0.5, 0.0001, "de re a roda gira para tras")


func test_angle_wraps_around_full_turn() -> void:
	var angle := CarWheels.rolled_angle_after(3.0, CarWheels.WHEEL_RADIUS, 1.0)
	assert_true(angle >= -PI, "angulo nunca passa de meia volta para tras")
	assert_true(angle <= PI, "angulo nunca passa de meia volta para frente")
	assert_near(angle, 4.0 - TAU, 0.0001, "dar a volta continua no angulo certo")
