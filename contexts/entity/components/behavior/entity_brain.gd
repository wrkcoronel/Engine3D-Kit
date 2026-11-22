class_name EntityBrain
extends RefCounted

var mode: EntityState.Mode = EntityState.Mode.VANISHED
var mode_timer := 3.0
var watched_seconds := 0.0
var wants_relocate := false
var triggered_glitch_flash := false
var triggered_attack_strike := false


func advance(
	delta: float, distance_to_target: float, target_is_looking: bool, random: RandomNumberGenerator
) -> void:
	wants_relocate = false
	triggered_glitch_flash = false
	triggered_attack_strike = false
	mode_timer = maxf(0.0, mode_timer - delta)

	if mode == EntityState.Mode.VANISHED:
		_update_vanished(random)
		return
	if mode == EntityState.Mode.STARE:
		_update_stare(delta, distance_to_target, target_is_looking, random)
		return
	if mode == EntityState.Mode.STALK:
		_update_stalk(distance_to_target, target_is_looking, random)
		return
	if mode == EntityState.Mode.ATTACK:
		_update_attack(distance_to_target, random)


func react_to_hit(random: RandomNumberGenerator) -> void:
	if mode == EntityState.Mode.VANISHED:
		return
	triggered_glitch_flash = true
	_enter_vanished(random)


func move_speed() -> float:
	if mode == EntityState.Mode.STALK:
		return EntityState.STALK_SPEED
	if mode == EntityState.Mode.ATTACK:
		return EntityState.ATTACK_SPEED
	return 0.0


func glitch_intensity(distance_to_target: float, target_is_looking: bool) -> float:
	if mode == EntityState.Mode.VANISHED:
		return 0.0
	var base := 0.22
	if mode == EntityState.Mode.ATTACK:
		base = 0.88
	elif target_is_looking:
		base = 0.48
	var closeness := clampf(1.0 - distance_to_target / 24.0, 0.0, 1.0)
	return clampf(base + closeness * 0.35, 0.0, 1.0)


func _update_vanished(random: RandomNumberGenerator) -> void:
	if mode_timer > 0.0:
		return
	wants_relocate = true
	watched_seconds = 0.0
	if random.randf() < EntityState.STALK_CHANCE_ON_REAPPEAR:
		mode = EntityState.Mode.STALK
		mode_timer = random.randf_range(5.0, 9.0)
		return
	mode = EntityState.Mode.STARE
	mode_timer = random.randf_range(EntityState.MIN_STARE_SECONDS, EntityState.MAX_STARE_SECONDS)


func _update_stare(
	delta: float, distance_to_target: float, target_is_looking: bool, random: RandomNumberGenerator
) -> void:
	if target_is_looking:
		watched_seconds += delta
	else:
		watched_seconds = maxf(0.0, watched_seconds - delta * 0.6)

	var stared_long_enough := watched_seconds >= EntityState.LOOKED_AT_TRIGGER_SECONDS
	if stared_long_enough:
		_react_to_being_spotted(distance_to_target, random)
		return

	if mode_timer <= 0.0:
		if not target_is_looking:
			mode = EntityState.Mode.STALK
			mode_timer = random.randf_range(4.0, 7.5)
			return
		triggered_glitch_flash = true
		_enter_vanished(random)


func _update_stalk(
	distance_to_target: float, target_is_looking: bool, random: RandomNumberGenerator
) -> void:
	if distance_to_target <= EntityState.ATTACK_TRIGGER_DISTANCE * 0.55:
		mode = EntityState.Mode.ATTACK
		mode_timer = 4.0
		triggered_glitch_flash = true
		return
	if target_is_looking:
		watched_seconds = 0.6
		mode = EntityState.Mode.STARE
		mode_timer = random.randf_range(2.0, 4.0)
		return
	if mode_timer <= 0.0:
		_enter_vanished(random)


func _update_attack(distance_to_target: float, random: RandomNumberGenerator) -> void:
	if distance_to_target <= EntityState.ATTACK_STRIKE_DISTANCE:
		triggered_attack_strike = true
		triggered_glitch_flash = true
		_enter_vanished(random)
		return
	if mode_timer <= 0.0:
		triggered_glitch_flash = true
		_enter_vanished(random)


func _react_to_being_spotted(distance_to_target: float, random: RandomNumberGenerator) -> void:
	var can_attack := distance_to_target <= EntityState.ATTACK_TRIGGER_DISTANCE
	if can_attack and random.randf() < EntityState.ATTACK_CHANCE_WHEN_SPOTTED:
		mode = EntityState.Mode.ATTACK
		mode_timer = 3.8
		triggered_glitch_flash = true
		return
	triggered_glitch_flash = true
	_enter_vanished(random)


func _enter_vanished(random: RandomNumberGenerator) -> void:
	mode = EntityState.Mode.VANISHED
	watched_seconds = 0.0
	mode_timer = random.randf_range(EntityState.MIN_VANISH_SECONDS, EntityState.MAX_VANISH_SECONDS)
