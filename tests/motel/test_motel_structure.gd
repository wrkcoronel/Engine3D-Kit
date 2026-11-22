extends TestCase


func test_all_motel_pieces_have_positive_sizes_and_known_materials() -> void:
	var palette := MotelMaterials.build_palette()
	var pieces: Array[MotelPiece] = []
	pieces.append_array(MotelStructure.build())
	pieces.append_array(MotelWalkways.build())
	pieces.append_array(MotelFacade.build())
	pieces.append_array(MotelReception.build())
	pieces.append_array(MotelReceptionInterior.build())
	pieces.append_array(MotelSigns.build())
	pieces.append_array(MotelRoomInterior.build())
	pieces.append_array(MotelWestRoomInterior.build())
	pieces.append_array(MotelLot.build())
	pieces.append_array(MotelRoad.build())
	pieces.append_array(MotelFoliage.build())

	assert_true(pieces.size() > 340, "motel gera pecas dos 5 ambientes, rua e arvores")
	for piece: MotelPiece in pieces:
		var has_positive_size := piece.size.x > 0.0 and piece.size.y > 0.0 and piece.size.z > 0.0
		assert_true(has_positive_size, "peca tem tamanho positivo")
		if not piece.material_name.is_empty():
			assert_true(
				palette.has(piece.material_name),
				"material conhecido na paleta: %s" % piece.material_name
			)


func test_mesh_builder_skips_collider_only_pieces_and_groups_by_material() -> void:
	var pieces: Array[MotelPiece] = [
		MotelPiece.new(Vector3.ZERO, Vector3(2.0, 2.0, 2.0), "stucco", true),
		MotelPiece.new(Vector3(3.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0), "stucco", false),
		MotelPiece.new(Vector3(6.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0), "", true),
	]
	var meshes := MotelMeshBuilder.build_meshes_by_material(pieces)
	assert_eq(meshes.size(), 1, "agrupa duas pecas stucco e ignora colisor invisivel")
	assert_true(meshes.has("stucco"), "gera malha para stucco")
	var shapes := MotelMeshBuilder.build_collision_shapes(pieces)
	assert_eq(shapes.size(), 2, "gera colisao somente para pecas solidas")
	for collision: CollisionShape3D in shapes:
		collision.free()


func test_boundary_detects_positions_near_edges_only() -> void:
	var bounds := MotelBoundary.PLAYABLE_BOUNDS
	var margin := MotelBoundary.WARNING_MARGIN
	assert_true(
		not MotelBoundary.is_near_boundary(Vector3(0.0, 1.0, 4.0), bounds, margin), "centro"
	)
	assert_true(
		MotelBoundary.is_near_boundary(Vector3(bounds.position.x + 1.0, 1.0, 25.0), bounds, margin),
		"perto do limite oeste da rua"
	)
	assert_true(
		MotelBoundary.is_near_boundary(Vector3(bounds.end.x - 1.0, 1.0, 25.0), bounds, margin),
		"perto do limite leste da rua"
	)
