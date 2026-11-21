extends TestCase


func test_no_smoke_in_the_air() -> void:
	var amount := TireSlipSmoke.slip_amount(false, 1.0, true, 20.0, 10.0, 25.0)
	assert_eq(amount, 0.0, "no ar nao tem fumaca")


func test_side_slip_below_threshold_makes_no_smoke() -> void:
	var amount := TireSlipSmoke.slip_amount(true, 1.0, false, 2.0, 10.0, 10.0)
	assert_eq(amount, 0.0, "deslize pequeno")


func test_strong_side_slip_makes_full_smoke() -> void:
	var amount := TireSlipSmoke.slip_amount(true, 1.0, false, 12.0, 10.0, 15.0)
	assert_near(amount, 1.0, 0.001, "deslize forte")


func test_handbrake_while_moving_makes_smoke() -> void:
	var amount := TireSlipSmoke.slip_amount(true, 0.0, true, 0.0, 10.0, 12.0)
	assert_near(amount, TireSlipSmoke.HANDBRAKE_SMOKE, 0.001, "freio de mao em movimento")


func test_burnout_needs_handbrake_throttle_and_low_speed() -> void:
	var standing := TireSlipSmoke.burnout_amount(true, 1.0, true, 0.0, 0.0)
	assert_near(standing, 0.8, 0.001, "parado e acelerando com freio de mao")
	var fast := TireSlipSmoke.burnout_amount(true, 1.0, true, 9.0, 12.0)
	assert_eq(fast, 0.0, "rapido nao e burnout")
	var without_handbrake := TireSlipSmoke.burnout_amount(true, 1.0, false, 0.0, 0.0)
	assert_eq(without_handbrake, 0.0, "sem freio de mao")


func test_hard_braking_smoke_is_capped() -> void:
	var amount := TireSlipSmoke.hard_braking_amount(-1.0, 100.0)
	assert_near(amount, TireSlipSmoke.HARD_BRAKE_MAX_SMOKE, 0.001, "limite da frenagem")
	assert_eq(TireSlipSmoke.hard_braking_amount(-1.0, 10.0), 0.0, "frenagem leve")


func test_visible_smoke_is_weaker_at_low_speed() -> void:
	var slow := TireSlipSmoke.visible_amount(1.0, 0.0, 0.0)
	var fast := TireSlipSmoke.visible_amount(1.0, 0.0, 50.0)
	assert_near(slow, TireSlipSmoke.MIN_SMOKE_AT_LOW_SPEED, 0.001, "devagar")
	assert_near(fast, 1.0, 0.001, "rapido")


func test_burnout_smoke_is_not_weakened_by_low_speed() -> void:
	var amount := TireSlipSmoke.visible_amount(0.0, 0.8, 0.0)
	assert_near(amount, 0.8, 0.001, "burnout parado fuma forte")
