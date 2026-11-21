extends TestCase

const WAIST_HEIGHT := 1.1


func test_clump_is_a_single_surface() -> void:
	var mesh := GrassClumpMesh.build(1)
	assert_eq(mesh.get_surface_count(), 1, "um tufo e uma superficie so")


func test_clump_stays_between_ground_and_waist() -> void:
	var bounds := GrassClumpMesh.build(1).get_aabb()
	assert_true(bounds.position.y >= -0.001, "nada abaixo do chao")
	assert_true(bounds.end.y <= WAIST_HEIGHT, "espiga mais alta nao passa da cintura")


func test_clump_is_narrow() -> void:
	var bounds := GrassClumpMesh.build(1).get_aabb()
	assert_true(bounds.size.x < 1.0, "largura do tufo em x")
	assert_true(bounds.size.z < 1.0, "largura do tufo em z")


func test_clump_has_ears_with_golden_vertices() -> void:
	var mesh := GrassClumpMesh.build(1)
	var surface_arrays := mesh.surface_get_arrays(0)
	var mesh_colors := surface_arrays[Mesh.ARRAY_COLOR] as PackedColorArray
	var golden_vertices := 0
	for vertex_color: Color in mesh_colors:
		if vertex_color.r > GrassClumpMesh.EAR_BASE_COLOR.r - 0.001:
			golden_vertices += 1
	assert_true(golden_vertices > 0, "o tufo tem espigas douradas")


func test_same_seed_gives_same_clump() -> void:
	var first := GrassClumpMesh.build(5).surface_get_arrays(0)
	var second := GrassClumpMesh.build(5).surface_get_arrays(0)
	assert_eq(first[Mesh.ARRAY_VERTEX], second[Mesh.ARRAY_VERTEX], "mesma semente, mesmo tufo")


func test_different_seed_gives_different_clump() -> void:
	var first := GrassClumpMesh.build(5).surface_get_arrays(0)
	var second := GrassClumpMesh.build(6).surface_get_arrays(0)
	assert_true(first[Mesh.ARRAY_VERTEX] != second[Mesh.ARRAY_VERTEX], "semente muda o tufo")
