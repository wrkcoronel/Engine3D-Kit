class_name WeaponStats
extends RefCounted

enum Action { PISTOL_SLIDE, PUMP, CARBINE_BOLT, RIFLE_BOLT }

var model_name := ""
var action: Action = Action.PISTOL_SLIDE
var long_gun := true
var magazine_capacity := 0
var starting_reserve := 0
var reload_time := 0.0
var shell_reload_time := 0.0
var fire_interval := 0.0
var pellets := 1
var spread_aimed := 0.0
var spread_hip := 0.0
var kick := 1.0
var damage := 0.0
var falloff_start := 0.0
var falloff_end := 0.0
var minimum_damage_factor := 1.0
var automatic := false
var has_scope := false


func loads_shell_by_shell() -> bool:
	return shell_reload_time > 0.0
