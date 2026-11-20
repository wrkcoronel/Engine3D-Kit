extends Node3D

const SCOPE_FOV := 20.0
const DRY_FIRE_COOLDOWN := 0.3
const AFTER_RELOAD_COOLDOWN := 0.12
const INTERRUPT_SHOT_DELAY := 0.12
const AIM_BLOCKED_BY_WALL := 0.3
const SPRINT_BLOCKS := 0.5
const SCOPED_LOOK_SCALE := 0.26
const AIMED_LOOK_SCALE := 0.6

@export var block_fire_above := 0.5

var _arsenal := GunArsenal.new()
var _input_reader := GunInput.new()
var _trigger := GunTrigger.new()
var _flash := GunMuzzleFlash.new()
var _check := AmmoCheck.new()
var _reloader := GunReloader.new()
var _action_state := GunActionState.new()
var _actions: Array[GunAction] = [
	PistolSlideAction.new(), PumpAction.new(), CarbineBoltAction.new(), RifleBoltAction.new()
]
var _switch: GunWeaponSwitch
var _aiming := false
var _scoped := false
var _wall_amount := 0.0
var _body: CharacterBody3D
var _head: HeadLean
var _mouse_look: MouseLook

@onready var wall: GunWallAvoid = $WallAvoid
@onready var cover: GunCoverPeek = $CoverPeek
@onready var aim: GunAim = $Aim
@onready var sway: GunSway = $Sway
@onready var recoil: GunRecoil = $Recoil
@onready var sprint: GunSprint = $Sprint
@onready var shooter: GunShooter = $Shooter
@onready var sounds: GunSounds = $Sounds
@onready var scope_overlay: CanvasItem = $ScopeOverlay/Lens


func _ready() -> void:
	_body = owner as CharacterBody3D
	_head = _body.get_node("Head")
	_mouse_look = _body.get_node("MouseLook")
	_action_state.casing_parent = shooter.effects_parent()
	_switch = GunWeaponSwitch.new(
		_arsenal, _trigger, _check, _reloader, _flash, _action_state, _actions, sounds
	)
	_switch.on_equipped = _on_equipped
	for stats: WeaponStats in _arsenal.weapons:
		var model := get_node(stats.model_name) as Node3D
		model.visible = false
		MagazineRoundsView.prepare(model)
		_actions[stats.action].prepare(model)
		_switch.models.append(model)
	_switch.equip(0)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	_input_reader.read(event)
	match _input_reader.command:
		GunInput.Command.HOLSTER:
			_switch.put_away_weapon()
		GunInput.Command.RELOAD:
			_request_reload()
		GunInput.Command.SELECT:
			_switch.select(_input_reader.selected_index)
		GunInput.Command.NEXT:
			_switch.cycle(1)
		GunInput.Command.PREVIOUS:
			_switch.cycle(-1)


func _process(delta: float) -> void:
	_trigger.tick(delta)
	_switch.finish_pending()
	var cam := get_viewport().get_camera_3d()
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_update_pose_components(delta, cam, captured)
	_update_ammo_check(delta, captured)
	_update_action(delta)
	_flash.update(delta)
	_place_model()
	_place_magazine(cam)
	_update_fire(cam, captured)


func _update_pose_components(delta: float, cam: Camera3D, captured: bool) -> void:
	var wants_aim := captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var stats := _arsenal.current_stats()
	wall.update(delta, cam)
	cover.update(delta, _body, _head, wants_aim, wall.check_distance)
	sprint.update(delta, bool(_body.get("is_sprinting")))
	_wall_amount = wall.amount * (1.0 - absf(cover.amount)) * (1.0 - sprint.amount)
	var wall_lets_aim := _wall_amount < AIM_BLOCKED_BY_WALL
	_aiming = wants_aim and wall_lets_aim and _hands_ready()
	_scoped = _aiming and stats.has_scope
	aim.update(delta, cam, _aiming and not _scoped)
	if _scoped:
		cam.fov = SCOPE_FOV
	sway.update(delta, _body, aim.steady())
	recoil.update(delta)
	_switch.holster.update(delta, stats.long_gun)
	_switch.hand.model.visible = not _scoped and not _switch.holster.hides_model()
	scope_overlay.visible = _scoped
	_update_look_speed()


func _hands_ready() -> bool:
	if _reloader.reloading:
		return false
	if _switch.holster.holstered:
		return false
	return sprint.amount < SPRINT_BLOCKS


func _update_look_speed() -> void:
	_mouse_look.sensitivity_scale = 1.0
	if _aiming:
		_mouse_look.sensitivity_scale = AIMED_LOOK_SCALE
	if _scoped:
		_mouse_look.sensitivity_scale = SCOPED_LOOK_SCALE


func _update_ammo_check(delta: float, captured: bool) -> void:
	var reload_key_down := captured and Input.is_physical_key_pressed(GunInput.RELOAD_KEY)
	var check_key_down := captured and Input.is_physical_key_pressed(GunInput.CHECK_KEY)
	var allowed := _hands_ready() and not _aiming
	_check.update(delta, reload_key_down, check_key_down, allowed, _trigger.queued_shot)


