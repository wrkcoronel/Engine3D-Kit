class_name CasingEjector
extends RefCounted

const FLIGHT_TIME := 0.8
const HALF_GRAVITY := Vector3(0.0, -4.9, 0.0)
const BULLET_NODE := "Projetil"


static func eject(
	casing_scene: PackedScene, parent: Node, weapon: Node3D, point: Vector3, speed: Vector3
) -> void:
	var casing := casing_scene.instantiate() as Node3D
	(casing.get_node(BULLET_NODE) as Node3D).visible = false
	parent.add_child(casing)
	var start := weapon.global_transform * Transform3D(Basis.IDENTITY, point)
	casing.global_transform = start
	var velocity := weapon.global_basis.orthonormalized() * speed
	var spin := random_spin()
	var fly := func(time: float) -> void:
		casing.global_transform = flight_transform(start, velocity, spin, time)
	var flight := casing.create_tween()
	flight.tween_method(fly, 0.0, FLIGHT_TIME, FLIGHT_TIME)
	flight.tween_callback(casing.queue_free)


static func random_spin() -> Vector3:
	var tumble := randf_range(-14.0, -9.0)
	var twist := randf_range(-5.0, 5.0)
	var roll := randf_range(-3.0, 3.0)
	return Vector3(tumble, twist, roll)


static func flight_transform(
	start: Transform3D, velocity: Vector3, spin: Vector3, time: float
) -> Transform3D:
	var turned := start.basis * Basis.from_euler(spin * time)
	var fall := HALF_GRAVITY * time * time
	var moved := start.origin + velocity * time + fall
	return Transform3D(turned, moved)
