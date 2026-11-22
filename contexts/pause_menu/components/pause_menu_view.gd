class_name PauseMenuView
extends Control

signal play_requested
signal settings_toggled
signal quit_requested
signal window_mode_stepped(delta: int)
signal entity_toggled
signal teleport_ramp_requested
signal teleport_motel_requested
signal bring_car_requested
signal teleport_to_car_requested

const MARGIN_HORIZONTAL := 96
const MARGIN_TOP := 64
const FOOTER_HEIGHT := 54.0
const DEFAULT_PAUSE_HINT := "Sair do menu de pausa e voltar para o jogo."
const DEFAULT_SETTINGS_HINT := "Ajuste a tela, a entidade ou use o teleporte."

var _backdrop_material: ShaderMaterial
var _title_label: Label
var _pause_page: VBoxContainer
var _settings_page: PauseSettingsPage
var _footer_description: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_backdrop()
	_build_main_layout()
	_build_footer()
	set_settings_visible(false)


func set_settings_visible(shown: bool) -> void:
	if _pause_page == null or _settings_page == null:
		return
	_pause_page.visible = not shown
	_settings_page.visible = shown
	if _backdrop_material != null:
		var mode_value := 1.0 if shown else 0.0
		_backdrop_material.set_shader_parameter("settings_mode", mode_value)
	if shown:
		_title_label.text = "CONFIGURAÇÕES"
		_set_description(DEFAULT_SETTINGS_HINT)
		return
	_title_label.text = "PAUSA"
	_set_description(DEFAULT_PAUSE_HINT)


func is_settings_visible() -> bool:
	if _settings_page == null:
		return false
	return _settings_page.visible


func set_selected_window_mode(option_index: int) -> void:
	if _settings_page != null:
		_settings_page.set_selected_window_mode(option_index)


func set_entity_state(available: bool, enabled: bool) -> void:
	if _settings_page != null:
		_settings_page.set_entity_state(available, enabled)


func select_settings_tab(tab: PauseSettingsPage.Tab) -> void:
	if _settings_page != null:
		_settings_page.select_tab(tab)


func current_settings_tab() -> PauseSettingsPage.Tab:
	if _settings_page == null:
		return PauseSettingsPage.Tab.VIDEO
	return _settings_page.current_tab()


func _build_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color.WHITE
	_backdrop_material = PauseMenuStyle.backdrop_material()
	backdrop.material = _backdrop_material
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)


func _build_main_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", MARGIN_HORIZONTAL)
	margin.add_theme_constant_override("margin_right", MARGIN_HORIZONTAL)
	margin.add_theme_constant_override("margin_top", MARGIN_TOP)
	margin.add_theme_constant_override("margin_bottom", int(FOOTER_HEIGHT) + 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 18)
	root_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root_column)

	_title_label = Label.new()
	_title_label.text = "PAUSA"
	PauseMenuStyle.apply_title_style(_title_label)
	root_column.add_child(_title_label)

	root_column.add_child(PauseMenuStyle.make_divider())

	var content_spacer := Control.new()
	content_spacer.custom_minimum_size = Vector2(0.0, 8.0)
	content_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_column.add_child(content_spacer)

	_build_pause_page(root_column)
	_build_settings_page(root_column)


func _build_pause_page(parent: VBoxContainer) -> void:
	_pause_page = VBoxContainer.new()
	_pause_page.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_pause_page.add_theme_constant_override("separation", 6)
	parent.add_child(_pause_page)

	_add_menu_button(_pause_page, "Jogar", DEFAULT_PAUSE_HINT, _on_play_pressed)
	_add_menu_button(
		_pause_page,
		"Configurações",
		"Abrir opções de tela, entidade e teleporte.",
		_on_settings_pressed
	)
	_add_menu_button(_pause_page, "Sair", "Fechar o jogo.", _on_quit_pressed)


func _build_settings_page(parent: VBoxContainer) -> void:
	_settings_page = PauseSettingsPage.new()
	_settings_page.visible = false
	_settings_page.back_requested.connect(_on_settings_pressed)
	_settings_page.window_mode_stepped.connect(_on_window_mode_stepped)
	_settings_page.entity_toggled.connect(_on_entity_toggled)
	_settings_page.teleport_ramp_requested.connect(_on_teleport_ramp_pressed)
	_settings_page.teleport_motel_requested.connect(_on_teleport_motel_pressed)
	_settings_page.bring_car_requested.connect(_on_bring_car_pressed)
	_settings_page.teleport_to_car_requested.connect(_on_teleport_to_car_pressed)
	_settings_page.description_hovered.connect(_set_description)
	parent.add_child(_settings_page)


func _build_footer() -> void:
	var footer := ColorRect.new()
	footer.anchor_left = 0.0
	footer.anchor_right = 1.0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_top = -FOOTER_HEIGHT
	footer.color = PauseMenuStyle.FOOTER_COLOR
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)

	_footer_description = Label.new()
	_footer_description.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_footer_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_footer_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseMenuStyle.apply_footer_style(_footer_description)
	footer.add_child(_footer_description)

	var hint_label := Label.new()
	hint_label.anchor_left = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 0.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = -220.0
	hint_label.offset_right = -42.0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.text = "[Esc]  Voltar"
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseMenuStyle.apply_footer_style(hint_label)
	footer.add_child(hint_label)


func _add_menu_button(
	parent: VBoxContainer, text: String, description: String, handler: Callable
) -> void:
	var button := Button.new()
	button.text = text
	PauseMenuStyle.apply_menu_button_style(button)
	button.pressed.connect(handler)
	button.mouse_entered.connect(_set_description.bind(description))
	parent.add_child(button)


func _set_description(text: String) -> void:
	if _footer_description != null:
		_footer_description.text = text


func _on_play_pressed() -> void:
	play_requested.emit()


func _on_settings_pressed() -> void:
	settings_toggled.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_window_mode_stepped(delta: int) -> void:
	window_mode_stepped.emit(delta)


func _on_entity_toggled() -> void:
	entity_toggled.emit()


func _on_teleport_ramp_pressed() -> void:
	teleport_ramp_requested.emit()


func _on_teleport_motel_pressed() -> void:
	teleport_motel_requested.emit()


func _on_bring_car_pressed() -> void:
	bring_car_requested.emit()


func _on_teleport_to_car_pressed() -> void:
	teleport_to_car_requested.emit()
