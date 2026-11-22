extends TestCase

const TEMP_PATH := "user://test_pause_settings.cfg"


func test_returns_defaults_when_file_does_not_exist() -> void:
	_remove_temp_file()
	var store := PauseSettingsStore.load_from(TEMP_PATH)
	assert_eq(
		store.window_mode, WindowModeSettings.Option.FULLSCREEN, "padrao sem arquivo e tela cheia"
	)
	assert_true(store.entity_enabled, "padrao sem arquivo mantem entidade ativa")


func test_saves_and_reloads_window_mode_and_entity_state() -> void:
	_remove_temp_file()
	var saved := PauseSettingsStore.new()
	saved.window_mode = WindowModeSettings.Option.WINDOWED
	saved.entity_enabled = false
	assert_eq(saved.save_to(TEMP_PATH), OK, "salva configuracoes no disco")

	var loaded := PauseSettingsStore.load_from(TEMP_PATH)
	assert_eq(
		loaded.window_mode, WindowModeSettings.Option.WINDOWED, "recarrega modo de tela salvo"
	)
	assert_true(not loaded.entity_enabled, "recarrega entidade desativada")
	_remove_temp_file()


func _remove_temp_file() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
