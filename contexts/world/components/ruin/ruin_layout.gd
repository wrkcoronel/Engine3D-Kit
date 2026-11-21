class_name RuinLayout
extends RefCounted

const WALL_THICKNESS := 0.7
const SEGMENT_WIDTH := 4.0
const CORNER_MIN_FRACTION := 0.75
const MID_MIN_FRACTION := 0.3
const BREACH_CHANCE := 0.12
const GAP_CHANCE := 0.08
const BREACH_MIN_HEIGHT := 2.2
const LEAN_CHANCE := 0.25
const MAX_LEAN_DEGREES := 3.0
const STOREY_HEIGHT := 3.6
const MAX_STOREYS := 10
const SLAB_THICKNESS := 0.35
const SLAB_KEEP_CHANCE := 0.75
const COLUMN_WIDTH := 0.9
const REBAR_WIDTH := 0.06
const MIN_RUBBLE := 10
const MAX_RUBBLE := 60


static func build(size: Vector3, random_seed: int) -> Array[RuinPiece]:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var pieces: Array[RuinPiece] = []
	for along_x: bool in [true, false]:
		for side_sign: float in [-1.0, 1.0]:
			pieces.append_array(_wall_side(size, random, along_x, side_sign))
	pieces.append_array(_columns(size, random))
	pieces.append_array(_slabs(size, random))
	pieces.append_array(_rubble(size, random))
	return pieces


static func segment_count(length: float) -> int:
	return maxi(2, roundi(length / SEGMENT_WIDTH))


static func segment_heights(
	count: int, full_height: float, random: RandomNumberGenerator
) -> Array[float]:
	var heights: Array[float] = []
	var phase := random.randf() * 10.0
	for index: int in count:
		var is_corner := index == 0 or index == count - 1
		if is_corner:
			heights.append(full_height * random.randf_range(CORNER_MIN_FRACTION, 1.0))
			continue
		var roll := random.randf()
		if roll < GAP_CHANCE:
			heights.append(0.0)
			continue
		if roll < GAP_CHANCE + BREACH_CHANCE:
			var breach_height := maxf(BREACH_MIN_HEIGHT, full_height * 0.12)
			heights.append(minf(full_height, breach_height))
			continue
		var wave := 0.5 + 0.5 * sin(phase + float(index) * 1.3)
		var fraction := lerpf(MID_MIN_FRACTION, 1.0, wave * random.randf_range(0.6, 1.0))
		heights.append(full_height * fraction)
	return heights


static func _wall_side(
	size: Vector3, random: RandomNumberGenerator, along_x: bool, side_sign: float
) -> Array[RuinPiece]:
	var pieces: Array[RuinPiece] = []
	var length := size.x
	var fixed_offset := side_sign * (size.z / 2.0 - WALL_THICKNESS / 2.0)
	if not along_x:
		length = size.z - 2.0 * WALL_THICKNESS
		fixed_offset = side_sign * (size.x / 2.0 - WALL_THICKNESS / 2.0)
	var count := segment_count(length)
	var segment_length := length / float(count)
	var heights := segment_heights(count, size.y, random)
	for index: int in count:
		var height := heights[index]
		if height < 0.05:
			continue
		var along := -length / 2.0 + segment_length * (float(index) + 0.5)
		var is_corner := index == 0 or index == count - 1
		var lean := 0.0
		if not is_corner and random.randf() < LEAN_CHANCE:
			lean = random.randf_range(-MAX_LEAN_DEGREES, MAX_LEAN_DEGREES)
		var wall := _wall_piece(
			RuinPiece.Kind.WALL,
			along_x,
			along,
			fixed_offset,
			height / 2.0,
			Vector3(segment_length + 0.02, height, WALL_THICKNESS),
			lean
		)
		pieces.append(wall)
		if height > 3.0 and height < size.y * 0.97:
			pieces.append_array(
				_broken_top(along_x, along, fixed_offset, height, segment_length, random)
			)
	return pieces


static func _broken_top(
	along_x: bool,
	along: float,
	fixed_offset: float,
	wall_height: float,
	segment_length: float,
	random: RandomNumberGenerator
) -> Array[RuinPiece]:
	var pieces: Array[RuinPiece] = []
	var crown_height := random.randf_range(0.5, 1.5)
	var crown_length := segment_length * random.randf_range(0.3, 0.7)
	var crown_along := along + random.randf_range(-0.3, 0.3) * segment_length
	var crown_thickness := WALL_THICKNESS * random.randf_range(0.6, 0.9)
	var crown_size := Vector3(crown_length, crown_height, crown_thickness)
	var crown_lean := random.randf_range(-15.0, 15.0)
	var crown_center_y := wall_height + crown_height / 2.0 - 0.1
	pieces.append(
		_wall_piece(
			RuinPiece.Kind.RUBBLE,
			along_x,
			crown_along,
			fixed_offset,
			crown_center_y,
			crown_size,
			crown_lean
		)
	)
	var rebar_count := random.randi_range(2, 4)
	for rebar_index: int in rebar_count:
		var rebar_length := random.randf_range(0.8, 2.5)
		var rebar_along := along + random.randf_range(-0.45, 0.45) * segment_length
		var rebar_fixed := fixed_offset + random.randf_range(-0.2, 0.2)
		var rebar_size := Vector3(REBAR_WIDTH, rebar_length, REBAR_WIDTH)
		var rebar_center_y := wall_height + rebar_length / 2.0 - 0.2
		var rebar_lean := random.randf_range(-15.0, 15.0)
		pieces.append(
			_wall_piece(
				RuinPiece.Kind.REBAR,
				along_x,
				rebar_along,
				rebar_fixed,
				rebar_center_y,
				rebar_size,
				rebar_lean
			)
		)
	return pieces


