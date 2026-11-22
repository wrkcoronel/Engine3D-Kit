class_name MotelLot
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_asphalt_lot(pieces)
	_add_parking_lines(pieces)
	_add_curbs(pieces)
	_add_courtyard_pool(pieces)
	_add_pool_fence(pieces)
	_add_pool_loungers(pieces)
	return pieces


static func _add_asphalt_lot(pieces: Array[MotelPiece]) -> void:
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(MotelConstants.LOT_MIN_X, 0.0, MotelConstants.LOT_MIN_Z),
			Vector3(MotelConstants.LOT_MAX_X, 0.015, MotelConstants.LOT_MAX_Z),
			"asphalt",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(MotelConstants.RECEPTION_END_X, 0.0, MotelConstants.CANOPY_BACK_Z - 1.5),
			Vector3(MotelConstants.LOT_MAX_X, 0.015, MotelConstants.LOT_MIN_Z),
			"asphalt",
			false
		)
	)


static func _add_parking_lines(pieces: Array[MotelPiece]) -> void:
	for stall_index: int in range(6):
		var line_x := -7.6 + float(stall_index) * 3.2
		pieces.append(
			MotelPiece.new(
				Vector3(line_x, 0.02, -5.2), Vector3(0.12, 0.01, 4.6), "paint_white", false
			)
		)

	for stall_index: int in range(5):
		var line_z := -5.8 + float(stall_index) * 3.1
		pieces.append(
			MotelPiece.new(
				Vector3(-7.2, 0.02, line_z), Vector3(4.6, 0.01, 0.12), "paint_white", false
			)
		)

	for stall_index: int in range(4):
		var line_x := -2.5 + float(stall_index) * 3.2
		pieces.append(
			MotelPiece.new(
				Vector3(line_x, 0.02, 13.5), Vector3(0.12, 0.01, 4.6), "paint_white", false
			)
		)

	pieces.append(
		MotelPiece.new(Vector3(4.5, 0.02, 17.4), Vector3(20.0, 0.01, 0.16), "paint_yellow", false)
	)


static func _add_curbs(pieces: Array[MotelPiece]) -> void:
	var min_x := MotelConstants.LOT_MIN_X
	var max_x := MotelConstants.LOT_MAX_X
	var max_z := MotelConstants.LOT_MAX_Z

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, 0.0, max_z - 0.45), Vector3(-2.0, 0.18, max_z), "concrete", true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(8.5, 0.0, max_z - 0.45), Vector3(max_x, 0.18, max_z), "concrete", true
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(max_x - 0.45, 0.0, MotelConstants.CANOPY_BACK_Z - 1.5),
			Vector3(max_x, 0.18, max_z - 0.45),
			"concrete",
			true
		)
	)


static func _add_courtyard_pool(pieces: Array[MotelPiece]) -> void:
	var min_x := MotelConstants.POOL_MIN_X
	var max_x := MotelConstants.POOL_MAX_X
	var min_z := MotelConstants.POOL_MIN_Z
	var max_z := MotelConstants.POOL_MAX_Z

	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x, 0.0, min_z), Vector3(max_x, 0.03, max_z), "concrete", false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x + 1.35, 0.03, min_z + 1.35),
			Vector3(max_x - 1.35, 0.055, max_z - 1.35),
			"pool_water",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x + 1.15, 0.03, min_z + 1.15),
			Vector3(max_x - 1.15, 0.06, min_z + 1.35),
			"paint_white",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x + 1.15, 0.03, max_z - 1.35),
			Vector3(max_x - 1.15, 0.06, max_z - 1.15),
			"paint_white",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(min_x + 1.15, 0.03, min_z + 1.35),
			Vector3(min_x + 1.35, 0.06, max_z - 1.35),
			"paint_white",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(max_x - 1.35, 0.03, min_z + 1.35),
			Vector3(max_x - 1.15, 0.06, max_z - 1.35),
			"paint_white",
			false
		)
	)


static func _add_pool_fence(pieces: Array[MotelPiece]) -> void:
	var min_x := MotelConstants.POOL_MIN_X
	var max_x := MotelConstants.POOL_MAX_X
	var min_z := MotelConstants.POOL_MIN_Z
	var max_z := MotelConstants.POOL_MAX_Z

	_add_fence_x(pieces, min_x, max_x, min_z)
	_add_fence_x(pieces, min_x, max_x, max_z)
	_add_fence_z(pieces, min_z, max_z, max_x)
	_add_fence_z(pieces, min_z, min_z + 3.6, min_x)
	_add_fence_z(pieces, max_z - 3.6, max_z, min_x)


static func _add_fence_x(
	pieces: Array[MotelPiece], start_x: float, end_x: float, fence_z: float
) -> void:
	var fence_h := 1.15
	var length := end_x - start_x
	var mid_x := (start_x + end_x) * 0.5
	pieces.append(
		MotelPiece.new(
			Vector3(mid_x, fence_h - 0.06, fence_z),
			Vector3(length, 0.06, 0.06),
			"fence_white",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(mid_x, 0.18, fence_z), Vector3(length, 0.05, 0.05), "fence_white", false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(mid_x, fence_h * 0.5, fence_z), Vector3(length, fence_h, 0.1), "", true
		)
	)
	var post_x := start_x
	while post_x <= end_x + 0.01:
		pieces.append(
			MotelPiece.new(
				Vector3(post_x, fence_h * 0.5, fence_z),
				Vector3(0.05, fence_h, 0.05),
				"fence_white",
				false
			)
		)
		post_x += 0.8


static func _add_fence_z(
	pieces: Array[MotelPiece], start_z: float, end_z: float, fence_x: float
) -> void:
	var fence_h := 1.15
	var length := end_z - start_z
	var mid_z := (start_z + end_z) * 0.5
	pieces.append(
		MotelPiece.new(
			Vector3(fence_x, fence_h - 0.06, mid_z),
			Vector3(0.06, 0.06, length),
			"fence_white",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(fence_x, 0.18, mid_z), Vector3(0.05, 0.05, length), "fence_white", false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(fence_x, fence_h * 0.5, mid_z), Vector3(0.1, fence_h, length), "", true
		)
	)
	var post_z := start_z
	while post_z <= end_z + 0.01:
		pieces.append(
			MotelPiece.new(
				Vector3(fence_x, fence_h * 0.5, post_z),
				Vector3(0.05, fence_h, 0.05),
				"fence_white",
				false
			)
		)
		post_z += 0.8


static func _add_pool_loungers(pieces: Array[MotelPiece]) -> void:
	var lounger_x := MotelConstants.POOL_MAX_X - 0.65
	for lounger_z: float in [6.0, 8.2, 10.4]:
		pieces.append(
			MotelPiece.new(
				Vector3(lounger_x, 0.2, lounger_z), Vector3(0.7, 0.16, 1.55), "lounge_yellow", true
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(lounger_x, 0.45, lounger_z - 0.6),
				Vector3(0.7, 0.45, 0.14),
				"lounge_yellow",
				false,
				Vector3(deg_to_rad(-28.0), 0.0, 0.0)
			)
		)
