class_name MotelReceptionInterior
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_lobby_finishes(pieces)
	_add_front_desk_and_key_rack(pieces)
	_add_waiting_area(pieces)
	return pieces


static func lobby_light_position() -> Vector3:
	var mid_x := (MotelConstants.RECEPTION_START_X + MotelConstants.RECEPTION_END_X) * 0.5
	var mid_z := (MotelConstants.MAIN_WING_BACK_Z + MotelConstants.RECEPTION_FRONT_Z) * 0.5
	return Vector3(mid_x, MotelConstants.FLOOR_HEIGHT - 0.35, mid_z)


static func _add_lobby_finishes(pieces: Array[MotelPiece]) -> void:
	var wall := MotelConstants.WALL_THICKNESS
	var min_x := MotelConstants.RECEPTION_START_X + 0.04
	var max_x := MotelConstants.RECEPTION_END_X - wall
	var min_z := MotelConstants.MAIN_WING_BACK_Z + wall
	var max_z := MotelConstants.RECEPTION_FRONT_Z - wall
	var ceil_y := MotelConstants.FLOOR_HEIGHT

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, 0.0, min_z), Vector3(max_x, 0.025, max_z), "tile_floor", false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, ceil_y - 0.04, min_z), Vector3(max_x, ceil_y, max_z), "ceiling", false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, 0.0, min_z), Vector3(max_x, ceil_y, min_z + 0.05), "interior_wall", false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, 0.0, min_z), Vector3(min_x + 0.05, ceil_y, max_z), "interior_wall", false
		)
	)


static func _add_front_desk_and_key_rack(pieces: Array[MotelPiece]) -> void:
	var start_x := MotelConstants.RECEPTION_START_X
	var desk_z := -13.6
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x + 1.2, 0.0, desk_z - 0.65),
			Vector3(start_x + 4.0, 1.0, desk_z),
			"wood_dark",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x + 1.15, 1.0, desk_z - 0.72),
			Vector3(start_x + 4.08, 1.08, desk_z + 0.06),
			"porcelain",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x + 3.45, 0.0, -15.4),
			Vector3(start_x + 4.0, 1.0, desk_z - 0.65),
			"wood_dark",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(start_x + 3.4, 1.0, -15.45),
			Vector3(start_x + 4.08, 1.08, desk_z - 0.65),
			"porcelain",
			false
		)
	)

	pieces.append(
		MotelPiece.new(
			Vector3(start_x + 2.2, 1.32, desk_z - 0.35),
			Vector3(0.46, 0.36, 0.08),
			"tv_screen",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(start_x + 2.2, 1.12, desk_z - 0.35),
			Vector3(0.18, 0.08, 0.18),
			"metal_dark",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(start_x + 2.5, 0.45, -14.85), Vector3(0.55, 0.9, 0.55), "armchair", true
		)
	)

	var back_z := MotelConstants.MAIN_WING_BACK_Z + MotelConstants.WALL_THICKNESS + 0.08
	pieces.append(
		MotelPiece.new(
			Vector3(start_x + 2.5, 1.65, back_z), Vector3(1.6, 0.9, 0.06), "wood_dark", false
		)
	)
	for slot_index: int in range(6):
		var slot_x := start_x + 1.9 + float(slot_index) * 0.24
		pieces.append(
			MotelPiece.new(
				Vector3(slot_x, 1.65, back_z + 0.05),
				Vector3(0.06, 0.08, 0.05),
				"sign_yellow",
				false
			)
		)


static func _add_waiting_area(pieces: Array[MotelPiece]) -> void:
	var east_x := MotelConstants.RECEPTION_END_X - MotelConstants.WALL_THICKNESS - 0.45
	_add_sofa(pieces, Vector3(east_x, 0.0, -11.3), true)
	pieces.append(
		MotelPiece.new(
			Vector3(east_x - 1.15, 0.24, -11.3), Vector3(0.65, 0.42, 1.15), "wood_dark", true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(MotelConstants.RECEPTION_START_X + 0.45, 0.52, -11.2),
			Vector3(0.5, 1.04, 0.5),
			"porcelain",
			true
		)
	)


static func _add_sofa(pieces: Array[MotelPiece], center: Vector3, faces_west: bool) -> void:
	var back_offset := 0.32
	if not faces_west:
		back_offset = -0.32
	pieces.append(
		MotelPiece.new(center + Vector3(0.0, 0.24, 0.0), Vector3(0.8, 0.44, 1.85), "armchair", true)
	)
	pieces.append(
		MotelPiece.new(
			center + Vector3(back_offset, 0.62, 0.0), Vector3(0.18, 0.52, 1.85), "armchair", true
		)
	)
	pieces.append(
		MotelPiece.new(
			center + Vector3(0.0, 0.42, -0.9), Vector3(0.8, 0.36, 0.12), "wood_dark", false
		)
	)
	pieces.append(
		MotelPiece.new(
			center + Vector3(0.0, 0.42, 0.9), Vector3(0.8, 0.36, 0.12), "wood_dark", false
		)
	)
