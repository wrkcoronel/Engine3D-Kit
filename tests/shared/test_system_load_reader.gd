extends TestCase

const CPU_HEADER := "\r\r\nNode,PercentProcessorTime,PercentProcessorUtility\r\r\n"
const CPU_OUTPUT := CPU_HEADER + "PC,2,37\r\r\n\r\r\n"
const ENGINE_3D := "p1_phys_0_eng_0_engtype_3D"
const SECOND := 10000000


func test_cpu_utility_is_read_by_column_name() -> void:
	assert_eq(SystemLoadReader.parse_cpu_utility(CPU_OUTPUT), 37, "usa a utilizacao")


func test_cpu_garbage_is_unknown() -> void:
	assert_eq(SystemLoadReader.parse_cpu_utility("falhou"), SystemLoadReader.UNKNOWN, "texto")
	assert_eq(SystemLoadReader.parse_cpu_utility(""), SystemLoadReader.UNKNOWN, "vazio")


func test_cpu_over_100_is_clamped() -> void:
	var output := "Node,PercentProcessorTime,PercentProcessorUtility\r\nPC,90,134\r\n"
	assert_eq(SystemLoadReader.parse_cpu_utility(output), 100, "limite de 100")


func test_gpu_percent_is_busy_time_over_elapsed_time() -> void:
	var previous := _sample(SECOND, {ENGINE_3D: 0})
	var current := _sample(2 * SECOND, {ENGINE_3D: 4000000})
	assert_eq(GpuLoadSample.busiest_engine_percent(previous, current), 40, "40 por cento")


func test_gpu_sums_processes_on_the_same_engine_and_takes_the_busiest() -> void:
	var other_process_3d := "p2_phys_0_eng_0_engtype_3D"
	var copy_engine := "p2_phys_0_eng_3_engtype_Copy"
	var previous := _sample(SECOND, {ENGINE_3D: 0, other_process_3d: 0, copy_engine: 0})
	var current := _sample(
		2 * SECOND, {ENGINE_3D: 3000000, other_process_3d: 2500000, copy_engine: 1000000}
	)
	assert_eq(GpuLoadSample.busiest_engine_percent(previous, current), 55, "soma por motor")


func test_gpu_without_a_previous_sample_is_unknown() -> void:
	var empty := GpuLoadSample.new()
	var current := _sample(2 * SECOND, {ENGINE_3D: 4000000})
	var percent := GpuLoadSample.busiest_engine_percent(empty, current)
	assert_eq(percent, SystemLoadReader.UNKNOWN, "primeira leitura")


func test_gpu_ignores_processes_that_appeared_between_samples() -> void:
	var new_process_3d := "p9_phys_0_eng_0_engtype_3D"
	var previous := _sample(SECOND, {ENGINE_3D: 0})
	var current := _sample(2 * SECOND, {ENGINE_3D: 1000000, new_process_3d: 9000000})
	assert_eq(GpuLoadSample.busiest_engine_percent(previous, current), 10, "so quem ja existia")


func test_gpu_is_clamped_to_100() -> void:
	var previous := _sample(SECOND, {ENGINE_3D: 0})
	var current := _sample(2 * SECOND, {ENGINE_3D: 18000000})
	assert_eq(GpuLoadSample.busiest_engine_percent(previous, current), 100, "limite de 100")


func test_gpu_garbage_gives_an_invalid_sample() -> void:
	assert_true(not GpuLoadSample.parse("falhou").is_valid(), "texto")
	assert_true(not GpuLoadSample.parse("").is_valid(), "vazio")


func test_gpu_columns_are_found_by_name() -> void:
	var output := "\r\r\nNode,Name,Timestamp_Sys100NS,UtilizationPercentage\r\r\n"
	output += "PC,%s,500,77\r\r\n" % ENGINE_3D
	var sample := GpuLoadSample.parse(output)
	assert_true(sample.is_valid(), "valida")
	assert_eq(sample.timestamp, 500.0, "hora")
	assert_eq(sample.usage_by_instance[ENGINE_3D], 77.0, "uso")


func test_gpu_engine_types_are_reported_separately() -> void:
	var graphics_engine := "p1_phys_0_eng_9_engtype_Graphics_1"
	var previous := _sample(SECOND, {ENGINE_3D: 0, graphics_engine: 0})
	var current := _sample(2 * SECOND, {ENGINE_3D: 1200000, graphics_engine: 2300000})
	var engines := GpuLoadSample.engine_percentages(previous, current)
	assert_eq(GpuLoadSample.percent_for_type(engines, "3D"), 12, "motor 3D")
	assert_eq(GpuLoadSample.percent_for_type(engines, "Graphics_1"), 23, "motor Graphics_1")
	assert_eq(GpuLoadSample.busiest_percent(engines), 23, "o mais ocupado")


func test_gpu_type_without_instances_is_zero_and_no_data_is_unknown() -> void:
	var previous := _sample(SECOND, {ENGINE_3D: 0})
	var current := _sample(2 * SECOND, {ENGINE_3D: 1200000})
	var engines := GpuLoadSample.engine_percentages(previous, current)
	assert_eq(GpuLoadSample.percent_for_type(engines, "Graphics_1"), 0, "tipo ausente")
	var none := GpuLoadSample.engine_percentages(GpuLoadSample.new(), current)
	assert_eq(GpuLoadSample.percent_for_type(none, "3D"), SystemLoadReader.UNKNOWN, "sem dados")


func test_overlay_text_shows_each_gpu_engine() -> void:
	var text := PerformanceOverlay.build_text(60, 12, 8, 23, 4.24)
	assert_eq(text, "FPS 60  CPU 12%  3D 8%  G1 23%  GPU 4.2 ms", "texto")


func test_overlay_text_marks_unknown_values() -> void:
	var unknown := SystemLoadReader.UNKNOWN
	var text := PerformanceOverlay.build_text(60, unknown, unknown, unknown, 0.0)
	assert_eq(text, "FPS 60  CPU --  3D --  G1 --  GPU 0.0 ms", "texto")


func _sample(timestamp: int, usage_by_instance: Dictionary) -> GpuLoadSample:
	var output := "Node,Name,Timestamp_Sys100NS,UtilizationPercentage\r\n"
	for instance_name: String in usage_by_instance:
		var usage := usage_by_instance[instance_name] as int
		output += "PC,%s,%d,%d\r\n" % [instance_name, timestamp, usage]
	return GpuLoadSample.parse(output)
