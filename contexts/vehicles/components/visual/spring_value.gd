class_name SpringValue
extends RefCounted

var value := 0.0
var speed := 0.0


func step(target: float, stiffness: float, damping: float, delta: float) -> void:
	var pull_to_target := (target - value) * stiffness
	var resistance := speed * damping
	var acceleration := pull_to_target - resistance
	speed += acceleration * delta
	value += speed * delta
