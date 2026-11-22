class_name WindowModeSettings
extends RefCounted

enum Option { FULLSCREEN, MAXIMIZED, WINDOWED }

const DEFAULT_WINDOWED_SIZE := Vector2i(1280, 720)
const OPTION_LABELS: Array[String] = ["Tela cheia", "Janela maximizada", "Janela"]

static var _initial_fullscreen_applied := false


static func option_for_window_mode(window_mode: Window.Mode) -> Option:
	if window_mode == Window.MODE_FULLSCREEN:
		return Option.FULLSCREEN
	if window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		return Option.FULLSCREEN
	if window_mode == Window.MODE_MAXIMIZED:
		return Option.MAXIMIZED
	return Option.WINDOWED


static func window_mode_for_option(option: Option) -> Window.Mode:
	if option == Option.FULLSCREEN:
		return Window.MODE_FULLSCREEN
	if option == Option.MAXIMIZED:
		return Window.MODE_MAXIMIZED
	return Window.MODE_WINDOWED


static func apply_initial_fullscreen(window: Window) -> void:
	apply_initial_option(window, Option.FULLSCREEN)


static func apply_initial_option(window: Window, option: Option) -> void:
	if _initial_fullscreen_applied:
		return
	_initial_fullscreen_applied = true
	apply_option(window, option)


static func apply_option(window: Window, option: Option) -> void:
	if window == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var target_mode := window_mode_for_option(option)
	window.mode = target_mode
	if option == Option.WINDOWED:
		_center_windowed(window)


static func current_option(window: Window) -> Option:
	if window == null:
		return Option.FULLSCREEN
	if DisplayServer.get_name() == "headless":
		return Option.FULLSCREEN
	return option_for_window_mode(window.mode)


static func _center_windowed(window: Window) -> void:
	var screen := window.current_screen
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var width := mini(DEFAULT_WINDOWED_SIZE.x, usable.size.x)
	var height := mini(DEFAULT_WINDOWED_SIZE.y, usable.size.y)
	var target_size := Vector2i(width, height)
	window.size = target_size
	var offset_x := floori(float(usable.size.x - target_size.x) * 0.5)
	var offset_y := floori(float(usable.size.y - target_size.y) * 0.5)
	window.position = usable.position + Vector2i(offset_x, offset_y)
