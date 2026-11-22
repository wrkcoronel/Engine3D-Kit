class_name Flashlight
extends Node3D

const VISUAL_SCENE := preload("res://contexts/flashlight/models/flashlight_visual.tscn")
const LENS_PATH := "Lens"
const LENS_OFF_META := "lens_off"
const TOGGLE_KEY := KEY_F
const LIGHT_ENERGY := 6.0
const LIGHT_RANGE := 45.0
const BEAM_ANGLE_DEGREES := 26.0
const ANGLE_ATTENUATION := 1.2
const DRAW_SPEED := 3.5
const BEAM_ON_AT := 0.85

var draw_amount := 0.0

var _on := false
var _holder_active := true
var _sway := FlashlightSway.new()
var _beam: SpotLight3D
var _visual: Node3D
var _lens: MeshInstance3D
var _lens_off_material: Material
var _rig: PlayerRig
var _anchor: HeldItemAnchor


func _ready() -> void:
	top_level = true
	_beam = _create_beam()
	add_child(_beam)
	_visual = VISUAL_SCENE.instantiate() as Node3D
	add_child(_visual)
	_lens = _visual.get_node_or_null(LENS_PATH) as MeshInstance3D
	if _lens != null:
		_lens_off_material = _lens.get_meta(LENS_OFF_META, null) as Material
	_apply_state(false)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	_find_neighbors()
	_holder_active = _is_holder_active()
	if not _holder_active:
		_hide_while_holder_is_away()
		return
	var aim_amount := 0.0
	var scoped := false
	var item_transform := camera.global_transform
	var muzzle_position := camera.global_position
	var sprint_amount := 0.0
	if _anchor != null and _anchor.has_item:
		aim_amount = _anchor.aim_amount
		scoped = _anchor.scoped
		item_transform = _anchor.item_transform
		muzzle_position = _anchor.muzzle_position
		sprint_amount = _anchor.sprint_amount
	_update_motion(delta, sprint_amount)
	update(delta, aim_amount, scoped, camera.global_transform, item_transform, muzzle_position)


func is_on() -> bool:
	return _on


func beam() -> SpotLight3D:
	return _beam


func visual() -> Node3D:
	return _visual


func update(
	delta: float,
	aim_amount: float,
	scoped: bool,
	camera_transform: Transform3D,
	weapon_transform: Transform3D,
	muzzle_position: Vector3
) -> void:
	var draw_target := 0.0
	if _on:
		draw_target = 1.0
	draw_amount = move_toward(draw_amount, draw_target, delta * DRAW_SPEED)
	var hand_in_camera := (
		camera_transform.affine_inverse() * FlashlightPose.hand_pose(camera_transform)
	)
	var swayed_hand := _sway.apply(hand_in_camera, 1.0)
	var resting_pose := camera_transform * swayed_hand
	var blend := smoothstep(0.0, 1.0, aim_amount)
	if scoped:
		resting_pose = FlashlightPose.scope_pose(camera_transform)
		blend = 0.0
	var aimed_pose := FlashlightPose.under_barrel_pose(weapon_transform, muzzle_position)
	var raised_pose := resting_pose.interpolate_with(aimed_pose, blend)
	var pose_in_camera := camera_transform.affine_inverse() * raised_pose
	var lowered_amount := 1.0 - smoothstep(0.0, 1.0, draw_amount)
	global_transform = (
		camera_transform * FlashlightPose.lowered_pose(pose_in_camera, lowered_amount)
	)
	_visual.visible = draw_amount > 0.0 and not scoped
	_beam.visible = _on and draw_amount >= BEAM_ON_AT


func handle_key(key: InputEventKey) -> void:
	if not _holder_active:
		return
	if not key.pressed:
		return
	if key.echo:
		return
	if key.keycode != TOGGLE_KEY:
		return
	_apply_state(not _on)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var key := event as InputEventKey
	if key == null:
		return
	handle_key(key)


func _find_neighbors() -> void:
	if _rig == null:
		_rig = PlayerRig.find(get_tree())
	if _anchor == null:
		_anchor = HeldItemAnchor.find(get_tree())


func _update_motion(delta: float, sprint_target: float) -> void:
	var ground_speed := 0.0
	var body: CharacterBody3D = null
	if _rig != null:
		body = _rig.body
	if body != null and body.is_on_floor():
		ground_speed = Vector2(body.velocity.x, body.velocity.z).length()
	_sway.update(delta, ground_speed, sprint_target)


func _is_holder_active() -> bool:
	if _rig == null:
		return true
	if _rig.body == null:
		return true
	return _rig.body.visible


func _hide_while_holder_is_away() -> void:
	_visual.visible = false
	_beam.visible = false


func _apply_state(turned_on: bool) -> void:
	_on = turned_on
	if not turned_on:
		_beam.visible = false
	if not is_instance_valid(_lens):
		return
	if turned_on:
		_lens.material_override = null
	else:
		_lens.material_override = _lens_off_material


func _create_beam() -> SpotLight3D:
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.95, 0.85)
	spot.light_energy = LIGHT_ENERGY
	spot.spot_range = LIGHT_RANGE
	spot.spot_angle = BEAM_ANGLE_DEGREES
	spot.spot_angle_attenuation = ANGLE_ATTENUATION
	spot.light_projector = FlashlightBeamTexture.create()
	spot.shadow_enabled = true
	spot.visible = false
	return spot
