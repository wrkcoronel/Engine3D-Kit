class_name MotelMeshBuilder
extends RefCounted

const FACES := [
	{
		"normal": Vector3(0.0, 0.0, 1.0),
		"u_axis": Vector3(1.0, 0.0, 0.0),
		"v_axis": Vector3(0.0, 1.0, 0.0)
	},
	{
		"normal": Vector3(0.0, 0.0, -1.0),
		"u_axis": Vector3(-1.0, 0.0, 0.0),
		"v_axis": Vector3(0.0, 1.0, 0.0)
	},
	{
		"normal": Vector3(1.0, 0.0, 0.0),
		"u_axis": Vector3(0.0, 0.0, -1.0),
		"v_axis": Vector3(0.0, 1.0, 0.0)
	},
	{
		"normal": Vector3(-1.0, 0.0, 0.0),
		"u_axis": Vector3(0.0, 0.0, 1.0),
		"v_axis": Vector3(0.0, 1.0, 0.0)
	},
	{
		"normal": Vector3(0.0, 1.0, 0.0),
		"u_axis": Vector3(1.0, 0.0, 0.0),
		"v_axis": Vector3(0.0, 0.0, -1.0)
	},
	{
		"normal": Vector3(0.0, -1.0, 0.0),
		"u_axis": Vector3(1.0, 0.0, 0.0),
		"v_axis": Vector3(0.0, 0.0, 1.0)
	},
]


static func build_meshes_by_material(pieces: Array[MotelPiece]) -> Dictionary:
	var grouped: Dictionary = {}
	for piece: MotelPiece in pieces:
		if piece.material_name.is_empty():
			continue
		if not grouped.has(piece.material_name):
			var empty_list: Array[MotelPiece] = []
			grouped[piece.material_name] = empty_list
		var bucket := grouped[piece.material_name] as Array[MotelPiece]
		bucket.append(piece)

	var meshes: Dictionary = {}
	for material_name: String in grouped.keys():
		var bucket := grouped[material_name] as Array[MotelPiece]
		meshes[material_name] = _build_group_mesh(bucket)
	return meshes


static func build_collision_shapes(pieces: Array[MotelPiece]) -> Array[CollisionShape3D]:
	var shapes: Array[CollisionShape3D] = []
	for piece: MotelPiece in pieces:
		if not piece.solid:
			continue
		var shape := BoxShape3D.new()
		shape.size = piece.size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var basis := Basis.from_euler(piece.rotation)
		collision.transform = Transform3D(basis, piece.center)
		shapes.append(collision)
	return shapes


static func _build_group_mesh(pieces: Array[MotelPiece]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for piece: MotelPiece in pieces:
		_append_box(piece, vertices, normals, uvs, indices)

	var surface_arrays: Array = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_NORMAL] = normals
	surface_arrays[Mesh.ARRAY_TEX_UV] = uvs
	surface_arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	return mesh


static func _append_box(
	piece: MotelPiece,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var half := piece.size * 0.5
	var basis := Basis.from_euler(piece.rotation)
	for face: Dictionary in FACES:
		var local_normal := face["normal"] as Vector3
		var local_u := face["u_axis"] as Vector3
		var local_v := face["v_axis"] as Vector3
		var u_extent := _axis_extent(local_u, half)
		var v_extent := _axis_extent(local_v, half)
		var n_extent := _axis_extent(local_normal, half)

		var face_center := local_normal * n_extent
		var u_vec := local_u * u_extent
		var v_vec := local_v * v_extent
		var world_normal := basis * local_normal
		var base_index := vertices.size()

		var corners: Array[Vector3] = [
			face_center - u_vec - v_vec,
			face_center + u_vec - v_vec,
			face_center + u_vec + v_vec,
			face_center - u_vec + v_vec,
		]
		var face_uvs: Array[Vector2] = [
			Vector2(0.0, 0.0),
			Vector2(u_extent * 2.0, 0.0),
			Vector2(u_extent * 2.0, v_extent * 2.0),
			Vector2(0.0, v_extent * 2.0),
		]
		for corner_index: int in range(4):
			var world_point := piece.center + basis * corners[corner_index]
			vertices.append(world_point)
			normals.append(world_normal)
			uvs.append(face_uvs[corner_index])

		indices.append(base_index)
		indices.append(base_index + 2)
		indices.append(base_index + 1)
		indices.append(base_index)
		indices.append(base_index + 3)
		indices.append(base_index + 2)


static func _axis_extent(axis: Vector3, half: Vector3) -> float:
	return absf(axis.x) * half.x + absf(axis.y) * half.y + absf(axis.z) * half.z
