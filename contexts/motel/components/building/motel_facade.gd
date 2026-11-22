class_name MotelFacade
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	for story_index: int in range(2):
		var floor_y := MotelConstants.story_floor_y(story_index)
		_add_main_wing_facades(pieces, story_index, floor_y)
		_add_west_wing_facades(pieces, story_index, floor_y)
	return pieces


static func sconce_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for story_index: int in range(2):
		var light_y := MotelConstants.story_floor_y(story_index) + 2.35
		for room_index: int in range(MotelConstants.MAIN_ROOM_COUNT):
			var start_x := MotelConstants.main_room_start_x(room_index)
			positions.append(
				Vector3(start_x + 1.85, light_y, MotelConstants.MAIN_WING_FRONT_Z + 0.28)
			)
		for room_index: int in range(MotelConstants.WEST_ROOM_COUNT):
			var start_z := MotelConstants.west_room_start_z(room_index)
			positions.append(
				Vector3(MotelConstants.WEST_WING_FRONT_X + 0.28, light_y, start_z + 1.85)
			)
	return positions


static func room_plaques() -> Array[Dictionary]:
	var plaques: Array[Dictionary] = []
	for story_index: int in range(2):
		var plaque_y := MotelConstants.story_floor_y(story_index) + 1.82
		for room_index: int in range(MotelConstants.MAIN_ROOM_COUNT):
			var start_x := MotelConstants.main_room_start_x(room_index)
			plaques.append(
				{
					"text": MotelConstants.main_room_number(story_index, room_index),
					"position":
					Vector3(start_x + 1.85, plaque_y, MotelConstants.MAIN_WING_FRONT_Z + 0.05),
					"rotation": Vector3.ZERO
				}
			)
		for room_index: int in range(MotelConstants.WEST_ROOM_COUNT):
			var start_z := MotelConstants.west_room_start_z(room_index)
			plaques.append(
				{
					"text": MotelConstants.west_room_number(story_index, room_index),
					"position":
					Vector3(MotelConstants.WEST_WING_FRONT_X + 0.05, plaque_y, start_z + 1.85),
					"rotation": Vector3(0.0, PI * 0.5, 0.0)
				}
			)
	return plaques


static func _add_main_wing_facades(
	pieces: Array[MotelPiece], story_index: int, floor_y: float
) -> void:
	for room_index: int in range(MotelConstants.MAIN_ROOM_COUNT):
		var start_x := MotelConstants.main_room_start_x(room_index)
		var origin := Vector3(start_x, floor_y, MotelConstants.MAIN_WING_FRONT_Z)
		var is_open := MotelConstants.is_main_room_open(story_index, room_index)
		_add_bay(pieces, origin, Vector3.RIGHT, Vector3.BACK, is_open, false)


static func _add_west_wing_facades(
	pieces: Array[MotelPiece], story_index: int, floor_y: float
) -> void:
	for room_index: int in range(MotelConstants.WEST_ROOM_COUNT):
		var start_z := MotelConstants.west_room_start_z(room_index)
		var origin := Vector3(MotelConstants.WEST_WING_FRONT_X, floor_y, start_z)
		var is_open := MotelConstants.is_west_room_open(story_index, room_index)
		_add_bay(pieces, origin, Vector3.BACK, Vector3.RIGHT, is_open, true)


static func _add_bay(
	pieces: Array[MotelPiece],
	origin: Vector3,
	along: Vector3,
	outward: Vector3,
	is_open: bool,
	is_west: bool
) -> void:
	var door_left := 0.35
	var door_center := door_left + MotelConstants.DOOR_WIDTH * 0.5
	var window_center := (
		door_left + MotelConstants.DOOR_WIDTH + 0.5 + MotelConstants.WINDOW_WIDTH * 0.5
	)

	if is_open:
		_add_open_bay(pieces, origin, along, outward, door_left, window_center, is_west)
	else:
		_add_closed_bay(pieces, origin, along, outward, door_center, window_center, is_west)

	_add_ac_and_fixtures(pieces, origin, along, outward, window_center, is_west)


