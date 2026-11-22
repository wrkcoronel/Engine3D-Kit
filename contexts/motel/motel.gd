class_name Motel
extends StaticBody3D

@export var enable_boundary := false


func _ready() -> void:
	var pieces := collect_all_pieces()
	_attach_meshes(pieces)
	_attach_collisions(pieces)
	_add_lights()
	_add_signs()
	_add_room_plaques()
	if enable_boundary:
		_add_boundary()


func collect_all_pieces() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	pieces.append_array(MotelStructure.build())
	pieces.append_array(MotelWalkways.build())
	pieces.append_array(MotelFacade.build())
	pieces.append_array(MotelReception.build())
	pieces.append_array(MotelReceptionInterior.build())
	pieces.append_array(MotelSigns.build())
	pieces.append_array(MotelRoomInterior.build())
	pieces.append_array(MotelWestRoomInterior.build())
	pieces.append_array(MotelLot.build())
	pieces.append_array(MotelRoad.build())
	pieces.append_array(MotelFoliage.build())
	return pieces


func _attach_meshes(pieces: Array[MotelPiece]) -> void:
	var palette := MotelMaterials.build_palette()
	var meshes := MotelMeshBuilder.build_meshes_by_material(pieces)
	for material_name: String in meshes.keys():
		var instance := MeshInstance3D.new()
		instance.name = "Mesh_" + material_name
		instance.mesh = meshes[material_name] as ArrayMesh
		if palette.has(material_name):
			instance.material_override = palette[material_name] as Material
		add_child(instance)


func _attach_collisions(pieces: Array[MotelPiece]) -> void:
	var shapes := MotelMeshBuilder.build_collision_shapes(pieces)
	for collision: CollisionShape3D in shapes:
		add_child(collision)


func _add_lights() -> void:
	var warm_color := Color(1.0, 0.84, 0.58)
	var sconce_positions := MotelFacade.sconce_positions()
	for index: int in range(sconce_positions.size()):
		if index % 2 == 0:
			_spawn_omni_light(sconce_positions[index], warm_color, 1.4, 7.5)

	_spawn_omni_light(MotelReception.canopy_light_position(), Color(1.0, 0.94, 0.82), 2.4, 12.0)
	_spawn_omni_light(
		MotelReceptionInterior.lobby_light_position(), Color(1.0, 0.92, 0.78), 2.2, 10.0
	)
	for room_light: Vector3 in MotelRoomInterior.light_positions():
		_spawn_omni_light(room_light, Color(1.0, 0.89, 0.7), 1.6, 8.0)
	for west_light: Vector3 in MotelWestRoomInterior.light_positions():
		_spawn_omni_light(west_light, Color(1.0, 0.89, 0.7), 1.6, 8.0)
	for pole_light: Vector3 in MotelFoliage.pole_light_positions():
		_spawn_omni_light(pole_light, Color(1.0, 0.82, 0.52), 2.6, 18.0)
	for road_light: Vector3 in MotelRoad.pole_light_positions():
		_spawn_omni_light(road_light + Vector3(0.0, 0.0, 0.85), Color(1.0, 0.82, 0.52), 2.8, 20.0)


func _spawn_omni_light(
	light_position: Vector3, light_color: Color, energy: float, light_range: float
) -> void:
	var light := OmniLight3D.new()
	light.position = light_position
	light.light_color = light_color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	add_child(light)


func _add_signs() -> void:
	var roof_center := MotelSigns.rooftop_sign_center()
	_spawn_label(
		"MOTEL", roof_center + Vector3(0.0, 0.0, 0.26), Vector3.ZERO, 180, Color(0.78, 0.1, 0.08)
	)
	_spawn_label(
		"MOTEL",
		roof_center + Vector3(0.0, 0.0, -0.26),
		Vector3(0.0, PI, 0.0),
		180,
		Color(0.78, 0.1, 0.08)
	)

	var road_center := MotelSigns.roadside_sign_center()
	_spawn_label(
		"AMERICAN\nMOTEL",
		road_center + Vector3(0.0, 0.02, 0.17),
		Vector3.ZERO,
		72,
		Color(0.68, 0.12, 0.12)
	)

	var canopy_x := (MotelConstants.RECEPTION_END_X + MotelConstants.CANOPY_END_X) * 0.5
	var canopy_y := (MotelConstants.CANOPY_BOTTOM_Y + MotelConstants.CANOPY_TOP_Y) * 0.5
	var canopy_z := MotelConstants.RECEPTION_FRONT_Z + 0.02
	_spawn_label(
		"WELCOME", Vector3(canopy_x, canopy_y, canopy_z), Vector3.ZERO, 52, Color(0.68, 0.12, 0.12)
	)

	_spawn_label(
		"RECEPCAO",
		MotelReception.office_plaque_position(),
		Vector3.ZERO,
		34,
		Color(0.95, 0.93, 0.85)
	)


func _add_room_plaques() -> void:
	for plaque: Dictionary in MotelFacade.room_plaques():
		var plaque_text := plaque["text"] as String
		var plaque_pos := plaque["position"] as Vector3
		var plaque_rot := plaque["rotation"] as Vector3
		_spawn_label(plaque_text, plaque_pos, plaque_rot, 20, Color(0.96, 0.94, 0.88))


func _add_boundary() -> void:
	var boundary := MotelBoundary.new()
	boundary.name = "Boundary"
	add_child(boundary)


func _spawn_label(
	label_text: String,
	label_position: Vector3,
	label_rotation: Vector3,
	font_size: int,
	text_color: Color
) -> void:
	var label := Label3D.new()
	label.text = label_text
	label.position = label_position
	label.rotation = label_rotation
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = text_color
	label.outline_size = 10
	label.outline_modulate = Color(0.12, 0.05, 0.05)
	label.shaded = false
	add_child(label)
