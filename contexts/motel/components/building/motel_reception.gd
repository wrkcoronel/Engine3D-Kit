class_name MotelReception
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_upper_story_and_slab(pieces)
	_add_ground_lobby_shell(pieces)
	_add_lobby_door_and_glass(pieces)
	_add_porte_cochere(pieces)
	return pieces


static func canopy_light_position() -> Vector3:
	var mid_x := (MotelConstants.RECEPTION_END_X + MotelConstants.CANOPY_END_X) * 0.5
	var mid_z := (MotelConstants.CANOPY_BACK_Z + MotelConstants.RECEPTION_FRONT_Z) * 0.5
	return Vector3(mid_x, MotelConstants.CANOPY_BOTTOM_Y - 0.25, mid_z)


static func office_plaque_position() -> Vector3:
	var plaque_x := MotelConstants.RECEPTION_START_X + 1.25
	return Vector3(plaque_x, 2.55, MotelConstants.RECEPTION_FRONT_Z + 0.05)


static func _add_upper_story_and_slab(pieces: Array[MotelPiece]) -> void:
	var start_x := MotelConstants.RECEPTION_START_X
	var end_x := MotelConstants.RECEPTION_END_X
	var back_z := MotelConstants.MAIN_WING_BACK_Z
	var front_z := MotelConstants.RECEPTION_FRONT_Z

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x, MotelConstants.FLOOR_HEIGHT, back_z),
			Vector3(end_x, MotelConstants.STORY_STEP, front_z),
			"concrete",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x, MotelConstants.STORY_STEP, back_z),
			Vector3(end_x, MotelConstants.ROOF_BOTTOM_Y, front_z),
			"stucco",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x, 0.0, front_z),
			Vector3(end_x + 0.6, 0.03, MotelConstants.MAIN_WALKWAY_FRONT_Z + 0.4),
			"concrete",
			false
		)
	)


static func _add_ground_lobby_shell(pieces: Array[MotelPiece]) -> void:
	var start_x := MotelConstants.RECEPTION_START_X
	var end_x := MotelConstants.RECEPTION_END_X
	var back_z := MotelConstants.MAIN_WING_BACK_Z
	var front_z := MotelConstants.RECEPTION_FRONT_Z
	var wall := MotelConstants.WALL_THICKNESS
	var ceil_y := MotelConstants.FLOOR_HEIGHT

	_add_stucco_box(pieces, start_x, end_x, 0.0, ceil_y, back_z, back_z + wall)
	_add_stucco_box(
		pieces, start_x, start_x + wall, 0.0, ceil_y, MotelConstants.MAIN_WING_FRONT_Z, front_z
	)

	var door_left_x := start_x + 0.55
	var door_right_x := door_left_x + MotelConstants.RECEPTION_DOOR_WIDTH
	var win_left_x := door_right_x + 0.45
	var win_right_x := end_x - 0.45
	var front_back_z := front_z - wall

	_add_stucco_box(pieces, start_x, door_left_x, 0.0, ceil_y, front_back_z, front_z)
	_add_stucco_box(
		pieces,
		door_left_x,
		door_right_x,
		MotelConstants.RECEPTION_DOOR_HEIGHT,
		ceil_y,
		front_back_z,
		front_z
	)
	_add_stucco_box(pieces, door_right_x, win_left_x, 0.0, ceil_y, front_back_z, front_z)
	_add_stucco_box(pieces, win_left_x, win_right_x, 0.0, 0.72, front_back_z, front_z)
	_add_stucco_box(pieces, win_left_x, win_right_x, 2.45, ceil_y, front_back_z, front_z)
	_add_stucco_box(pieces, win_right_x, end_x, 0.0, ceil_y, front_back_z, front_z)

	var east_in_x := end_x - wall
	var side_back_z := -14.2
	var side_front_z := -10.2
	_add_stucco_box(pieces, east_in_x, end_x, 0.0, ceil_y, back_z + wall, side_back_z)
	_add_stucco_box(pieces, east_in_x, end_x, 0.0, 0.72, side_back_z, side_front_z)
	_add_stucco_box(pieces, east_in_x, end_x, 2.45, ceil_y, side_back_z, side_front_z)
	_add_stucco_box(pieces, east_in_x, end_x, 0.0, ceil_y, side_front_z, front_back_z)


