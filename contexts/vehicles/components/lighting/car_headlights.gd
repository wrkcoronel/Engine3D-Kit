class_name CarHeadlights
extends RefCounted

const LIGHT_POSITIONS: Array[Vector3] = [Vector3(-0.47, 0.585, -2.05), Vector3(0.47, 0.585, -2.05)]
const LENS_NAMES: Array[String] = [
	"FarolLente",
	"FarolLente_001",
	"FarolLente_002",
	"FarolLente_003",
]
const LIGHT_COLOR := Color(1.0, 0.93, 0.8)
const SPOT_ANGLE_ATTENUATION := 1.6

var mode := CarBeamMode.Mode.OFF

var _spots: Array[SpotLight3D] = []
var _lens_materials: Array[StandardMaterial3D] = []


func setup(car_body: Node3D, model: Node3D) -> void:
	for light_position: Vector3 in LIGHT_POSITIONS:
		var spot := _create_spot(light_position)
		car_body.add_child(spot)
		_spots.append(spot)
	var lens_meshes := CarLightMeshes.find_by_names(model, LENS_NAMES)
	_lens_materials = CarLightMeshes.own_materials(lens_meshes)
	_apply()


func cycle() -> void:
	mode = CarBeamMode.next(mode)
	_apply()


func is_on() -> bool:
	return mode != CarBeamMode.Mode.OFF


func spot_count() -> int:
	return _spots.size()


func spot_energy() -> float:
	return _spots[0].light_energy


func _create_spot(light_position: Vector3) -> SpotLight3D:
	var spot := SpotLight3D.new()
	spot.position = light_position
	spot.light_color = LIGHT_COLOR
	spot.shadow_enabled = true
	spot.spot_attenuation = 1.0
	spot.spot_angle_attenuation = SPOT_ANGLE_ATTENUATION
	spot.visible = false
	return spot


func _apply() -> void:
	for spot: SpotLight3D in _spots:
		spot.visible = is_on()
		spot.light_energy = CarBeamMode.spot_energy(mode)
		spot.spot_range = CarBeamMode.spot_range(mode)
		spot.spot_angle = CarBeamMode.spot_angle_degrees(mode)
		spot.rotation_degrees.x = CarBeamMode.pitch_degrees(mode)
	for material: StandardMaterial3D in _lens_materials:
		material.emission_energy_multiplier = CarBeamMode.lens_glow(mode)
