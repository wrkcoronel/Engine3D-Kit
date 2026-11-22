class_name PauseSettingsPage
extends HBoxContainer

signal back_requested
signal window_mode_stepped(delta: int)
signal entity_toggled
signal teleport_ramp_requested
signal teleport_motel_requested
signal bring_car_requested
signal teleport_to_car_requested
signal description_hovered(text: String)

enum Tab { VIDEO, WORLD, TELEPORT }

const SIDE_COLUMN_WIDTH := 220.0

var _current_tab := Tab.VIDEO
var _video_tab_button: Button
var _world_tab_button: Button
var _teleport_tab_button: Button
var _video_table: VBoxContainer
var _world_table: VBoxContainer
var _teleport_table: VBoxContainer
var _window_mode_row: PauseSettingsRow
var _entity_row: PauseSettingsRow


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 64)
	_build_side_column()
	_build_tables()
	select_tab(Tab.VIDEO)


func select_tab(tab: Tab) -> void:
	_current_tab = tab
	if _video_table == null:
		return
	_video_table.visible = tab == Tab.VIDEO
	_world_table.visible = tab == Tab.WORLD
	_teleport_table.visible = tab == Tab.TELEPORT
	_update_tab_button_colors()


func current_tab() -> Tab:
	return _current_tab


func set_selected_window_mode(option_index: int) -> void:
	if _window_mode_row == null:
		return
	if option_index < 0 or option_index >= WindowModeSettings.OPTION_LABELS.size():
		return
	_window_mode_row.set_value_text(WindowModeSettings.OPTION_LABELS[option_index])


func set_entity_state(available: bool, enabled: bool) -> void:
	if _entity_row == null:
		return
	_entity_row.set_row_disabled(not available)
	if not available:
		_entity_row.set_value_text("Indisponível")
		return
	var state_text := "Ativada" if enabled else "Desativada"
	_entity_row.set_value_text(state_text)


func _build_side_column() -> void:
	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0.0)
	left_column.add_theme_constant_override("separation", 6)
	add_child(left_column)

	_video_tab_button = _make_tab_button("Vídeo", "Configurações de tela e janela.", Tab.VIDEO)
	left_column.add_child(_video_tab_button)

	_world_tab_button = _make_tab_button("Mundo", "Configurações do mapa e da entidade.", Tab.WORLD)
	left_column.add_child(_world_tab_button)

	_teleport_tab_button = _make_tab_button(
		"Teleporte", "Atalhos de teleporte pelo mapa e carro.", Tab.TELEPORT
	)
	left_column.add_child(_teleport_tab_button)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 18.0)
	left_column.add_child(spacer)

	var back_button := Button.new()
	back_button.text = "Voltar"
	PauseMenuStyle.apply_menu_button_style(back_button)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_emit_description.bind("Voltar para o menu de pausa."))
	left_column.add_child(back_button)


func _build_tables() -> void:
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(stack)

	_video_table = _make_table(stack)
	_window_mode_row = PauseSettingsRow.new()
	_window_mode_row.setup_selector(
		"Modo de tela",
		WindowModeSettings.OPTION_LABELS[0],
		"Alterna entre Tela cheia, Janela maximizada e Janela."
	)
	_window_mode_row.stepped.connect(_on_window_mode_stepped)
	_window_mode_row.hovered.connect(_emit_description)
	_video_table.add_child(_window_mode_row)
	_video_table.add_child(PauseMenuStyle.make_divider())

	_world_table = _make_table(stack)
	_entity_row = PauseSettingsRow.new()
	_entity_row.setup_selector("Entidade", "Ativada", "Habilita ou desabilita a entidade no mapa.")
	_entity_row.stepped.connect(_on_entity_stepped)
	_entity_row.hovered.connect(_emit_description)
	_world_table.add_child(_entity_row)
	_world_table.add_child(PauseMenuStyle.make_divider())

	_teleport_table = _make_table(stack)
	_add_action_row(
		_teleport_table,
		"Rampa",
		"Teleporta você para a frente da rampa.",
		_on_teleport_ramp_pressed
	)
	_add_action_row(
		_teleport_table,
		"Motel",
		"Teleporta você para o pátio do motel.",
		_on_teleport_motel_pressed
	)
	_add_action_row(
		_teleport_table,
		"Trazer carro",
		"Teleporta o carro para a sua frente.",
		_on_bring_car_pressed
	)
	_add_action_row(
		_teleport_table,
		"Ir para o carro",
		"Teleporta você para o lado do carro.",
		_on_teleport_to_car_pressed
	)


func _make_table(parent: VBoxContainer) -> VBoxContainer:
	var table := VBoxContainer.new()
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("separation", 0)
	table.add_child(PauseMenuStyle.make_divider())
	parent.add_child(table)
	return table


func _make_tab_button(title: String, description: String, tab: Tab) -> Button:
	var button := Button.new()
	button.text = title
	PauseMenuStyle.apply_menu_button_style(button)
	button.pressed.connect(select_tab.bind(tab))
	button.mouse_entered.connect(_emit_description.bind(description))
	return button


func _update_tab_button_colors() -> void:
	_set_tab_active(_video_tab_button, _current_tab == Tab.VIDEO)
	_set_tab_active(_world_tab_button, _current_tab == Tab.WORLD)
	_set_tab_active(_teleport_tab_button, _current_tab == Tab.TELEPORT)


func _set_tab_active(button: Button, active: bool) -> void:
	if button == null:
		return
	var color := PauseMenuStyle.TEXT_BRIGHT if active else PauseMenuStyle.TEXT_MUTED
	button.add_theme_color_override("font_color", color)


func _add_action_row(
	parent: VBoxContainer, title: String, description: String, handler: Callable
) -> void:
	var row := PauseSettingsRow.new()
	row.setup_action(title, "Ir", description)
	row.activated.connect(handler)
	row.hovered.connect(_emit_description)
	parent.add_child(row)
	parent.add_child(PauseMenuStyle.make_divider())


func _emit_description(text: String) -> void:
	description_hovered.emit(text)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_window_mode_stepped(delta: int) -> void:
	window_mode_stepped.emit(delta)


func _on_entity_stepped(_delta: int) -> void:
	entity_toggled.emit()


func _on_teleport_ramp_pressed() -> void:
	teleport_ramp_requested.emit()


func _on_teleport_motel_pressed() -> void:
	teleport_motel_requested.emit()


func _on_bring_car_pressed() -> void:
	bring_car_requested.emit()


func _on_teleport_to_car_pressed() -> void:
	teleport_to_car_requested.emit()
