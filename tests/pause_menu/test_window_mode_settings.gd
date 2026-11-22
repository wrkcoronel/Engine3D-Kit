extends TestCase


func test_maps_fullscreen_modes_to_fullscreen_option() -> void:
	assert_eq(
		WindowModeSettings.option_for_window_mode(Window.MODE_FULLSCREEN),
		WindowModeSettings.Option.FULLSCREEN,
		"tela cheia mapeia para FULLSCREEN"
	)
	assert_eq(
		WindowModeSettings.option_for_window_mode(Window.MODE_EXCLUSIVE_FULLSCREEN),
		WindowModeSettings.Option.FULLSCREEN,
		"tela cheia exclusiva mapeia para FULLSCREEN"
	)


func test_maps_maximized_and_windowed_modes() -> void:
	assert_eq(
		WindowModeSettings.option_for_window_mode(Window.MODE_MAXIMIZED),
		WindowModeSettings.Option.MAXIMIZED,
		"maximizada mapeia para MAXIMIZED"
	)
	assert_eq(
		WindowModeSettings.option_for_window_mode(Window.MODE_WINDOWED),
		WindowModeSettings.Option.WINDOWED,
		"janela mapeia para WINDOWED"
	)


func test_maps_options_back_to_window_modes() -> void:
	assert_eq(
		WindowModeSettings.window_mode_for_option(WindowModeSettings.Option.FULLSCREEN),
		Window.MODE_FULLSCREEN,
		"FULLSCREEN vira MODE_FULLSCREEN"
	)
	assert_eq(
		WindowModeSettings.window_mode_for_option(WindowModeSettings.Option.MAXIMIZED),
		Window.MODE_MAXIMIZED,
		"MAXIMIZED vira MODE_MAXIMIZED"
	)
	assert_eq(
		WindowModeSettings.window_mode_for_option(WindowModeSettings.Option.WINDOWED),
		Window.MODE_WINDOWED,
		"WINDOWED vira MODE_WINDOWED"
	)
