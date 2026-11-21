class_name GrassRibbonArrays
extends RefCounted

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


func add_ribbon(
	centers: PackedVector3Array,
	half_widths: Array[float],
	point_colors: PackedColorArray,
	side_direction: Vector3,
) -> void:
	var first_vertex_index := vertices.size()
	var face_normal := side_direction.cross(Vector3.UP).normalized()
	for point_index: int in centers.size():
		var center := centers[point_index]
		var side_offset := side_direction * half_widths[point_index]
		vertices.append(center - side_offset)
		vertices.append(center + side_offset)
		normals.append(face_normal)
		normals.append(face_normal)
		colors.append(point_colors[point_index])
		colors.append(point_colors[point_index])
	for segment_index: int in centers.size() - 1:
		var lower_left := first_vertex_index + segment_index * 2
		var lower_right := lower_left + 1
		var upper_left := lower_left + 2
		var upper_right := lower_left + 3
		indices.append_array(PackedInt32Array([lower_left, lower_right, upper_left]))
		indices.append_array(PackedInt32Array([lower_right, upper_right, upper_left]))


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
