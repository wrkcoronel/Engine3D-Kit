extends TestCase


func test_full_damage_before_falloff() -> void:
	var pistol := WeaponCatalog.pistol_1911()
	assert_eq(WeaponDamage.at_distance(pistol, 5.0), 35.0, "perto tira o dano cheio")


func test_minimum_damage_after_falloff() -> void:
	var pistol := WeaponCatalog.pistol_1911()
	var expected := roundf(35.0 * pistol.minimum_damage_factor)
	assert_eq(WeaponDamage.at_distance(pistol, 500.0), expected, "longe tira o minimo da arma")


func test_damage_drops_halfway_through_falloff() -> void:
	var pistol := WeaponCatalog.pistol_1911()
	var halfway := (pistol.falloff_start + pistol.falloff_end) / 2.0
	var expected := roundf(35.0 * lerpf(1.0, pistol.minimum_damage_factor, 0.5))
	assert_eq(WeaponDamage.at_distance(pistol, halfway), expected, "no meio cai pela metade")


func test_damage_never_below_one() -> void:
	var shotgun := WeaponCatalog.boito_pump()
	shotgun.damage = 1.0
	assert_eq(WeaponDamage.at_distance(shotgun, 500.0), 1.0, "sempre tira pelo menos 1")
