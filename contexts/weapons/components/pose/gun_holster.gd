class_name GunHolster
extends RefCounted

enum SwitchPlan { EQUIP_NOW, DRAW_AGAIN, PUT_AWAY_FIRST }

const PISTOL_POSITION := Vector3(0.06, -0.42, 0.12)
const PISTOL_ROTATION := Vector3(-0.9, 0.2, -0.3)
const BACK_POSITION := Vector3(0.14, 0.5, 0.32)
const BACK_ROTATION := Vector3(1.75, 0.4, 0.5)
const BACK_ARC_HEIGHT := 0.06
const PISTOL_SPEED := 3.5
const LONG_GUN_SPEED := 2.9
const HIDDEN_AT := 0.98
const NO_WEAPON := -1

var holstered := false
var amount := 0.0
var pending_index := NO_WEAPON


func update(delta: float, long_gun: bool) -> void:
	var speed := PISTOL_SPEED
	if long_gun:
		speed = LONG_GUN_SPEED
	var target := 0.0
	if holstered:
		target = 1.0
	amount = move_toward(amount, target, delta * speed)


func is_away() -> bool:
	return holstered and amount >= 1.0


func hides_model() -> bool:
	return amount >= HIDDEN_AT


func is_changing_weapon() -> bool:
	if has_pending():
		return true
	var drawing := not holstered and amount > 0.0
	return drawing


func has_pending() -> bool:
	return pending_index != NO_WEAPON


func plan_switch(index: int, current_index: int) -> SwitchPlan:
	if is_away():
		return SwitchPlan.EQUIP_NOW
	if index == current_index:
		return SwitchPlan.DRAW_AGAIN
	return SwitchPlan.PUT_AWAY_FIRST


func position_offset(long_gun: bool) -> Vector3:
	var eased := smoothstep(0.0, 1.0, amount)
	if not long_gun:
		return PISTOL_POSITION * eased
	var over_shoulder := Vector3(0.0, BACK_ARC_HEIGHT * sin(PI * eased), 0.0)
	return BACK_POSITION * eased * eased + over_shoulder


func rotation_offset(long_gun: bool) -> Vector3:
	var eased := smoothstep(0.0, 1.0, amount)
	if long_gun:
		return BACK_ROTATION * eased
	return PISTOL_ROTATION * eased
