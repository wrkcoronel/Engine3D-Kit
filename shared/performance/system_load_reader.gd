class_name SystemLoadReader
extends RefCounted

const UNKNOWN := -1
const POLL_MILLISECONDS := 1000
const CPU_COLUMN := "PercentProcessorUtility"
const GPU_3D_TYPE := "3D"
const GPU_GRAPHICS_TYPE := "Graphics_1"

var _thread := Thread.new()
var _mutex := Mutex.new()
var _stopping := false
var _gpu_percent := UNKNOWN
var _gpu_3d_percent := UNKNOWN
var _gpu_graphics_percent := UNKNOWN
var _cpu_percent := UNKNOWN
var _previous_gpu_sample := GpuLoadSample.new()


static func parse_cpu_utility(command_output: String) -> int:
	var table := _parse_csv(command_output)
	var column := _column_index(table, CPU_COLUMN)
	if column == -1:
		return UNKNOWN
	var rows := _data_rows(table)
	if rows.is_empty():
		return UNKNOWN
	var first_row := rows[0] as PackedStringArray
	if column >= first_row.size():
		return UNKNOWN
	var value := first_row[column].strip_edges()
	if not value.is_valid_float():
		return UNKNOWN
	return clampi(roundi(value.to_float()), 0, 100)


static func _parse_csv(command_output: String) -> Array[PackedStringArray]:
	var table: Array[PackedStringArray] = []
	var normalized := command_output.replace("\r", "\n")
	for line: String in normalized.split("\n"):
		var cleaned_line := line.strip_edges()
		if cleaned_line.is_empty():
			continue
		table.append(cleaned_line.split(","))
	return table


static func _column_index(table: Array[PackedStringArray], column_name: String) -> int:
	if table.is_empty():
		return -1
	return table[0].find(column_name)


static func _data_rows(table: Array[PackedStringArray]) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	for row_index: int in range(1, table.size()):
		rows.append(table[row_index])
	return rows


func start() -> void:
	_stopping = false
	_thread.start(_poll_loop)


func stop() -> void:
	_stopping = true
	if _thread.is_started():
		_thread.wait_to_finish()


func gpu_3d_percent() -> int:
	_mutex.lock()
	var value := _gpu_3d_percent
	_mutex.unlock()
	return value


func gpu_graphics_percent() -> int:
	_mutex.lock()
	var value := _gpu_graphics_percent
	_mutex.unlock()
	return value


func gpu_percent() -> int:
	_mutex.lock()
	var value := _gpu_percent
	_mutex.unlock()
	return value


func cpu_percent() -> int:
	_mutex.lock()
	var value := _cpu_percent
	_mutex.unlock()
	return value


func _poll_loop() -> void:
	while not _stopping:
		var gpu_engines := _read_gpu_engines()
		var cpu_value := _read_cpu_percent()
		_mutex.lock()
		_gpu_percent = GpuLoadSample.busiest_percent(gpu_engines)
		_gpu_3d_percent = GpuLoadSample.percent_for_type(gpu_engines, GPU_3D_TYPE)
		_gpu_graphics_percent = GpuLoadSample.percent_for_type(gpu_engines, GPU_GRAPHICS_TYPE)
		_cpu_percent = cpu_value
		_mutex.unlock()
		OS.delay_msec(POLL_MILLISECONDS)


func _read_gpu_engines() -> Dictionary:
	var command_output: Array = []
	var arguments := [
		"path", "Win32_PerfRawData_GPUPerformanceCounters_GPUEngine", "get", "/format:csv"
	]
	var exit_code := OS.execute("wmic", arguments, command_output)
	if exit_code != 0 or command_output.is_empty():
		return {}
	var current_sample := GpuLoadSample.parse(str(command_output[0]))
	var engines := GpuLoadSample.engine_percentages(_previous_gpu_sample, current_sample)
	_previous_gpu_sample = current_sample
	return engines


func _read_cpu_percent() -> int:
	var command_output: Array = []
	var arguments := [
		"path",
		"Win32_PerfFormattedData_Counters_ProcessorInformation",
		"where",
		"Name='_Total'",
		"get",
		"PercentProcessorUtility",
		"/format:csv"
	]
	var exit_code := OS.execute("wmic", arguments, command_output)
	if exit_code != 0 or command_output.is_empty():
		return UNKNOWN
	return parse_cpu_utility(str(command_output[0]))
