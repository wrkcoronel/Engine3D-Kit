extends TestCase


func test_beam_center_is_white() -> void:
	var center := FlashlightBeamTexture.color_at(0.0)
	assert_near(center.r, 1.0, 0.01, "centro vermelho")
	assert_near(center.g, 1.0, 0.01, "centro verde")
	assert_near(center.b, 1.0, 0.01, "centro azul")


func test_beam_body_is_yellowish() -> void:
	var body := FlashlightBeamTexture.color_at(0.7)
	assert_true(body.r > body.g, "amarelo tem mais vermelho que verde")
	assert_true(body.g > body.b, "amarelo tem mais verde que azul")


func test_beam_fades_to_black_at_the_edge() -> void:
	var edge := FlashlightBeamTexture.color_at(1.0)
	assert_eq(edge.r, 0.0, "borda apagada")


func test_beam_image_has_requested_size() -> void:
	var image := FlashlightBeamTexture.build_image(16)
	assert_eq(image.get_width(), 16, "largura")
	assert_eq(image.get_height(), 16, "altura")
