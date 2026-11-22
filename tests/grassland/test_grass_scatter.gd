extends TestCase

const HEIGHT_RANGE := Vector2(0.7, 1.0)
const CHUNK_CORNER := Vector2(10.0, -20.0)
const CHUNK_SIZE := 10.0


func test_lowest_noise_gives_shortest_height() -> void:
	var height_scale := GrassScatter.height_scale_at(-1.0, HEIGHT_RANGE, 0.0)
	assert_near(height_scale, HEIGHT_RANGE.x, 0.001, "ruido minimo vira a altura minima")


func test_highest_noise_gives_tallest_height() -> void:
	var height_scale := GrassScatter.height_scale_at(1.0, HEIGHT_RANGE, 0.0)
	assert_near(height_scale, HEIGHT_RANGE.y, 0.001, "ruido maximo vira a altura maxima")


func test_jitter_never_leaves_height_range() -> void:
	var too_tall := GrassScatter.height_scale_at(1.0, HEIGHT_RANGE, 0.5)
	var too_short := GrassScatter.height_scale_at(-1.0, HEIGHT_RANGE, -0.5)
	assert_near(too_tall, HEIGHT_RANGE.y, 0.001, "variacao nao passa da altura maxima")
	assert_near(too_short, HEIGHT_RANGE.x, 0.001, "variacao nao passa da altura minima")


func test_chunk_has_requested_clump_count() -> void:
	var transforms := _scatter_chunk(25, 1)
	assert_eq(transforms.size(), 25, "quantidade de tufos do pedaco")


func test_clumps_stay_inside_chunk_on_the_ground() -> void:
	var transforms := _scatter_chunk(200, 1)
	for clump_transform: Transform3D in transforms:
		var position := clump_transform.origin
		var inside_x := position.x >= CHUNK_CORNER.x and position.x <= CHUNK_CORNER.x + CHUNK_SIZE
		var inside_z := position.z >= CHUNK_CORNER.y and position.z <= CHUNK_CORNER.y + CHUNK_SIZE
		assert_true(inside_x and inside_z, "tufo dentro do pedaco: %s" % position)
		assert_eq(position.y, 0.0, "tufo nasce no chao")


func test_clump_heights_stay_inside_range() -> void:
	var transforms := _scatter_chunk(200, 1)
	for clump_transform: Transform3D in transforms:
		var height_scale := clump_transform.basis.get_scale().y
		assert_true(height_scale >= HEIGHT_RANGE.x - 0.001, "altura acima do minimo")
		assert_true(height_scale <= HEIGHT_RANGE.y + 0.001, "altura abaixo do maximo")


func test_same_seed_gives_same_field() -> void:
	var first := _scatter_chunk(50, 3)
	var second := _scatter_chunk(50, 3)
	assert_eq(first, second, "mesma semente, mesmo campo")


func test_different_seed_gives_different_field() -> void:
	var first := _scatter_chunk(50, 3)
	var second := _scatter_chunk(50, 4)
	assert_true(first != second, "semente diferente, campo diferente")


func test_cleared_area_keeps_clumps_outside() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 5
	var height_noise := GrassScatter.create_height_noise(5, 0.07)
	var cleared := Rect2(CHUNK_CORNER, Vector2(5.0, 10.0))
	var transforms := GrassScatter.chunk_transforms(
		CHUNK_CORNER, CHUNK_SIZE, 200, height_noise, HEIGHT_RANGE, random, cleared
	)
	assert_true(transforms.size() > 0, "ainda nasce mato fora da area limpa")
	for clump_transform: Transform3D in transforms:
		var point := Vector2(clump_transform.origin.x, clump_transform.origin.z)
		assert_true(not cleared.has_point(point), "nenhum tufo nasce dentro da area limpa")


func _scatter_chunk(clump_count: int, random_seed: int) -> Array[Transform3D]:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var height_noise := GrassScatter.create_height_noise(random_seed, 0.07)
	return GrassScatter.chunk_transforms(
		CHUNK_CORNER, CHUNK_SIZE, clump_count, height_noise, HEIGHT_RANGE, random
	)
