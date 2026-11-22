class_name PauseSettingsStore
extends RefCounted

const DEFAULT_PATH := "user://settings.cfg"
const VIDEO_SECTION := "video"
const WORLD_SECTION := "world"
const WINDOW_MODE_KEY := "window_mode"
const ENTITY_ENABLED_KEY := "entity_enabled"

var window_mode := WindowModeSettings.Option.FULLSCREEN
var entity_enabled := true


static func load_from(path: String = DEFAULT_PATH) -> PauseSettingsStore:
	var store := PauseSettingsStore.new()
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return store
	var saved_mode: int = int(
		config.get_value(VIDEO_SECTION, WINDOW_MODE_KEY, int(WindowModeSettings.Option.FULLSCREEN))
	)
	var option_count := WindowModeSettings.OPTION_LABELS.size()
	if saved_mode >= 0 and saved_mode < option_count:
		store.window_mode = saved_mode as WindowModeSettings.Option
	store.entity_enabled = bool(config.get_value(WORLD_SECTION, ENTITY_ENABLED_KEY, true))
	return store


func save_to(path: String = DEFAULT_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value(VIDEO_SECTION, WINDOW_MODE_KEY, int(window_mode))
	config.set_value(WORLD_SECTION, ENTITY_ENABLED_KEY, entity_enabled)
	return config.save(path)
