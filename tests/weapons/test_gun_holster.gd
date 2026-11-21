extends TestCase


func test_switching_puts_away_first() -> void:
	var holster := GunHolster.new()
	var plan := holster.plan_switch(2, 0)
	assert_eq(plan, GunHolster.SwitchPlan.PUT_AWAY_FIRST, "com arma na mao, guarda antes")


func test_away_weapon_equips_at_once() -> void:
	var holster := GunHolster.new()
	holster.holstered = true
	holster.update(1.0, true)
	assert_true(holster.is_away(), "terminou de guardar")
	assert_eq(holster.plan_switch(3, 0), GunHolster.SwitchPlan.EQUIP_NOW, "guardada, saca direto")


func test_same_weapon_mid_holster_comes_back() -> void:
	var holster := GunHolster.new()
	holster.holstered = true
	holster.update(0.1, false)
	assert_eq(holster.plan_switch(0, 0), GunHolster.SwitchPlan.DRAW_AGAIN, "pediu a mesma, volta")


func test_pistol_goes_down_and_long_gun_goes_up() -> void:
	var holster := GunHolster.new()
	holster.amount = 1.0
	assert_true(holster.position_offset(false).y < 0.0, "pistola desce ao coldre")
	assert_true(holster.position_offset(true).y > 0.0, "arma longa sobe para as costas")


func test_scroll_is_ignored_while_drawing_or_switching() -> void:
	var holster := GunHolster.new()
	assert_true(not holster.is_changing_weapon(), "arma na mao, pode trocar")
	holster.amount = 0.5
	assert_true(holster.is_changing_weapon(), "sacando, espera terminar")
	holster.amount = 0.0
	holster.holstered = true
	holster.pending_index = 2
	assert_true(holster.is_changing_weapon(), "trocando, espera terminar")
