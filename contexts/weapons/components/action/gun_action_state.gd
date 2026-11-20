class_name GunActionState
extends RefCounted

var inspect_amount := 0.0
var checking_chamber := false
var loaded_rounds := 0
var hammer_down := false
var cycle_left := 0.0
var cycle_total := 0.0
var casing_ejected := false
var casing_parent: Node


func start_cycle(duration: float) -> void:
	cycle_total = duration
	cycle_left = duration
	casing_ejected = false


func stop_cycle() -> void:
	cycle_left = 0.0


func tick(delta: float) -> void:
	cycle_left = maxf(0.0, cycle_left - delta)


func is_cycling() -> bool:
	return cycle_left > 0.0


func cycle_progress() -> float:
	if cycle_total <= 0.0:
		return 1.0
	return 1.0 - cycle_left / cycle_total


func cycle_swing() -> float:
	return sin(PI * cycle_progress())
