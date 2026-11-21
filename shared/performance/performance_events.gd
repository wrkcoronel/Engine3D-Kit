class_name PerformanceEvents
extends RefCounted

const LOW_FPS := 30
const RECOVERED_FPS := 45
const BUSY_PERCENT := 95

var _fps_is_low := false
var _gpu_is_busy := false


func events_for(frames_per_second: int, cpu_percent: int, gpu_percent: int) -> Array[String]:
	var events: Array[String] = []
	events.append_array(_fps_events(frames_per_second, cpu_percent, gpu_percent))
	events.append_array(_gpu_events(gpu_percent))
	return events


func _fps_events(frames_per_second: int, cpu_percent: int, gpu_percent: int) -> Array[String]:
	var events: Array[String] = []
	if not _fps_is_low and frames_per_second < LOW_FPS:
		_fps_is_low = true
		var cause := "FPS caiu para %d (CPU %d%%, GPU %d%%)"
		events.append(cause % [frames_per_second, cpu_percent, gpu_percent])
	elif _fps_is_low and frames_per_second >= RECOVERED_FPS:
		_fps_is_low = false
		events.append("FPS voltou a %d" % frames_per_second)
	return events


func _gpu_events(gpu_percent: int) -> Array[String]:
	var events: Array[String] = []
	if not _gpu_is_busy and gpu_percent >= BUSY_PERCENT:
		_gpu_is_busy = true
		events.append("GPU no limite: %d%%" % gpu_percent)
	elif _gpu_is_busy and gpu_percent < BUSY_PERCENT - 10:
		_gpu_is_busy = false
		events.append("GPU aliviou: %d%%" % gpu_percent)
	return events
