extends TestCase


func test_gpu_output_with_line_break_is_parsed() -> void:
	assert_eq(SystemLoadReader.parse_percent("40\r\n"), 40, "porcentagem da gpu")


func test_gpu_output_with_two_cards_uses_the_first() -> void:
	assert_eq(SystemLoadReader.parse_percent("7\n55\n"), 7, "primeira placa")


func test_gpu_garbage_is_unknown() -> void:
	assert_eq(SystemLoadReader.parse_percent("falhou"), SystemLoadReader.UNKNOWN, "texto")
	assert_eq(SystemLoadReader.parse_percent(""), SystemLoadReader.UNKNOWN, "vazio")


func test_cpu_output_skips_the_header() -> void:
	var wmic_output := "LoadPercentage  \r\r\n12              \r\r\n\r\r\n"
	assert_eq(SystemLoadReader.parse_percent(wmic_output), 12, "porcentagem da cpu")


func test_percent_is_clamped_to_100() -> void:
	assert_eq(SystemLoadReader.parse_percent("250"), 100, "limite de 100")


func test_overlay_text_shows_all_three_values() -> void:
	assert_eq(PerformanceOverlay.build_text(60, 12, 40), "FPS 60  CPU 12%  GPU 40%", "texto")


func test_overlay_text_marks_unknown_values() -> void:
	var unknown := SystemLoadReader.UNKNOWN
	assert_eq(
		PerformanceOverlay.build_text(60, unknown, unknown), "FPS 60  CPU --  GPU --", "texto"
	)
