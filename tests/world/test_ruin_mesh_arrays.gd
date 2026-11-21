extends TestCase


func test_one_box_has_24_vertices_and_12_triangles() -> void:
	var arrays := RuinMeshArrays.new()
	arrays.add_box(Vector3.ZERO, Vector3(2.0, 4.0, 6.0), Vector3.ZERO, true)
	assert_eq(arrays.vertices.size(), 24, "quatro vertices por face")
	assert_eq(arrays.indices.size(), 36, "dois triangulos por face")


func test_box_vertices_fill_the_requested_size() -> void:
	var arrays := RuinMeshArrays.new()
	arrays.add_box(Vector3(10.0, 0.0, 0.0), Vector3(2.0, 4.0, 6.0), Vector3.ZERO, true)
	var bounds := arrays.to_mesh().get_aabb()
	assert_eq(bounds.position, Vector3(9.0, -2.0, -3.0), "canto minimo")
	assert_eq(bounds.size, Vector3(2.0, 4.0, 6.0), "tamanho")


func test_rotated_box_keeps_its_center() -> void:
	var arrays := RuinMeshArrays.new()
	arrays.add_box(Vector3(5.0, 1.0, 2.0), Vector3(2.0, 2.0, 2.0), Vector3(0.4, 0.9, 0.2), true)
	var bounds := arrays.to_mesh().get_aabb()
	assert_near(bounds.get_center().x, 5.0, 0.001, "centro x")
	assert_near(bounds.get_center().y, 1.0, 0.001, "centro y")
	assert_near(bounds.get_center().z, 2.0, 0.001, "centro z")


func test_face_normals_are_unit_and_point_away_from_the_center() -> void:
	var arrays := RuinMeshArrays.new()
	arrays.add_box(Vector3.ZERO, Vector3(2.0, 2.0, 2.0), Vector3.ZERO, true)
	for vertex_index: int in arrays.vertices.size():
		var normal := arrays.normals[vertex_index]
		assert_near(normal.length(), 1.0, 0.001, "normal unitaria")
		assert_true(normal.dot(arrays.vertices[vertex_index]) > 0.0, "normal aponta para fora")


func test_rebar_is_marked_as_metal_by_vertex_alpha() -> void:
	var arrays := RuinMeshArrays.new()
	arrays.add_box(Vector3.ZERO, Vector3.ONE, Vector3.ZERO, true)
	arrays.add_box(Vector3.ZERO, Vector3.ONE, Vector3.ZERO, false)
	assert_eq(arrays.colors[0].a, 1.0, "concreto")
	assert_eq(arrays.colors[24].a, 0.0, "ferro")
