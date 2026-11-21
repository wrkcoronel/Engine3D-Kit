class_name RuinPiece
extends RefCounted

enum Kind { WALL, COLUMN, SLAB, REBAR, RUBBLE }

var kind := Kind.WALL
var center := Vector3.ZERO
var size := Vector3.ONE
var rotation := Vector3.ZERO


static func create(
	piece_kind: Kind, piece_center: Vector3, piece_size: Vector3, piece_rotation: Vector3
) -> RuinPiece:
	var piece := RuinPiece.new()
	piece.kind = piece_kind
	piece.center = piece_center
	piece.size = piece_size
	piece.rotation = piece_rotation
	return piece


func has_collision() -> bool:
	if kind == Kind.WALL:
		return true
	if kind == Kind.COLUMN:
		return true
	return kind == Kind.SLAB
