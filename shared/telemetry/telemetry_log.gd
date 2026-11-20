class_name TelemetryLog
extends RefCounted

signal event_added(event_line: String)

const MAX_EVENTS := 400
const MAX_SAMPLES := 300
const SAMPLE_INTERVAL := 0.1
const MODE_SOURCE := "modo"

var current_source := ""
var latest_sample := ""

var _events: Array[String] = []
var _samples: Array[String] = []
var _last_sample_time := -INF


static func format_vector(vector: Vector3) -> String:
	var x := round_to_two_decimals(vector.x)
	var y := round_to_two_decimals(vector.y)
	var z := round_to_two_decimals(vector.z)
	return "(%.2f, %.2f, %.2f)" % [x, y, z]


static func round_to_two_decimals(value: float) -> float:
	return roundf(value * 100.0) / 100.0


static func format_line(clock: String, time: float, source: String, message: String) -> String:
	return "[%s | %8.2fs] %-8s | %s" % [clock, time, source, message]


static func clock_text(unix_time: float) -> String:
	var total_milliseconds := roundi(unix_time * 1000.0)
	var milliseconds := total_milliseconds % 1000
	var whole_seconds := floori((total_milliseconds - milliseconds) / 1000.0)
	var time_of_day := Time.get_time_string_from_unix_time(whole_seconds)
	return "%s.%03d" % [time_of_day, milliseconds]


static func local_unix_time() -> float:
	var time_zone := Time.get_time_zone_from_system()
	var bias_minutes := time_zone["bias"] as int
	return Time.get_unix_time_from_system() + bias_minutes * 60.0


static func clock_now() -> String:
	return clock_text(local_unix_time())


static func describe_node(node: Node) -> String:
	var parent := node.get_parent()
	if parent == null:
		return String(node.name)
	return "%s/%s" % [parent.name, node.name]


func add_event(time: float, source: String, message: String) -> void:
	var event_line := format_line(clock_now(), time, source, message)
	_push_limited(_events, event_line, MAX_EVENTS)
	event_added.emit(event_line)


func add_sample(time: float, source: String, text: String) -> void:
	if source != current_source:
		add_event(time, MODE_SOURCE, "agora controlando: " + source)
		current_source = source
		_last_sample_time = -INF
	latest_sample = text
	var time_since_last_sample := time - _last_sample_time
	if time_since_last_sample < SAMPLE_INTERVAL:
		return
	_last_sample_time = time
	var sample_line := format_line(clock_now(), time, source, text)
	_push_limited(_samples, sample_line, MAX_SAMPLES)


func event_count() -> int:
	return _events.size()


func sample_count() -> int:
	return _samples.size()


func recent_events(count: int) -> Array[String]:
	var first_index := maxi(_events.size() - count, 0)
	var recent: Array[String] = []
	for index: int in range(first_index, _events.size()):
		recent.append(_events[index])
	return recent


func build_report(time: float, reason: String) -> String:
	var lines: PackedStringArray = []
	lines.append("RELATORIO DE TELEMETRIA")
	lines.append("motivo: " + reason)
	lines.append("gerado em: " + Time.get_datetime_string_from_system(false, true))
	lines.append("tempo de jogo: %.2f s" % time)
	lines.append("controlando agora: " + current_source)
	lines.append("estado agora: " + latest_sample)
	lines.append("")
	lines.append("== EVENTOS (mais antigo primeiro, ate %d) ==" % MAX_EVENTS)
	lines.append_array(PackedStringArray(_events))
	lines.append("")
	lines.append(_samples_title())
	lines.append_array(PackedStringArray(_samples))
	return "\n".join(lines)


func _samples_title() -> String:
	var samples_per_second := roundi(1.0 / SAMPLE_INTERVAL)
	var seconds_of_samples := MAX_SAMPLES * SAMPLE_INTERVAL
	return (
		"== AMOSTRAS (%d por segundo, ultimos %.0f s) ==" % [samples_per_second, seconds_of_samples]
	)


func _push_limited(lines: Array[String], new_line: String, limit: int) -> void:
	lines.append(new_line)
	if lines.size() > limit:
		lines.pop_front()
