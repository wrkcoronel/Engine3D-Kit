class_name MotelFoliage
extends RefCounted

const CLEARING_MIN_X := -21.0
const CLEARING_MAX_X := 27.5
const CLEARING_MIN_Z := -19.0
const CLEARING_MAX_Z := 20.0
const ROAD_CLEAR_MIN_Z := 19.0
const ROAD_CLEAR_MAX_Z := 33.5
const DRIVEWAY_MIN_X := -3.5
const DRIVEWAY_MAX_X := 10.5
const FOREST_SEED := 42


static func build() -> Array[MotelPiece]:
	var pieces: Array[MotelPiece] = []
	var random := RandomNumberGenerator.new()
	random.seed = FOREST_SEED
	_add_trees(pieces, random)
	_add_bushes(pieces, random)
	_add_parking_light_poles(pieces)
	return pieces


static func pole_light_positions() -> Array[Vector3]:
	return [
		Vector3(-9.4, 5.1, 16.4),
		Vector3(23.2, 5.1, 16.4),
	]


static func _add_trees(pieces: Array[MotelPiece], random: RandomNumberGenerator) -> void:
	var placed: Array[Vector2] = []
	var attempts := 0
	while placed.size() < 70 and attempts < 600:
		attempts += 1
		var tree_x := random.randf_range(-56.0, 58.0)
		var tree_z := random.randf_range(-52.0, 52.0)
		var candidate := Vector2(tree_x, tree_z)
		if _is_blocked_for_tree(candidate, placed):
			continue
		placed.append(candidate)
		_append_single_tree(pieces, tree_x, tree_z, random)


static func _is_blocked_for_tree(candidate: Vector2, placed: Array[Vector2]) -> bool:
	var in_x := candidate.x > CLEARING_MIN_X and candidate.x < CLEARING_MAX_X
	var in_z := candidate.y > CLEARING_MIN_Z and candidate.y < CLEARING_MAX_Z
	if in_x and in_z:
		return true
	if candidate.y >= ROAD_CLEAR_MIN_Z and candidate.y <= ROAD_CLEAR_MAX_Z:
		return true
	var in_driveway := (
		candidate.x > DRIVEWAY_MIN_X
		and candidate.x < DRIVEWAY_MAX_X
		and candidate.y >= CLEARING_MAX_Z
	)
	if in_driveway:
		return true
	for existing: Vector2 in placed:
		if candidate.distance_to(existing) < 5.2:
			return true
	return false


static func _append_single_tree(
	pieces: Array[MotelPiece], tree_x: float, tree_z: float, random: RandomNumberGenerator
) -> void:
	var trunk_height := random.randf_range(2.6, 4.4)
	var trunk_width := random.randf_range(0.36, 0.56)
	var yaw := random.randf_range(0.0, TAU)
	pieces.append(
		MotelPiece.new(
			Vector3(tree_x, trunk_height * 0.5, tree_z),
			Vector3(trunk_width, trunk_height, trunk_width),
			"bark",
			true,
			Vector3(0.0, yaw, 0.0)
		)
	)

	var lower_width := random.randf_range(2.6, 4.2)
	var lower_height := random.randf_range(2.2, 3.2)
	var lower_y := trunk_height + lower_height * 0.4
	pieces.append(
		MotelPiece.new(
			Vector3(tree_x, lower_y, tree_z),
			Vector3(lower_width, lower_height, lower_width),
			"foliage_dark",
			false,
			Vector3(0.0, yaw + 0.35, 0.0)
		)
	)

	var upper_width := lower_width * random.randf_range(0.62, 0.78)
	var upper_height := random.randf_range(1.6, 2.5)
	var upper_y := lower_y + lower_height * 0.45 + upper_height * 0.35
	var top_material := "foliage"
	if random.randf() < 0.45:
		top_material = "foliage_dark"
	pieces.append(
		MotelPiece.new(
			Vector3(tree_x, upper_y, tree_z),
			Vector3(upper_width, upper_height, upper_width),
			top_material,
			false,
			Vector3(0.0, yaw + 0.9, 0.0)
		)
	)


static func _add_bushes(pieces: Array[MotelPiece], random: RandomNumberGenerator) -> void:
	var count := 0
	var attempts := 0
	while count < 55 and attempts < 400:
		attempts += 1
		var bush_x := random.randf_range(-42.0, 44.0)
		var bush_z := random.randf_range(-38.0, 38.0)
		var in_x := bush_x > CLEARING_MIN_X + 1.0 and bush_x < CLEARING_MAX_X - 1.0
		var in_z := bush_z > CLEARING_MIN_Z + 1.0 and bush_z < CLEARING_MAX_Z - 1.0
		if in_x and in_z:
			continue
		if bush_z >= ROAD_CLEAR_MIN_Z and bush_z <= ROAD_CLEAR_MAX_Z:
			continue
		var in_driveway := (
			bush_x > DRIVEWAY_MIN_X and bush_x < DRIVEWAY_MAX_X and bush_z >= CLEARING_MAX_Z - 1.0
		)
		if in_driveway:
			continue
		count += 1
		var width := random.randf_range(0.9, 2.0)
		var height := random.randf_range(0.65, 1.35)
		var material := "foliage"
		if random.randf() < 0.5:
			material = "foliage_dark"
		pieces.append(
			MotelPiece.new(
				Vector3(bush_x, height * 0.5, bush_z),
				Vector3(width, height, width * random.randf_range(0.8, 1.2)),
				material,
				false,
				Vector3(0.0, random.randf_range(0.0, TAU), 0.0)
			)
		)


static func _add_parking_light_poles(pieces: Array[MotelPiece]) -> void:
	for light_pos: Vector3 in pole_light_positions():
		var pole_height := light_pos.y + 0.25
		pieces.append(
			MotelPiece.new(
				Vector3(light_pos.x, pole_height * 0.5, light_pos.z),
				Vector3(0.16, pole_height, 0.16),
				"metal_dark",
				true
			)
		)
		pieces.append(
			MotelPiece.new(
				Vector3(light_pos.x, pole_height + 0.1, light_pos.z),
				Vector3(0.55, 0.2, 0.55),
				"sconce_glow",
				false
			)
		)