func _update_action(delta: float) -> void:
	var ammo := _arsenal.current_ammo()
	_action_state.tick(delta)
	_action_state.inspect_amount = _check.amount
	_action_state.checking_chamber = _check.checking_chamber
	_action_state.loaded_rounds = ammo.loaded
	_current_action().update(_switch.hand.model, _action_state)
	var rounds := ammo.magazine_rounds()
	MagazineRoundsView.update(_switch.hand.model, rounds, _current_check_marker(), _check.amount)


func _place_model() -> void:
	var long_gun := _arsenal.current_stats().long_gun
	var pose := GunModelPose.new(_switch.hand.rest_position, _switch.hand.rest_rotation)
	GunPoseBuilder.add_sight(pose, _switch.hand.model, aim.amount)
	var is_pistol := _arsenal.current_stats().action == WeaponStats.Action.PISTOL_SLIDE
	var turns_pistol_first := is_pistol and _check.checking_chamber
	var check_marker := _current_check_marker()
	var reload_turn := _reloader.pose.turn
	GunPoseBuilder.add_ammo_check(
		pose, _switch.hand.model, check_marker, _check.amount, reload_turn, turns_pistol_first
	)
	var holster := _switch.holster
	pose.add(holster.position_offset(long_gun), holster.rotation_offset(long_gun))
	pose.add(_reloader.pose.offset, _reloader.pose.rotation)
	var steady := aim.steady()
	pose.add(wall.pos(_wall_amount), wall.rot(_wall_amount))
	pose.add(sprint.pos(sprint.amount), sprint.rot(sprint.amount))
	pose.add(sway.pos, sway.rot)
	pose.add(recoil.pos(steady), recoil.rot(steady))
	_switch.hand.model.position = pose.position
	_switch.hand.model.rotation = pose.rotation


func _place_magazine(cam: Camera3D) -> void:
	if _reloader.reloading:
		return
	var hand := _switch.hand
	var check_marker := _current_check_marker()
	var camera_transform := cam.global_transform
	MagazineInHand.place(
		hand.model, hand.magazine, hand.magazine_rest, check_marker, camera_transform, _check.amount
	)


func _current_check_marker() -> Marker3D:
	var checking_chamber := _check.checking_chamber and not _reloader.reloading
	return AmmoCheckPose.marker(_switch.hand.model, checking_chamber)


func _current_action() -> GunAction:
	return _actions[_arsenal.current_stats().action]


func _update_fire(cam: Camera3D, captured: bool) -> void:
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
		_shoot(cam)
	_trigger.remember(pressed)
	if _trigger.take_queued_shot():
		_shoot(cam)


func _can_shoot() -> bool:
	if _reloader.reloading:
		return false
	if _check.active:
		return false
	if _switch.holster.holstered:
		return false
	var sprint_free := sprint.amount < SPRINT_BLOCKS
	return sprint_free and _wall_amount < block_fire_above


func _shoot(cam: Camera3D) -> void:
	if not _can_shoot():
		return
	var stats := _arsenal.current_stats()
	var ammo := _arsenal.current_ammo()
	if ammo.is_empty():
		_dry_fire(ammo)
		return
	ammo.consume_round()
	_action_state.hammer_down = false
	GunSounds.play_shot(_switch.hand.shot_sound())
	_trigger.cooldown = stats.fire_interval
	recoil.fire(stats.kick)
	_flash.fire()
	_action_state.start_cycle(_current_action().cycle_time())
	var barrel_basis := _switch.hand.model.global_basis.orthonormalized()
	for pellet_number: int in stats.pellets:
		shooter.fire_pellet(cam, _switch.hand.muzzle(), barrel_basis, _aiming, stats)


func _dry_fire(ammo: WeaponAmmo) -> void:
	_trigger.cooldown = DRY_FIRE_COOLDOWN
	sounds.empty_click.play()
	_action_state.hammer_down = true
	if ammo.reserve > 0:
		_start_reload()
		return
	if not _aiming:
		_check.start_chamber_check(false)


func _interrupt_for_shot() -> void:
	if _switch.holster.holstered:
		return
	if _arsenal.current_ammo().is_empty():
		return
	if _reloader.reloading:
		sounds.reload.stop()
		_reloader.interrupt(create_tween())
	else:
		_check.interrupt()
	_trigger.queue_after(INTERRUPT_SHOT_DELAY)


func _request_reload() -> void:
	if not _hands_ready():
		return
	if _arsenal.current_ammo().can_reload():
		_start_reload()
		return
	var is_pistol := _arsenal.current_stats().action == WeaponStats.Action.PISTOL_SLIDE
	_check.start_chamber_check(is_pistol)


func _start_reload() -> void:
	_flash.hide()
	recoil.reset()
	var cam := get_viewport().get_camera_3d()
	var stats := _arsenal.current_stats()
	var ammo := _arsenal.current_ammo()
	_reloader.start(create_tween(), stats, ammo, cam, sounds, _on_reload_finished)


func _on_reload_finished() -> void:
	_action_state.hammer_down = false
	_trigger.cooldown = AFTER_RELOAD_COOLDOWN


func _on_equipped() -> void:
	recoil.reset()
	aim.reset()
