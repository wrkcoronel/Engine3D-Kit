extends TestCase

const FRAME := 1.0 / 60.0


func _run(check: AmmoCheck, seconds: float, reload_down: bool, check_down: bool) -> void:
	var frames := int(seconds / FRAME)
	for frame_number: int in frames:
		check.update(FRAME, reload_down, check_down, true, false)


func test_holding_check_key_opens_and_closes() -> void:
	var check := AmmoCheck.new()
	_run(check, 1.0, false, true)
	assert_true(check.active, "segurando a tecla confere")
	assert_near(check.amount, 1.0, 0.01, "a arma chega na pose")
	assert_true(not check.checking_chamber, "a tecla de conferir olha o pente")
	_run(check, 1.0, false, false)
	assert_true(not check.active, "soltou, para")
	assert_eq(check.amount, 0.0, "a arma volta")


func test_chamber_check_ends_by_itself() -> void:
	var check := AmmoCheck.new()
	check.start_chamber_check(false)
	_run(check, 0.5, false, false)
	assert_true(check.active, "confere a camara por um tempo")
	assert_true(check.checking_chamber, "olha a camara")
	_run(check, AmmoCheck.CHAMBER_CHECK_TIME, false, false)
	assert_true(not check.active, "termina sozinho")


func test_held_chamber_check_lasts_while_key_down() -> void:
	var check := AmmoCheck.new()
	check.start_chamber_check(true)
	_run(check, AmmoCheck.CHAMBER_CHECK_TIME + 1.0, true, false)
	assert_true(check.active, "segurando R continua conferindo")
	_run(check, 0.1, false, false)
	assert_true(not check.active, "soltou R, para")


func test_interrupt_stays_closed_until_key_released() -> void:
	var check := AmmoCheck.new()
	_run(check, 0.5, false, true)
	check.interrupt()
	_run(check, 0.5, false, true)
	assert_true(not check.active, "interrompido nao volta com a tecla ainda segurada")
	_run(check, FRAME * 2.0, false, false)
	_run(check, 0.5, false, true)
	assert_true(check.active, "soltou e apertou de novo, confere")


func test_not_allowed_never_opens() -> void:
	var check := AmmoCheck.new()
	check.update(0.5, false, true, false, false)
	assert_true(not check.active, "correndo ou mirando nao confere")
