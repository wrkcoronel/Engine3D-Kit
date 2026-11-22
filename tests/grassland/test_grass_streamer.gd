extends TestCase

const CHUNK_SIZE := 16.0
const FIELD_SIZE := 320.0
const NEAR_RADIUS := 26.0
const FAR_RADIUS := 70.0


func test_cell_of_a_point_uses_floor() -> void:
	assert_eq(GrassStreamer.cell_of(Vector2(0.5, 0.5), CHUNK_SIZE), Vector2i(0, 0), "origem")
	assert_eq(GrassStreamer.cell_of(Vector2(-0.5, 17.0), CHUNK_SIZE), Vector2i(-1, 1), "negativo")


func test_cell_center_is_half_a_chunk_from_the_corner() -> void:
	assert_eq(GrassStreamer.cell_center(Vector2i(1, -1), CHUNK_SIZE), Vector2(24.0, -8.0), "centro")


func test_cells_outside_the_field_are_rejected() -> void:
	assert_true(GrassStreamer.cell_in_field(Vector2i(-10, -10), CHUNK_SIZE, FIELD_SIZE), "borda")
	assert_true(GrassStreamer.cell_in_field(Vector2i(9, 9), CHUNK_SIZE, FIELD_SIZE), "outra borda")
	assert_true(not GrassStreamer.cell_in_field(Vector2i(10, 0), CHUNK_SIZE, FIELD_SIZE), "fora")
	assert_true(not GrassStreamer.cell_in_field(Vector2i(0, -11), CHUNK_SIZE, FIELD_SIZE), "fora")


func test_level_depends_on_distance() -> void:
	var no_level := GrassStreamer.NO_LEVEL
	assert_eq(GrassStreamer.level_for(10.0, NEAR_RADIUS, FAR_RADIUS, no_level), 0, "perto")
	assert_eq(GrassStreamer.level_for(50.0, NEAR_RADIUS, FAR_RADIUS, no_level), 1, "longe")
	assert_eq(GrassStreamer.level_for(90.0, NEAR_RADIUS, FAR_RADIUS, no_level), no_level, "fora")


func test_level_has_hysteresis_to_avoid_flicker() -> void:
	var just_past_near := NEAR_RADIUS + 3.0
	var was_near := GrassStreamer.level_for(just_past_near, NEAR_RADIUS, FAR_RADIUS, 0)
	var was_far := GrassStreamer.level_for(just_past_near, NEAR_RADIUS, FAR_RADIUS, 1)
	assert_eq(was_near, 0, "quem era perto continua perto na margem")
	assert_eq(was_far, 1, "quem era longe continua longe na margem")


func test_wanted_levels_surround_the_focus_with_near_then_far() -> void:
	var wanted := GrassStreamer.wanted_levels(
		Vector2.ZERO, CHUNK_SIZE, FIELD_SIZE, NEAR_RADIUS, FAR_RADIUS, {}
	)
	assert_eq(wanted[Vector2i(0, 0)], 0, "o chunk do foco e perto")
	assert_eq(wanted[Vector2i(3, 0)], 1, "um chunk a uns 56 m e longe")
	assert_true(not wanted.has(Vector2i(8, 0)), "a 136 m nao entra")


func test_wanted_levels_never_leave_the_field() -> void:
	var wanted := GrassStreamer.wanted_levels(
		Vector2(155.0, 0.0), CHUNK_SIZE, FIELD_SIZE, NEAR_RADIUS, FAR_RADIUS, {}
	)
	for cell: Vector2i in wanted:
		assert_true(GrassStreamer.cell_in_field(cell, CHUNK_SIZE, FIELD_SIZE), "celula no campo")


func test_grass_fades_out_before_the_nearest_edge_of_a_new_chunk() -> void:
	var fade_end := GrassStreamer.fade_end_distance(FAR_RADIUS, CHUNK_SIZE)
	var half_diagonal := CHUNK_SIZE * sqrt(2.0) / 2.0
	var nearest_edge := FAR_RADIUS - half_diagonal
	assert_true(fade_end <= nearest_edge, "capim some antes de o pedaco novo aparecer")
	var fade_start := GrassStreamer.fade_start_distance(FAR_RADIUS, CHUNK_SIZE)
	assert_true(fade_start < fade_end, "comeca a encolher antes do fim")
