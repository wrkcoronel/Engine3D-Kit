extends TestCase

const MATERIAL_PATH := "res://contexts/grassland/materials/grass_material.tres"


func test_near_chunk_is_denser_than_far_chunk() -> void:
	var field := await _make_field()
	field.update_chunks(Vector2.ZERO, 200)
	var near_chunk := field.chunk_at(Vector2i(0, 0))
	var far_chunk := field.chunk_at(Vector2i(2, 0))
	assert_true(near_chunk != null, "chunk do foco existe")
	assert_true(far_chunk != null, "chunk distante existe")
	assert_eq(near_chunk.level, GrassStreamer.NEAR_LEVEL, "nivel perto")
	assert_eq(far_chunk.level, GrassStreamer.FAR_LEVEL, "nivel longe")
	var expected_ratio := field.near_clumps_per_square_meter / field.far_clumps_per_square_meter
	var actual_ratio := float(near_chunk.clump_count()) / float(far_chunk.clump_count())
	assert_near(actual_ratio, expected_ratio, 0.05, "a razao de tufos segue as densidades")
	assert_true(actual_ratio > 1.5, "perto e bem mais denso que longe")


func test_chunks_follow_the_focus_and_old_ones_are_freed() -> void:
	var field := await _make_field()
	field.update_chunks(Vector2.ZERO, 200)
	assert_true(field.chunk_at(Vector2i(0, 0)) != null, "comeca no centro")
	field.update_chunks(Vector2(-120.0, -120.0), 200)
	await tree.process_frame
	assert_true(field.chunk_at(Vector2i(0, 0)) == null, "o chunk antigo some")
	assert_true(field.chunk_at(Vector2i(-8, -8)) != null, "aparece perto do novo foco")


func test_budget_limits_chunks_built_per_call() -> void:
	var field := await _make_field()
	field.update_chunks(Vector2.ZERO, 3)
	assert_eq(field.chunk_count(), 3, "so 3 chunks por vez")
	field.update_chunks(Vector2.ZERO, 3)
	assert_eq(field.chunk_count(), 6, "mais 3 na chamada seguinte")


func test_nearest_chunks_are_built_first() -> void:
	var field := await _make_field()
	field.update_chunks(Vector2.ZERO, 4)
	assert_true(field.chunk_at(Vector2i(0, 0)) != null, "o do foco vem primeiro")
	assert_true(field.chunk_at(Vector2i(-1, -1)) != null, "e os vizinhos")


func test_same_cell_gives_same_grass() -> void:
	var first_field := await _make_field()
	var second_field := await _make_field()
	first_field.update_chunks(Vector2.ZERO, 1)
	second_field.update_chunks(Vector2.ZERO, 1)
	var first_instance := first_field.chunk_at(Vector2i(0, 0)).get_child(0) as MultiMeshInstance3D
	var second_instance := second_field.chunk_at(Vector2i(0, 0)).get_child(0) as MultiMeshInstance3D
	var first_transform := first_instance.multimesh.get_instance_transform(0)
	var second_transform := second_instance.multimesh.get_instance_transform(0)
	assert_eq(first_transform, second_transform, "mesmo chunk, mesmo capim")


func test_grass_does_not_cast_shadow_and_stays_in_its_cell() -> void:
	var field := await _make_field()
	field.update_chunks(Vector2.ZERO, 1)
	var chunk := field.chunk_at(Vector2i(0, 0))
	for child: Node in chunk.get_children():
		var instance := child as MultiMeshInstance3D
		assert_eq(instance.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "sem sombra")
		var position := instance.multimesh.get_instance_transform(0).origin
		assert_true(position.x >= 0.0 and position.x <= field.chunk_size, "dentro da celula em x")
		assert_true(position.z >= 0.0 and position.z <= field.chunk_size, "dentro da celula em z")


func test_follows_a_vehicle_in_the_group() -> void:
	var field := await _make_field()
	var vehicle := Node3D.new()
	vehicle.add_to_group(GrassField.VEHICLE_GROUP)
	vehicle.position = Vector3(3.0, 0.0, 2.0)
	spawn(vehicle)
	await tree.process_frame
	await tree.process_frame
	var material := field.grass_material
	assert_eq(material.get_shader_parameter(GrassClearing.ACTIVE), 1.0, "segue o veiculo")


func _make_field() -> GrassField:
	var field := GrassField.new()
	field.grass_material = (load(MATERIAL_PATH) as ShaderMaterial).duplicate() as ShaderMaterial
	field.trail_resolution = 64
	field.chunks_per_frame = 0
	field.first_frame_chunks = 0
	spawn(field)
	await tree.process_frame
	return field


func test_trail_window_follows_the_camera_when_it_goes_far() -> void:
	var field := await _make_field()
	var camera := Camera3D.new()
	camera.position = Vector3(600.0, 1.6, -400.0)
	spawn(camera)
	camera.make_current()
	await tree.process_frame
	await tree.process_frame
	var window_center := field.trail_origin() + Vector2.ONE * field.trail_window_size / 2.0
	assert_true(
		window_center.distance_to(Vector2(600.0, -400.0)) < field.chunk_size, "janela perto"
	)
