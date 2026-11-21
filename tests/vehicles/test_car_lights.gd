extends TestCase


func test_handbrake_always_counts_as_braking() -> void:
	assert_true(CarLights.is_braking(0.0, true, 0.0), "freio de mao")


func test_reverse_pedal_while_rolling_forward_is_braking() -> void:
	assert_true(CarLights.is_braking(-1.0, false, 10.0), "freando")


func test_reverse_pedal_while_stopped_is_not_braking() -> void:
	assert_true(not CarLights.is_braking(-1.0, false, 0.0), "dando re")


func test_throttle_is_not_braking() -> void:
	assert_true(not CarLights.is_braking(1.0, false, 10.0), "acelerando")


func test_taillights_are_brightest_when_braking() -> void:
	var braking := CarTaillights.glow_for(true, true)
	var lights_on := CarTaillights.glow_for(true, false)
	var lights_off := CarTaillights.glow_for(false, false)
	assert_true(braking > lights_on, "freio mais forte que lanterna")
	assert_true(lights_on > lights_off, "lanterna mais forte que apagado")
	assert_eq(CarTaillights.light_energy_for(false, false), 0.0, "apagado nao ilumina")


func test_headlights_create_two_spots_and_follow_the_mode() -> void:
	var rig := _make_rig()
	var headlights := CarHeadlights.new()
	headlights.setup(rig["body"] as Node3D, rig["model"] as Node3D)
	assert_eq(headlights.spot_count(), 2, "um spot por farol")
	assert_true(not headlights.is_on(), "comeca desligado")
	headlights.cycle()
	var low_energy := headlights.spot_energy()
	headlights.cycle()
	assert_true(headlights.spot_energy() > low_energy, "farol alto mais forte")
	headlights.cycle()
	assert_eq(headlights.spot_energy(), 0.0, "voltou a desligar")


func test_lens_material_is_not_shared_with_other_meshes() -> void:
	var rig := _make_rig()
	var headlights := CarHeadlights.new()
	headlights.setup(rig["body"] as Node3D, rig["model"] as Node3D)
	headlights.cycle()
	var lens := rig["lens"] as MeshInstance3D
	var other := rig["other"] as MeshInstance3D
	var lens_material := lens.get_active_material(0) as StandardMaterial3D
	var other_material := other.get_active_material(0) as StandardMaterial3D
	assert_eq(lens_material.emission_energy_multiplier, 2.0, "lente brilha")
	assert_eq(other_material.emission_energy_multiplier, 1.0, "outra malha nao muda")


func test_key_toggles_only_with_a_driver() -> void:
	var rig := _make_rig()
	var lights := CarLights.new()
	spawn(lights)
	lights.setup(rig["body"] as Node3D, rig["model"] as Node3D)
	lights.handle_key(_key_press(KEY_L))
	assert_eq(lights.beam_mode(), CarBeamMode.Mode.OFF, "sem motorista a tecla nao faz nada")
	lights.set_driver_present(true)
	lights.handle_key(_key_press(KEY_L))
	assert_eq(lights.beam_mode(), CarBeamMode.Mode.LOW, "com motorista liga o farol baixo")
	lights.handle_key(_key_press(KEY_E))
	assert_eq(lights.beam_mode(), CarBeamMode.Mode.LOW, "outra tecla nao muda")


func _key_press(keycode: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	return key


func _make_rig() -> Dictionary:
	var body := Node3D.new()
	var model := Node3D.new()
	body.add_child(model)
	var shared_material := StandardMaterial3D.new()
	shared_material.emission_enabled = true
	var lens := _make_mesh("FarolLente", shared_material)
	var other := _make_mesh("Outra", shared_material)
	model.add_child(lens)
	model.add_child(other)
	spawn(body)
	return {"body": body, "model": model, "lens": lens, "other": other}


func _make_mesh(mesh_name: String, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = BoxMesh.new()
	mesh.set_surface_override_material(0, material)
	return mesh
