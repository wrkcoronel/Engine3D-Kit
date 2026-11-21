extends TestCase

const BUILDING_SCENE := "res://contexts/world/props/building.tscn"


func test_building_has_ruined_mesh_and_collision_pieces() -> void:
	var building := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(40.0, 0.0, -30.0))
	var mesh_instance := building.get_child(building.get_child_count() - 1) as MeshInstance3D
	assert_true(mesh_instance != null, "tem a malha das ruinas")
	assert_true(mesh_instance.mesh.get_surface_count() == 1, "uma malha so por predio")
	var collisions := _collision_count(building)
	assert_true(collisions >= 8, "varias pecas de colisao: %d" % collisions)


func test_building_is_not_a_plain_box_any_more() -> void:
	var building := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(40.0, 0.0, -30.0))
	for child: Node in building.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			assert_true(not (mesh_instance.mesh is BoxMesh), "nao e mais uma caixa")


func test_each_building_gets_its_own_material_with_its_color() -> void:
	var first := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(40.0, 0.0, -30.0))
	first.color = Color(0.1, 0.2, 0.3)
	var second := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(-45.0, 0.0, -40.0))
	var first_material := _material_of(first)
	var second_material := _material_of(second)
	assert_true(first_material != second_material, "material proprio")
	var tint := second_material.get_shader_parameter("tint") as Vector3
	assert_near(tint.x, second.color.r, 0.001, "cor do predio vai para o shader")


func test_different_positions_give_different_ruins() -> void:
	var first := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(40.0, 0.0, -30.0))
	var second := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(-45.0, 0.0, -40.0))
	assert_true(first.ruin_seed() != second.ruin_seed(), "semente muda com a posicao")


func test_standing_walls_block_the_way_at_ground_level() -> void:
	var building := _make_building(Vector3(20.0, 18.0, 20.0), Vector3(0.0, 0.0, 0.0))
	await tree.physics_frame
	await tree.physics_frame
	var space_state := building.get_world_3d().direct_space_state
	var corner_query := PhysicsRayQueryParameters3D.create(
		Vector3(30.0, 1.0, 9.65), Vector3(0.0, 1.0, 9.65)
	)
	var hit := space_state.intersect_ray(corner_query)
	assert_true(not hit.is_empty(), "um raio rente ao chao bate na parede do canto")


func _make_building(size: Vector3, world_position: Vector3) -> Building:
	var building := (load(BUILDING_SCENE) as PackedScene).instantiate() as Building
	building.size = size
	building.position = world_position
	spawn(building)
	return building


func _collision_count(building: Building) -> int:
	var count := 0
	for child: Node in building.get_children():
		if child is CollisionShape3D:
			count += 1
	return count


func _material_of(building: Building) -> ShaderMaterial:
	for child: Node in building.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			return mesh_instance.material_override as ShaderMaterial
	return null
