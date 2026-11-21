extends TestCase


func test_ribbon_with_three_points_has_six_vertices_and_four_triangles() -> void:
	var arrays := GrassRibbonArrays.new()
	_add_straight_ribbon(arrays, 3)
	assert_eq(arrays.vertices.size(), 6, "dois vertices por ponto")
	assert_eq(arrays.indices.size(), 12, "dois triangulos por trecho")


func test_second_ribbon_indices_start_after_the_first() -> void:
	var arrays := GrassRibbonArrays.new()
	_add_straight_ribbon(arrays, 2)
	_add_straight_ribbon(arrays, 2)
	assert_eq(arrays.vertices.size(), 8, "duas fitas de dois pontos")
	assert_eq(arrays.indices[6], 4, "indice da segunda fita comeca no vertice 4")


func test_vertices_are_placed_on_both_sides_of_the_center() -> void:
	var arrays := GrassRibbonArrays.new()
	_add_straight_ribbon(arrays, 2)
	assert_eq(arrays.vertices[0], Vector3(-0.5, 0.0, 0.0), "vertice da esquerda")
	assert_eq(arrays.vertices[1], Vector3(0.5, 0.0, 0.0), "vertice da direita")


func test_mesh_has_one_surface_with_colors() -> void:
	var arrays := GrassRibbonArrays.new()
	_add_straight_ribbon(arrays, 3)
	var mesh := arrays.to_mesh()
	assert_eq(mesh.get_surface_count(), 1, "uma superficie")
	var surface_arrays := mesh.surface_get_arrays(0)
	var mesh_colors := surface_arrays[Mesh.ARRAY_COLOR] as PackedColorArray
	assert_eq(mesh_colors.size(), 6, "uma cor por vertice")


func _add_straight_ribbon(arrays: GrassRibbonArrays, point_count: int) -> void:
	var centers := PackedVector3Array()
	var half_widths: Array[float] = []
	var point_colors := PackedColorArray()
	for point_index: int in point_count:
		centers.append(Vector3(0.0, float(point_index), 0.0))
		half_widths.append(0.5)
		point_colors.append(Color.WHITE)
	arrays.add_ribbon(centers, half_widths, point_colors, Vector3.RIGHT)
