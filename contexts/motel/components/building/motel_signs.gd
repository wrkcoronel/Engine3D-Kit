class_name MotelSigns
extends RefCounted


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_rooftop_sign(pieces)
	_add_roadside_sign_planter(pieces)
	return pieces


static func rooftop_sign_center() -> Vector3:
	var sign_x := (MotelConstants.RECEPTION_START_X + MotelConstants.RECEPTION_END_X) * 0.5
	return Vector3(sign_x, MotelConstants.ROOF_TOP_Y + 1.55, MotelConstants.RECEPTION_FRONT_Z - 1.2)


static func roadside_sign_center() -> Vector3:
	return Vector3(20.6, 1.35, 11.4)


static func _add_rooftop_sign(pieces: Array[MotelPiece]) -> void:
	var center := rooftop_sign_center()
	var sign_w := 5.2
	var sign_h := 1.7
	var roof_y := MotelConstants.ROOF_TOP_Y

	for offset_x: float in [-1.8, 1.8]:
		pieces.append(
			MotelPiece.from_bounds(
				Vector3(center.x + offset_x - 0.08, roof_y, center.z - 0.08),
				Vector3(center.x + offset_x + 0.08, center.y - sign_h * 0.45, center.z + 0.08),
				"metal_dark",
				false
			)
		)
	pieces.append(
		MotelPiece.new(center, Vector3(sign_w + 0.26, sign_h + 0.26, 0.42), "sign_red", false)
	)
	pieces.append(MotelPiece.new(center, Vector3(sign_w, sign_h, 0.48), "sign_yellow", false))


static func _add_roadside_sign_planter(pieces: Array[MotelPiece]) -> void:
	var sign_pos := roadside_sign_center()
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(sign_pos.x - 2.3, 0.0, sign_pos.z - 0.9),
			Vector3(sign_pos.x + 2.3, 0.55, sign_pos.z + 0.9),
			"concrete",
			true
		)
	)
	pieces.append(MotelPiece.new(sign_pos, Vector3(3.6, 1.3, 0.3), "paint_white", true))
	pieces.append(
		MotelPiece.new(
			sign_pos + Vector3(0.0, 0.72, 0.0), Vector3(3.75, 0.14, 0.36), "sign_red", false
		)
	)
	pieces.append(
		MotelPiece.new(
			sign_pos + Vector3(-1.85, -0.45, -0.3), Vector3(0.75, 0.7, 0.75), "foliage", false
		)
	)
	pieces.append(
		MotelPiece.new(
			sign_pos + Vector3(1.85, -0.5, -0.25), Vector3(0.8, 0.65, 0.8), "foliage", false
		)
	)
