class_name CollisionDescription
extends RefCounted


static func describe(collision: KinematicCollision3D) -> String:
	var collider := collision.get_collider() as Node
	var point := collision.get_position()
	var parts: PackedStringArray = []
	parts.append(_collider_name(collider))
	parts.append("ponto " + TelemetryLog.format_vector(point))
	parts.append("normal " + TelemetryLog.format_vector(collision.get_normal()))
	var shape_node := collision.get_collider_shape() as CollisionShape3D
	if shape_node:
		parts.append(describe_shape(shape_node))
		parts.append(_nearest_edge_text(shape_node, point))
	return " | ".join(parts)


static func describe_shape(shape_node: CollisionShape3D) -> String:
	var shape_transform := shape_node.global_transform
	var rotation_degrees := shape_transform.basis.get_euler() * (180.0 / PI)
	var origin_text := "origem " + TelemetryLog.format_vector(shape_transform.origin)
	var rotation_text := "rotacao graus " + TelemetryLog.format_vector(rotation_degrees)
	var shape_text := shape_node.shape.get_class()
	var box := shape_node.shape as BoxShape3D
	if box:
		shape_text += " tamanho " + TelemetryLog.format_vector(box.size)
	return "forma %s %s %s" % [shape_text, origin_text, rotation_text]


static func _collider_name(collider: Node) -> String:
	if collider == null:
		return "?"
	return TelemetryLog.describe_node(collider)


static func _nearest_edge_text(shape_node: CollisionShape3D, point: Vector3) -> String:
	var box := shape_node.shape as BoxShape3D
	if box == null:
		return "aresta: so calculada para BoxShape3D"
	var shape_transform := shape_node.global_transform
	var edge := BoxEdges.nearest_edge(box.size, shape_transform, point)
	var distance := BoxEdges.distance_to_segment(point, edge[0], edge[1])
	var edge_start := TelemetryLog.format_vector(edge[0])
	var edge_end := TelemetryLog.format_vector(edge[1])
	return "aresta mais proxima %s -> %s a %.2f m" % [edge_start, edge_end, distance]