static func _add_closed_bay(
	pieces: Array[MotelPiece],
	origin: Vector3,
	along: Vector3,
	outward: Vector3,
	door_center: float,
	window_center: float,
	is_west: bool
) -> void:
	var door_h := MotelConstants.DOOR_HEIGHT
	var door_w := MotelConstants.DOOR_WIDTH
	var door_pos := origin + along * door_center + Vector3(0.0, door_h * 0.5, 0.0)
	pieces.append(
		MotelPiece.new(
			door_pos + outward * 0.02,
			_oriented_size(door_w + 0.14, door_h + 0.08, 0.06, is_west),
			"door_frame",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			door_pos + outward * 0.045,
			_oriented_size(door_w, door_h, 0.04, is_west),
			"door_red",
			false
		)
	)

	var win_h := MotelConstants.WINDOW_TOP_Y - MotelConstants.WINDOW_BOTTOM_Y
	var win_mid_y := MotelConstants.WINDOW_BOTTOM_Y + win_h * 0.5
	var win_w := MotelConstants.WINDOW_WIDTH
	var win_pos := origin + along * window_center + Vector3(0.0, win_mid_y, 0.0)
	pieces.append(
		MotelPiece.new(
			win_pos + outward * 0.02,
			_oriented_size(win_w + 0.14, win_h + 0.14, 0.06, is_west),
			"door_frame",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			win_pos + outward * 0.045,
			_oriented_size(win_w, win_h, 0.04, is_west),
			"glass_dark",
			false
		)
	)


static func _add_open_bay(
	pieces: Array[MotelPiece],
	origin: Vector3,
	along: Vector3,
	outward: Vector3,
	door_left: float,
	window_center: float,
	is_west: bool
) -> void:
	var door_h := MotelConstants.DOOR_HEIGHT
	var door_w := MotelConstants.DOOR_WIDTH
	var wall_t := MotelConstants.WALL_THICKNESS
	var mid_out := -outward * (wall_t * 0.5)

	pieces.append(
		MotelPiece.new(
			origin + along * door_left + mid_out + Vector3(0.0, door_h * 0.5, 0.0),
			_oriented_size(0.08, door_h, wall_t + 0.04, is_west),
			"door_frame",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			origin + along * (door_left + door_w) + mid_out + Vector3(0.0, door_h * 0.5, 0.0),
			_oriented_size(0.08, door_h, wall_t + 0.04, is_west),
			"door_frame",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			origin + along * (door_left + door_w * 0.5) + mid_out + Vector3(0.0, door_h, 0.0),
			_oriented_size(door_w + 0.16, 0.08, wall_t + 0.04, is_west),
			"door_frame",
			false
		)
	)

	var angle_rad := deg_to_rad(86.0)
	var yaw := angle_rad
	if is_west:
		yaw = -angle_rad
	var hinge_pos := origin + along * (door_left + 0.06) - outward * (wall_t + 0.04)
	var half_door := door_w * 0.5
	var door_center := (
		hinge_pos
		+ along * (cos(angle_rad) * half_door)
		- outward * (sin(angle_rad) * half_door)
		+ Vector3(0.0, door_h * 0.5, 0.0)
	)
	pieces.append(
		MotelPiece.new(
			door_center,
			_oriented_size(door_w - 0.08, door_h - 0.04, 0.06, is_west),
			"door_red",
			true,
			Vector3(0.0, yaw, 0.0)
		)
	)

	var win_h := MotelConstants.WINDOW_TOP_Y - MotelConstants.WINDOW_BOTTOM_Y
	var win_mid_y := MotelConstants.WINDOW_BOTTOM_Y + win_h * 0.5
	var win_w := MotelConstants.WINDOW_WIDTH
	var win_pos := origin + along * window_center + mid_out + Vector3(0.0, win_mid_y, 0.0)
	pieces.append(
		MotelPiece.new(win_pos, _oriented_size(win_w, win_h, 0.04, is_west), "glass_clear", true)
	)
	pieces.append(
		MotelPiece.new(win_pos, _oriented_size(0.06, win_h, 0.08, is_west), "door_frame", false)
	)


static func _add_ac_and_fixtures(
	pieces: Array[MotelPiece],
	origin: Vector3,
	along: Vector3,
	outward: Vector3,
	window_center: float,
	is_west: bool
) -> void:
	var ac_pos := origin + along * window_center + Vector3(0.0, 0.5, 0.0)
	pieces.append(
		MotelPiece.new(
			ac_pos + outward * 0.14, _oriented_size(0.95, 0.45, 0.28, is_west), "ac_unit", false
		)
	)
	pieces.append(
		MotelPiece.new(
			ac_pos + outward * 0.29, _oriented_size(0.78, 0.3, 0.03, is_west), "ac_grille", false
		)
	)
	pieces.append(
		MotelPiece.new(
			origin + along * 1.85 + outward * 0.08 + Vector3(0.0, 2.35, 0.0),
			Vector3(0.16, 0.22, 0.16),
			"sconce_glow",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			origin + along * 1.85 + outward * 0.02 + Vector3(0.0, 1.82, 0.0),
			_oriented_size(0.28, 0.16, 0.03, is_west),
			"door_frame",
			false
		)
	)


static func _oriented_size(along_len: float, height: float, depth: float, is_west: bool) -> Vector3:
	if is_west:
		return Vector3(depth, height, along_len)
	return Vector3(along_len, height, depth)
