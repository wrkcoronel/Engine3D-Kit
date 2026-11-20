class_name TelemetryDetailWindow
extends RefCounted

const WINDOW_FRAMES := 30
const COMMAND_LINE_FLAG := "--telemetria-detalhada"

var enabled := false

var _recent_lines: Array[String] = []
var _frames_left_after_anomaly := 0


static func asked_on_command_line() -> bool:
	return OS.get_cmdline_user_args().has(COMMAND_LINE_FLAG)


func push_frame(frame_line: String) -> Array[String]:
	var lines_to_log: Array[String] = []
	if not enabled:
		return lines_to_log
	if _frames_left_after_anomaly > 0:
		_frames_left_after_anomaly -= 1
		lines_to_log.append("detalhe depois | " + frame_line)
		return lines_to_log
	_recent_lines.append(frame_line)
	if _recent_lines.size() > WINDOW_FRAMES:
		_recent_lines.pop_front()
	return lines_to_log


func anomaly_happened() -> Array[String]:
	var lines_to_log: Array[String] = []
	if not enabled:
		return lines_to_log
	for recent_line: String in _recent_lines:
		lines_to_log.append("detalhe antes  | " + recent_line)
	_recent_lines.clear()
	_frames_left_after_anomaly = WINDOW_FRAMES
	return lines_to_log


func clear() -> void:
	_recent_lines.clear()
	_frames_left_after_anomaly = 0
