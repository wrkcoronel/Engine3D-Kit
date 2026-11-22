class_name MotelRoad
extends RefCounted

const ROAD_MIN_X := -110.0
const ROAD_MAX_X := 110.0
const ROAD_MIN_Z := 21.5
const ROAD_MAX_Z := 30.5
const SHOULDER_WIDTH := 1.2
const DRIVEWAY_MIN_X := -2.5
const DRIVEWAY_MAX_X := 9.0


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	_add_road_surface_and_shoulders(pieces)
	_add_driveway_connection(pieces)
	_add_road_markings(pieces)
	_add_roadside_poles(pieces)
	return pieces


static func pole_light_positions() -> Array[Vector3]:
	return [
		Vector3(-34.0, 5.4, ROAD_MIN_Z - 0.9),
		Vector3(-12.0, 5.4, ROAD_MIN_Z - 0.9),
		Vector3(16.0, 5.4, ROAD_MIN_Z - 0.9),
		Vector3(38.0, 5.4, ROAD_MIN_Z - 0.9),
	]


static func _add_road_surface_and_shoulders(pieces: Array[MotelPiece]) -> void:
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(ROAD_MIN_X, 0.0, ROAD_MIN_Z),
			Vector3(ROAD_MAX_X, 0.016, ROAD_MAX_Z),
			"asphalt",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(ROAD_MIN_X, 0.0, ROAD_MIN_Z - SHOULDER_WIDTH),
			Vector3(ROAD_MAX_X, 0.01, ROAD_MIN_Z),
			"concrete",
			false
		)
	)
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(ROAD_MIN_X, 0.0, ROAD_MAX_Z),
			Vector3(ROAD_MAX_X, 0.01, ROAD_MAX_Z + SHOULDER_WIDTH),
			"concrete",
			false
		)
	)


static func _add_driveway_connection(pieces: Array[MotelPiece]) -> void:
	pieces.append(
		MotelPiece.from_bounds(
			Vector3(DRIVEWAY_MIN_X, 0.0, MotelConstants.LOT_MAX_Z - 0.1),
			Vector3(DRIVEWAY_MAX_X, 0.016, ROAD_MIN_Z + 0.1),
			"asphalt",
			false
		)
	)


static func _add_road_markings(pieces: Array[MotelPiece]) -> void:
	var road_length := ROAD_MAX_X - ROAD_MIN_X
	var road_mid_x := (ROAD_MIN_X + ROAD_MAX_X) * 0.5
	var center_z := (ROAD_MIN_Z + ROAD_MAX_Z) * 0.5

	pieces.append(
		MotelPiece.new(
			Vector3(road_mid_x, 0.022, ROAD_MIN_Z + 0.35),
			Vector3(road_length, 0.01, 0.14),
			"paint_white",
			false
		)
	)
	pieces.append(
		MotelPiece.new(
			Vector3(road_mid_x, 0.022, ROAD_MAX_Z - 0.35),
			Vector3(road_length, 0.01, 0.14),
			"paint_white",
			false
		)
	)

	var dash_x := ROAD_MIN_X + 3.0
	while dash_x < ROAD_MAX_X - 3.0:
		pieces.append(
			MotelPiece.new(
				Vector3(dash_x, 0.022, center_z), Vector3(3.0, 0.01, 0.16), "paint_yellow", false
			)
		)
		dash_x += 6.5


static func _add_roadside_poles(pieces: Array[MotelPiece]) -> void:
	for light_pos: Vector3 in pole_light_positions():
		var pole_height := light_pos.y + 0.25
		pieces.append(
			MotelPiece.new(
				Vector3(light_pos.x, pole_height * 0.5, light_pos.z),
				Vector3(0.18, pole_height, 0.18),
				"metal_dark",
				true
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(light_pos.x, pole_height + 0.08, light_pos.z + 0.45),
				Vector3(0.22, 0.12, 1.0),
				"metal_dark",
				false
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(light_pos.x, pole_height - 0.04, light_pos.z + 0.85),
				Vector3(0.36, 0.12, 0.48),
				"sconce_glow",
				false
			)
		)
