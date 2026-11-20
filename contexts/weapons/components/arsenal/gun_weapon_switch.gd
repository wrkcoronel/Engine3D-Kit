class_name GunWeaponSwitch
extends RefCounted

const EQUIP_COOLDOWN := 0.25

var holster := GunHolster.new()
var hand := WeaponInHand.new()
var models: Array[Node3D] = []
var on_equipped: Callable

var _arsenal: GunArsenal
var _trigger: GunTrigger
var _check: AmmoCheck
var _reloader: GunReloader
var _flash: GunMuzzleFlash
var _action_state: GunActionState
var _actions: Array[GunAction]
var _sounds: GunSounds


func _init(
	arsenal: GunArsenal,
	trigger: GunTrigger,
	check: AmmoCheck,
	reloader: GunReloader,
	flash: GunMuzzleFlash,
	action_state: GunActionState,
	actions: Array[GunAction],
	sounds: GunSounds
) -> void:
	_arsenal = arsenal
	_trigger = trigger
	_check = check
	_reloader = reloader
	_flash = flash
	_action_state = action_state
	_actions = actions
	_sounds = sounds


func select(index: int) -> void:
	var already_in_hand := index == _arsenal.current_index and not holster.holstered
	if already_in_hand:
		put_away_weapon()
		return
	switch_to(index)


func cycle(step: int) -> void:
	if holster.holstered and not holster.has_pending():
		switch_to(_arsenal.current_index)
		return
	var from_index := _arsenal.current_index
	if holster.has_pending():
		from_index = holster.pending_index
	switch_to(_arsenal.neighbor_index(from_index, step))


func switch_to(index: int) -> void:
	var plan := holster.plan_switch(index, _arsenal.current_index)
	if plan == GunHolster.SwitchPlan.EQUIP_NOW:
		equip(index)
		return
	if plan == GunHolster.SwitchPlan.DRAW_AGAIN:
		holster.pending_index = GunHolster.NO_WEAPON
		holster.holstered = false
		return
	put_away_weapon()
	holster.pending_index = index


func put_away_weapon() -> void:
	holster.pending_index = GunHolster.NO_WEAPON
	_trigger.queued_shot = false
	if holster.holstered:
		return
	_sounds.switch.play()
	if _reloader.reloading:
		_sounds.reload.stop()
		_reloader.cancel()
	_check.cancel()
	holster.holstered = true


func finish_pending() -> void:
	if not holster.has_pending():
		return
	if not holster.is_away():
		return
	equip(holster.pending_index)


func equip(index: int) -> void:
	_sounds.reload.stop()
	if hand.is_holding():
		_sounds.switch.play()
		hand.put_away(_current_action(), _flash, _reloader)
	_arsenal.current_index = index
	holster.pending_index = GunHolster.NO_WEAPON
	holster.holstered = false
	_trigger.queued_shot = false
	_trigger.cooldown = EQUIP_COOLDOWN
	_trigger.remember(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	_check.cancel()
	_action_state.stop_cycle()
	hand.take_out(models[index], _flash, _reloader)
	if on_equipped.is_valid():
		on_equipped.call()


func _current_action() -> GunAction:
	return _actions[_arsenal.current_stats().action]
