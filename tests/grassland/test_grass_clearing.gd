extends TestCase


func test_follow_activates_clearing_and_stores_inverse_transform() -> void:
	var material := ShaderMaterial.new()
	var vehicle_transform := Transform3D(Basis.IDENTITY, Vector3(5.0, 0.0, 4.0))
	GrassClearing.follow(material, vehicle_transform, Vector2(1.0, 2.0))
	assert_eq(material.get_shader_parameter(GrassClearing.ACTIVE), 1.0, "limpeza ligada")
	var stored := material.get_shader_parameter(GrassClearing.WORLD_TO_LOCAL) as Transform3D
	assert_eq(stored * Vector3(5.0, 0.0, 4.0), Vector3.ZERO, "o carro vira a origem")


func test_release_turns_clearing_off() -> void:
	var material := ShaderMaterial.new()
	GrassClearing.follow(material, Transform3D.IDENTITY, Vector2.ONE)
	GrassClearing.release(material)
	assert_eq(material.get_shader_parameter(GrassClearing.ACTIVE), 0.0, "limpeza desligada")


func test_field_follows_a_vehicle_in_the_group() -> void:
	var field := GrassField.new()
	var material_resource := load("res://contexts/grassland/materials/grass_material.tres")
	field.grass_material = (material_resource as ShaderMaterial).duplicate() as ShaderMaterial
	field.trail_resolution = 64
	field.chunks_per_frame = 0
	field.first_frame_chunks = 0
	spawn(field)
	var vehicle := Node3D.new()
	vehicle.add_to_group(GrassField.VEHICLE_GROUP)
	vehicle.position = Vector3(3.0, 0.0, 2.0)
	spawn(vehicle)
	await tree.process_frame
	await tree.process_frame
	var material := field.grass_material
	assert_eq(material.get_shader_parameter(GrassClearing.ACTIVE), 1.0, "segue o veiculo")
	var stored := material.get_shader_parameter(GrassClearing.WORLD_TO_LOCAL) as Transform3D
	assert_eq(stored * Vector3(3.0, 0.0, 2.0), Vector3.ZERO, "centro na posicao do veiculo")
