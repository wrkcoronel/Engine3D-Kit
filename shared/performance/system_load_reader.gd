class_name SystemLoadReader
extends RefCounted

const UNKNOWN := -1
const POLL_MILLISECONDS := 1000

var _thread := Thread.new()
var _mutex := Mutex.new()
var _stopping := false
var _gpu_percent := UNKNOWN
var _cpu_percent := UNKNOWN


static func parse_percent(command_output: String) -> int:
	for line: String in command_output.split("\n"):
		var cleaned_line := line.strip_edges()
		if cleaned_line.is_valid_int():
			return clampi(cleaned_line.to_int(), 0, 100)
	return UNKNOWN


func start() -> void:
	_stopping = false
	_thread.start(_poll_loop)


func stop() -> void:
	_stopping = true
	if _thread.is_started():
		_thread.wait_to_finish()


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
		var gpu_value := _read_gpu_percent()
		var cpu_value := _read_cpu_percent()
		_mutex.lock()
		_gpu_percent = gpu_value
		_cpu_percent = cpu_value
		_mutex.unlock()
		OS.delay_msec(POLL_MILLISECONDS)


func _read_gpu_percent() -> int:
	var command_output: Array = []
	var arguments := ["--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
	var exit_code := OS.execute("nvidia-smi", arguments, command_output)
	if exit_code != 0 or command_output.is_empty():
		return UNKNOWN
	return parse_percent(str(command_output[0]))


func _read_cpu_percent() -> int:
	var command_output: Array = []
	var arguments := ["cpu", "get", "loadpercentage"]
	var exit_code := OS.execute("wmic", arguments, command_output)
	if exit_code != 0 or command_output.is_empty():
		return UNKNOWN
	return parse_percent(str(command_output[0]))
