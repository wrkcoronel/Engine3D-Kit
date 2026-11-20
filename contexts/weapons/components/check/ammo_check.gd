class_name AmmoCheck
extends RefCounted

const CHAMBER_CHECK_TIME := 1.6
const NORMAL_SPEED := 8.0
const INTERRUPTED_SPEED := 22.0
const SETTLED := 0.001

var amount := 0.0
var checking_chamber := false
var active := false

var _timer := 0.0
var _held_by_reload_key := false
var _suppressed := false


func start_chamber_check(hold_while_reload_key_down: bool) -> void:
	checking_chamber = true
	_timer = CHAMBER_CHECK_TIME
	_held_by_reload_key = hold_while_reload_key_down


func interrupt() -> void:
	_timer = 0.0
	_suppressed = true
	active = false


func cancel() -> void:
	_timer = 0.0
	_held_by_reload_key = false
	active = false
	amount = 0.0


func update(
	delta: float, reload_key_down: bool, check_key_down: bool, allowed: bool, return_fast: bool
) -> void:
	_follow_keys(delta, reload_key_down, check_key_down)
	var wants_check := check_key_down or _timer > 0.0
	active = allowed and wants_check and not _suppressed
	if not active:
		_timer = 0.0
		_held_by_reload_key = false
	_blend(delta, return_fast)


func _follow_keys(delta: float, reload_key_down: bool, check_key_down: bool) -> void:
	if _held_by_reload_key and not reload_key_down:
		_held_by_reload_key = false
		_timer = 0.0
	if not _held_by_reload_key:
		_timer = maxf(0.0, _timer - delta)
	if check_key_down:
		if _held_by_reload_key:
			_held_by_reload_key = false
			_timer = 0.0
		checking_chamber = false
	if not check_key_down and _timer <= 0.0:
		_suppressed = false


func _blend(delta: float, return_fast: bool) -> void:
	var speed := NORMAL_SPEED
	if _suppressed or return_fast:
		speed = INTERRUPTED_SPEED
	var target := 0.0
	if active:
		target = 1.0
	amount = lerpf(amount, target, minf(delta * speed, 1.0))
	if amount < SETTLED:
		amount = 0.0
