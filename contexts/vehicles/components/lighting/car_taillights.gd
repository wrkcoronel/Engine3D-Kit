class_name CarTaillights
extends RefCounted

const LIGHT_POSITIONS: Array[Vector3] = [Vector3(-0.63, 0.86, 2.05), Vector3(0.63, 0.86, 2.05)]
const MESH_NAMES: Array[String] = ["Lanterna", "Lanterna_001", "LuzDeFreio"]
const LIGHT_COLOR := Color(1.0, 0.05, 0.03)
const LIGHT_RANGE := 4.0

var _lights: Array[OmniLight3D] = []
var _materials: Array[StandardMaterial3D] = []


static func glow_for(lights_on: bool, braking: bool) -> float:
	if braking:
		return 3.0
	if lights_on:
		return 1.0
	return 0.25


static func light_energy_for(lights_on: bool, braking: bool) -> float:
	if braking:
		return 1.2
	if lights_on:
		return 0.3
	return 0.0


func setup(car_body: Node3D, model: Node3D) -> void:
	for light_position: Vector3 in LIGHT_POSITIONS:
		var light := OmniLight3D.new()
		light.position = light_position
		light.light_color = LIGHT_COLOR
		light.omni_range = LIGHT_RANGE
		light.visible = false
		car_body.add_child(light)
		_lights.append(light)
	var meshes := CarLightMeshes.find_by_names(model, MESH_NAMES)
	_materials = CarLightMeshes.own_materials(meshes)
	update(false, false)


func update(lights_on: bool, braking: bool) -> void:
	var energy := light_energy_for(lights_on, braking)
	for light: OmniLight3D in _lights:
		light.light_energy = energy
		light.visible = energy > 0.0
	var glow := glow_for(lights_on, braking)
	for material: StandardMaterial3D in _materials:
		material.emission_energy_multiplier = glow
