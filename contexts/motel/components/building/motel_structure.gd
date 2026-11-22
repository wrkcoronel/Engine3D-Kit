class_name MotelStructure
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_corner_blocks(pieces)
	_add_main_wing_rooms(pieces)
	_add_west_wing_rooms(pieces)
	_add_roof(pieces)
	return pieces


static func _add_corner_blocks(pieces: Array[MotelPiece]) -> void:
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(MotelConstants.WEST_WING_OUTER_X, 0.0, MotelConstants.MAIN_WING_BACK_Z),
			Vector3(
				MotelConstants.MAIN_WING_START_X,
				MotelConstants.ROOF_BOTTOM_Y,
				MotelConstants.WEST_WING_START_Z
			),
			"stucco",
			true
		)
	)


static func _add_main_wing_rooms(pieces: Array[MotelPiece]) -> void:
	for story_index: int in range(2):
		for room_index: int in range(MotelConstants.MAIN_ROOM_COUNT):
			var start_x := MotelConstants.main_room_start_x(room_index)
			var end_x := start_x + MotelConstants.ROOM_WIDTH
			if MotelConstants.is_main_room_open(story_index, room_index):
				_add_open_main_room_shell(pieces, start_x, end_x, story_index)
			else:
				_add_closed_main_room(pieces, start_x, end_x, story_index)


static func _add_closed_main_room(
	pieces: Array[MotelPiece], start_x: float, end_x: float, story_index: int
) -> void:
	var floor_y := MotelConstants.story_floor_y(story_index)
	var top_y := floor_y + MotelConstants.STORY_STEP
	if story_index == 1:
		top_y = MotelConstants.ROOF_BOTTOM_Y
	var min_corner := Vector3(start_x, floor_y, MotelConstants.MAIN_WING_BACK_Z)
	var max_corner := Vector3(end_x, top_y, MotelConstants.MAIN_WING_FRONT_Z)
	pieces.append(MotelPiece.from_bounds(min_corner, max_corner, "stucco", true))


static func _add_open_main_room_shell(
	pieces: Array[MotelPiece], start_x: float, end_x: float, story_index: int
) -> void:
	var floor_y := MotelConstants.story_floor_y(story_index)
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT
	var wall := MotelConstants.WALL_THICKNESS
	var back_z := MotelConstants.MAIN_WING_BACK_Z
	var front_z := MotelConstants.MAIN_WING_FRONT_Z

	_add_stucco_box(pieces, start_x, end_x, floor_y, ceiling_y, back_z, back_z + wall)
	if story_index == 0:
		pieces.append(
			MotelPiece.from_bounds(
				Vector3(start_x, ceiling_y, back_z),
				Vector3(end_x, ceiling_y + MotelConstants.SLAB_THICKNESS, front_z),
				"concrete",
				true
			)
		)
	_add_open_main_front_wall(pieces, start_x, end_x, floor_y, ceiling_y)


static func _add_open_main_front_wall(
	pieces: Array[MotelPiece], start_x: float, end_x: float, floor_y: float, ceiling_y: float
) -> void:
	var wall_back_z := MotelConstants.MAIN_WING_FRONT_Z - MotelConstants.WALL_THICKNESS
	var wall_front_z := MotelConstants.MAIN_WING_FRONT_Z
	var door_left_x := start_x + 0.35
	var door_right_x := door_left_x + MotelConstants.DOOR_WIDTH
	var window_left_x := door_right_x + 0.5
	var window_right_x := window_left_x + MotelConstants.WINDOW_WIDTH
	var door_top_y := floor_y + MotelConstants.DOOR_HEIGHT
	var win_bot_y := floor_y + MotelConstants.WINDOW_BOTTOM_Y
	var win_top_y := floor_y + MotelConstants.WINDOW_TOP_Y

	_add_stucco_box(pieces, start_x, door_left_x, floor_y, ceiling_y, wall_back_z, wall_front_z)
	_add_stucco_box(
		pieces, door_left_x, door_right_x, door_top_y, ceiling_y, wall_back_z, wall_front_z
	)
	_add_stucco_box(
		pieces, door_right_x, window_left_x, floor_y, ceiling_y, wall_back_z, wall_front_z
	)
	_add_stucco_box(
		pieces, window_left_x, window_right_x, floor_y, win_bot_y, wall_back_z, wall_front_z
	)
	_add_stucco_box(
		pieces, window_left_x, window_right_x, win_top_y, ceiling_y, wall_back_z, wall_front_z
	)
	_add_stucco_box(pieces, window_right_x, end_x, floor_y, ceiling_y, wall_back_z, wall_front_z)


static func _add_west_wing_rooms(pieces: Array[MotelPiece]) -> void:
	for story_index: int in range(2):
		for room_index: int in range(MotelConstants.WEST_ROOM_COUNT):
			var start_z := MotelConstants.west_room_start_z(room_index)
			var end_z := start_z + MotelConstants.ROOM_WIDTH
			if MotelConstants.is_west_room_open(story_index, room_index):
				_add_open_west_room_shell(pieces, start_z, end_z, story_index)
			else:
				_add_closed_west_room(pieces, start_z, end_z, story_index)


