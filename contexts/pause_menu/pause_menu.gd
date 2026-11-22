class_name PauseMenu
extends CanvasLayer

const MENU_LAYER := 20

var _is_open := false
var _store := PauseSettingsStore.new()
var _view: PauseMenuView


func _ready() -> void:
	layer = MENU_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_saved_settings()
	WindowModeSettings.apply_initial_option(get_window(), _store.window_mode)
	_apply_saved_entity_state.call_deferred()
	_view = PauseMenuView.new()
	_view.visible = false
	add_child(_view)
	_connect_view()


func _exit_tree() -> void:
	if _is_open and get_tree() != null:
		get_tree().paused = false


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if not key.pressed or key.echo:
		return
	if key.keycode != KEY_ESCAPE:
		return
	handle_escape()
	get_viewport().set_input_as_handled()


func handle_escape() -> void:
	if _is_open and is_settings_open():
		toggle_settings()
		return
	toggle_menu()


func toggle_menu() -> void:
	if _is_open:
		close_menu()
		return
	open_menu()


func open_menu() -> void:
	_is_open = true
	_refresh_settings_state()
	_view.set_settings_visible(false)
	_view.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_menu() -> void:
	_is_open = false
	_view.set_settings_visible(false)
	_view.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _is_open


func toggle_settings() -> void:
	if not _is_open:
		return
	var next_visible := not _view.is_settings_visible()
	if next_visible:
		_refresh_settings_state()
	_view.set_settings_visible(next_visible)


func is_settings_open() -> bool:
	if _view == null:
		return false
	return _view.is_settings_visible()


func select_window_mode(option_index: int) -> void:
	var option_count := WindowModeSettings.OPTION_LABELS.size()
	var wrapped := posmod(option_index, option_count)
	_store.window_mode = wrapped as WindowModeSettings.Option
	WindowModeSettings.apply_option(get_window(), _store.window_mode)
	_view.set_selected_window_mode(wrapped)
	_save_settings()


func step_window_mode(delta: int) -> void:
	select_window_mode(int(_store.window_mode) + delta)


func current_window_option() -> WindowModeSettings.Option:
	return _store.window_mode


func select_settings_tab(tab: PauseSettingsPage.Tab) -> void:
	if _view != null:
		_view.select_settings_tab(tab)


func current_settings_tab() -> PauseSettingsPage.Tab:
	if _view == null:
		return PauseSettingsPage.Tab.VIDEO
	return _view.current_settings_tab()


func set_entity_enabled(enabled: bool) -> void:
	_store.entity_enabled = enabled
	EntityToggle.set_enabled(get_tree(), enabled)
	_view.set_entity_state(EntityToggle.has_entity(get_tree()), enabled)
	_save_settings()


func toggle_entity_enabled() -> void:
	var currently_enabled := EntityToggle.is_enabled(get_tree())
	set_entity_enabled(not currently_enabled)


func teleport_to_ramp() -> void:
	WorldTeleporter.teleport_to_ramp(get_tree())
	close_menu()


func teleport_to_motel() -> void:
	WorldTeleporter.teleport_to_motel(get_tree())
	close_menu()


func bring_car_to_player() -> void:
	WorldTeleporter.bring_car_to_player(get_tree())
	close_menu()


func teleport_to_car() -> void:
	WorldTeleporter.teleport_player_to_car(get_tree())
	close_menu()


func _connect_view() -> void:
	_view.play_requested.connect(close_menu)
	_view.settings_toggled.connect(toggle_settings)
	_view.quit_requested.connect(_quit_game)
	_view.window_mode_stepped.connect(step_window_mode)
	_view.entity_toggled.connect(toggle_entity_enabled)
	_view.teleport_ramp_requested.connect(teleport_to_ramp)
	_view.teleport_motel_requested.connect(teleport_to_motel)
	_view.bring_car_requested.connect(bring_car_to_player)
	_view.teleport_to_car_requested.connect(teleport_to_car)


func _refresh_settings_state() -> void:
	if DisplayServer.get_name() != "headless":
		_store.window_mode = WindowModeSettings.current_option(get_window())
	_view.set_selected_window_mode(int(_store.window_mode))
	var tree := get_tree()
	var has_entity := EntityToggle.has_entity(tree)
	var entity_enabled := EntityToggle.is_enabled(tree)
	_view.set_entity_state(has_entity, entity_enabled)


func _load_saved_settings() -> void:
	if DisplayServer.get_name() == "headless":
		_store = PauseSettingsStore.new()
		return
	_store = PauseSettingsStore.load_from()


func _save_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_store.save_to()


func _apply_saved_entity_state() -> void:
	if get_tree() == null:
		return
	if not _store.entity_enabled:
		EntityToggle.set_enabled(get_tree(), false)


func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
