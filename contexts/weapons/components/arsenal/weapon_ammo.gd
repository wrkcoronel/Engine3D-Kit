class_name WeaponAmmo
extends RefCounted

var loaded := 0
var reserve := 0
var magazine_capacity := 0


static func full(capacity: int, reserve_rounds: int) -> WeaponAmmo:
	var ammo := WeaponAmmo.new()
	ammo.magazine_capacity = capacity
	ammo.loaded = capacity + 1
	ammo.reserve = reserve_rounds
	return ammo


func full_load() -> int:
	var round_in_chamber := 1
	return magazine_capacity + round_in_chamber


func is_empty() -> bool:
	return loaded <= 0


func is_full() -> bool:
	return loaded >= full_load()


func can_reload() -> bool:
	if is_full():
		return false
	return reserve > 0


func magazine_rounds() -> int:
	return maxi(loaded - 1, 0)


func missing_rounds() -> int:
	var empty_places := full_load() - loaded
	return clampi(empty_places, 0, reserve)


func consume_round() -> void:
	if is_empty():
		return
	loaded -= 1


func reload_all() -> void:
	var moved_rounds := missing_rounds()
	loaded += moved_rounds
	reserve -= moved_rounds


func load_one() -> void:
	if missing_rounds() <= 0:
		return
	loaded += 1
	reserve -= 1
