extends TestCase


func test_low_fps_is_reported_once_with_cpu_and_gpu() -> void:
	var events := PerformanceEvents.new()
	var first := events.events_for(20, 30, 99)
	var second := events.events_for(18, 30, 99)
	assert_true(
		first.any(func(line: String) -> bool: return line.contains("FPS caiu para 20")), "avisa"
	)
	assert_true(
		first.any(func(line: String) -> bool: return line.contains("GPU 99%")), "traz a gpu"
	)
	assert_eq(second.size(), 0, "nao repete enquanto continua baixo")


func test_fps_recovery_is_reported() -> void:
	var events := PerformanceEvents.new()
	events.events_for(20, 10, 10)
	var between := events.events_for(35, 10, 10)
	var recovered := events.events_for(60, 10, 10)
	assert_eq(between.size(), 0, "histerese: 35 ainda nao e recuperado")
	assert_eq(recovered.size(), 1, "avisa a recuperacao")


func test_gpu_at_limit_is_reported_once() -> void:
	var events := PerformanceEvents.new()
	var first := events.events_for(60, 10, 97)
	var second := events.events_for(60, 10, 98)
	assert_eq(first.size(), 1, "avisa GPU no limite")
	assert_eq(second.size(), 0, "nao repete")


func test_unknown_gpu_never_counts_as_busy() -> void:
	var events := PerformanceEvents.new()
	var result := events.events_for(60, -1, -1)
	assert_eq(result.size(), 0, "sem leitura nao ha evento")
