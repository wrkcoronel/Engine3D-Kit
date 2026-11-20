extends TestCase


func test_new_press_fires() -> void:
	var trigger := GunTrigger.new()
	assert_true(trigger.should_fire(true, false, true), "clique novo atira")


func test_holding_semi_auto_does_not_repeat() -> void:
	var trigger := GunTrigger.new()
	trigger.remember(true)
	assert_true(not trigger.should_fire(true, false, true), "segurar nao repete")


func test_holding_automatic_repeats_with_ammo() -> void:
	var trigger := GunTrigger.new()
	trigger.remember(true)
	assert_true(trigger.should_fire(true, true, true), "automatica repete segurando")
	assert_true(not trigger.should_fire(true, true, false), "sem bala nao repete")


func test_cooldown_blocks_until_it_ends() -> void:
	var trigger := GunTrigger.new()
	trigger.cooldown = 0.2
	assert_true(not trigger.should_fire(true, false, true), "no intervalo nao atira")
	trigger.tick(0.25)
	assert_true(trigger.should_fire(true, false, true), "depois do intervalo atira")


func test_queued_shot_waits_for_the_gun_to_return() -> void:
	var trigger := GunTrigger.new()
	trigger.queue_after(0.12)
	assert_true(not trigger.take_queued_shot(), "ainda voltando")
	trigger.tick(0.2)
	assert_true(trigger.take_queued_shot(), "voltou, o tiro sai")
	assert_true(not trigger.take_queued_shot(), "sai uma vez so")
