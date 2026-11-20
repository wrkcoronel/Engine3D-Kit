extends TestCase


func test_events_are_kept_in_order() -> void:
	var history := TelemetryLog.new()
	history.add_event(1.0, "carro", "primeiro")
	history.add_event(2.0, "carro", "segundo")
	var recent := history.recent_events(2)
	assert_true(recent[0].contains("primeiro"), "o evento mais antigo vem primeiro")
	assert_true(recent[1].contains("segundo"), "o evento mais novo vem por ultimo")


func test_old_events_are_dropped_after_limit() -> void:
	var history := TelemetryLog.new()
	for index: int in TelemetryLog.MAX_EVENTS + 5:
		history.add_event(float(index), "carro", "evento %d" % index)
	assert_eq(history.event_count(), TelemetryLog.MAX_EVENTS, "guarda no maximo MAX_EVENTS")


func test_samples_are_stored_ten_times_per_second() -> void:
	var history := TelemetryLog.new()
	var frame_time := 1.0 / 60.0
	for frame_index: int in 60:
		history.add_sample(frame_index * frame_time, "carro", "estado")
	assert_eq(history.sample_count(), 10, "um segundo a 60 fps guarda 10 amostras")


func test_changing_source_records_mode_event() -> void:
	var history := TelemetryLog.new()
	history.add_sample(0.0, "jogador", "a pe")
	history.add_sample(0.01, "carro", "dirigindo")
	var recent := history.recent_events(2)
	assert_true(recent[1].contains("agora controlando: carro"), "registra a troca para o carro")
	assert_eq(history.current_source, "carro", "lembra quem esta sendo controlado")
	assert_eq(history.sample_count(), 2, "a troca de modo grava a amostra na hora")


func test_report_contains_events_and_samples() -> void:
	var history := TelemetryLog.new()
	history.add_event(1.0, "arma", "tiro: acertou World/Wall")
	history.add_sample(1.0, "jogador", "posicao (0.00, 1.00, 4.00)")
	var report := history.build_report(2.0, "teste")
	assert_true(report.contains("motivo: teste"), "o relatorio diz o motivo")
	assert_true(report.contains("tiro: acertou World/Wall"), "o relatorio tem os eventos")
	assert_true(report.contains("posicao (0.00, 1.00, 4.00)"), "o relatorio tem as amostras")


func test_clock_text_shows_time_with_milliseconds() -> void:
	var fourteen_oh_three_and_a_half := 14 * 3600 + 3 * 60 + 22 + 0.512
	var text := TelemetryLog.clock_text(fourteen_oh_three_and_a_half)
	assert_eq(text, "14:03:22.512", "horario com milissegundos")


func test_each_line_starts_with_clock_and_game_time() -> void:
	var line := TelemetryLog.format_line("14:03:22.512", 110.02, "carro", "pulou")
	assert_true(line.begins_with("[14:03:22.512 |   110.02s]"), "horario e tempo de jogo")
	assert_true(line.ends_with("| pulou"), "a mensagem vem no fim")


func test_recorded_event_has_clock() -> void:
	var history := TelemetryLog.new()
	history.add_event(1.0, "arma", "tiro")
	var clock_pattern := RegEx.create_from_string("^\\[\\d{2}:\\d{2}:\\d{2}\\.\\d{3} \\|")
	var event_line := history.recent_events(1)[0]
	assert_true(clock_pattern.search(event_line) != null, "o evento gravado tem horario")


func test_format_vector_uses_two_decimals() -> void:
	var text := TelemetryLog.format_vector(Vector3(1.0, -2.5, 0.125))
	assert_eq(text, "(1.00, -2.50, 0.13)", "vetor com duas casas")
