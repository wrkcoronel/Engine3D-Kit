extends TestCase


func test_puff_is_transparent_at_the_edges() -> void:
	var image := SmokePuffTexture.build_image(64, 1)
	assert_eq(image.get_pixel(0, 0).a, 0.0, "canto transparente")
	assert_eq(image.get_pixel(63, 63).a, 0.0, "outro canto transparente")


func test_puff_is_denser_in_the_middle_than_near_the_edge() -> void:
	var image := SmokePuffTexture.build_image(64, 1)
	var middle := image.get_pixel(32, 32).a
	var near_edge := image.get_pixel(32, 2).a
	assert_true(middle > near_edge, "miolo mais denso que a borda")
	assert_true(middle > 0.25, "miolo visivel")


func test_alpha_is_zero_outside_the_circle() -> void:
	assert_eq(SmokePuffTexture.alpha_at(1.0, 1.0), 0.0, "fora do circulo")


func test_alpha_follows_the_noise_inside_the_circle() -> void:
	var cloudy := SmokePuffTexture.alpha_at(0.0, 1.0)
	var thin := SmokePuffTexture.alpha_at(0.0, -1.0)
	assert_true(cloudy > thin, "ruido forma nuvem")


func test_same_seed_gives_same_puff_and_other_seed_differs() -> void:
	var first := SmokePuffTexture.build_image(32, 5).get_data()
	var second := SmokePuffTexture.build_image(32, 5).get_data()
	var other := SmokePuffTexture.build_image(32, 6).get_data()
	assert_eq(first, second, "mesma semente")
	assert_true(first != other, "semente diferente")
