extends TestCase


func test_small_drop_does_not_shake() -> void:
	var strength := CarCamera.shake_strength_for_fall(2.0)
	assert_near(strength, 0.0, 0.001, "queda pequena nao balanca a camera")


func test_hard_landing_shakes_fully() -> void:
	var strength := CarCamera.shake_strength_for_fall(30.0)
	assert_near(strength, 1.0, 0.001, "queda forte balanca no maximo")


func test_medium_landing_shakes_halfway() -> void:
	var halfway_speed := (CarCamera.SHAKE_MIN_FALL_SPEED + CarCamera.SHAKE_FULL_FALL_SPEED) / 2.0
	var strength := CarCamera.shake_strength_for_fall(halfway_speed)
	assert_near(strength, 0.5, 0.001, "queda media balanca pela metade")


func test_moving_up_does_not_shake() -> void:
	var strength := CarCamera.shake_strength_for_fall(-5.0)
	assert_near(strength, 0.0, 0.001, "subindo nao conta como queda")
