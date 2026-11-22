class_name GrassStreamer
extends RefCounted

const NO_LEVEL := -1
const NEAR_LEVEL := 0
const FAR_LEVEL := 1
const SWITCH_MARGIN := 6.0
const FADE_CHUNK_FRACTION := 0.75
const FADE_LENGTH := 14.0


static func cell_of(point: Vector2, chunk_size: float) -> Vector2i:
	return Vector2i(floori(point.x / chunk_size), floori(point.y / chunk_size))


static func cell_center(cell: Vector2i, chunk_size: float) -> Vector2:
	var origin := Vector2(cell) * chunk_size
	return origin + Vector2(chunk_size, chunk_size) / 2.0


static func cell_in_field(cell: Vector2i, chunk_size: float, field_size: float) -> bool:
	var half_cells := roundi(field_size / chunk_size / 2.0)
	var inside_x := cell.x >= -half_cells and cell.x < half_cells
	var inside_y := cell.y >= -half_cells and cell.y < half_cells
	return inside_x and inside_y


static func level_for(
	distance: float, near_radius: float, far_radius: float, current_level: int
) -> int:
	var near_limit := near_radius
	if current_level == NEAR_LEVEL:
		near_limit += SWITCH_MARGIN
	var far_limit := far_radius
	if current_level != NO_LEVEL:
		far_limit += SWITCH_MARGIN
	if distance <= near_limit:
		return NEAR_LEVEL
	if distance <= far_limit:
		return FAR_LEVEL
	return NO_LEVEL


static func wanted_levels(
	focus: Vector2,
	chunk_size: float,
	field_size: float,
	near_radius: float,
	far_radius: float,
	current_levels: Dictionary
) -> Dictionary:
	var wanted := {}
	var reach := Vector2.ONE * (far_radius + SWITCH_MARGIN + chunk_size)
	var first_cell := cell_of(focus - reach, chunk_size)
	var last_cell := cell_of(focus + reach, chunk_size)
	for cell_x: int in range(first_cell.x, last_cell.x + 1):
		for cell_y: int in range(first_cell.y, last_cell.y + 1):
			var cell := Vector2i(cell_x, cell_y)
			if not cell_in_field(cell, chunk_size, field_size):
				continue
			var distance := cell_center(cell, chunk_size).distance_to(focus)
			var current_level := current_levels.get(cell, NO_LEVEL) as int
			var level := level_for(distance, near_radius, far_radius, current_level)
			if level != NO_LEVEL:
				wanted[cell] = level
	return wanted


static func fade_end_distance(far_radius: float, chunk_size: float) -> float:
	return far_radius - chunk_size * FADE_CHUNK_FRACTION


static func fade_start_distance(far_radius: float, chunk_size: float) -> float:
	return fade_end_distance(far_radius, chunk_size) - FADE_LENGTH
