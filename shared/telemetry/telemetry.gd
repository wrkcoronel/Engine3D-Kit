class_name Telemetry
extends CanvasLayer

const GROUP := "telemetry"
const REPORT_KEY := KEY_F2
const OVERLAY_KEY := KEY_F3
const REPORTS_FOLDER := "user://relatorios/"
const LATEST_REPORT_FILE := "ultimo.txt"
const NOTICE_SECONDS := 5.0
const OVERLAY_EVENT_COUNT := 3
const FONT_SIZE := 14
const OUTLINE_SIZE := 4
const SCREEN_MARGIN := 12.0
const OVERLAY_TOP := 40.0
const DRAW_ABOVE_GAME_LAYER := 10

@export var save_on_close := true
@export var detailed := false

var history := TelemetryLog.new()

var _overlay := Label.new()
var _notice := Label.new()
var _notice_time_left := 0.0


static func record(from: Node, source: String, message: String) -> void:
	var telemetry := _find(from)
	if telemetry == null:
		return
	telemetry.history.add_event(telemetry.now(), source, message)


static func sample(from: Node, source: String, text: String) -> void:
	var telemetry := _find(from)
	if telemetry == null:
		return
	telemetry.history.add_sample(telemetry.now(), source, text)


static func wants_detail(from: Node) -> bool:
	if TelemetryDetailWindow.asked_on_command_line():
		return true
	var telemetry := _find(from)
	if telemetry == null:
		return false
	return telemetry.detailed


static func _find(from: Node) -> Telemetry:
	if not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as Telemetry


func _ready() -> void:
	add_to_group(GROUP)
	layer = DRAW_ABOVE_GAME_LAYER
	_setup_label(_overlay, Vector2(SCREEN_MARGIN, OVERLAY_TOP))
	_setup_label(_notice, Vector2(SCREEN_MARGIN, SCREEN_MARGIN))
	_overlay.visible = false
	_notice.visible = false
	history.event_added.connect(_print_event)


func _print_event(event_line: String) -> void:
	print(event_line)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if not key.pressed or key.echo:
		return
	if key.keycode == REPORT_KEY:
		save_report("o jogador apertou F2")
	elif key.keycode == OVERLAY_KEY:
		_overlay.visible = not _overlay.visible


func _process(delta: float) -> void:
	_update_notice(delta)
	if _overlay.visible:
		_overlay.text = _overlay_text()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if save_on_close:
		save_report("o jogo foi fechado")


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func save_report(reason: String) -> String:
	history.add_event(now(), "jogador", "MARCA: " + reason)
	var report_text := history.build_report(now(), reason)
	DirAccess.make_dir_recursive_absolute(REPORTS_FOLDER)
	var report_path := REPORTS_FOLDER + "relatorio_%s.txt" % _file_timestamp()
	_write_file(report_path, report_text)
	_write_file(REPORTS_FOLDER + LATEST_REPORT_FILE, report_text)
	var full_path := ProjectSettings.globalize_path(report_path)
	print("relatorio de telemetria salvo em ", full_path)
	_show_notice("Relatorio salvo: " + full_path)
	return full_path


func _write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("nao foi possivel salvar o relatorio em " + path)
		return
	file.store_string(text)
	file.close()


func _file_timestamp() -> String:
	var date_and_time := Time.get_datetime_string_from_system()
	return date_and_time.replace(":", "-")


func _overlay_text() -> String:
	var lines: PackedStringArray = []
	lines.append("TELEMETRIA  (F3 esconde, F2 salva relatorio)")
	lines.append("controlando: " + history.current_source)
	var state_lines := history.latest_sample.split(" | ")
	lines.append_array(state_lines)
	lines.append("")
	lines.append("ultimos eventos:")
	lines.append_array(PackedStringArray(history.recent_events(OVERLAY_EVENT_COUNT)))
	return "\n".join(lines)


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice.visible = true
	_notice_time_left = NOTICE_SECONDS


func _update_notice(delta: float) -> void:
	if not _notice.visible:
		return
	_notice_time_left -= delta
	if _notice_time_left <= 0.0:
		_notice.visible = false


func _setup_label(label: Label, screen_position: Vector2) -> void:
	label.position = screen_position
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
