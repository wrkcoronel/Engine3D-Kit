class_name MotelPiece
extends RefCounted

var center: Vector3
var size: Vector3
var material_name: String
var solid: bool
var rotation: Vector3


func _init(
	piece_center: Vector3,
	piece_size: Vector3,
	piece_material: String,
	is_solid: bool = true,
	piece_rotation: Vector3 = Vector3.ZERO
) -> void:
	center = piece_center
	size = piece_size
	material_name = piece_material
	solid = is_solid
	rotation = piece_rotation


static func from_bounds(
	min_corner: Vector3, max_corner: Vector3, piece_material: String, is_solid: bool = true
) -> MotelPiece:
	var piece_size := max_corner - min_corner
	var piece_center := (min_corner + max_corner) * 0.5
	return MotelPiece.new(piece_center, piece_size, piece_material, is_solid)
