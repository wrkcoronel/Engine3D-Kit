class_name PerformanceOverlay
extends CanvasLayer

const SOURCE := "desempenho"
const STARTUP_GRACE_SECONDS := 5.0
const FONT_SIZE := 11
const OUTLINE_SIZE := 3
const MARGIN := Vector2(6.0, 4.0)
const REFRESH_SECONDS := 0.25
const DRAW_ABOVE_TELEMETRY_LAYER := 11
const UNKNOWN_TEXT := "--"

var _label := Label.new()
var _reader := SystemLoadReader.new()
var _render_time := RenderTimeReader.new()
var _events := PerformanceEvents.new()
var _seconds_until_refresh := 0.0
var _seconds_alive := 0.0


func _ready() -> void:
	layer = DRAW_ABOVE_TELEMETRY_LAYER
	_setup_label()
	add_child(_label)
	_reader.start()
	_render_time.start(get_viewport())


func _exit_tree() -> void:
	_reader.stop()
	_render_time.stop()


func _process(delta: float) -> void:
	_seconds_alive += delta
	_render_time.update()
	_seconds_until_refresh -= delta
	if _seconds_until_refresh > 0.0:
		return
	_seconds_until_refresh = REFRESH_SECONDS
	var frames_per_second := int(Engine.get_frames_per_second())
	var cpu_percent := _reader.cpu_percent()
	var gpu_percent := _reader.gpu_percent()
	var text := build_text(
		frames_per_second,
		cpu_percent,
		_reader.gpu_3d_percent(),
		_reader.gpu_graphics_percent(),
		_render_time.gpu_milliseconds
	)
	_label.text = text
	Telemetry.performance(self, text)
	if _seconds_alive < STARTUP_GRACE_SECONDS:
		return
	for event: String in _events.events_for(frames_per_second, cpu_percent, gpu_percent):
		Telemetry.record(self, SOURCE, event)


static func build_text(
	frames_per_second: int,
	cpu_percent: int,
	gpu_3d_percent: int,
	gpu_graphics_percent: int,
	gpu_milliseconds: float
) -> String:
	var cpu_text := _percent_text(cpu_percent)
	var gpu_3d_text := _percent_text(gpu_3d_percent)
	var gpu_graphics_text := _percent_text(gpu_graphics_percent)
	var template := "FPS %d  CPU %s  3D %s  G1 %s  GPU %.1f ms"
	return (
		template % [frames_per_second, cpu_text, gpu_3d_text, gpu_graphics_text, gpu_milliseconds]
	)


static func _percent_text(percent: int) -> String:
	if percent == SystemLoadReader.UNKNOWN:
		return UNKNOWN_TEXT
	return "%d%%" % percent


func _setup_label() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas"])
	_label.position = MARGIN
	_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
