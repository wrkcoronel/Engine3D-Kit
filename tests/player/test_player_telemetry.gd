extends TestCase

const FRAME_TIME := 1.0 / 60.0


func test_jump_and_landing_are_reported() -> void:
	var telemetry := PlayerTelemetry.new()
	telemetry.events_for(FRAME_TIME, 0.0, true, false)
	var jump_events := telemetry.events_for(FRAME_TIME, 6.0, false, false)
	telemetry.events_for(FRAME_TIME, -4.0, false, false)
	var landing_events := telemetry.events_for(FRAME_TIME, 0.0, true, false)
	assert_true(jump_events[0].begins_with("pulou"), "subir saindo do chao e pulo")
	assert_true(landing_events[0].contains("caindo a 4.00 m/s"), "o pouso diz a queda")


func test_walking_off_ledge_is_not_a_jump() -> void:
	var telemetry := PlayerTelemetry.new()
	telemetry.events_for(FRAME_TIME, 0.0, true, false)
	var events := telemetry.events_for(FRAME_TIME, -0.5, false, false)
	assert_true(events[0].contains("sem pular"), "cair de uma borda nao e pulo")


func test_slide_start_and_end_are_reported() -> void:
	var telemetry := PlayerTelemetry.new()
	telemetry.events_for(FRAME_TIME, 0.0, true, false)
	var start_events := telemetry.events_for(FRAME_TIME, 0.0, true, true)
	var end_events := telemetry.events_for(FRAME_TIME, 0.0, true, false)
	assert_eq(start_events, ["comecou a deslizar"] as Array[String], "avisa o inicio")
	assert_eq(end_events, ["parou de deslizar"] as Array[String], "avisa o fim")


func test_describe_shows_posture() -> void:
	var text := PlayerTelemetry.describe(Vector3.ZERO, Vector3.ZERO, true, true, false, false)
	assert_true(text.contains("correndo"), "mostra que esta correndo")
	assert_true(text.contains("no chao"), "mostra que esta no chao")
