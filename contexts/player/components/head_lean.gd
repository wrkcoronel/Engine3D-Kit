class_name HeadLean
extends Node3D

@export var lean_distance := 0.5
@export var lean_angle_deg := 10.0

var lean := 0.0
var rest_position: Vector3


func _ready() -> void:
	rest_position = position


func _process(_delta: float) -> void:
	position.x = rest_position.x + lean * lean_distance
	rotation.z = -lean * deg_to_rad(lean_angle_deg)
