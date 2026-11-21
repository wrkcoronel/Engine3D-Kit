extends TestCase

const SIZE := Vector3(20.0, 18.0, 20.0)


func test_same_seed_gives_same_ruin_and_other_seed_differs() -> void:
	var first := RuinLayout.build(SIZE, 5)
	var second := RuinLayout.build(SIZE, 5)
	var other := RuinLayout.build(SIZE, 6)
	assert_eq(first.size(), second.size(), "mesma semente, mesma quantidade")
	assert_eq(first[3].center, second[3].center, "mesma semente, mesma peca")
	assert_true(first.size() != other.size() or first[3].center != other[3].center, "semente muda")


func test_corners_are_always_standing() -> void:
	for random_seed: int in 20:
		var heights := RuinLayout.segment_heights(5, 18.0, _random(random_seed))
		assert_true(
			heights[0] >= 18.0 * RuinLayout.CORNER_MIN_FRACTION - 0.001, "canto esquerdo em pe"
		)
		assert_true(
			heights[4] >= 18.0 * RuinLayout.CORNER_MIN_FRACTION - 0.001, "canto direito em pe"
		)


func test_heights_are_ragged_not_flat() -> void:
	var heights := RuinLayout.segment_heights(12, 30.0, _random(3))
	var lowest := heights.min() as float
	var highest := heights.max() as float
	assert_true(highest - lowest > 5.0, "o topo e irregular")
	assert_true(highest <= 30.0, "nunca passa da altura do predio")


func test_segment_count_follows_length() -> void:
	assert_eq(RuinLayout.segment_count(20.0), 5, "20 m em trechos de 4 m")
	assert_eq(RuinLayout.segment_count(1.0), 2, "no minimo dois")


func test_every_piece_stays_near_the_footprint_and_above_ground() -> void:
	var pieces := RuinLayout.build(SIZE, 9)
	for piece: RuinPiece in pieces:
		assert_true(piece.center.y > 0.0, "peca acima do chao")
		assert_true(absf(piece.center.x) <= SIZE.x / 2.0 + 4.0, "perto do predio em x")
		assert_true(absf(piece.center.z) <= SIZE.z / 2.0 + 4.0, "perto do predio em z")
		assert_true(piece.center.y <= SIZE.y + 3.0, "nao passa muito do topo")


func test_ruin_has_every_kind_of_damage() -> void:
	var kinds := {}
	for piece: RuinPiece in RuinLayout.build(Vector3(30.0, 30.0, 30.0), 11):
		kinds[piece.kind] = true
	assert_true(kinds.has(RuinPiece.Kind.WALL), "paredes")
	assert_true(kinds.has(RuinPiece.Kind.COLUMN), "colunas")
	assert_true(kinds.has(RuinPiece.Kind.SLAB), "lajes caidas")
	assert_true(kinds.has(RuinPiece.Kind.REBAR), "ferragem exposta")
	assert_true(kinds.has(RuinPiece.Kind.RUBBLE), "entulho")


func test_only_structure_has_collision() -> void:
	var rebar := RuinPiece.create(RuinPiece.Kind.REBAR, Vector3.ZERO, Vector3.ONE, Vector3.ZERO)
	var rubble := RuinPiece.create(RuinPiece.Kind.RUBBLE, Vector3.ZERO, Vector3.ONE, Vector3.ZERO)
	var wall := RuinPiece.create(RuinPiece.Kind.WALL, Vector3.ZERO, Vector3.ONE, Vector3.ZERO)
	var slab := RuinPiece.create(RuinPiece.Kind.SLAB, Vector3.ZERO, Vector3.ONE, Vector3.ZERO)
	assert_true(wall.has_collision() and slab.has_collision(), "parede e laje colidem")
	assert_true(
		not rebar.has_collision() and not rubble.has_collision(), "ferro e entulho sao so visuais"
	)


func test_wall_perimeter_is_closed_at_the_corners() -> void:
	var pieces := RuinLayout.build(SIZE, 2)
	var corner_walls := 0
	for piece: RuinPiece in pieces:
		if piece.kind != RuinPiece.Kind.WALL:
			continue
		var near_x := absf(piece.center.x) > SIZE.x / 2.0 - 5.0
		var near_z := absf(piece.center.z) > SIZE.z / 2.0 - 5.0
		if near_x and near_z:
			corner_walls += 1
	assert_true(corner_walls >= 4, "os quatro cantos tem parede")


func _random(random_seed: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	return random
