extends TestCase


func _key(keycode: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	key.pressed = true
	return key


func test_number_keys_select_each_weapon() -> void:
	var reader := GunInput.new()
	for weapon_index: int in GunInput.WEAPON_KEYS.size():
		reader.read(_key(GunInput.WEAPON_KEYS[weapon_index]))
		assert_eq(reader.command, GunInput.Command.SELECT, "tecla de numero escolhe arma")
		assert_eq(reader.selected_index, weapon_index, "cada tecla e uma arma")


func test_reload_and_holster_keys() -> void:
	var reader := GunInput.new()
	reader.read(_key(GunInput.RELOAD_KEY))
	assert_eq(reader.command, GunInput.Command.RELOAD, "R recarrega")
	reader.read(_key(GunInput.HOLSTER_KEY))
	assert_eq(reader.command, GunInput.Command.HOLSTER, "Q guarda")


func test_wheel_cycles() -> void:
	var reader := GunInput.new()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	reader.read(wheel)
	assert_eq(reader.command, GunInput.Command.PREVIOUS, "roda para baixo volta uma arma")
