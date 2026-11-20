extends TestCase


func test_all_four_weapons_are_carried() -> void:
	var arsenal := GunArsenal.new()
	assert_eq(arsenal.weapons.size(), 4, "o personagem leva as quatro armas")
	assert_eq(arsenal.ammo.size(), 4, "cada arma tem a sua municao")


func test_wheel_wraps_around() -> void:
	var arsenal := GunArsenal.new()
	assert_eq(arsenal.neighbor_index(3, 1), 0, "depois da ultima volta para a primeira")
	assert_eq(arsenal.neighbor_index(0, -1), 3, "antes da primeira vem a ultima")


func test_each_weapon_keeps_its_own_ammo() -> void:
	var arsenal := GunArsenal.new()
	arsenal.current_ammo().consume_round()
	arsenal.current_index = 1
	assert_true(
		arsenal.current_ammo().is_full(), "a espingarda nao perde bala pelo tiro da pistola"
	)
