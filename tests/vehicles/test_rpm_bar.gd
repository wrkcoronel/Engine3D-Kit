extends TestCase


func test_fill_fraction_stays_between_zero_and_one() -> void:
	assert_eq(RpmBar.fill_fraction(-500.0, 6800.0), 0.0, "rpm negativo fica vazio")
	assert_eq(RpmBar.fill_fraction(20000.0, 6800.0), 1.0, "acima do corte fica cheio")
	assert_near(
		RpmBar.fill_fraction(3400.0, 6800.0), 0.5, 0.0001, "metade do corte, metade da barra"
	)


func test_fill_fraction_without_redline_is_empty() -> void:
	assert_eq(RpmBar.fill_fraction(3000.0, 0.0), 0.0, "sem corte a barra fica vazia")


func test_fill_is_white_until_shift_zone_then_red() -> void:
	var before_shift_zone := RpmBar.SHIFT_START_FRACTION - 0.1
	assert_near(RpmBar.white_fraction(before_shift_zone), before_shift_zone, 0.0001, "branca")
	assert_eq(RpmBar.red_fraction(before_shift_zone), 0.0, "sem vermelho antes da zona")
	assert_eq(RpmBar.white_fraction(1.0), RpmBar.SHIFT_START_FRACTION, "branca para na zona")
	var expected_red := 1.0 - RpmBar.SHIFT_START_FRACTION
	assert_near(RpmBar.red_fraction(1.0), expected_red, 0.0001, "cheia tem a zona toda vermelha")
