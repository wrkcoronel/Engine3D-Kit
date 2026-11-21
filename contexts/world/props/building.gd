class_name Building
extends StaticBody3D

@export var size := Vector3(20, 15, 20)
@export var color := Color(0.6, 0.6, 0.65)
@export var ruin_material: ShaderMaterial


func _ready() -> void:
	var pieces := RuinLayout.build(size, ruin_seed())
	var arrays := RuinMeshArrays.new()
	for piece: RuinPiece in pieces:
		var is_concrete := piece.kind != RuinPiece.Kind.REBAR
		arrays.add_box(piece.center, piece.size, piece.rotation, is_concrete)
		if piece.has_collision():
			_add_collision(piece)
	_add_visual(arrays.to_mesh())


func ruin_seed() -> int:
	return hash(Vector2i(roundi(position.x), roundi(position.z)))


func _add_collision(piece: RuinPiece) -> void:
	var shape := BoxShape3D.new()
	shape.size = piece.size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(Basis.from_euler(piece.rotation), piece.center)
	add_child(collision)


func _add_visual(mesh: ArrayMesh) -> void:
	var material := ruin_material.duplicate() as ShaderMaterial
	material.set_shader_parameter("tint", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("building_seed", float(ruin_seed() % 97))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
