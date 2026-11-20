class_name MagazineReload
extends RefCounted

const LOWERED_OFFSET := Vector3(-0.06, -0.12, 0.08)
const LOWERED_ROTATION := Vector3(-0.25, 0.05, -0.45)
const MAGAZINE_DROP := Vector3(0.0, -0.15, 0.0)


static func add_steps(
	tween: Tween, pose: GunReloadPose, magazine: Node3D, magazine_rest: Vector3, duration: float
) -> void:
	var dropped_magazine := magazine_rest + MAGAZINE_DROP
	tween.tween_property(pose, "offset", LOWERED_OFFSET, duration * 0.2)
	tween.parallel().tween_property(pose, "rotation", LOWERED_ROTATION, duration * 0.2)
	tween.tween_property(magazine, "position", dropped_magazine, duration * 0.2)
	tween.tween_interval(duration * 0.15)
	tween.tween_property(magazine, "position", magazine_rest, duration * 0.25)
	tween.tween_property(pose, "offset", Vector3.ZERO, duration * 0.2)
	tween.parallel().tween_property(pose, "rotation", Vector3.ZERO, duration * 0.2)
