class_name GunArsenal
extends RefCounted

var weapons: Array[WeaponStats] = WeaponCatalog.all()
var ammo: Array[WeaponAmmo] = []
var current_index := 0


func _init() -> void:
	for stats: WeaponStats in weapons:
		ammo.append(WeaponAmmo.full(stats.magazine_capacity, stats.starting_reserve))


func current_stats() -> WeaponStats:
	return weapons[current_index]


func current_ammo() -> WeaponAmmo:
	return ammo[current_index]


func neighbor_index(from_index: int, step: int) -> int:
	return posmod(from_index + step, weapons.size())
