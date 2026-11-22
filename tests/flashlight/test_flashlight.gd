extends TestCase

const FULL_DRAW_TIME := 1.0
const SHORT_TIME := 0.05


func test_key_toggles_the_light() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	assert_true(not flashlight.is_on(), "comeca apagada")
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(flashlight.is_on(), "F acende")
	flashlight.handle_key(_key_press(KEY_E))
	assert_true(flashlight.is_on(), "outra tecla nao muda")
	flashlight.handle_key(_key_press(KEY_F))
	assert_true(not flashlight.is_on(), "F apaga")


func test_light_projects_the_beam_texture() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	assert_true(flashlight.beam().light_projector != null, "usa o projetor do feixe")


func test_drawing_starts_below_and_rises_to_the_hand() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.handle_key(_key_press(KEY_F))
	_update(flashlight, SHORT_TIME, 0.0, false)
	var just_drawn_height := flashlight.global_position.y
	_update(flashlight, FULL_DRAW_TIME, 0.0, false)
	var raised_height := flashlight.global_position.y
	assert_true(just_drawn_height < raised_height - 0.2, "comeca bem abaixo da mao")
	var hand_height := FlashlightPose.hand_pose(Transform3D.IDENTITY).origin.y
	assert_near(raised_height, hand_height, 0.001, "termina na mao")


func test_beam_only_lights_after_the_flashlight_is_raised() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.handle_key(_key_press(KEY_F))
	_update(flashlight, SHORT_TIME, 0.0, false)
	assert_true(not flashlight.beam().visible, "ainda subindo, sem luz")
	assert_true(flashlight.visual().visible, "ja aparece")
	_update(flashlight, FULL_DRAW_TIME, 0.0, false)
	assert_true(flashlight.beam().visible, "erguida, com luz")


func test_turning_off_cuts_the_beam_at_once_and_hides_after_lowering() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.handle_key(_key_press(KEY_F))
	_update(flashlight, FULL_DRAW_TIME, 0.0, false)
	flashlight.handle_key(_key_press(KEY_F))
	_update(flashlight, SHORT_TIME, 0.0, false)
	assert_true(not flashlight.beam().visible, "luz apaga no clique")
	assert_true(flashlight.visual().visible, "ainda descendo")
	_update(flashlight, FULL_DRAW_TIME, 0.0, false)
	assert_true(not flashlight.visual().visible, "guardada")


func test_aiming_moves_the_light_under_the_barrel() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.handle_key(_key_press(KEY_F))
	var weapon_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, -0.1, -0.4))
	var muzzle_position := Vector3(0.0, -0.09, -1.1)
	flashlight.update(
		FULL_DRAW_TIME, 1.0, false, Transform3D.IDENTITY, weapon_transform, muzzle_position
	)
	var expected := FlashlightPose.under_barrel_pose(weapon_transform, muzzle_position).origin
	var distance := flashlight.global_position.distance_to(expected)
	assert_near(distance, 0.0, 0.001, "junto da arma")
	assert_true(flashlight.global_position.y < muzzle_position.y, "abaixo do cano")


func test_under_barrel_light_points_where_the_weapon_points() -> void:
	var weapon_basis := Basis.from_euler(Vector3(0.0, 0.5, 0.0))
	var weapon_transform := Transform3D(weapon_basis, Vector3(1.0, 2.0, 3.0))
	var pose := FlashlightPose.under_barrel_pose(weapon_transform, Vector3(1.0, 2.0, 2.0))
	var weapon_forward := -weapon_basis.z
	var light_forward := -pose.basis.z
	assert_near(weapon_forward.dot(light_forward), 1.0, 0.001, "mesma direcao")


func test_scoped_light_goes_to_the_center_of_the_view_and_hides_the_body() -> void:
	var flashlight := Flashlight.new()
	spawn(flashlight)
	flashlight.handle_key(_key_press(KEY_F))
	_update(flashlight, FULL_DRAW_TIME, 1.0, true)
	var expected := FlashlightPose.scope_pose(Transform3D.IDENTITY).origin
	var distance := flashlight.global_position.distance_to(expected)
	assert_near(distance, 0.0, 0.001, "no centro da mira")
	assert_true(not flashlight.visual().visible, "corpo some na luneta")


func test_lowered_pose_with_zero_amount_changes_nothing() -> void:
	var pose := Transform3D(Basis.from_euler(Vector3(0.1, 0.2, 0.3)), Vector3(1.0, 2.0, 3.0))
	var result := FlashlightPose.lowered_pose(pose, 0.0)
	assert_near(result.origin.distance_to(pose.origin), 0.0, 0.0001, "mesma posicao")
	assert_near(result.basis.z.distance_to(pose.basis.z), 0.0, 0.0001, "mesma direcao")


func _update(flashlight: Flashlight, delta: float, aim_amount: float, scoped: bool) -> void:
	var weapon_transform := Transform3D(Basis.IDENTITY, Vector3(0.3, -0.2, -0.5))
	var muzzle_position := Vector3(0.3, -0.2, -1.0)
	flashlight.update(
		delta, aim_amount, scoped, Transform3D.IDENTITY, weapon_transform, muzzle_position
	)


func _key_press(keycode: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	return key
