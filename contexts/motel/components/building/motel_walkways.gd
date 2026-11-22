class_name MotelWalkways
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_walkways_and_balconies(pieces)
	_add_columns(pieces)
	_add_balcony_railings(pieces)
	_add_exterior_stairs(pieces)
	return pieces


static func _add_walkways_and_balconies(pieces: Array[MotelPiece]) -> void:
	var main_end_x := MotelConstants.main_wing_end_x()
	var west_end_z := MotelConstants.west_wing_end_z()
	var west_walk_x := MotelConstants.WEST_WALKWAY_FRONT_X
	var main_front_z := MotelConstants.MAIN_WING_FRONT_Z
	var main_walk_z := MotelConstants.MAIN_WALKWAY_FRONT_Z

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_walk_x, 0.0, main_front_z),
			Vector3(main_end_x, 0.03, main_walk_z),
			"concrete",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(MotelConstants.WEST_WING_FRONT_X, 0.0, main_front_z),
			Vector3(west_walk_x, 0.03, west_end_z),
			"concrete",
			false
		)
	)

	var balcony_bottom := MotelConstants.FLOOR_HEIGHT
	var balcony_top := MotelConstants.STORY_STEP
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_walk_x, balcony_bottom, main_front_z),
			Vector3(main_end_x, balcony_top, main_walk_z),
			"concrete",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(MotelConstants.WEST_WING_FRONT_X, balcony_bottom, main_front_z),
			Vector3(west_walk_x, balcony_top, west_end_z),
			"concrete",
			true
		)
	)


static func _add_columns(pieces: Array[MotelPiece]) -> void:
	var half_col := MotelConstants.COLUMN_SIZE * 0.5
	var main_col_z := MotelConstants.MAIN_WALKWAY_FRONT_Z - half_col
	var main_xs: Array[float] = [-9.8 + half_col, -7.4, -2.8, 1.8, 6.4, 11.0 - half_col]
	for column_x: float in main_xs:
		_add_single_column(pieces, column_x, main_col_z)

	var west_col_x := MotelConstants.WEST_WALKWAY_FRONT_X - half_col
	var west_zs: Array[float] = [-3.2, 1.4, MotelConstants.west_wing_end_z() - half_col]
	for column_z: float in west_zs:
		_add_single_column(pieces, west_col_x, column_z)


static func _add_single_column(pieces: Array[MotelPiece], column_x: float, column_z: float) -> void:
	var half_col := MotelConstants.COLUMN_SIZE * 0.5
	var min_corner := Vector3(column_x - half_col, 0.0, column_z - half_col)
	var max_corner := Vector3(
		column_x + half_col, MotelConstants.ROOF_BOTTOM_Y, column_z + half_col
	)
	pieces.append(MotelPiece.from_bounds(min_corner, max_corner, "trim", true))


static func _add_balcony_railings(pieces: Array[MotelPiece]) -> void:
	var base_y := MotelConstants.STORY_STEP
	var main_start_x := MotelConstants.WEST_WALKWAY_FRONT_X
	var main_end_x := MotelConstants.main_wing_end_x()
	var main_rail_z := MotelConstants.MAIN_WALKWAY_FRONT_Z - 0.06
	_add_railing_run_x(pieces, main_start_x, main_end_x, main_rail_z, base_y)

	var west_start_z := MotelConstants.MAIN_WALKWAY_FRONT_Z
	var west_end_z := MotelConstants.west_wing_end_z()
	var west_rail_x := MotelConstants.WEST_WALKWAY_FRONT_X - 0.06
	_add_railing_run_z(pieces, west_start_z, west_end_z, west_rail_x, base_y)


static func _add_railing_run_x(
	pieces: Array[MotelPiece], start_x: float, end_x: float, rail_z: float, base_y: float
) -> void:
	var rail_h := MotelConstants.RAILING_HEIGHT
	var length := end_x - start_x
	var mid_x := (start_x + end_x) * 0.5
	var mid_y := base_y + rail_h * 0.5

	pieces.append(
		MotelPiece.new(
			Vector3(mid_x, base_y + rail_h - 0.03, rail_z),
			Vector3(length, 0.06, 0.06),
			"metal_dark",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(mid_x, base_y + 0.12, rail_z), Vector3(length, 0.05, 0.05), "metal_dark", false
		)
	)
	pieces.append(
		MotelPiece.new(Vector3(mid_x, mid_y, rail_z), Vector3(length, rail_h, 0.12), "", true)
	)

	var post_x := start_x
	while post_x <= end_x + 0.01:
		pieces.append(
			MotelPiece.new(
				Vector3(post_x, mid_y, rail_z), Vector3(0.04, rail_h, 0.04), "metal_dark", false
			)
		)
		post_x += 0.6


