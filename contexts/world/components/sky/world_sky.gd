class_name WorldSky
extends Node

@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var ground_material: ShaderMaterial


func _ready() -> void:
	var dark_sky := SkyPresets.dark()
	SkyApplier.apply(dark_sky, world_environment.environment, sun, ground_material)
