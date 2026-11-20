class_name GunTrigger
extends RefCounted

var cooldown := 0.0
var queued_shot := false

var _held := false


func tick(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)


func is_new_press(pressed: bool) -> bool:
	if not pressed:
		return false
	return not _held


func should_fire(pressed: bool, automatic: bool, has_ammo: bool) -> bool:
	if queued_shot:
		return false
	if not pressed:
		return false
	if cooldown > 0.0:
		return false
	if not _held:
		return true
	return automatic and has_ammo


func queue_after(delay: float) -> void:
	queued_shot = true
	cooldown = maxf(cooldown, delay)


func take_queued_shot() -> bool:
	if not queued_shot:
		return false
	if cooldown > 0.0:
		return false
	queued_shot = false
	return true


func remember(pressed: bool) -> void:
	_held = pressed
