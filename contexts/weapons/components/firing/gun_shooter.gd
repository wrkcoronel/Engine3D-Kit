class_name GunShooter
extends Node

@export var impact_scene: PackedScene
@export var tracer_scene: PackedScene
@export var shoot_range := 200.0
@export_flags_3d_physics var collision_mask := 1


func fire_pellet(
	cam: Camera3D, muzzle: Node3D, barrel_basis: Basis, aimed: bool, stats: WeaponStats
) -> void:
	var origin := muzzle.global_position
	var aim_basis := barrel_basis
	var spread := stats.spread_hip
	if aimed:
		origin = cam.global_position
		aim_basis = cam.global_basis
		spread = stats.spread_aimed
	var direction := WeaponSpread.random_direction(aim_basis, spread)
	var hit := _cast(cam.get_world_3d(), origin, direction)
	var impact_point := origin + direction * shoot_range
	if not hit.is_empty():
		impact_point = hit["position"]
	GunTracer.spawn(tracer_scene, effects_parent(), muzzle.global_position, impact_point)
	_report_shot(hit, origin)
	if hit.is_empty():
		return
	_apply_hit(hit, direction, origin, stats)


func effects_parent() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return get_tree().root
	return scene


func _cast(world: World3D, origin: Vector3, direction: Vector3) -> Dictionary:
	var end_point := origin + direction * shoot_range
	var query := PhysicsRayQueryParameters3D.create(origin, end_point, collision_mask)
	return world.direct_space_state.intersect_ray(query)


func _apply_hit(hit: Dictionary, direction: Vector3, origin: Vector3, stats: WeaponStats) -> void:
	var hit_position: Vector3 = hit["position"]
	var target := hit["collider"] as Object
	var distance := origin.distance_to(hit_position)
	var damage := WeaponDamage.at_distance(stats, distance)
	if target.has_method("take_hit"):
		target.call("take_hit", hit, direction, damage)
		return
	var impact := impact_scene.instantiate() as Node3D
	effects_parent().add_child(impact)
	impact.global_position = hit_position


func _report_shot(hit: Dictionary, from: Vector3) -> void:
	if hit.is_empty():
		Telemetry.record(self, "arma", "tiro: nao acertou nada")
		return
	var target := hit["collider"] as Node
	var hit_position := hit["position"] as Vector3
	var distance := from.distance_to(hit_position)
	var target_name := TelemetryLog.describe_node(target)
	var where := TelemetryLog.format_vector(hit_position)
	Telemetry.record(
		self, "arma", "tiro: acertou %s a %.1f m em %s" % [target_name, distance, where]
	)