static func _add_railing_run_z(
	pieces: Array[MotelPiece], start_z: float, end_z: float, rail_x: float, base_y: float
) -> void:
	var rail_h := MotelConstants.RAILING_HEIGHT
	var length := end_z - start_z
	var mid_z := (start_z + end_z) * 0.5
	var mid_y := base_y + rail_h * 0.5

	pieces.append(
		MotelPiece.new(
			Vector3(rail_x, base_y + rail_h - 0.03, mid_z),
			Vector3(0.06, 0.06, length),
			"metal_dark",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(rail_x, base_y + 0.12, mid_z), Vector3(0.05, 0.05, length), "metal_dark", false
		)
	)
	pieces.append(
		MotelPiece.new(Vector3(rail_x, mid_y, mid_z), Vector3(0.12, rail_h, length), "", true)
	)

	var post_z := start_z
	while post_z <= end_z + 0.01:
		pieces.append(
			MotelPiece.new(
				Vector3(rail_x, mid_y, post_z), Vector3(0.04, rail_h, 0.04), "metal_dark", false
			)
		)
		post_z += 0.6


static func _add_exterior_stairs(pieces: Array[MotelPiece]) -> void:
	var stair_min_x := MotelConstants.WEST_WING_FRONT_X
	var stair_max_x := MotelConstants.WEST_WALKWAY_FRONT_X
	var stair_center_x := (stair_min_x + stair_max_x) * 0.5
	var stair_width := stair_max_x - stair_min_x
	var run_length := MotelConstants.STAIR_END_Z - MotelConstants.STAIR_START_Z
	var rise_height := MotelConstants.STORY_STEP
	var step_count := MotelConstants.STAIR_STEP_COUNT
	var step_depth := run_length / float(step_count)
	var step_height := rise_height / float(step_count)

	for step_index: int in range(step_count):
		var z_front := MotelConstants.STAIR_END_Z - float(step_index) * step_depth
		var z_back := z_front - step_depth
		var top_y := float(step_index + 1) * step_height
		var bottom_y := maxf(0.0, top_y - step_height * 1.4)
		pieces.append(
			MotelPiece.from_bounds(
				Vector3(stair_min_x, bottom_y, z_back),
				Vector3(stair_max_x, top_y, z_front),
				"concrete",
				false
			)
		)

	var slope_angle := atan2(rise_height, run_length)
	var ramp_length := sqrt(run_length * run_length + rise_height * rise_height)
	var ramp_thickness := 0.24
	var mid_z := (MotelConstants.STAIR_START_Z + MotelConstants.STAIR_END_Z) * 0.5
	var mid_y := rise_height * 0.5
	var normal_offset_y := -cos(slope_angle) * (ramp_thickness * 0.5)
	var normal_offset_z := -sin(slope_angle) * (ramp_thickness * 0.5)
	var ramp_center := Vector3(stair_center_x, mid_y + normal_offset_y, mid_z + normal_offset_z)
	pieces.append(
		MotelPiece.new(
			ramp_center,
			Vector3(stair_width, ramp_thickness, ramp_length),
			"",
			true,
			Vector3(slope_angle, 0.0, 0.0)
		)
	)

	var rail_center_y := mid_y + MotelConstants.RAILING_HEIGHT * 0.5
	var rail_rotation := Vector3(slope_angle, 0.0, 0.0)
	pieces.append(
		MotelPiece.new(
			Vector3(stair_max_x - 0.06, rail_center_y, mid_z),
			Vector3(0.08, 0.08, ramp_length),
			"metal_dark",
			false,
			rail_rotation
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(stair_min_x + 0.06, rail_center_y, mid_z),
			Vector3(0.08, 0.08, ramp_length),
			"metal_dark",
			false,
			rail_rotation
		)
	)
