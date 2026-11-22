class_name GrassField
extends Node3D

const CLUMP_VARIANT_COUNT := 3
const TRAIL_RECENTER_DISTANCE := 110.0
const VEHICLE_GROUP := "vehicles"
const REFRESH_SECONDS := 0.2

@export var grass_material: ShaderMaterial
@export var field_size := 3000.0
@export var chunk_size := 16.0
@export var near_radius := 20.0
@export var far_radius := 55.0
@export var near_clumps_per_square_meter := 9.0
@export var far_clumps_per_square_meter := 4.5
@export var height_range := Vector2(0.72, 1.0)
@export var height_noise_frequency := 0.07
@export var random_seed := 7
@export var chunks_per_frame := 2
@export var first_frame_chunks := 80
@export var vehicle_half_size := Vector2(0.95, 2.1)
@export var trail_recovery_seconds := 30.0
@export var trail_window_size := 320.0
@export var trail_resolution := 1280
@export var trail_padding := 0.25
@export var cleared_area := Rect2()
@export var extra_cleared_areas: Array[Rect2] = []

var _clump_meshes: Array[ArrayMesh] = []
var _trail_origin := Vector2.ZERO
var _height_noise: FastNoiseLite
var _chunks: Dictionary = {}
var _wanted: Dictionary = {}
var _trail := GrassTrail.new()
var _seconds_until_refresh := 0.0
var _first_frame := true


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_height_noise = GrassScatter.create_height_noise(random_seed, height_noise_frequency)
	_build_meshes()
	_setup_distance_fade()
	_setup_trail()


func _process(delta: float) -> void:
	_trail.advance(delta)
	_recenter_trail_if_far(_focus_point())
	_follow_vehicle()
	_seconds_until_refresh -= delta
	if _seconds_until_refresh <= 0.0:
		_seconds_until_refresh = REFRESH_SECONDS
		_wanted = _wanted_levels(_focus_point())
	var budget := chunks_per_frame
	if _first_frame:
		budget = first_frame_chunks
		_first_frame = false
	_free_unwanted_chunks()
	_plant_missing_chunks(budget)


func update_chunks(focus: Vector2, budget: int) -> void:
	_wanted = _wanted_levels(focus)
	_free_unwanted_chunks()
	_plant_missing_chunks(budget)


func trail_origin() -> Vector2:
	return _trail_origin


func chunk_count() -> int:
	return _chunks.size()


func chunk_at(cell: Vector2i) -> GrassChunk:
	return _chunks.get(cell) as GrassChunk


func _build_meshes() -> void:
	for variant_index: int in CLUMP_VARIANT_COUNT:
		var variant_seed := random_seed + variant_index
		_clump_meshes.append(GrassClumpMesh.build(variant_seed))


func _setup_trail() -> void:
	_trail.setup(trail_resolution, trail_recovery_seconds)
	add_child(_trail)
	grass_material.set_shader_parameter("trample_map", _trail.get_texture())
	grass_material.set_shader_parameter("trample_size", trail_window_size)
	_move_trail_window(Vector2.ZERO)


func _follow_vehicle() -> void:
	var vehicle := get_tree().get_first_node_in_group(VEHICLE_GROUP) as Node3D
	if vehicle == null:
		GrassClearing.release(grass_material)
		_trail.clear_stamp()
		return
	var vehicle_transform := vehicle.get_global_transform_interpolated()
	GrassClearing.follow(grass_material, vehicle_transform, vehicle_half_size)
	var footprint := GrassTrail.footprint_in_map(
		vehicle_transform,
		vehicle_half_size,
		trail_padding,
		_trail_origin,
		trail_window_size,
		trail_resolution
	)
	_trail.stamp(footprint)


func _focus_point() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	return Vector2(camera.global_position.x, camera.global_position.z)


func _wanted_levels(focus: Vector2) -> Dictionary:
	var current_levels := {}
	for cell: Vector2i in _chunks:
		current_levels[cell] = (_chunks[cell] as GrassChunk).level
	return GrassStreamer.wanted_levels(
		focus, chunk_size, field_size, near_radius, far_radius, current_levels
	)


func _free_unwanted_chunks() -> void:
	for cell: Vector2i in _chunks.keys():
		if _wanted.has(cell):
			continue
		(_chunks[cell] as GrassChunk).queue_free()
		_chunks.erase(cell)


func _plant_missing_chunks(budget: int) -> void:
	var pending := _pending_cells()
	var planted := 0
	for cell: Vector2i in pending:
		if planted >= budget:
			return
		_replace_chunk(cell, _wanted[cell] as int)
		planted += 1


func _pending_cells() -> Array[Vector2i]:
	var pending: Array[Vector2i] = []
	for cell: Vector2i in _wanted:
		var existing := _chunks.get(cell) as GrassChunk
		if existing == null or existing.level != _wanted[cell] as int:
			pending.append(cell)
	var focus := _focus_point()
	pending.sort_custom(
		func(first: Vector2i, second: Vector2i) -> bool:
			var first_distance := GrassStreamer.cell_center(first, chunk_size).distance_to(focus)
			var second_distance := GrassStreamer.cell_center(second, chunk_size).distance_to(focus)
			return first_distance < second_distance
	)
	return pending


func _replace_chunk(cell: Vector2i, level: int) -> void:
	var old_chunk := _chunks.get(cell) as GrassChunk
	if old_chunk != null:
		old_chunk.queue_free()
	var chunk := _build_chunk(cell, level)
	add_child(chunk)
	_chunks[cell] = chunk


func _build_chunk(cell: Vector2i, level: int) -> GrassChunk:
	var chunk := GrassChunk.new()
	chunk.cell = cell
	chunk.level = level
	var density := near_clumps_per_square_meter
	if level == GrassStreamer.FAR_LEVEL:
		density = far_clumps_per_square_meter
	var random := RandomNumberGenerator.new()
	random.seed = hash(Vector3i(cell.x, cell.y, random_seed))
	var chunk_corner := Vector2(cell) * chunk_size
	var clumps_per_variant := roundi(chunk_size * chunk_size * density / float(CLUMP_VARIANT_COUNT))
	for clump_mesh: ArrayMesh in _clump_meshes:
		var transforms := GrassScatter.chunk_transforms(
			chunk_corner,
			chunk_size,
			clumps_per_variant,
			_height_noise,
			height_range,
			random,
			cleared_area,
			extra_cleared_areas
		)
		chunk.plant(clump_mesh, transforms, grass_material)
	return chunk


func _recenter_trail_if_far(focus: Vector2) -> void:
	var window_center := _trail_origin + Vector2.ONE * trail_window_size / 2.0
	if focus.distance_to(window_center) < TRAIL_RECENTER_DISTANCE:
		return
	_trail.clear_all()
	_move_trail_window(focus)


func _move_trail_window(center: Vector2) -> void:
	var snapped_center := (center / chunk_size).round() * chunk_size
	_trail_origin = snapped_center - Vector2.ONE * trail_window_size / 2.0
	grass_material.set_shader_parameter("trample_origin", _trail_origin)


func _setup_distance_fade() -> void:
	var fade_start := GrassStreamer.fade_start_distance(far_radius, chunk_size)
	var fade_end := GrassStreamer.fade_end_distance(far_radius, chunk_size)
	grass_material.set_shader_parameter("fade_start_distance", fade_start)
	grass_material.set_shader_parameter("fade_end_distance", fade_end)
