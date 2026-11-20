class_name BoxEdges
extends RefCounted

const CORNER_SIGNS: Array[Vector3] = [
	Vector3(-1, -1, -1),
	Vector3(1, -1, -1),
	Vector3(-1, 1, -1),
	Vector3(1, 1, -1),
	Vector3(-1, -1, 1),
	Vector3(1, -1, 1),
	Vector3(-1, 1, 1),
	Vector3(1, 1, 1),
]


static func corners(box_size: Vector3, box_transform: Transform3D) -> Array[Vector3]:
	var half_size := box_size / 2.0
	var world_corners: Array[Vector3] = []
	for corner_sign: Vector3 in CORNER_SIGNS:
		var local_corner := corner_sign * half_size
		world_corners.append(box_transform * local_corner)
	return world_corners


static func edges(box_size: Vector3, box_transform: Transform3D) -> Array[PackedVector3Array]:
	var box_corners := corners(box_size, box_transform)
	var box_edges: Array[PackedVector3Array] = []
	for first_index: int in CORNER_SIGNS.size():
		for second_index: int in range(first_index + 1, CORNER_SIGNS.size()):
			var sign_difference := CORNER_SIGNS[first_index] - CORNER_SIGNS[second_index]
			var differs_on_one_axis := absf(sign_difference.length() - 2.0) < 0.001
			if not differs_on_one_axis:
				continue
			var edge := PackedVector3Array([box_corners[first_index], box_corners[second_index]])
			box_edges.append(edge)
	return box_edges


static func nearest_edge(
	box_size: Vector3, box_transform: Transform3D, point: Vector3
) -> PackedVector3Array:
	var best_edge := PackedVector3Array()
	var best_distance := INF
	for edge: PackedVector3Array in edges(box_size, box_transform):
		var distance := distance_to_segment(point, edge[0], edge[1])
		if distance < best_distance:
			best_distance = distance
			best_edge = edge
	return best_edge


static func distance_to_segment(point: Vector3, start: Vector3, end: Vector3) -> float:
	var closest := Geometry3D.get_closest_point_to_segment(point, start, end)
	return point.distance_to(closest)
