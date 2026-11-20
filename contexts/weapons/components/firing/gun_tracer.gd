class_name GunTracer
extends RefCounted

const SPEED := 400.0
const LENGTH := 0.35
const HEAD_START := 0.06
const LIFETIME := 0.075
const SHORTEST := 0.01


static func spawn(scene: PackedScene, parent: Node, start: Vector3, end: Vector3) -> void:
	if start.distance_to(end) < SHORTEST:
		return
	var tracer := scene.instantiate() as MeshInstance3D
	parent.add_child(tracer)
	var material := tracer.material_override as StandardMaterial3D
	place(tracer, 0.0, start, end)
	var move_along := func(age: float) -> void: place(tracer, age, start, end)
	var fade := tracer.create_tween()
	fade.tween_method(move_along, 0.0, LIFETIME, LIFETIME)
	fade.parallel().tween_property(material, "albedo_color:a", 0.0, LIFETIME)
	fade.tween_callback(tracer.queue_free)


static func place(tracer: MeshInstance3D, age: float, start: Vector3, end: Vector3) -> void:
	var total_length := start.distance_to(end)
	var direction := (end - start) / total_length
	var head := age * SPEED + HEAD_START
	var tail := maxf(0.0, head - LENGTH)
	if tail >= total_length:
		tracer.visible = false
		return
	var head_point := start + direction * minf(head, total_length)
	var tail_point := start + direction * tail
	stretch_between(tracer, tail_point, head_point)


static func stretch_between(tracer: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var length := start.distance_to(end)
	tracer.visible = length >= SHORTEST
	if not tracer.visible:
		return
	tracer.global_position = (start + end) * 0.5
	var direction := (end - start).normalized()
	var up := Vector3.UP
	if absf(direction.dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT
	tracer.look_at(end, up)
	tracer.scale.z = length