static func _add_lobby_door_and_glass(pieces: Array[MotelPiece]) -> void:
	var start_x := MotelConstants.RECEPTION_START_X
	var end_x := MotelConstants.RECEPTION_END_X
	var front_z := MotelConstants.RECEPTION_FRONT_Z
	var wall := MotelConstants.WALL_THICKNESS
	var door_left_x := start_x + 0.55
	var door_w := MotelConstants.RECEPTION_DOOR_WIDTH
	var door_h := MotelConstants.RECEPTION_DOOR_HEIGHT
	var mid_z := front_z - wall * 0.5

	pieces.append(
		MotelPiece.new(
			Vector3(door_left_x + door_w * 0.5, door_h, mid_z),
			Vector3(door_w + 0.16, 0.08, wall + 0.04),
			"door_frame",
			false
		)
	)
	var open_angle := deg_to_rad(86.0)
	var hinge_x := door_left_x + 0.06
	var hinge_z := front_z - wall - 0.04
	var panel_center := Vector3(
		hinge_x + cos(open_angle) * (door_w * 0.5),
		door_h * 0.5,
		hinge_z - sin(open_angle) * (door_w * 0.5)
	)
	pieces.append(
		MotelPiece.new(
			panel_center,
			Vector3(door_w - 0.1, door_h - 0.06, 0.06),
			"door_frame",
			true,
			Vector3(0.0, open_angle, 0.0)
		)
	)

	var win_left_x := door_left_x + door_w + 0.45
	var win_right_x := end_x - 0.45
	var win_w := win_right_x - win_left_x
	var win_cx := (win_left_x + win_right_x) * 0.5
	pieces.append(
		MotelPiece.new(
			Vector3(win_cx, 1.585, mid_z), Vector3(win_w, 1.73, 0.04), "glass_clear", true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(win_cx, 1.585, mid_z), Vector3(0.06, 1.73, 0.08), "door_frame", false
		)
	)

	var east_mid_x := end_x - wall * 0.5
	pieces.append(
		MotelPiece.new(
			Vector3(east_mid_x, 1.585, -12.2), Vector3(0.04, 1.73, 4.0), "glass_clear", true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(east_mid_x, 1.585, -12.2), Vector3(0.08, 1.73, 0.06), "door_frame", false
		)
	)


static func _add_porte_cochere(pieces: Array[MotelPiece]) -> void:
	var start_x := MotelConstants.RECEPTION_END_X
	var end_x := MotelConstants.CANOPY_END_X
	var back_z := MotelConstants.CANOPY_BACK_Z
	var front_z := MotelConstants.RECEPTION_FRONT_Z
	var bottom_y := MotelConstants.CANOPY_BOTTOM_Y
	var top_y := MotelConstants.CANOPY_TOP_Y

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x, bottom_y, back_z), Vector3(end_x, top_y, front_z), "trim", true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x, top_y, back_z + 0.1),
			Vector3(end_x - 0.1, top_y + 0.18, front_z - 0.1),
			"sign_red",
			false
		)
	)

	var column_x := end_x - 0.35
	for column_z: float in [back_z + 0.35, front_z - 0.35]:
		pieces.append(
			MotelPiece.from_bounds(
				Vector3(column_x - 0.28, 0.0, column_z - 0.28),
				Vector3(column_x + 0.28, bottom_y, column_z + 0.28),
				"trim",
				true
			)
		)


static func _add_stucco_box(
	pieces: Array[MotelPiece],
	min_x: float,
	max_x: float,
	min_y: float,
	max_y: float,
	min_z: float,
	max_z: float
) -> void:
	pieces.append(
		MotelPiece.from_bounds(Vector3(min_x, min_y, min_z), Vector3(max_x, max_y, max_z), "stucco")
	)
