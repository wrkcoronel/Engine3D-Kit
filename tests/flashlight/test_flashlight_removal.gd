extends TestCase

const GAME_SCENE := "res://app/main.tscn"


func _spawn_game() -> Node3D:
	var game := (load(GAME_SCENE) as PackedScene).instantiate() as Node3D
	spawn(game)
	await tree.process_frame
	await tree.process_frame
	return game


func test_flashlight_works_alone_without_player_gun_or_car() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	await tree.process_frame
	await tree.process_frame
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(flashlight.is_on(), "liga sozinha")


func test_game_runs_without_the_flashlight() -> void:
	var game := await _spawn_game()
	game.get_node("Flashlight").free()
	await tree.process_frame
	await tree.process_frame
	var gun := game.get_node("Player/Head/Camera/Gun") as Node3D
	assert_true(gun.is_inside_tree(), "arma continua funcionando")


func test_game_runs_without_the_car() -> void:
	var game := await _spawn_game()
	game.get_node("Car").free()
	await tree.process_frame
	await tree.process_frame
	assert_true(game.get_node("Player").is_inside_tree(), "jogador continua")
	var flashlight := game.get_node("Flashlight") as Flashlight
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(flashlight.is_on(), "lanterna continua")


func test_game_runs_without_the_gun_and_the_flashlight_stays_in_hand() -> void:
	var game := await _spawn_game()
	game.get_node("Player/Head/Camera/Gun").free()
	var flashlight := game.get_node("Flashlight") as Flashlight
	flashlight.handle_key(_key_press(KEY_F))
	await tree.process_frame
	await tree.process_frame
	assert_true(flashlight.is_on(), "lanterna sem arma")


func test_flashlight_hides_while_the_player_is_away() -> void:
	var game := await _spawn_game()
	var flashlight := game.get_node("Flashlight") as Flashlight
	flashlight.handle_key(_key_press(KEY_F))
	for frame: int in 60:
		await tree.process_frame
	var rig := PlayerRig.find(tree)
	rig.body.visible = false
	await tree.process_frame
	assert_true(not flashlight.visual().visible, "corpo some com o jogador fora")
	assert_true(not flashlight.beam().visible, "luz some com o jogador fora")


func _key_press(keycode: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	return key


func test_flashlight_without_lens_node_still_toggles() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.visual().get_node("Lens").free()
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(flashlight.is_on(), "liga mesmo sem a lente")
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(not flashlight.is_on(), "desliga mesmo sem a lente")
