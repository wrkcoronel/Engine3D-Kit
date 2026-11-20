class_name WeaponCatalog
extends RefCounted


static func all() -> Array[WeaponStats]:
	var weapons: Array[WeaponStats] = []
	weapons.append(pistol_1911())
	weapons.append(boito_pump())
	weapons.append(carbine_22())
	weapons.append(hunting_rifle())
	return weapons


static func pistol_1911() -> WeaponStats:
	var stats := WeaponStats.new()
	stats.model_name = "Pistola"
	stats.action = WeaponStats.Action.PISTOL_SLIDE
	stats.long_gun = false
	stats.magazine_capacity = 7
	stats.starting_reserve = 36
	stats.reload_time = 1.5
	stats.fire_interval = 0.22
	stats.spread_aimed = 0.004
	stats.spread_hip = 0.035
	stats.kick = 1.0
	stats.damage = 35.0
	stats.falloff_start = 15.0
	stats.falloff_end = 60.0
	stats.minimum_damage_factor = 0.45
	return stats


static func boito_pump() -> WeaponStats:
	var stats := WeaponStats.new()
	stats.model_name = "Escopeta"
	stats.action = WeaponStats.Action.PUMP
	stats.magazine_capacity = 5
	stats.starting_reserve = 12
	stats.reload_time = 0.6
	stats.shell_reload_time = 0.45
	stats.fire_interval = 0.85
	stats.pellets = 8
	stats.spread_aimed = 0.065
	stats.spread_hip = 0.065
	stats.kick = 2.0
	stats.damage = 12.0
	stats.falloff_start = 8.0
	stats.falloff_end = 35.0
	stats.minimum_damage_factor = 0.15
	return stats


static func carbine_22() -> WeaponStats:
	var stats := WeaponStats.new()
	stats.model_name = "Carabina22"
	stats.action = WeaponStats.Action.CARBINE_BOLT
	stats.magazine_capacity = 10
	stats.starting_reserve = 90
	stats.reload_time = 2.0
	stats.fire_interval = 0.085
	stats.spread_aimed = 0.008
	stats.spread_hip = 0.03
	stats.kick = 0.65
	stats.damage = 15.0
	stats.falloff_start = 20.0
	stats.falloff_end = 80.0
	stats.minimum_damage_factor = 0.4
	stats.automatic = true
	return stats


static func hunting_rifle() -> WeaponStats:
	var stats := WeaponStats.new()
	stats.model_name = "RifleCaca"
	stats.action = WeaponStats.Action.RIFLE_BOLT
	stats.magazine_capacity = 4
	stats.starting_reserve = 10
	stats.reload_time = 2.5
	stats.fire_interval = 1.2
	stats.spread_aimed = 0.0012
	stats.spread_hip = 0.045
	stats.kick = 1.7
	stats.damage = 120.0
	stats.falloff_start = 60.0
	stats.falloff_end = 180.0
	stats.minimum_damage_factor = 0.65
	stats.has_scope = true
	return stats
