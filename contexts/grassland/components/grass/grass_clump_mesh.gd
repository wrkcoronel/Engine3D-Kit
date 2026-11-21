class_name GrassClumpMesh
extends RefCounted

const STALK_COUNT := 6
const CLUMP_RADIUS := 0.14
const MIN_STALK_HEIGHT := 0.62
const MAX_STALK_HEIGHT := 0.88
const MAX_LEAN_DISTANCE := 0.22

const STEM_SEGMENTS := 3
const STEM_BASE_HALF_WIDTH := 0.012
const STEM_TIP_HALF_WIDTH := 0.006

const LEAF_SEGMENTS := 3
const LEAF_LENGTH_FRACTION := 0.5
const LEAF_HALF_WIDTHS: Array[float] = [0.004, 0.016, 0.012, 0.0]

const EAR_CHANCE := 0.75
const EAR_SEGMENTS := 3
const EAR_MIN_LENGTH := 0.11
const EAR_MAX_LENGTH := 0.17
const EAR_HALF_WIDTHS: Array[float] = [0.005, 0.013, 0.011, 0.003]

const BASE_COLOR := Color(0.03, 0.05, 0.02)
const MIDDLE_COLOR := Color(0.1, 0.16, 0.05)
const TIP_COLOR := Color(0.28, 0.27, 0.1)
const LEAF_COLOR := Color(0.07, 0.17, 0.05)
const EAR_BASE_COLOR := Color(0.42, 0.25, 0.05)
const EAR_TIP_COLOR := Color(0.62, 0.38, 0.08)


static func build(random_seed: int, stalk_count: int = STALK_COUNT) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var arrays := GrassRibbonArrays.new()
	for stalk_index: int in stalk_count:
		_add_stalk(arrays, random)
	return arrays.to_mesh()


static func _add_stalk(arrays: GrassRibbonArrays, random: RandomNumberGenerator) -> void:
	var base_position := _random_base_position(random)
	var facing_angle := random.randf() * TAU
	var lean_direction := Vector3(cos(facing_angle), 0.0, sin(facing_angle))
	var side_direction := Vector3(-lean_direction.z, 0.0, lean_direction.x)
	var lean_distance := random.randf_range(0.0, MAX_LEAN_DISTANCE)
	var stalk_height := random.randf_range(MIN_STALK_HEIGHT, MAX_STALK_HEIGHT)
	var has_ear := random.randf() < EAR_CHANCE
	var stem_points := _stem_points(base_position, lean_direction, lean_distance, stalk_height)
	_add_stem(arrays, stem_points, side_direction, has_ear)
	_add_leaf(arrays, stem_points, random)
	if has_ear:
		_add_ear(arrays, stem_points, side_direction, random)


static func _random_base_position(random: RandomNumberGenerator) -> Vector3:
	var angle := random.randf() * TAU
	var distance_from_center := CLUMP_RADIUS * sqrt(random.randf())
	return Vector3(cos(angle) * distance_from_center, 0.0, sin(angle) * distance_from_center)


static func _stem_points(
	base_position: Vector3, lean_direction: Vector3, lean_distance: float, stalk_height: float
) -> PackedVector3Array:
	var points := PackedVector3Array()
	for point_index: int in STEM_SEGMENTS + 1:
		var height_fraction := float(point_index) / float(STEM_SEGMENTS)
		var lean_offset := lean_direction * lean_distance * height_fraction * height_fraction
		var height_offset := Vector3.UP * stalk_height * height_fraction
		points.append(base_position + lean_offset + height_offset)
	return points


static func _add_stem(
	arrays: GrassRibbonArrays,
	stem_points: PackedVector3Array,
	side_direction: Vector3,
	has_ear: bool
) -> void:
	var tip_half_width := 0.0
	if has_ear:
		tip_half_width = STEM_TIP_HALF_WIDTH
	var half_widths: Array[float] = []
	var point_colors := PackedColorArray()
	for point_index: int in stem_points.size():
		var height_fraction := float(point_index) / float(STEM_SEGMENTS)
		half_widths.append(lerpf(STEM_BASE_HALF_WIDTH, tip_half_width, height_fraction))
		point_colors.append(_stem_color(height_fraction))
	arrays.add_ribbon(stem_points, half_widths, point_colors, side_direction)


static func _add_leaf(
	arrays: GrassRibbonArrays, stem_points: PackedVector3Array, random: RandomNumberGenerator
) -> void:
	var attach_position := stem_points[1]
	var stalk_height := stem_points[stem_points.size() - 1].y
	var leaf_length := stalk_height * LEAF_LENGTH_FRACTION
	var leaf_angle := random.randf() * TAU
	var leaf_direction := Vector3(cos(leaf_angle), 0.0, sin(leaf_angle))
	var leaf_points := PackedVector3Array()
	var leaf_colors := PackedColorArray()
	for point_index: int in LEAF_SEGMENTS + 1:
		var along := float(point_index) / float(LEAF_SEGMENTS)
		var outward_distance := leaf_length * along * 0.8
		var rise := leaf_length * (along - 0.8 * along * along)
		var outward_offset := leaf_direction * outward_distance
		leaf_points.append(attach_position + outward_offset + Vector3.UP * rise)
		leaf_colors.append(LEAF_COLOR.lerp(TIP_COLOR, along * 0.4))
	var tilted_side := Vector3(-leaf_direction.z, 0.4, leaf_direction.x).normalized()
	arrays.add_ribbon(leaf_points, LEAF_HALF_WIDTHS, leaf_colors, tilted_side)


static func _add_ear(
	arrays: GrassRibbonArrays,
	stem_points: PackedVector3Array,
	side_direction: Vector3,
	random: RandomNumberGenerator
) -> void:
	var tip_position := stem_points[stem_points.size() - 1]
	var previous_position := stem_points[stem_points.size() - 2]
	var ear_direction := (tip_position - previous_position).normalized()
	var ear_length := random.randf_range(EAR_MIN_LENGTH, EAR_MAX_LENGTH)
	var ear_points := PackedVector3Array()
	var ear_colors := PackedColorArray()
	for point_index: int in EAR_SEGMENTS + 1:
		var along := float(point_index) / float(EAR_SEGMENTS)
		ear_points.append(tip_position + ear_direction * ear_length * along)
		ear_colors.append(EAR_BASE_COLOR.lerp(EAR_TIP_COLOR, along))
	arrays.add_ribbon(ear_points, EAR_HALF_WIDTHS, ear_colors, side_direction)
	var crossing_side := ear_direction.cross(side_direction).normalized()
	arrays.add_ribbon(ear_points, EAR_HALF_WIDTHS, ear_colors, crossing_side)


static func _stem_color(height_fraction: float) -> Color:
	if height_fraction < 0.5:
		return BASE_COLOR.lerp(MIDDLE_COLOR, height_fraction * 2.0)
	var upper_fraction := (height_fraction - 0.5) * 2.0
	return MIDDLE_COLOR.lerp(TIP_COLOR, upper_fraction)
