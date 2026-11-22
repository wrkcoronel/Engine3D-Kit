extends TestCase


func test_smoothing_moves_a_fraction_towards_the_measurement() -> void:
	var result := RenderTimeReader.smoothed(10.0, 20.0)
	assert_near(result, 11.0, 0.0001, "um decimo do caminho")


func test_smoothing_keeps_a_steady_value() -> void:
	assert_near(RenderTimeReader.smoothed(5.0, 5.0), 5.0, 0.0001, "estavel")


func test_update_without_start_does_nothing() -> void:
	var reader := RenderTimeReader.new()
	reader.update()
	assert_eq(reader.gpu_milliseconds, 0.0, "sem viewport nao mede")
