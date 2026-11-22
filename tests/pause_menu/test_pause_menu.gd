extends TestCase

const GAME_SCENE := "res://app/main.tscn"


func _spawn_game() -> Node3D:
	var game := (load(GAME_SCENE) as PackedScene).instantiate() as Node3D
	spawn(game)
	await tree.process_frame
	await tree.process_frame
	return game


func test_esc_toggles_pause_menu_and_tree_pause() -> void:
	var game := await _spawn_game()
	var menu := game.get_node("PauseMenu") as PauseMenu
	assert_true(not menu.is_open(), "comeca fechado")
	assert_true(not tree.paused, "jogo comeca despausado")

	menu.toggle_menu()
	assert_true(menu.is_open(), "abre ao alternar")
	assert_true(tree.paused, "pausa o jogo quando abre")
	assert_true(not menu.is_settings_open(), "configuracoes comecam recolhidas")

	menu.toggle_settings()
	assert_true(menu.is_settings_open(), "abre painel de configuracoes")
	assert_eq(menu.current_settings_tab(), PauseSettingsPage.Tab.VIDEO, "abre na aba Video")

	menu.select_settings_tab(PauseSettingsPage.Tab.WORLD)
	assert_eq(menu.current_settings_tab(), PauseSettingsPage.Tab.WORLD, "troca para aba Mundo")

	menu.select_settings_tab(PauseSettingsPage.Tab.TELEPORT)
	assert_eq(
		menu.current_settings_tab(), PauseSettingsPage.Tab.TELEPORT, "troca para aba Teleporte"
	)

	menu.handle_escape()
	assert_true(menu.is_open(), "esc nas configuracoes volta para a pausa")
	assert_true(not menu.is_settings_open(), "configuracoes fecham ao apertar esc")

	menu.handle_escape()
	assert_true(not menu.is_open(), "esc na pausa fecha o menu")
	assert_true(not tree.paused, "despausa o jogo ao fechar")


func test_stepping_window_mode_cycles_through_options() -> void:
	var game := await _spawn_game()
	var menu := game.get_node("PauseMenu") as PauseMenu
	assert_eq(
		menu.current_window_option(), WindowModeSettings.Option.FULLSCREEN, "comeca em tela cheia"
	)
	menu.step_window_mode(1)
	assert_eq(
		menu.current_window_option(),
		WindowModeSettings.Option.MAXIMIZED,
		"avanca para janela maximizada"
	)
	menu.step_window_mode(1)
	assert_eq(
		menu.current_window_option(), WindowModeSettings.Option.WINDOWED, "avanca para janela"
	)
	menu.step_window_mode(1)
	assert_eq(
		menu.current_window_option(),
		WindowModeSettings.Option.FULLSCREEN,
		"volta para tela cheia no fim do ciclo"
	)


func test_disabling_entity_hides_and_stops_it() -> void:
	var game := await _spawn_game()
	var menu := game.get_node("PauseMenu") as PauseMenu
	var entity := game.get_node("Entity") as SpectralEntity
	assert_true(entity.is_entity_enabled(), "entidade comeca ativa")

	menu.open_menu()
	menu.set_entity_enabled(false)
	assert_true(not entity.is_entity_enabled(), "entidade fica desativada")
	assert_true(not entity.visible, "entidade fica invisivel")
	assert_true(not entity.is_physics_processing(), "entidade para de processar")

	menu.set_entity_enabled(true)
	assert_true(entity.is_entity_enabled(), "entidade volta ativa")
	assert_true(entity.visible, "entidade volta visivel")
	assert_true(entity.is_physics_processing(), "entidade volta a processar")
	menu.close_menu()


func test_teleports_player_to_ramp_and_motel() -> void:
	var game := await _spawn_game()
	var menu := game.get_node("PauseMenu") as PauseMenu
	var player := game.get_node("Player") as CharacterBody3D

	menu.open_menu()
	menu.teleport_to_ramp()
	assert_true(not menu.is_open(), "fecha menu apos teleporte para a rampa")
	assert_near(player.global_position.x, 20.0, 0.1, "jogador vai para x da rampa")
	assert_near(player.global_position.z, 11.41, 0.1, "jogador vai para frente da rampa")

	menu.open_menu()
	menu.teleport_to_motel()
	assert_true(not menu.is_open(), "fecha menu apos teleporte para o motel")
	assert_near(player.global_position.x, 0.5, 0.1, "jogador volta para x do motel")
	assert_near(player.global_position.z, 179.5, 0.1, "jogador volta para z do motel")


func test_brings_car_to_player_and_teleports_player_to_car() -> void:
	var game := await _spawn_game()
	var menu := game.get_node("PauseMenu") as PauseMenu
	var player := game.get_node("Player") as CharacterBody3D
	var car := game.get_node("Car") as RigidBody3D

	player.global_transform = Transform3D(Basis.IDENTITY, Vector3(50.0, 1.0, 50.0))
	menu.open_menu()
	menu.bring_car_to_player()
	assert_true(not menu.is_open(), "fecha menu apos trazer carro")
	assert_near(car.global_position.x, 50.0, 0.1, "carro vai para x do jogador")
	assert_near(car.global_position.z, 45.0, 0.1, "carro vai para a frente do jogador")

	player.global_transform = Transform3D(Basis.IDENTITY, Vector3(-20.0, 1.0, -20.0))
	menu.open_menu()
	menu.teleport_to_car()
	assert_true(not menu.is_open(), "fecha menu apos ir para o carro")
	assert_near(player.global_position.x, 47.0, 0.2, "jogador vai para o lado do carro")
	assert_near(player.global_position.z, 45.0, 0.2, "jogador alinha no z do carro")


func test_pause_menu_works_without_entity_or_motel() -> void:
	var game := await _spawn_game()
	game.get_node("Entity").free()
	game.get_node("MotelEnvironment").free()
	await tree.process_frame

	var menu := game.get_node("PauseMenu") as PauseMenu
	menu.open_menu()
	menu.set_entity_enabled(false)
	menu.teleport_to_motel()
	assert_true(not menu.is_open(), "fecha menu mesmo sem motel")
	assert_true(not tree.paused, "nao deixa o jogo travado pausado")
