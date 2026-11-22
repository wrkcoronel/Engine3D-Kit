class_name GunFiring
extends RefCounted

const DRY_FIRE_COOLDOWN := 0.3
const INTERRUPT_SHOT_DELAY := 0.12
const SPRINT_BLOCKS := 0.5
const BLOCK_FIRE_ABOVE := 0.5

var _arsenal: GunArsenal
var _trigger: GunTrigger
var _check: AmmoCheck
var _reloader: GunReloader
var _flash: GunMuzzleFlash
var _action_state: GunActionState
var _actions: Array[GunAction]
var _weapon_switch: GunWeaponSwitch
var _recoil: GunRecoil
var _sounds: GunSounds
var _shooter: GunShooter
var _tween_source: Node
var _start_reload: Callable


func _init(
	arsenal: GunArsenal,
	trigger: GunTrigger,
	check: AmmoCheck,
	reloader: GunReloader,
	flash: GunMuzzleFlash,
	action_state: GunActionState,
	actions: Array[GunAction],
	weapon_switch: GunWeaponSwitch
) -> void:
	_arsenal = arsenal
	_trigger = trigger
	_check = check
	_reloader = reloader
	_flash = flash
	_action_state = action_state
	_actions = actions
	_weapon_switch = weapon_switch


func bind_effects(
	recoil: GunRecoil,
	sounds: GunSounds,
	shooter: GunShooter,
	tween_source: Node,
	start_reload: Callable
) -> void:
	_recoil = recoil
	_sounds = sounds
	_shooter = shooter
	_tween_source = tween_source
	_start_reload = start_reload


func update(
	cam: Camera3D, captured: bool, aiming: bool, wall_amount: float, sprint_amount: float
) -> void:
	if not captured:
		_trigger.remember(false)
		return
	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var busy := _reloader.reloading or _check.active
	if _trigger.is_new_press(pressed) and busy:
		_interrupt_for_shot()
	var automatic := _arsenal.current_stats().automatic
	var has_ammo := not _arsenal.current_ammo().is_empty()
	if _trigger.should_fire(pressed, automatic, has_ammo):
		shoot(cam, aiming, wall_amount, sprint_amount)
	_trigger.remember(pressed)
	if _trigger.take_queued_shot():
		shoot(cam, aiming, wall_amount, sprint_amount)


func shoot(cam: Camera3D, aiming: bool, wall_amount: float, sprint_amount: float) -> void:
	if not _can_shoot(wall_amount, sprint_amount):
		return
	var stats := _arsenal.current_stats()
	var ammo := _arsenal.current_ammo()
	if ammo.is_empty():
		_dry_fire(ammo, aiming)
		return
	ammo.consume_round()
	_action_state.hammer_down = false
	GunSounds.play_shot(_weapon_switch.hand.shot_sound())
	_trigger.cooldown = stats.fire_interval
	_recoil.fire(stats.kick)
	_flash.fire()
	var current_action := _actions[stats.action]
	_action_state.start_cycle(current_action.cycle_time())
	var hand := _weapon_switch.hand
	var barrel_basis := hand.model.global_basis.orthonormalized()
	for pellet_number: int in stats.pellets:
		_shooter.fire_pellet(cam, hand.muzzle(), barrel_basis, aiming, stats)


func _can_shoot(wall_amount: float, sprint_amount: float) -> bool:
	if _reloader.reloading:
		return false
	if _check.active:
		return false
	if _weapon_switch.holster.holstered:
		return false
	var sprint_free := sprint_amount < SPRINT_BLOCKS
	return sprint_free and wall_amount < BLOCK_FIRE_ABOVE


func _dry_fire(ammo: WeaponAmmo, aiming: bool) -> void:
	_trigger.cooldown = DRY_FIRE_COOLDOWN
	_sounds.empty_click.play()
	_action_state.hammer_down = true
	if ammo.reserve > 0:
		_start_reload.call()
		return
	if not aiming:
		_check.start_chamber_check(false)


func _interrupt_for_shot() -> void:
	if _weapon_switch.holster.holstered:
		return
	if _arsenal.current_ammo().is_empty():
		return
	if _reloader.reloading:
		_sounds.reload.stop()
		_reloader.interrupt(_tween_source.create_tween())
	else:
		_check.interrupt()
	_trigger.queue_after(INTERRUPT_SHOT_DELAY)
