extends TestCase


func test_box_has_twelve_edges() -> void:
	var edges := BoxEdges.edges(Vector3(2, 2, 2), Transform3D.IDENTITY)
	assert_eq(edges.size(), 12, "uma caixa tem 12 arestas")


func test_nearest_edge_of_unit_box() -> void:
	var point := Vector3(0.0, 1.1, 1.1)
	var edge := BoxEdges.nearest_edge(Vector3(2, 2, 2), Transform3D.IDENTITY, point)
	var distance := BoxEdges.distance_to_segment(point, edge[0], edge[1])
	assert_near(edge[0].y, 1.0, 0.001, "a aresta mais proxima fica no topo")
	assert_near(edge[0].z, 1.0, 0.001, "a aresta mais proxima fica na frente")
	assert_near(distance, sqrt(0.02), 0.001, "distancia ate a aresta")


func test_corners_follow_transform() -> void:
	var moved := Transform3D(Basis.IDENTITY, Vector3(10, 0, 0))
	var corners := BoxEdges.corners(Vector3(2, 2, 2), moved)
	assert_eq(corners[0], Vector3(9, -1, -1), "o canto acompanha a posicao da caixa")
