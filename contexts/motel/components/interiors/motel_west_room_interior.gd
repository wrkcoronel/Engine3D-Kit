class_name MotelWestRoomInterior
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_build_queen_room(pieces, 0, false)
	_build_queen_room(pieces, 1, true)
	return pieces


static func light_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var start_z := MotelConstants.west_room_start_z(MotelConstants.OPEN_WEST_ROOM_INDEX)
	var center_z := start_z + MotelConstants.ROOM_WIDTH * 0.5
	for story_index: int in range(2):
		var floor_y := MotelConstants.story_floor_y(story_index)
		positions.append(Vector3(-14.6, floor_y + MotelConstants.FLOOR_HEIGHT - 0.35, center_z))
		positions.append(Vector3(-17.4, floor_y + 2.35, start_z + 1.55))
	return positions


static func _build_queen_room(pieces: Array[MotelPiece], story_index: int, has_sofa: bool) -> void:
	var start_z := MotelConstants.west_room_start_z(MotelConstants.OPEN_WEST_ROOM_INDEX)
	var end_z := start_z + MotelConstants.ROOM_WIDTH
	var floor_y := MotelConstants.story_floor_y(story_index)
	_add_finishes(pieces, start_z, end_z, floor_y)
	_add_queen_bed_and_stands(pieces, end_z, floor_y)
	_add_tv_and_seating(pieces, start_z, end_z, floor_y, has_sofa)
	_add_west_vanity_and_bath(pieces, start_z, end_z, floor_y)


static func _add_finishes(
	pieces: Array[MotelPiece], start_z: float, end_z: float, floor_y: float
) -> void:
	var wall := MotelConstants.WALL_THICKNESS
	var inner_back_x := MotelConstants.WEST_WING_OUTER_X + wall
	var inner_front_x := MotelConstants.WEST_WING_FRONT_X - wall
	var divider_x := -16.85
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(divider_x, floor_y, start_z + 0.02),
			Vector3(inner_front_x, floor_y + 0.02, end_z - 0.02),
			"carpet",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(inner_back_x, floor_y, start_z + 0.02),
			Vector3(divider_x, floor_y + 0.02, end_z - 0.02),
			"tile_floor",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(inner_back_x, ceiling_y - 0.04, start_z + 0.02),
			Vector3(inner_front_x, ceiling_y, end_z - 0.02),
			"ceiling",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(inner_back_x, floor_y, start_z),
			Vector3(inner_front_x, ceiling_y, start_z + 0.05),
			"interior_wall",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(inner_back_x, floor_y, end_z - 0.05),
			Vector3(inner_front_x, ceiling_y, end_z),
			"interior_wall",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(inner_back_x, floor_y, start_z + 0.05),
			Vector3(inner_back_x + 0.05, ceiling_y, end_z - 0.05),
			"interior_wall",
			false
		)
	)


static func _add_queen_bed_and_stands(
	pieces: Array[MotelPiece], end_z: float, floor_y: float
) -> void:
	var south_wall_z := end_z - 0.06
	var bed_x := -15.1
	var bed_w := 1.85
	var bed_len := 2.05
	var bed_z := south_wall_z - bed_len * 0.5 - 0.08

	pieces.append(
		MotelPiece.new(
			Vector3(bed_x, floor_y + 0.62, south_wall_z - 0.04),
			Vector3(bed_w + 0.1, 1.24, 0.08),
			"wood_dark",
			true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(bed_x, floor_y + 0.28, bed_z), Vector3(bed_w, 0.56, bed_len), "bedspread", true
		)
	)
	for pillow_dx: float in [-0.45, 0.45]:
		pieces.append(
			MotelPiece.new(
				Vector3(bed_x + pillow_dx, floor_y + 0.64, south_wall_z - 0.34),
				Vector3(0.68, 0.18, 0.42),
				"pillow",
				false
			)
		)

	for side_dx: float in [-1.25, 1.25]:
		var stand_x := bed_x + side_dx
		var stand_z := south_wall_z - 0.3
		pieces.append(
			MotelPiece.new(
				Vector3(stand_x, floor_y + 0.3, stand_z), Vector3(0.5, 0.6, 0.5), "wood_dark", true
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(stand_x, floor_y + 0.78, stand_z),
				Vector3(0.24, 0.28, 0.24),
				"sconce_glow",
				false
			)
		)