static func _wall_piece(
	kind: RuinPiece.Kind,
	along_x: bool,
	along: float,
	fixed_offset: float,
	center_y: float,
	piece_size: Vector3,
	lean_degrees: float
) -> RuinPiece:
	var lean := deg_to_rad(lean_degrees)
	if along_x:
		var center := Vector3(along, center_y, fixed_offset)
		return RuinPiece.create(kind, center, piece_size, Vector3(lean, 0.0, 0.0))
	var turned_size := Vector3(piece_size.z, piece_size.y, piece_size.x)
	var turned_center := Vector3(fixed_offset, center_y, along)
	return RuinPiece.create(kind, turned_center, turned_size, Vector3(0.0, 0.0, lean))


static func _columns(size: Vector3, random: RandomNumberGenerator) -> Array[RuinPiece]:
	var pieces: Array[RuinPiece] = []
	var count := clampi(roundi(size.x * size.z / 150.0), 1, 6)
	var margin := 3.0
	for column_index: int in count:
		var column_x := random.randf_range(-size.x / 2.0 + margin, size.x / 2.0 - margin)
		var column_z := random.randf_range(-size.z / 2.0 + margin, size.z / 2.0 - margin)
		var column_height := size.y * random.randf_range(0.25, 0.85)
		var column_size := Vector3(COLUMN_WIDTH, column_height, COLUMN_WIDTH)
		var column_center := Vector3(column_x, column_height / 2.0, column_z)
		var lean := Vector3(random.randf_range(-0.08, 0.08), 0.0, random.randf_range(-0.08, 0.08))
		pieces.append(RuinPiece.create(RuinPiece.Kind.COLUMN, column_center, column_size, lean))
	return pieces


static func _slabs(size: Vector3, random: RandomNumberGenerator) -> Array[RuinPiece]:
	var pieces: Array[RuinPiece] = []
	var storeys := mini(MAX_STOREYS, int(size.y * 0.8 / STOREY_HEIGHT))
	var inner_x := size.x - 2.0 * WALL_THICKNESS
	var inner_z := size.z - 2.0 * WALL_THICKNESS
	for storey: int in range(1, storeys + 1):
		if random.randf() > SLAB_KEEP_CHANCE:
			continue
		for fragment_index: int in random.randi_range(2, 3):
			var slab_x := inner_x * random.randf_range(0.3, 0.6)
			var slab_z := inner_z * random.randf_range(0.3, 0.6)
			var center_x := random.randf_range(-1.0, 1.0) * (inner_x - slab_x) / 2.0
			var center_z := random.randf_range(-1.0, 1.0) * (inner_z - slab_z) / 2.0
			var slab_y := float(storey) * STOREY_HEIGHT - random.randf_range(0.0, 1.2)
			var tilt := Vector3(random.randf_range(-0.2, 0.2), 0.0, random.randf_range(-0.2, 0.2))
			var slab_size := Vector3(slab_x, SLAB_THICKNESS, slab_z)
			var slab_center := Vector3(center_x, slab_y, center_z)
			pieces.append(RuinPiece.create(RuinPiece.Kind.SLAB, slab_center, slab_size, tilt))
	return pieces


static func _rubble(size: Vector3, random: RandomNumberGenerator) -> Array[RuinPiece]:
	var pieces: Array[RuinPiece] = []
	var count := clampi(roundi((size.x + size.z) / 1.2), MIN_RUBBLE, MAX_RUBBLE)
	for rubble_index: int in count:
		var chunk_size := Vector3(
			random.randf_range(0.4, 1.6), random.randf_range(0.3, 1.0), random.randf_range(0.4, 1.6)
		)
		var outward := random.randf_range(0.3, 3.5)
		var along := random.randf_range(-0.5, 0.5)
		var rubble_position := _perimeter_point(size, random.randi_range(0, 3), along, outward)
		var center := Vector3(rubble_position.x, chunk_size.y * 0.35, rubble_position.y)
		var spin := Vector3(
			random.randf_range(-0.3, 0.3), random.randf() * TAU, random.randf_range(-0.3, 0.3)
		)
		pieces.append(RuinPiece.create(RuinPiece.Kind.RUBBLE, center, chunk_size, spin))
	return pieces


static func _perimeter_point(
	size: Vector3, side: int, along_fraction: float, outward: float
) -> Vector2:
	var half_x := size.x / 2.0
	var half_z := size.z / 2.0
	if side == 0:
		return Vector2(along_fraction * size.x, -half_z - outward)
	if side == 1:
		return Vector2(along_fraction * size.x, half_z + outward)
	if side == 2:
		return Vector2(-half_x - outward, along_fraction * size.z)
	return Vector2(half_x + outward, along_fraction * size.z)
