class_name HeadLean
extends Node3D

@export var lean_distance := 0.5
@export var lean_angle_deg := 10.0

var rest_position: Vector3

var _rig: PlayerRig


func _ready() -> void:
	rest_position = position


func bind(rig: PlayerRig) -> void:
	_rig = rig


func _process(_delta: float) -> void:
	var lean := 0.0
	if _rig != null:
		lean = _rig.lean
		_rig.eye_rest_position = rest_position
		_rig.lean_distance = lean_distance
	position.x = rest_position.x + lean * lean_distance
	rotation.z = -lean * deg_to_rad(lean_angle_deg)