static func _add_tv_and_seating(
	pieces: Array[MotelPiece], start_z: float, end_z: float, floor_y: float, has_sofa: bool
) -> void:
	var north_wall_z := start_z + 0.06
	pieces.append(
		MotelPiece.new(
			Vector3(-15.1, floor_y + 0.39, north_wall_z + 0.28),
			Vector3(1.5, 0.78, 0.54),
			"wood_dark",
			true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(-15.1, floor_y + 1.65, north_wall_z + 0.04),
			Vector3(1.15, 0.68, 0.06),
			"tv_screen",
			false
		)
	)

	var nook_x := -13.0
	var nook_z := end_z - 0.9
	if has_sofa:
		pieces.append(
			MotelPiece.new(
				Vector3(nook_x, floor_y + 0.24, nook_z), Vector3(0.75, 0.44, 1.4), "armchair", true
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(nook_x + 0.3, floor_y + 0.62, nook_z),
				Vector3(0.16, 0.54, 1.4),
				"armchair",
				true
			)
		)
		return

	pieces.append(
		MotelPiece.new(
			Vector3(nook_x, floor_y + 0.72, nook_z), Vector3(0.78, 0.06, 0.78), "wood_dark", true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(nook_x, floor_y + 0.36, nook_z), Vector3(0.12, 0.72, 0.12), "metal_dark", true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(nook_x, floor_y + 0.24, nook_z - 0.72),
			Vector3(0.46, 0.46, 0.46),
			"armchair",
			true
		)
	)


static func _add_west_vanity_and_bath(
	pieces: Array[MotelPiece], start_z: float, end_z: float, floor_y: float
) -> void:
	var divider_x := -16.85
	var arch_left_z := start_z + 0.95
	var arch_right_z := arch_left_z + 1.25
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(divider_x - 0.12, floor_y, start_z + 0.05),
			Vector3(divider_x, ceiling_y, arch_left_z),
			"interior_wall",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(divider_x - 0.12, floor_y + MotelConstants.DOOR_HEIGHT, arch_left_z),
			Vector3(divider_x, ceiling_y, arch_right_z),
			"interior_wall",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(divider_x - 0.12, floor_y, arch_right_z),
			Vector3(divider_x, ceiling_y, end_z - 0.05),
			"interior_wall",
			true
		)
	)

	var vanity_z := start_z + 1.15
	var back_wall_x := MotelConstants.WEST_WING_OUTER_X + MotelConstants.WALL_THICKNESS + 0.05
	pieces.append(
		MotelPiece.new(
			Vector3(back_wall_x + 0.28, floor_y + 0.42, vanity_z),
			Vector3(0.54, 0.84, 1.15),
			"wood_dark",
			true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(back_wall_x + 0.28, floor_y + 0.86, vanity_z),
			Vector3(0.58, 0.06, 1.2),
			"porcelain",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(back_wall_x + 0.03, floor_y + 1.58, vanity_z),
			Vector3(0.05, 0.95, 1.1),
			"mirror",
			false
		)
	)

	var bath_wall_z := start_z + 2.45
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(back_wall_x, floor_y, bath_wall_z),
			Vector3(divider_x - 0.9, ceiling_y, bath_wall_z + 0.12),
			"interior_wall",
			true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(back_wall_x + 0.3, floor_y + 0.24, bath_wall_z + 0.45),
			Vector3(0.56, 0.48, 0.42),
			"porcelain",
			true
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(back_wall_x + 0.6, floor_y + 0.26, end_z - 0.5),
			Vector3(1.15, 0.52, 0.75),
			"porcelain",
			true
		)
	)
