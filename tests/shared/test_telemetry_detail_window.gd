extends TestCase


func test_disabled_window_logs_nothing() -> void:
	var window := TelemetryDetailWindow.new()
	window.push_frame("frame 1")
	assert_eq(window.anomaly_happened().size(), 0, "desligada nao registra nada")


func test_anomaly_flushes_frames_before() -> void:
	var window := TelemetryDetailWindow.new()
	window.enabled = true
	for frame_index: int in TelemetryDetailWindow.WINDOW_FRAMES + 10:
		window.push_frame("frame %d" % frame_index)
	var before := window.anomaly_happened()
	assert_eq(before.size(), TelemetryDetailWindow.WINDOW_FRAMES, "guarda so os ultimos 0.5 s")
	assert_true(before[0].begins_with("detalhe antes"), "marca as linhas de antes")


func test_frames_after_anomaly_are_logged_then_stop() -> void:
	var window := TelemetryDetailWindow.new()
	window.enabled = true
	window.anomaly_happened()
	var logged_after := 0
	for frame_index: int in TelemetryDetailWindow.WINDOW_FRAMES + 10:
		logged_after += window.push_frame("frame %d" % frame_index).size()
	assert_eq(logged_after, TelemetryDetailWindow.WINDOW_FRAMES, "registra so os 0.5 s depois")
