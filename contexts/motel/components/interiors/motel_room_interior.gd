class_name MotelRoomInterior
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_build_double_room(pieces, 0, false)
	_build_double_room(pieces, 1, true)
	return pieces


static func light_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var start_x := MotelConstants.main_room_start_x(MotelConstants.OPEN_ROOM_INDEX)
	var center_x := start_x + MotelConstants.ROOM_WIDTH * 0.5
	for story_index: int in range(2):
		var floor_y := MotelConstants.story_floor_y(story_index)
		positions.append(Vector3(center_x, floor_y + MotelConstants.FLOOR_HEIGHT - 0.35, -12.6))
		positions.append(Vector3(start_x + 1.55, floor_y + 2.35, -15.5))
	return positions


static func _build_double_room(
	pieces: Array[MotelPiece], story_index: int, has_minifridge: bool
) -> void:
	var start_x := MotelConstants.main_room_start_x(MotelConstants.OPEN_ROOM_INDEX)
	var end_x := start_x + MotelConstants.ROOM_WIDTH
	var floor_y := MotelConstants.story_floor_y(story_index)
	_add_interior_finishes(pieces, start_x, end_x, floor_y)
	_add_beds_and_nightstand(pieces, end_x, floor_y)
	_add_desk_tv_and_armchair(pieces, start_x, floor_y, has_minifridge)
	_add_vanity_and_bathroom(pieces, start_x, end_x, floor_y)


static func _add_interior_finishes(
	pieces: Array[MotelPiece], start_x: float, end_x: float, floor_y: float
) -> void:
	var wall := MotelConstants.WALL_THICKNESS
	var inner_back_z := MotelConstants.MAIN_WING_BACK_Z + wall
	var inner_front_z := MotelConstants.MAIN_WING_FRONT_Z - wall
	var divider_z := -14.85
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT

	_add_bounds(
		pieces,
		Vector3(start_x + 0.02, floor_y, divider_z),
		Vector3(end_x - 0.02, floor_y + 0.02, inner_front_z),
		"carpet",
		false
	)
	_add_bounds(
		pieces,
		Vector3(start_x + 0.02, floor_y, inner_back_z),
		Vector3(end_x - 0.02, floor_y + 0.02, divider_z),
		"tile_floor",
		false
	)
	_add_bounds(
		pieces,
		Vector3(start_x + 0.02, ceiling_y - 0.04, inner_back_z),
		Vector3(end_x - 0.02, ceiling_y, inner_front_z),
		"ceiling",
		false
	)
	_add_bounds(
		pieces,
		Vector3(start_x, floor_y, inner_back_z),
		Vector3(start_x + 0.05, ceiling_y, inner_front_z),
		"interior_wall",
		false
	)
	_add_bounds(
		pieces,
		Vector3(end_x - 0.05, floor_y, inner_back_z),
		Vector3(end_x, ceiling_y, inner_front_z),
		"interior_wall",
		false
	)
	_add_bounds(
		pieces,
		Vector3(start_x + 0.05, floor_y, inner_back_z),
		Vector3(end_x - 0.05, ceiling_y, inner_back_z + 0.05),
		"interior_wall",
		false
	)


static func _add_beds_and_nightstand(
	pieces: Array[MotelPiece], end_x: float, floor_y: float
) -> void:
	var east_wall_x := end_x - 0.06
	_add_single_bed(pieces, east_wall_x, -11.75, floor_y)
	_add_single_bed(pieces, east_wall_x, -13.95, floor_y)

	var stand_x := east_wall_x - 0.3
	_add_box(pieces, Vector3(stand_x, floor_y + 0.3, -12.85), Vector3(0.55, 0.6, 0.55), "wood_dark")
	_add_box(
		pieces, Vector3(stand_x, floor_y + 0.72, -12.85), Vector3(0.18, 0.24, 0.18), "trim", false
	)
	_add_box(
		pieces,
		Vector3(stand_x, floor_y + 0.92, -12.85),
		Vector3(0.28, 0.22, 0.28),
		"sconce_glow",
		false
	)


static func _add_single_bed(
	pieces: Array[MotelPiece], east_wall_x: float, bed_center_z: float, floor_y: float
) -> void:
	var bed_length := 2.0
	var bed_width := 1.4
	var bed_center_x := east_wall_x - bed_length * 0.5 - 0.08

	_add_box(
		pieces,
		Vector3(east_wall_x - 0.04, floor_y + 0.62, bed_center_z),
		Vector3(0.08, 1.24, bed_width + 0.08),
		"wood_dark"
	)
	_add_box(
		pieces,
		Vector3(bed_center_x, floor_y + 0.28, bed_center_z),
		Vector3(bed_length, 0.56, bed_width),
		"bedspread"
	)
	_add_box(
		pieces,
		Vector3(east_wall_x - 0.32, floor_y + 0.64, bed_center_z - 0.32),
		Vector3(0.4, 0.18, 0.56),
		"pillow",
		false
	)
	_add_box(
		pieces,
		Vector3(east_wall_x - 0.32, floor_y + 0.64, bed_center_z + 0.32),
		Vector3(0.4, 0.18, 0.56),
		"pillow",
		false
	)


