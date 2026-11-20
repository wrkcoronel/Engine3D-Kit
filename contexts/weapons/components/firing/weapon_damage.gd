class_name WeaponDamage
extends RefCounted

const MINIMUM_DAMAGE := 1.0


static func at_distance(stats: WeaponStats, distance: float) -> float:
	var falloff_length := stats.falloff_end - stats.falloff_start
	var distance_past_start := distance - stats.falloff_start
	var falloff_progress := clampf(distance_past_start / falloff_length, 0.0, 1.0)
	var distance_factor := lerpf(1.0, stats.minimum_damage_factor, falloff_progress)
	var damage := roundf(stats.damage * distance_factor)
	return maxf(MINIMUM_DAMAGE, damage)
