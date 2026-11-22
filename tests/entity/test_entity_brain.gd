extends TestCase


func test_vanished_entity_reappears_and_requests_relocate() -> void:
	var brain := EntityBrain.new()
	brain.mode = EntityState.Mode.VANISHED
	brain.mode_timer = 1.0
	var random := _seeded_random(10)

	brain.advance(1.5, 20.0, false, random)
	assert_true(brain.wants_relocate, "pede nova posicao ao reaparecer")
	var is_visible_mode := (
		brain.mode == EntityState.Mode.STARE or brain.mode == EntityState.Mode.STALK
	)
	assert_true(is_visible_mode, "reaparece observando ou perseguindo")


func test_staring_long_enough_triggers_vanish_or_attack() -> void:
	var brain := EntityBrain.new()
	brain.mode = EntityState.Mode.STARE
	brain.mode_timer = 10.0
	var random := _seeded_random(7)

	brain.advance(EntityState.LOOKED_AT_TRIGGER_SECONDS + 0.1, 12.0, true, random)
	assert_true(brain.triggered_glitch_flash, "dispara glitch ao reagir ao olhar")
	var reacted := brain.mode == EntityState.Mode.VANISHED or brain.mode == EntityState.Mode.ATTACK
	assert_true(reacted, "ou some ou avanca para atacar")


func test_attack_strikes_when_reaching_player_and_vanishes() -> void:
	var brain := EntityBrain.new()
	brain.mode = EntityState.Mode.ATTACK
	brain.mode_timer = 4.0
	var random := _seeded_random(3)

	brain.advance(0.1, EntityState.ATTACK_STRIKE_DISTANCE - 0.2, true, random)
	assert_true(brain.triggered_attack_strike, "registra impacto do ataque")
	assert_true(brain.triggered_glitch_flash, "dispara glitch no impacto")
	assert_eq(brain.mode, EntityState.Mode.VANISHED, "desaparece logo apos o ataque")


func test_taking_a_hit_makes_the_entity_vanish_in_a_glitch() -> void:
	var brain := EntityBrain.new()
	brain.mode = EntityState.Mode.STARE
	var random := _seeded_random(9)

	brain.react_to_hit(random)
	assert_true(brain.triggered_glitch_flash, "dispara glitch ao levar tiro")
	assert_eq(brain.mode, EntityState.Mode.VANISHED, "some ao ser atingida")


func _seeded_random(seed_value: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	return random
