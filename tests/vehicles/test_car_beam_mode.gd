extends TestCase


func test_mode_cycles_off_low_high_off() -> void:
	var mode := CarBeamMode.Mode.OFF
	mode = CarBeamMode.next(mode)
	assert_eq(mode, CarBeamMode.Mode.LOW, "desligado vai para baixo")
	mode = CarBeamMode.next(mode)
	assert_eq(mode, CarBeamMode.Mode.HIGH, "baixo vai para alto")
	mode = CarBeamMode.next(mode)
	assert_eq(mode, CarBeamMode.Mode.OFF, "alto volta a desligado")


func test_off_gives_no_light() -> void:
	assert_eq(CarBeamMode.spot_energy(CarBeamMode.Mode.OFF), 0.0, "sem energia")


func test_high_beam_is_stronger_longer_and_narrower_than_low() -> void:
	var low := CarBeamMode.Mode.LOW
	var high := CarBeamMode.Mode.HIGH
	assert_true(CarBeamMode.spot_energy(high) > CarBeamMode.spot_energy(low), "mais forte")
	assert_true(CarBeamMode.spot_range(high) > CarBeamMode.spot_range(low), "mais longe")
	var low_angle := CarBeamMode.spot_angle_degrees(low)
	assert_true(CarBeamMode.spot_angle_degrees(high) < low_angle, "mais estreito")


func test_low_beam_points_lower_than_high_beam() -> void:
	var low_pitch := CarBeamMode.pitch_degrees(CarBeamMode.Mode.LOW)
	var high_pitch := CarBeamMode.pitch_degrees(CarBeamMode.Mode.HIGH)
	assert_true(low_pitch < high_pitch, "farol baixo aponta mais para o chao")


func test_lens_glows_more_when_light_is_stronger() -> void:
	var off := CarBeamMode.lens_glow(CarBeamMode.Mode.OFF)
	var low := CarBeamMode.lens_glow(CarBeamMode.Mode.LOW)
	var high := CarBeamMode.lens_glow(CarBeamMode.Mode.HIGH)
	assert_true(off < low, "lente apagada brilha menos")
	assert_true(low < high, "farol alto brilha mais")
