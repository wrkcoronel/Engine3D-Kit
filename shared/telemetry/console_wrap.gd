class_name ConsoleWrap
extends RefCounted

const MAX_WIDTH := 100
const SEPARATOR := " | "
const HEADER_END := "] "


static func wrap_event(event_line: String, max_width: int = MAX_WIDTH) -> String:
	if event_line.length() <= max_width:
		return event_line
	var message_start := _message_start(event_line)
	if message_start < 0:
		return "\n".join(PackedStringArray(wrap_words(event_line, max_width)))
	var prefix := event_line.substr(0, message_start)
	var message := event_line.substr(message_start)
	var text_width := maxi(max_width - prefix.length(), 20)
	var text_indent := " ".repeat(prefix.length())
	var bar_indent := " ".repeat(prefix.length() - SEPARATOR.length() + 1)
	var lines: PackedStringArray = []
	var segments := message.split(SEPARATOR)
	for segment_index: int in segments.size():
		var segment_lines := wrap_words(segments[segment_index], text_width)
		for line_index: int in segment_lines.size():
			lines.append(
				(
					_line_start(prefix, text_indent, bar_indent, segment_index, line_index)
					+ segment_lines[line_index]
				)
			)
	return "\n".join(lines)


static func wrap_words(text: String, width: int) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word: String in tokens(text):
		if current.is_empty():
			current = word
			continue
		if current.length() + 1 + word.length() > width:
			lines.append(current)
			current = word
			continue
		current += " " + word
	lines.append(current)
	return lines


static func tokens(text: String) -> Array[String]:
	var found: Array[String] = []
	var current := ""
	var depth := 0
	for character: String in text:
		if character == "(":
			depth += 1
		elif character == ")":
			depth = maxi(depth - 1, 0)
		if character == " " and depth == 0:
			if not current.is_empty():
				found.append(current)
				current = ""
			continue
		current += character
	if not current.is_empty():
		found.append(current)
	return found


static func _line_start(
	prefix: String, text_indent: String, bar_indent: String, segment_index: int, line_index: int
) -> String:
	if segment_index == 0 and line_index == 0:
		return prefix
	if line_index == 0:
		return bar_indent + "| "
	return text_indent


static func _message_start(event_line: String) -> int:
	var header_close := event_line.find(HEADER_END)
	if header_close < 0:
		return -1
	var separator_index := event_line.find(SEPARATOR, header_close)
	if separator_index < 0:
		return -1
	return separator_index + SEPARATOR.length()