static func _add_desk_tv_and_armchair(
	pieces: Array[MotelPiece], start_x: float, floor_y: float, has_minifridge: bool
) -> void:
	var west_wall_x := start_x + 0.06
	_add_box(
		pieces,
		Vector3(west_wall_x + 0.28, floor_y + 0.39, -12.55),
		Vector3(0.54, 0.78, 1.5),
		"wood_dark"
	)
	_add_box(
		pieces,
		Vector3(west_wall_x + 0.04, floor_y + 1.65, -12.55),
		Vector3(0.06, 0.68, 1.15),
		"tv_screen",
		false
	)
	if has_minifridge:
		_add_box(
			pieces,
			Vector3(west_wall_x + 0.3, floor_y + 0.42, -11.45),
			Vector3(0.54, 0.84, 0.54),
			"porcelain"
		)

	var chair_x := west_wall_x + 0.5
	var chair_z := -14.1
	_add_box(
		pieces, Vector3(chair_x, floor_y + 0.24, chair_z), Vector3(0.68, 0.44, 0.68), "armchair"
	)
	_add_box(
		pieces,
		Vector3(chair_x - 0.26, floor_y + 0.62, chair_z),
		Vector3(0.16, 0.54, 0.68),
		"armchair"
	)
	_add_box(
		pieces,
		Vector3(chair_x, floor_y + 0.48, chair_z - 0.34),
		Vector3(0.68, 0.14, 0.08),
		"wood_dark",
		false
	)
	_add_box(
		pieces,
		Vector3(chair_x, floor_y + 0.48, chair_z + 0.34),
		Vector3(0.68, 0.14, 0.08),
		"wood_dark",
		false
	)


static func _add_vanity_and_bathroom(
	pieces: Array[MotelPiece], start_x: float, end_x: float, floor_y: float
) -> void:
	var divider_z := -14.85
	var arch_left_x := start_x + 0.95
	var arch_right_x := arch_left_x + 1.25
	var ceiling_y := floor_y + MotelConstants.FLOOR_HEIGHT

	_add_bounds(
		pieces,
		Vector3(start_x + 0.05, floor_y, divider_z - 0.12),
		Vector3(arch_left_x, ceiling_y, divider_z),
		"interior_wall",
		true
	)
	_add_bounds(
		pieces,
		Vector3(arch_left_x, floor_y + MotelConstants.DOOR_HEIGHT, divider_z - 0.12),
		Vector3(arch_right_x, ceiling_y, divider_z),
		"interior_wall",
		true
	)
	_add_bounds(
		pieces,
		Vector3(arch_right_x, floor_y, divider_z - 0.12),
		Vector3(end_x - 0.05, ceiling_y, divider_z),
		"interior_wall",
		true
	)

	var vanity_x := start_x + 1.15
	var back_wall_z := MotelConstants.MAIN_WING_BACK_Z + MotelConstants.WALL_THICKNESS + 0.05
	_add_box(
		pieces,
		Vector3(vanity_x, floor_y + 0.42, back_wall_z + 0.28),
		Vector3(1.15, 0.84, 0.54),
		"wood_dark"
	)
	_add_box(
		pieces,
		Vector3(vanity_x, floor_y + 0.86, back_wall_z + 0.28),
		Vector3(1.2, 0.06, 0.58),
		"porcelain",
		false
	)
	_add_box(
		pieces,
		Vector3(vanity_x, floor_y + 1.58, back_wall_z + 0.03),
		Vector3(1.1, 0.95, 0.05),
		"mirror",
		false
	)

	var bath_wall_x := start_x + 2.45
	_add_bounds(
		pieces,
		Vector3(bath_wall_x, floor_y, back_wall_z),
		Vector3(bath_wall_x + 0.12, ceiling_y, divider_z - 0.9),
		"interior_wall",
		true
	)
	_add_box(
		pieces,
		Vector3(bath_wall_x + 0.45, floor_y + 0.24, back_wall_z + 0.3),
		Vector3(0.42, 0.48, 0.56),
		"porcelain"
	)
	_add_box(
		pieces,
		Vector3(end_x - 0.5, floor_y + 0.26, back_wall_z + 0.6),
		Vector3(0.75, 0.52, 1.15),
		"porcelain"
	)


static func _add_box(
	pieces: Array[MotelPiece],
	center: Vector3,
	size: Vector3,
	material_name: String,
	is_solid: bool = true
) -> void:
	pieces.append(MotelPiece.new(center, size, material_name, is_solid))


static func _add_bounds(
	pieces: Array[MotelPiece],
	min_corner: Vector3,
	max_corner: Vector3,
	material_name: String,
	is_solid: bool
) -> void:
	pieces.append(MotelPiece.from_bounds(min_corner, max_corner, material_name, is_solid))
