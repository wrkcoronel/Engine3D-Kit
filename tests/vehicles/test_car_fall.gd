extends TestCase


func test_rising_speed_is_not_changed() -> void:
	var speed := CarFall.limited_vertical_speed(3.0, 0.0)
	assert_eq(speed, 3.0, "subindo nao mexe")


func test_blocked_fall_does_not_accumulate() -> void:
	var speed := CarFall.limited_vertical_speed(-80.0, 0.0)
	assert_eq(speed, 0.0, "apoiado na quina a velocidade de queda volta a zero")


func test_free_fall_is_capped() -> void:
	var speed := CarFall.limited_vertical_speed(-80.0, -80.0)
	assert_eq(speed, -CarFall.MAX_FALL_SPEED, "queda livre tem velocidade maxima")


func test_normal_fall_is_unchanged() -> void:
	var speed := CarFall.limited_vertical_speed(-10.0, -10.0)
	assert_eq(speed, -10.0, "queda normal nao muda")


func test_depenetration_push_never_turns_a_fall_into_a_climb() -> void:
	var speed := CarFall.limited_vertical_speed(-5.0, 4.0)
	assert_eq(speed, 0.0, "empurrao para cima da colisao nao vira subida")
