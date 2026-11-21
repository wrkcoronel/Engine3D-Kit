class_name BulletHole
extends Decal

const LIFETIME_SECONDS := 20.0
const FADE_SECONDS := 3.0


static func place(hole: Decal, hit_position: Vector3, surface_normal: Vector3) -> void:
	hole.global_transform = hole_transform(hit_position, surface_normal)


static func hole_transform(hit_position: Vector3, surface_normal: Vector3) -> Transform3D:
	var reference_axis := Vector3.UP
	if absf(surface_normal.dot(Vector3.UP)) > 0.99:
		reference_axis = Vector3.RIGHT
	var tangent := surface_normal.cross(reference_axis).normalized()
	var bitangent := surface_normal.cross(tangent)
	var hole_basis := Basis(tangent, surface_normal, bitangent)
	var random_turn := randf() * TAU
	var turned_basis := hole_basis.rotated(surface_normal, random_turn)
	return Transform3D(turned_basis, hit_position)


func _ready() -> void:
	texture_albedo = BulletHoleTexture.albedo()
	texture_normal = BulletHoleTexture.normal()
	await get_tree().create_timer(LIFETIME_SECONDS).timeout
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	await fade.finished
	queue_free()
