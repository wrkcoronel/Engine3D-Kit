extends TestCase


func test_new_weapon_starts_full_with_round_in_chamber() -> void:
	var ammo := WeaponAmmo.full(7, 36)
	assert_eq(ammo.loaded, 8, "pente cheio mais a bala na camara")
	assert_true(ammo.is_full(), "comeca cheia")
	assert_true(not ammo.can_reload(), "cheia nao recarrega")


func test_shooting_spends_rounds_until_empty() -> void:
	var ammo := WeaponAmmo.full(1, 0)
	ammo.consume_round()
	ammo.consume_round()
	ammo.consume_round()
	assert_eq(ammo.loaded, 0, "nao passa de zero")
	assert_true(ammo.is_empty(), "sem bala")


func test_reload_fills_from_reserve() -> void:
	var ammo := WeaponAmmo.full(7, 36)
	ammo.loaded = 3
	ammo.reload_all()
	assert_eq(ammo.loaded, 8, "volta a ficar cheia")
	assert_eq(ammo.reserve, 31, "tira da reserva so o que faltava")


func test_reload_with_small_reserve_uses_what_is_left() -> void:
	var ammo := WeaponAmmo.full(7, 2)
	ammo.loaded = 0
	ammo.reload_all()
	assert_eq(ammo.loaded, 2, "poe so o que tinha na reserva")
	assert_eq(ammo.reserve, 0, "reserva acaba")


func test_empty_reserve_cannot_reload() -> void:
	var ammo := WeaponAmmo.full(7, 0)
	ammo.loaded = 2
	assert_true(not ammo.can_reload(), "sem reserva nao ha o que recarregar")


func test_shell_by_shell_stops_when_full() -> void:
	var ammo := WeaponAmmo.full(5, 12)
	ammo.loaded = 4
	ammo.load_one()
	ammo.load_one()
	ammo.load_one()
	assert_eq(ammo.loaded, 6, "para no tubo cheio mais a camara")
	assert_eq(ammo.reserve, 10, "so gastou dois cartuchos")


func test_magazine_rounds_leave_the_chamber_out() -> void:
	var ammo := WeaponAmmo.full(7, 0)
	assert_eq(ammo.magazine_rounds(), 7, "o pente tem tudo menos a camara")
	ammo.loaded = 0
	assert_eq(ammo.magazine_rounds(), 0, "vazia nao fica negativa")
