class_name RuinMeshArrays
extends RefCounted

const FACE_NORMALS: Array[Vector3] = [
	Vector3.RIGHT,
	Vector3.LEFT,
	Vector3.UP,
	Vector3.DOWN,
	Vector3.BACK,
	Vector3.FORWARD,
]

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


func add_box(
	box_center: Vector3, box_size: Vector3, box_rotation: Vector3, is_concrete: bool
) -> void:
	var box_basis := Basis.from_euler(box_rotation)
	var half_size := box_size / 2.0
	var vertex_color := Color(1.0, 1.0, 1.0, 1.0)
	if not is_concrete:
		vertex_color = Color(1.0, 1.0, 1.0, 0.0)
	for face_normal: Vector3 in FACE_NORMALS:
		var first_vertex := vertices.size()
		var tangent := _tangent_for(face_normal)
		var bitangent := face_normal.cross(tangent)
		var normal_extent := _extent(face_normal, half_size)
		var tangent_extent := _extent(tangent, half_size)
		var bitangent_extent := _extent(bitangent, half_size)
		for corner_sign: Vector2 in [
			Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)
		]:
			var local_corner := face_normal * normal_extent
			local_corner += tangent * tangent_extent * corner_sign.x
			local_corner += bitangent * bitangent_extent * corner_sign.y
			vertices.append(box_center + box_basis * local_corner)
			normals.append(box_basis * face_normal)
			colors.append(vertex_color)
		indices.append_array(PackedInt32Array([first_vertex, first_vertex + 1, first_vertex + 2]))
		indices.append_array(PackedInt32Array([first_vertex, first_vertex + 2, first_vertex + 3]))


func to_mesh() -> ArrayMesh:
	var surface_arrays: Array = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_NORMAL] = normals
	surface_arrays[Mesh.ARRAY_COLOR] = colors
	surface_arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	return mesh


func _tangent_for(face_normal: Vector3) -> Vector3:
	if absf(face_normal.y) > 0.9:
		return Vector3.RIGHT
	return face_normal.cross(Vector3.UP).normalized()


func _extent(axis: Vector3, half_size: Vector3) -> float:
	return absf(axis.x) * half_size.x + absf(axis.y) * half_size.y + absf(axis.z) * half_size.z