static func _add_closed_west_room(
	pieces: Array[MotelPiece], start_z: float, end_z: float, story_index: int
) -> void:
	var floor_y := MotelConstants.story_floor_y(story_index)
	var top_y := floor_y + MotelConstants.STORY_STEP
	if story_index == 1:
		top_y = MotelConstants.ROOF_BOTTOM_Y
	var min_corner := Vector3(MotelConstants.WEST_WING_OUTER_X, floor_y, start_z)
	var max_corner := Vector3(MotelConstants.WEST_WING_FRONT_X, top_y, end_z)
	pieces.append(MotelPiece.from_bounds(min_corner, max_corner, "stucco", true))


static func _add_open_west_room_shell(
	pieces: Array[MotelPiece], start_z: float, end_z: float, story_index: int
) -> void:
	var floor_y := MotelConstants.story_floor_y(story_index)
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT
	var wall := MotelConstants.WALL_THICKNESS
	var back_x := MotelConstants.WEST_WING_OUTER_X
	var front_x := MotelConstants.WEST_WING_FRONT_X

	_add_stucco_box(pieces, back_x, back_x + wall, floor_y, ceiling_y, start_z, end_z)
	if story_index == 0:
		pieces.append(
			MotelPiece.from_bounds(
				Vector3(back_x, ceiling_y, start_z),
				Vector3(front_x, ceiling_y + MotelConstants.SLAB_THICKNESS, end_z),
				"concrete",
				true
			)
		)
	_add_open_west_front_wall(pieces, start_z, end_z, floor_y, ceiling_y)


static func _add_open_west_front_wall(
	pieces: Array[MotelPiece], start_z: float, end_z: float, floor_y: float, ceiling_y: float
) -> void:
	var wall_back_x := MotelConstants.WEST_WING_FRONT_X - MotelConstants.WALL_THICKNESS
	var wall_front_x := MotelConstants.WEST_WING_FRONT_X
	var door_left_z := start_z + 0.35
	var door_right_z := door_left_z + MotelConstants.DOOR_WIDTH
	var window_left_z := door_right_z + 0.5
	var window_right_z := window_left_z + MotelConstants.WINDOW_WIDTH
	var door_top_y := floor_y + MotelConstants.DOOR_HEIGHT
	var win_bot_y := floor_y + MotelConstants.WINDOW_BOTTOM_Y
	var win_top_y := floor_y + MotelConstants.WINDOW_TOP_Y

	_add_stucco_box(pieces, wall_back_x, wall_front_x, floor_y, ceiling_y, start_z, door_left_z)
	_add_stucco_box(
		pieces, wall_back_x, wall_front_x, door_top_y, ceiling_y, door_left_z, door_right_z
	)
	_add_stucco_box(
		pieces, wall_back_x, wall_front_x, floor_y, ceiling_y, door_right_z, window_left_z
	)
	_add_stucco_box(
		pieces, wall_back_x, wall_front_x, floor_y, win_bot_y, window_left_z, window_right_z
	)
	_add_stucco_box(
		pieces, wall_back_x, wall_front_x, win_top_y, ceiling_y, window_left_z, window_right_z
	)
	_add_stucco_box(pieces, wall_back_x, wall_front_x, floor_y, ceiling_y, window_right_z, end_z)


static func _add_stucco_box(
	pieces: Array[MotelPiece],
	min_x: float,
	max_x: float,
	min_y: float,
	max_y: float,
	min_z: float,
	max_z: float
) -> void:
	var min_corner := Vector3(min_x, min_y, min_z)
	var max_corner := Vector3(max_x, max_y, max_z)
	pieces.append(MotelPiece.from_bounds(min_corner, max_corner, "stucco", true))


static func _add_roof(pieces: Array[MotelPiece]) -> void:
	var roof_min_y := MotelConstants.ROOF_BOTTOM_Y
	var roof_max_y := MotelConstants.ROOF_TOP_Y
	var parapet_y := MotelConstants.PARAPET_TOP_Y
	var west_outer := MotelConstants.WEST_WING_OUTER_X
	var main_back := MotelConstants.MAIN_WING_BACK_Z
	var main_walk := MotelConstants.MAIN_WALKWAY_FRONT_Z
	var west_walk := MotelConstants.WEST_WALKWAY_FRONT_X
	var west_end := MotelConstants.west_wing_end_z()
	var office_end := MotelConstants.RECEPTION_END_X

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_outer - 0.3, roof_min_y, main_back - 0.3),
			Vector3(office_end + 0.3, roof_max_y, main_walk + 0.3),
			"trim",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_outer - 0.3, roof_min_y, main_walk + 0.3),
			Vector3(west_walk + 0.3, roof_max_y, west_end + 0.3),
			"trim",
			true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_outer + 0.2, roof_max_y, main_back + 0.2),
			Vector3(office_end - 0.2, parapet_y, MotelConstants.MAIN_WING_FRONT_Z + 0.4),
			"roof",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(west_outer + 0.2, roof_max_y, MotelConstants.MAIN_WING_FRONT_Z + 0.4),
			Vector3(MotelConstants.WEST_WING_FRONT_X + 0.4, parapet_y, west_end - 0.2),
			"roof",
			false
		)
	)
